package com.knevo.service;

import com.knevo.dto.session.*;
import com.knevo.model.*;
import com.knevo.repository.*;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SessionService {

    private final UserRepository userRepository;
    private final TherapyConfigRepository therapyConfigRepository;
    private final TherapySetConfigRepository setConfigRepository;
    private final SessionRepository sessionRepository;
    private final TherapySetRecordRepository setRecordRepository;
    private final PainLogRepository painLogRepository;
    private final AlertRepository alertRepository;

    @Transactional
    public SessionDto startSession(UUID patientId, StartSessionRequest req) {
        User patient = userRepository.findById(patientId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Patient not found"));

        if (req.getPainBefore() >= 7) {
            Alert alert = new Alert();
            alert.setPatient(patient);
            alert.setAlertType("HIGH_PAIN");
            alert.setSeverity("WARNING");
            alert.setMessage("Patient reported pain level " + req.getPainBefore()
                + " before session start — session blocked.");
            alert.setStatus("OPEN");
            alertRepository.save(alert);
            throw new ResponseStatusException(HttpStatus.UNPROCESSABLE_ENTITY,
                "Session blocked: pain level " + req.getPainBefore()
                    + " is too high to start. Please rest and consult your doctor.");
        }

        TherapyConfig config = therapyConfigRepository.findById(req.getConfigId())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Therapy config not found"));

        Session session = new Session();
        session.setPatient(patient);
        session.setTherapyConfig(config);
        session.setStatus("IN_PROGRESS");
        session.setStartedAt(OffsetDateTime.now());
        session.setPainBefore(req.getPainBefore());
        session = sessionRepository.save(session);

        PainLog painLog = new PainLog();
        painLog.setPatient(patient);
        painLog.setSession(session);
        painLog.setPainLevel(req.getPainBefore());
        painLog.setContext("BEFORE_SESSION");
        painLogRepository.save(painLog);

        return toDto(session, List.of());
    }

    @Transactional
    public SetRecordDto startSet(UUID sessionId, StartSetRequest req) {
        Session session = getActiveSession(sessionId);
        TherapySetConfig setConfig = setConfigRepository.findById(req.getTherapySetConfigId())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Set config not found"));

        TherapySetRecord record = new TherapySetRecord();
        record.setSession(session);
        record.setTherapySetConfig(setConfig);
        record.setExercise(setConfig.getExercise());
        record.setDeviceAssisted(setConfig.isDeviceAssisted());
        record.setPlannedDurationMin(setConfig.getDurationMin());
        record.setPlannedRestDurationMin(setConfig.getRestDurationMin());
        record.setStartDatetime(OffsetDateTime.now());
        record.setStatus("IN_PROGRESS");
        record = setRecordRepository.save(record);

        return toSetRecordDto(record);
    }

    @Transactional
    public SetRecordDto stopSet(UUID sessionId, StopSetRequest req) {
        getActiveSession(sessionId);
        TherapySetRecord record = setRecordRepository.findById(req.getTherapySetRecordId())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Set record not found"));

        record.setStopDatetime(OffsetDateTime.now());
        record.setPainLevel(req.getPainLevel());
        record.setPatientFeedback(req.getFeedback());
        record.setStatus("COMPLETED");
        record = setRecordRepository.save(record);

        if (req.getPainLevel() != null && req.getPainLevel() >= 4) {
            Session session = record.getSession();
            PainLog log = new PainLog();
            log.setPatient(session.getPatient());
            log.setSession(session);
            log.setPainLevel(req.getPainLevel());
            log.setContext("DURING_SESSION");
            painLogRepository.save(log);
        }

        return toSetRecordDto(record);
    }

    @Transactional
    public SessionDto handlePainButton(UUID sessionId, PainButtonRequest req) {
        Session session = getActiveSession(sessionId);
        session.setPainDuring(req.getPainLevel());
        session.setStatus("STOPPED_DUE_TO_PAIN");
        session.setEndedAt(OffsetDateTime.now());
        session = sessionRepository.save(session);

        PainLog log = new PainLog();
        log.setPatient(session.getPatient());
        log.setSession(session);
        log.setPainLevel(req.getPainLevel());
        log.setContext("DURING_SESSION");
        painLogRepository.save(log);

        if (req.getPainLevel() >= 7) {
            Alert alert = new Alert();
            alert.setPatient(session.getPatient());
            alert.setSession(session);
            alert.setAlertType(req.getPainLevel() >= 9 ? "SEVERE_PAIN" : "HIGH_PAIN");
            alert.setSeverity(req.getPainLevel() >= 9 ? "CRITICAL" : "WARNING");
            alert.setMessage("Patient reported pain level " + req.getPainLevel()
                + " during session — session terminated.");
            alert.setStatus("OPEN");
            alertRepository.save(alert);
        }

        List<TherapySetRecord> records = setRecordRepository.findBySession_Id(sessionId);
        records.stream()
            .filter(r -> "IN_PROGRESS".equals(r.getStatus()))
            .forEach(r -> {
                r.setStopDatetime(OffsetDateTime.now());
                r.setStatus("STOPPED_DUE_TO_PAIN");
                setRecordRepository.save(r);
            });

        return toDto(session, setRecordRepository.findBySession_Id(sessionId));
    }

    @Transactional
    public SessionDto completeSession(UUID sessionId, CompleteSessionRequest req) {
        Session session = getActiveSession(sessionId);
        session.setStatus("COMPLETED");
        session.setEndedAt(OffsetDateTime.now());
        session.setPainAfter(req.getPainAfter());
        session = sessionRepository.save(session);

        if (req.getPainAfter() != null) {
            PainLog log = new PainLog();
            log.setPatient(session.getPatient());
            log.setSession(session);
            log.setPainLevel(req.getPainAfter());
            log.setContext("AFTER_SESSION");
            painLogRepository.save(log);
        }

        List<TherapySetRecord> records = setRecordRepository.findBySession_Id(sessionId);
        return toDto(session, records);
    }

    @Transactional
    public SessionDto stopSession(UUID sessionId) {
        Session session = getActiveSession(sessionId);
        session.setStatus("STOPPED_BY_PATIENT");
        session.setEndedAt(OffsetDateTime.now());
        session = sessionRepository.save(session);

        List<TherapySetRecord> records = setRecordRepository.findBySession_Id(sessionId);
        records.stream()
            .filter(r -> "IN_PROGRESS".equals(r.getStatus()))
            .forEach(r -> {
                r.setStopDatetime(OffsetDateTime.now());
                r.setStatus("COMPLETED");
                setRecordRepository.save(r);
            });

        return toDto(session, setRecordRepository.findBySession_Id(sessionId));
    }

    public SessionDto getSession(UUID sessionId) {
        Session session = sessionRepository.findById(sessionId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));
        return toDto(session, setRecordRepository.findBySession_Id(sessionId));
    }

    public List<SessionDto> getPatientSessions(UUID patientId) {
        return sessionRepository.findByPatient_IdOrderByStartedAtDesc(patientId)
            .stream().map(s -> toDto(s, List.of())).toList();
    }

    private Session getActiveSession(UUID sessionId) {
        Session session = sessionRepository.findById(sessionId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));
        if (!"IN_PROGRESS".equals(session.getStatus())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Session is not in progress");
        }
        return session;
    }

    private SetRecordDto toSetRecordDto(TherapySetRecord record) {
        SetRecordDto dto = new SetRecordDto();
        dto.setId(record.getId());
        dto.setTherapySetConfigId(
            record.getTherapySetConfig() != null ? record.getTherapySetConfig().getId() : null);
        dto.setStartDatetime(record.getStartDatetime());
        dto.setStopDatetime(record.getStopDatetime());
        dto.setPainLevel(record.getPainLevel());
        dto.setFeedback(record.getPatientFeedback());
        dto.setStatus(record.getStatus());
        return dto;
    }

    private SessionDto toDto(Session session, List<TherapySetRecord> records) {
        SessionDto dto = new SessionDto();
        dto.setId(session.getId());
        dto.setPatientId(session.getPatient().getId());
        dto.setTherapyConfigId(
            session.getTherapyConfig() != null ? session.getTherapyConfig().getId() : null);
        dto.setStatus(session.getStatus());
        dto.setStartedAt(session.getStartedAt());
        dto.setEndedAt(session.getEndedAt());
        dto.setPainBefore(session.getPainBefore());
        dto.setPainDuring(session.getPainDuring());
        dto.setPainAfter(session.getPainAfter());
        dto.setSetRecords(records.stream().map(this::toSetRecordDto).toList());
        return dto;
    }
}

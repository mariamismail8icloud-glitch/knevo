package com.knevo.service;

import com.knevo.dto.sensor.SensorBatchResponse;
import com.knevo.dto.sensor.SensorReadingDto;
import com.knevo.dto.sensor.SensorReadingResponse;
import com.knevo.model.Session;
import com.knevo.model.TherapySetRecord;
import com.knevo.model.User;
import com.knevo.repository.SensorReadingRepository;
import com.knevo.repository.SessionRepository;
import com.knevo.repository.TherapySetRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.ArrayList;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SensorReadingService {

    private final TherapySetRecordRepository setRecordRepository;
    private final SensorReadingRepository sensorReadingRepository;
    private final SessionRepository sessionRepository;

    /** Default cap on returned points so the doctor portal isn't flooded (§5.2). */
    private static final int DEFAULT_MAX_POINTS = 2000;

    /**
     * Bulk-inserts raw sensor readings for a completed set after validating that
     * the set belongs to the given session and that session belongs to the
     * authenticated patient (decisions §5.1).
     */
    @Transactional
    public SensorBatchResponse ingest(UUID patientId, UUID sessionId, UUID setRecordId,
                                      List<SensorReadingDto> readings) {
        TherapySetRecord record = setRecordRepository.findById(setRecordId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Set record not found"));

        if (record.getSession() == null || !sessionId.equals(record.getSession().getId())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                "Set record does not belong to this session");
        }

        if (record.getSession().getPatient() == null
            || !patientId.equals(record.getSession().getPatient().getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                "You do not have access to this session");
        }

        if (readings == null || readings.isEmpty()) {
            return new SensorBatchResponse(0);
        }

        int inserted = sensorReadingRepository.batchInsert(setRecordId, readings);
        return new SensorBatchResponse(inserted);
    }

    /**
     * Returns a downsampled sensor series for a completed session so the doctor
     * portal can draw FSR-load and (Phase 3) knee-angle graphs (decisions §5.2).
     *
     * <p>Authorization: the session's patient must be assigned to the requesting
     * doctor (404 if the session does not exist, 403 if a different doctor asks).
     *
     * @param setRecordId optional filter to a single set; must belong to the session.
     * @param maxPoints   optional cap on total returned points (default 2000). The
     *                    series is thinned by keeping every Nth ordered sample where
     *                    N = ceil(total / maxPoints).
     */
    @Transactional(readOnly = true)
    public List<SensorReadingResponse> getReadingsForGraph(UUID doctorId, UUID sessionId,
                                                           UUID setRecordId, Integer maxPoints) {
        Session session = sessionRepository.findById(sessionId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Session not found"));

        User patient = session.getPatient();
        if (patient == null || patient.getDoctor() == null
            || !doctorId.equals(patient.getDoctor().getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                "You do not have access to this session");
        }

        List<TherapySetRecord> records = setRecordRepository.findBySession_Id(sessionId);
        if (setRecordId != null) {
            records = records.stream()
                .filter(r -> setRecordId.equals(r.getId()))
                .toList();
            if (records.isEmpty()) {
                throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                    "Set record does not belong to this session");
            }
        }

        int cap = (maxPoints != null && maxPoints > 0) ? maxPoints : DEFAULT_MAX_POINTS;

        long total = 0;
        for (TherapySetRecord r : records) {
            total += sensorReadingRepository.countForSet(r.getId());
        }
        if (total == 0) {
            return List.of();
        }
        int stride = (int) Math.ceil((double) total / cap);

        List<SensorReadingResponse> out = new ArrayList<>();
        for (TherapySetRecord r : records) {
            out.addAll(sensorReadingRepository.findForGraph(r.getId(), stride));
        }
        return out;
    }
}

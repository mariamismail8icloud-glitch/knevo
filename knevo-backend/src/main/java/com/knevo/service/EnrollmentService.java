package com.knevo.service;

import com.knevo.dto.enrollment.EnrollPatientRequest;
import com.knevo.dto.enrollment.EnrollmentCodeResponse;
import com.knevo.dto.patient.PatientSummaryDto;
import com.knevo.model.AuditLog;
import com.knevo.model.User;
import com.knevo.repository.AuditLogRepository;
import com.knevo.repository.UserRepository;
import com.knevo.util.EnrollmentCodeGenerator;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class EnrollmentService {

    private final UserRepository userRepository;
    private final AuditLogRepository auditLogRepository;
    private final EnrollmentCodeGenerator codeGenerator;

    public EnrollmentCodeResponse getCode(UUID patientId) {
        User patient = userRepository.findById(patientId)
            .filter(u -> u.getRole() == User.Role.PATIENT)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Patient not found"));
        return new EnrollmentCodeResponse(patient.getEnrollmentCode());
    }

    public EnrollmentCodeResponse regenerateCode(UUID patientId) {
        User patient = userRepository.findById(patientId)
            .filter(u -> u.getRole() == User.Role.PATIENT)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Patient not found"));
        patient.setEnrollmentCode(codeGenerator.generate());
        userRepository.save(patient);
        return new EnrollmentCodeResponse(patient.getEnrollmentCode());
    }

    public PatientSummaryDto enrollPatient(UUID doctorId, EnrollPatientRequest req) {
        User patient = userRepository.findByEnrollmentCode(req.getEnrollmentCode())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Invalid enrollment code"));

        if (patient.getRole() != User.Role.PATIENT) {
            throw new ResponseStatusException(HttpStatus.BAD_REQUEST, "Code does not belong to a patient");
        }

        User doctor = userRepository.findById(doctorId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Doctor not found"));

        patient.setDoctor(doctor);
        userRepository.save(patient);

        AuditLog log = new AuditLog();
        log.setUserId(doctorId);
        log.setRole("DOCTOR");
        log.setAction("ENROLL_PATIENT");
        log.setEntityType("USER");
        log.setEntityId(patient.getId());
        log.setPatientId(patient.getId());
        auditLogRepository.save(log);

        return toSummary(patient);
    }

    public List<PatientSummaryDto> getDoctorPatients(UUID doctorId) {
        return userRepository.findByDoctor_Id(doctorId)
            .stream()
            .map(this::toSummary)
            .collect(Collectors.toList());
    }

    public PatientSummaryDto getPatient(UUID patientId) {
        User patient = userRepository.findById(patientId)
            .orElseThrow(() -> new org.springframework.web.server.ResponseStatusException(
                org.springframework.http.HttpStatus.NOT_FOUND, "Patient not found"));
        return toSummary(patient);
    }

    public List<PatientSummaryDto> getAllPatients() {
        return userRepository.findByRoleOrderByCreatedAtDesc(User.Role.PATIENT)
            .stream()
            .map(this::toSummary)
            .collect(Collectors.toList());
    }

    private PatientSummaryDto toSummary(User patient) {
        return new PatientSummaryDto(
            patient.getId(),
            patient.getName(),
            patient.getEmail(),
            patient.getPhone(),
            patient.getEnrollmentCode()
        );
    }
}

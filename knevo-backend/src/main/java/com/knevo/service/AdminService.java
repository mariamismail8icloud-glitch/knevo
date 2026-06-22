package com.knevo.service;

import com.knevo.dto.admin.DoctorSummaryDto;
import com.knevo.model.AuditLog;
import com.knevo.model.User;
import com.knevo.repository.AuditLogRepository;
import com.knevo.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class AdminService {

    private final UserRepository userRepository;
    private final AuditLogRepository auditLogRepository;

    public List<DoctorSummaryDto> getPendingDoctors() {
        return userRepository.findByRoleAndDoctorStatus(User.Role.DOCTOR, User.DoctorStatus.PENDING)
            .stream()
            .map(u -> new DoctorSummaryDto(u.getId(), u.getName(), u.getEmail(),
                u.getClinicName(), u.getSpecialization(), u.getDoctorStatus().name(), u.getCreatedAt()))
            .collect(Collectors.toList());
    }

    public void approveDoctor(UUID doctorId, UUID adminId) {
        User doctor = getDoctorOrThrow(doctorId);
        doctor.setDoctorStatus(User.DoctorStatus.APPROVED);
        userRepository.save(doctor);
        logAction(adminId, "APPROVE_DOCTOR", "USER", doctorId, null, null);
    }

    public void rejectDoctor(UUID doctorId, UUID adminId, String reason) {
        User doctor = getDoctorOrThrow(doctorId);
        doctor.setDoctorStatus(User.DoctorStatus.REJECTED);
        doctor.setRejectionReason(reason);
        userRepository.save(doctor);
        logAction(adminId, "REJECT_DOCTOR", "USER", doctorId, null, reason);
    }

    private User getDoctorOrThrow(UUID id) {
        return userRepository.findById(id)
            .filter(u -> u.getRole() == User.Role.DOCTOR)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Doctor not found"));
    }

    private void logAction(UUID actorId, String action, String entityType, UUID entityId,
                           UUID patientId, String reason) {
        AuditLog log = new AuditLog();
        log.setUserId(actorId);
        log.setRole("ADMIN");
        log.setAction(action);
        log.setEntityType(entityType);
        log.setEntityId(entityId);
        log.setPatientId(patientId);
        log.setReason(reason);
        auditLogRepository.save(log);
    }
}

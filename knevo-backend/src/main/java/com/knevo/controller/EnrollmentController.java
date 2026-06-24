package com.knevo.controller;

import com.knevo.dto.enrollment.EnrollPatientRequest;
import com.knevo.dto.enrollment.EnrollmentCodeResponse;
import com.knevo.dto.patient.PatientSummaryDto;
import com.knevo.service.EnrollmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class EnrollmentController {

    private final EnrollmentService enrollmentService;

    @GetMapping("/api/patient/enrollment-code")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<EnrollmentCodeResponse> getCode(Authentication auth) {
        return ResponseEntity.ok(enrollmentService.getCode(UUID.fromString(auth.getName())));
    }

    @PostMapping("/api/patients/enrollment-code")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<EnrollmentCodeResponse> regenerateCode(Authentication auth) {
        return ResponseEntity.ok(enrollmentService.regenerateCode(UUID.fromString(auth.getName())));
    }

    @PostMapping("/api/doctor/enroll-patient")
    @PreAuthorize("hasRole('DOCTOR')")
    public ResponseEntity<PatientSummaryDto> enrollPatient(Authentication auth,
                                                           @Valid @RequestBody EnrollPatientRequest req) {
        return ResponseEntity.ok(enrollmentService.enrollPatient(UUID.fromString(auth.getName()), req));
    }

    @GetMapping("/api/doctor/patients")
    @PreAuthorize("hasRole('DOCTOR')")
    public ResponseEntity<List<PatientSummaryDto>> getPatients(Authentication auth) {
        return ResponseEntity.ok(enrollmentService.getDoctorPatients(UUID.fromString(auth.getName())));
    }
}

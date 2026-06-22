package com.knevo.controller;

import com.knevo.dto.enrollment.EnrollPatientRequest;
import com.knevo.dto.enrollment.EnrollmentCodeResponse;
import com.knevo.dto.patient.PatientSummaryDto;
import com.knevo.service.EnrollmentService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class EnrollmentController {

    private final EnrollmentService enrollmentService;

    @PostMapping("/api/patients/enrollment-code")
    public ResponseEntity<EnrollmentCodeResponse> regenerateCode(
            @RequestHeader("X-User-Id") UUID patientId) {
        return ResponseEntity.ok(enrollmentService.regenerateCode(patientId));
    }

    @PostMapping("/api/doctor/enroll-patient")
    public ResponseEntity<PatientSummaryDto> enrollPatient(
            @RequestHeader("X-User-Id") UUID doctorId,
            @Valid @RequestBody EnrollPatientRequest req) {
        return ResponseEntity.ok(enrollmentService.enrollPatient(doctorId, req));
    }

    @GetMapping("/api/doctor/patients")
    public ResponseEntity<List<PatientSummaryDto>> getPatients(
            @RequestHeader("X-User-Id") UUID doctorId) {
        return ResponseEntity.ok(enrollmentService.getDoctorPatients(doctorId));
    }
}

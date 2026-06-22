package com.knevo.controller;

import com.knevo.dto.therapy.*;
import com.knevo.service.TherapyPlanService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class TherapyController {

    private final TherapyPlanService therapyPlanService;

    @GetMapping("/api/exercises")
    public ResponseEntity<List<ExerciseDto>> listExercises(
            @RequestParam(required = false) String category,
            @RequestParam(required = false) String mode) {
        return ResponseEntity.ok(therapyPlanService.getActiveExercises(category, mode));
    }

    @GetMapping("/api/exercises/{id}")
    public ResponseEntity<ExerciseDto> getExercise(@PathVariable UUID id) {
        return ResponseEntity.ok(therapyPlanService.getExercise(id));
    }

    @PostMapping("/api/doctor/patients/{patientId}/plans")
    public ResponseEntity<PlanSummaryDto> createPlan(
            @PathVariable UUID patientId,
            @RequestHeader("X-User-Id") UUID doctorId,
            @Valid @RequestBody CreatePlanRequest req) {
        req.setPatientId(patientId);
        return ResponseEntity.status(HttpStatus.CREATED).body(therapyPlanService.createPlan(doctorId, req));
    }

    @GetMapping("/api/doctor/patients/{patientId}/plans")
    public ResponseEntity<List<PlanSummaryDto>> getPatientPlans(@PathVariable UUID patientId) {
        return ResponseEntity.ok(therapyPlanService.getPlansForPatient(patientId));
    }

    @GetMapping("/api/therapy-config/{id}")
    public ResponseEntity<TherapyConfigDto> getConfig(@PathVariable UUID id) {
        return ResponseEntity.ok(therapyPlanService.getConfig(id));
    }

    @GetMapping("/api/patient/active-plan")
    public ResponseEntity<TherapyConfigDto> getActivePlan(
            @RequestHeader("X-User-Id") UUID patientId) {
        return ResponseEntity.ok(therapyPlanService.getActiveConfigForPatient(patientId));
    }
}

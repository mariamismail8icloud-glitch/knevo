package com.knevo.controller;

import com.knevo.dto.therapy.*;
import com.knevo.service.TherapyPlanService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
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
    @PreAuthorize("hasRole('DOCTOR')")
    public ResponseEntity<PlanSummaryDto> createPlan(@PathVariable UUID patientId,
                                                     Authentication auth,
                                                     @Valid @RequestBody CreatePlanRequest req) {
        req.setPatientId(patientId);
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(therapyPlanService.createPlan(UUID.fromString(auth.getName()), req));
    }

    @GetMapping("/api/doctor/patients/{patientId}/plans")
    @PreAuthorize("hasRole('DOCTOR')")
    public ResponseEntity<List<PlanSummaryDto>> getPatientPlans(@PathVariable UUID patientId) {
        return ResponseEntity.ok(therapyPlanService.getPlansForPatient(patientId));
    }

    @GetMapping("/api/therapy-config/{id}")
    @PreAuthorize("hasRole('DOCTOR') or hasRole('PATIENT')")
    public ResponseEntity<TherapyConfigDto> getConfig(@PathVariable UUID id) {
        return ResponseEntity.ok(therapyPlanService.getConfig(id));
    }

    @GetMapping("/api/patient/active-plan")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<TherapyConfigDto> getActivePlan(Authentication auth) {
        return ResponseEntity.ok(therapyPlanService.getActiveConfigForPatient(UUID.fromString(auth.getName())));
    }

    @GetMapping("/api/therapy-config/defaults")
    @PreAuthorize("hasRole('DOCTOR')")
    public ResponseEntity<TherapyDefaultsDto> getConfigDefaults() {
        return ResponseEntity.ok(therapyPlanService.getConfigDefaults());
    }

    @PutMapping("/api/therapy-config/{id}")
    @PreAuthorize("hasRole('DOCTOR')")
    public ResponseEntity<TherapyConfigDto> updateConfig(@PathVariable UUID id,
                                                         @Valid @RequestBody UpdateConfigRequest req) {
        return ResponseEntity.ok(therapyPlanService.updateConfig(id, req));
    }

    @PatchMapping("/api/therapy-config/{id}/delivered")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<Void> markDelivered(@PathVariable UUID id) {
        therapyPlanService.markDelivered(id);
        return ResponseEntity.noContent().build();
    }
}

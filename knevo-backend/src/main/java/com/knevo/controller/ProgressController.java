package com.knevo.controller;

import com.knevo.dto.progress.ProgressResponse;
import com.knevo.service.ProgressService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class ProgressController {

    private final ProgressService progressService;

    @GetMapping("/api/patients/{patientId}/progress")
    @PreAuthorize("hasRole('DOCTOR')")
    public ResponseEntity<ProgressResponse> getProgress(@PathVariable UUID patientId) {
        return ResponseEntity.ok(progressService.getProgress(patientId));
    }

    @GetMapping("/api/patient/progress")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<ProgressResponse> getMyProgress(Authentication auth) {
        return ResponseEntity.ok(progressService.getProgress(UUID.fromString(auth.getName())));
    }
}

package com.knevo.controller;

import com.knevo.dto.progress.ProgressResponse;
import com.knevo.service.ProgressService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.PathVariable;
import org.springframework.web.bind.annotation.RequestHeader;
import org.springframework.web.bind.annotation.RestController;

import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class ProgressController {

    private final ProgressService progressService;

    @GetMapping("/api/patients/{patientId}/progress")
    public ResponseEntity<ProgressResponse> getProgress(@PathVariable UUID patientId) {
        return ResponseEntity.ok(progressService.getProgress(patientId));
    }

    @GetMapping("/api/patient/progress")
    public ResponseEntity<ProgressResponse> getMyProgress(
            @RequestHeader("X-User-Id") UUID patientId) {
        return ResponseEntity.ok(progressService.getProgress(patientId));
    }
}

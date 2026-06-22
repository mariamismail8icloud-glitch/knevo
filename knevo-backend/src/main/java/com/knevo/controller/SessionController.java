package com.knevo.controller;

import com.knevo.dto.session.*;
import com.knevo.service.SessionService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class SessionController {

    private final SessionService sessionService;

    @PostMapping("/api/sessions/start")
    public ResponseEntity<SessionDto> startSession(
            @RequestHeader("X-User-Id") UUID patientId,
            @Valid @RequestBody StartSessionRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(sessionService.startSession(patientId, req));
    }

    @PostMapping("/api/sessions/{sessionId}/start-set")
    public ResponseEntity<SetRecordDto> startSet(
            @PathVariable UUID sessionId,
            @Valid @RequestBody StartSetRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(sessionService.startSet(sessionId, req));
    }

    @PostMapping("/api/sessions/{sessionId}/stop-set")
    public ResponseEntity<SetRecordDto> stopSet(
            @PathVariable UUID sessionId,
            @Valid @RequestBody StopSetRequest req) {
        return ResponseEntity.ok(sessionService.stopSet(sessionId, req));
    }

    @PostMapping("/api/sessions/{sessionId}/pain-button")
    public ResponseEntity<SessionDto> painButton(
            @PathVariable UUID sessionId,
            @Valid @RequestBody PainButtonRequest req) {
        return ResponseEntity.ok(sessionService.handlePainButton(sessionId, req));
    }

    @PostMapping("/api/sessions/{sessionId}/complete")
    public ResponseEntity<SessionDto> completeSession(
            @PathVariable UUID sessionId,
            @Valid @RequestBody CompleteSessionRequest req) {
        return ResponseEntity.ok(sessionService.completeSession(sessionId, req));
    }

    @PostMapping("/api/sessions/{sessionId}/stop")
    public ResponseEntity<SessionDto> stopSession(@PathVariable UUID sessionId) {
        return ResponseEntity.ok(sessionService.stopSession(sessionId));
    }

    @GetMapping("/api/sessions/{sessionId}")
    public ResponseEntity<SessionDto> getSession(@PathVariable UUID sessionId) {
        return ResponseEntity.ok(sessionService.getSession(sessionId));
    }

    @GetMapping("/api/patient/sessions")
    public ResponseEntity<List<SessionDto>> getPatientSessions(
            @RequestHeader("X-User-Id") UUID patientId) {
        return ResponseEntity.ok(sessionService.getPatientSessions(patientId));
    }
}

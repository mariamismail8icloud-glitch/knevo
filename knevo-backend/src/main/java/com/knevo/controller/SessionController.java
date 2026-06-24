package com.knevo.controller;

import com.knevo.dto.session.*;
import com.knevo.service.SessionService;
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
public class SessionController {

    private final SessionService sessionService;

    @PostMapping("/api/sessions/start")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<SessionDto> startSession(Authentication auth,
                                                   @Valid @RequestBody StartSessionRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(sessionService.startSession(UUID.fromString(auth.getName()), req));
    }

    @PostMapping("/api/sessions/{sessionId}/start-set")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<SetRecordDto> startSet(@PathVariable UUID sessionId,
                                                 @Valid @RequestBody StartSetRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(sessionService.startSet(sessionId, req));
    }

    @PostMapping("/api/sessions/{sessionId}/stop-set")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<SetRecordDto> stopSet(@PathVariable UUID sessionId,
                                                @Valid @RequestBody StopSetRequest req) {
        return ResponseEntity.ok(sessionService.stopSet(sessionId, req));
    }

    @PostMapping("/api/sessions/{sessionId}/pain-button")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<SessionDto> painButton(@PathVariable UUID sessionId,
                                                 @Valid @RequestBody PainButtonRequest req) {
        return ResponseEntity.ok(sessionService.handlePainButton(sessionId, req));
    }

    @PostMapping("/api/sessions/{sessionId}/complete")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<SessionDto> completeSession(@PathVariable UUID sessionId,
                                                      @Valid @RequestBody CompleteSessionRequest req) {
        return ResponseEntity.ok(sessionService.completeSession(sessionId, req));
    }

    @PostMapping("/api/sessions/{sessionId}/stop")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<SessionDto> stopSession(@PathVariable UUID sessionId) {
        return ResponseEntity.ok(sessionService.stopSession(sessionId));
    }

    @GetMapping("/api/sessions/{sessionId}")
    @PreAuthorize("hasRole('PATIENT') or hasRole('DOCTOR')")
    public ResponseEntity<SessionDto> getSession(@PathVariable UUID sessionId) {
        return ResponseEntity.ok(sessionService.getSession(sessionId));
    }

    @GetMapping("/api/patient/sessions")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<List<SessionDto>> getPatientSessions(Authentication auth) {
        return ResponseEntity.ok(sessionService.getPatientSessions(UUID.fromString(auth.getName())));
    }

    @GetMapping("/api/doctor/patients/{patientId}/sessions")
    @PreAuthorize("hasRole('DOCTOR')")
    public ResponseEntity<List<SessionDto>> getDoctorPatientSessions(@PathVariable UUID patientId) {
        return ResponseEntity.ok(sessionService.getPatientSessions(patientId));
    }
}

package com.knevo.controller;

import com.knevo.dto.sensor.SensorBatchResponse;
import com.knevo.dto.sensor.SensorReadingDto;
import com.knevo.dto.sensor.SensorReadingResponse;
import com.knevo.service.SensorReadingService;
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
public class SensorReadingController {

    private final SensorReadingService sensorReadingService;

    @PostMapping("/api/sessions/{sessionId}/sets/{setRecordId}/sensor-readings")
    @PreAuthorize("hasRole('PATIENT')")
    public ResponseEntity<SensorBatchResponse> ingest(
            Authentication auth,
            @PathVariable UUID sessionId,
            @PathVariable UUID setRecordId,
            @Valid @RequestBody List<@Valid SensorReadingDto> readings) {
        return ResponseEntity.ok(sensorReadingService.ingest(
            UUID.fromString(auth.getName()), sessionId, setRecordId, readings));
    }

    /**
     * Doctor-facing read for the session sensor graphs (decisions §5.2).
     * Downsampling is controlled by {@code maxPoints} (a target cap on returned
     * points; default 2000) rather than a target Hz — simpler and bounds the
     * payload regardless of sample rate. Optional {@code setRecordId} filters to
     * a single set.
     */
    @GetMapping("/api/sessions/{sessionId}/sensor-readings")
    @PreAuthorize("hasRole('DOCTOR')")
    public ResponseEntity<List<SensorReadingResponse>> getReadings(
            Authentication auth,
            @PathVariable UUID sessionId,
            @RequestParam(required = false) UUID setRecordId,
            @RequestParam(required = false) Integer maxPoints) {
        return ResponseEntity.ok(sensorReadingService.getReadingsForGraph(
            UUID.fromString(auth.getName()), sessionId, setRecordId, maxPoints));
    }
}

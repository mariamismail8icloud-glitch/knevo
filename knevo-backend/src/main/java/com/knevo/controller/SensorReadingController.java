package com.knevo.controller;

import com.knevo.dto.sensor.SensorBatchResponse;
import com.knevo.dto.sensor.SensorReadingDto;
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
}

package com.knevo.service;

import com.knevo.dto.sensor.SensorBatchResponse;
import com.knevo.dto.sensor.SensorReadingDto;
import com.knevo.model.TherapySetRecord;
import com.knevo.repository.SensorReadingRepository;
import com.knevo.repository.TherapySetRecordRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class SensorReadingService {

    private final TherapySetRecordRepository setRecordRepository;
    private final SensorReadingRepository sensorReadingRepository;

    /**
     * Bulk-inserts raw sensor readings for a completed set after validating that
     * the set belongs to the given session and that session belongs to the
     * authenticated patient (decisions §5.1).
     */
    @Transactional
    public SensorBatchResponse ingest(UUID patientId, UUID sessionId, UUID setRecordId,
                                      List<SensorReadingDto> readings) {
        TherapySetRecord record = setRecordRepository.findById(setRecordId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Set record not found"));

        if (record.getSession() == null || !sessionId.equals(record.getSession().getId())) {
            throw new ResponseStatusException(HttpStatus.NOT_FOUND,
                "Set record does not belong to this session");
        }

        if (record.getSession().getPatient() == null
            || !patientId.equals(record.getSession().getPatient().getId())) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN,
                "You do not have access to this session");
        }

        if (readings == null || readings.isEmpty()) {
            return new SensorBatchResponse(0);
        }

        int inserted = sensorReadingRepository.batchInsert(setRecordId, readings);
        return new SensorBatchResponse(inserted);
    }
}

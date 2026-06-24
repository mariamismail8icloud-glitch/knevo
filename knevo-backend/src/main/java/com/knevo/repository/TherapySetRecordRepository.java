package com.knevo.repository;

import com.knevo.model.TherapySetRecord;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface TherapySetRecordRepository extends JpaRepository<TherapySetRecord, UUID> {
    List<TherapySetRecord> findBySession_Id(UUID sessionId);
}

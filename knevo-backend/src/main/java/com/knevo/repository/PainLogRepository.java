package com.knevo.repository;

import com.knevo.model.PainLog;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface PainLogRepository extends JpaRepository<PainLog, UUID> {
    List<PainLog> findBySession_Id(UUID sessionId);
}

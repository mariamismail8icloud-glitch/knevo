package com.knevo.repository;

import com.knevo.model.Session;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface SessionRepository extends JpaRepository<Session, UUID> {
    List<Session> findByPatient_IdOrderByStartedAtDesc(UUID patientId);
}

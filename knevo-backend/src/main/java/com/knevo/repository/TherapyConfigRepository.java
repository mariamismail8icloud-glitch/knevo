package com.knevo.repository;

import com.knevo.model.TherapyConfig;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface TherapyConfigRepository extends JpaRepository<TherapyConfig, UUID> {
    List<TherapyConfig> findByPatient_Id(UUID patientId);

    @Query("SELECT tc FROM TherapyConfig tc WHERE tc.patient.id = :patientId AND tc.status = 'INPROGRESS' ORDER BY tc.createdAt DESC")
    Optional<TherapyConfig> findActiveConfigForPatient(UUID patientId);
}

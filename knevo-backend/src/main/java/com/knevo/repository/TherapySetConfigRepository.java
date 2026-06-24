package com.knevo.repository;

import com.knevo.model.TherapySetConfig;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface TherapySetConfigRepository extends JpaRepository<TherapySetConfig, UUID> {
    List<TherapySetConfig> findByTherapyConfig_IdOrderBySetOrder(UUID therapyConfigId);
}

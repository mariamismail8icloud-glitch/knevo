package com.knevo.repository;

import com.knevo.model.RehabPlan;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface RehabPlanRepository extends JpaRepository<RehabPlan, UUID> {
    List<RehabPlan> findByPatient_Id(UUID patientId);
}

package com.knevo.repository;

import com.knevo.model.Exercise;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.UUID;

public interface ExerciseRepository extends JpaRepository<Exercise, UUID> {
    List<Exercise> findByActiveTrue();
    List<Exercise> findByCategoryAndActiveTrue(String category);
    List<Exercise> findByModeAndActiveTrue(String mode);
}

package com.knevo.repository;

import com.knevo.model.User;
import org.springframework.data.jpa.repository.JpaRepository;

import java.util.List;
import java.util.Optional;
import java.util.UUID;

public interface UserRepository extends JpaRepository<User, UUID> {
    Optional<User> findByEmail(String email);
    boolean existsByEmail(String email);
    boolean existsByUsername(String username);
    Optional<User> findByEnrollmentCode(String enrollmentCode);
    List<User> findByRoleAndDoctorStatus(User.Role role, User.DoctorStatus status);
    List<User> findByRoleOrderByCreatedAtDesc(User.Role role);
    List<User> findByDoctor_Id(UUID doctorId);
}

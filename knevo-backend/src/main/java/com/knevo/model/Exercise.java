package com.knevo.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@Entity
@Table(name = "exercises")
public class Exercise {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @Column(nullable = false)
    private String name;

    private String category;

    @Column(name = "activity_type")
    private String activityType;

    private String mode;
    private String difficulty;
    private String description;

    @Column(name = "patient_instructions")
    private String patientInstructions;

    @Column(name = "doctor_instructions")
    private String doctorInstructions;

    @Column(name = "default_sets")
    private Integer defaultSets;

    @Column(name = "default_reps")
    private Integer defaultReps;

    @Column(name = "default_rest_seconds")
    private Integer defaultRestSeconds;

    @Column(name = "default_min_rom_deg")
    private BigDecimal defaultMinRomDeg;

    @Column(name = "default_max_rom_deg")
    private BigDecimal defaultMaxRomDeg;

    @Column(name = "default_max_angular_velocity_deg_s")
    private BigDecimal defaultMaxAngularVelocityDegS;

    @Column(name = "default_pain_stop_threshold")
    private Integer defaultPainStopThreshold;

    @Column(name = "safety_notes")
    private String safetyNotes;

    @Column(name = "video_url")
    private String videoUrl;

    @Column(name = "image_url")
    private String imageUrl;

    @Column(name = "target_joint")
    private String targetJoint;

    @Column(name = "is_active")
    private boolean active = true;

    @Column(name = "created_at")
    private OffsetDateTime createdAt;

    @Column(name = "updated_at")
    private OffsetDateTime updatedAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = OffsetDateTime.now();
        if (updatedAt == null) updatedAt = OffsetDateTime.now();
    }

    @PreUpdate
    void preUpdate() {
        updatedAt = OffsetDateTime.now();
    }
}

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
@Table(name = "therapy_configs")
public class TherapyConfig {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "patient_id", nullable = false)
    private User patient;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "issued_by", nullable = false)
    private User issuedBy;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "rehab_plan_id")
    private RehabPlan rehabPlan;

    @Column(name = "max_speed")
    private BigDecimal maxSpeed;

    @Column(name = "max_extension_angle_deg")
    private BigDecimal maxExtensionAngleDeg;

    @Column(name = "max_flexion_angle_deg")
    private BigDecimal maxFlexionAngleDeg;

    @Column(name = "sessions_per_week")
    private Integer sessionsPerWeek;

    private String schedule;

    @Column(name = "total_sessions_num")
    private Integer totalSessionsNum;

    @Column(nullable = false)
    private String status = "SCHEDULED";

    private String comment;

    @Column(name = "created_at")
    private OffsetDateTime createdAt;

    @Column(name = "delivered_at")
    private OffsetDateTime deliveredAt;

    @PrePersist
    void prePersist() {
        if (createdAt == null) createdAt = OffsetDateTime.now();
    }
}

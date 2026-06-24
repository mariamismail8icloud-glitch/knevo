package com.knevo.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@NoArgsConstructor
@Entity
@Table(name = "therapy_set_records")
public class TherapySetRecord {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "session_id", nullable = false)
    private Session session;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "therapy_set_config_id")
    private TherapySetConfig therapySetConfig;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @Column(name = "device_assisted", nullable = false)
    private boolean deviceAssisted = false;

    @Column(name = "planned_duration_min")
    private Integer plannedDurationMin;

    @Column(name = "planned_rest_duration_min")
    private Integer plannedRestDurationMin;

    @Column(name = "start_datetime")
    private OffsetDateTime startDatetime;

    @Column(name = "stop_datetime")
    private OffsetDateTime stopDatetime;

    @Column(name = "pain_level")
    private Integer painLevel;

    @Column(name = "patient_feedback")
    private String patientFeedback;

    @Column(nullable = false)
    private String status = "IN_PROGRESS";
}

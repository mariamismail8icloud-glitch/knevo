package com.knevo.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.util.UUID;

@Data
@NoArgsConstructor
@Entity
@Table(name = "therapy_set_configs")
public class TherapySetConfig {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "therapy_config_id", nullable = false)
    private TherapyConfig therapyConfig;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "exercise_id", nullable = false)
    private Exercise exercise;

    @Column(name = "device_assisted")
    private boolean deviceAssisted = false;

    @Column(name = "duration_min")
    private Integer durationMin;

    @Column(name = "rest_duration_min")
    private Integer restDurationMin;

    @Column(name = "set_order")
    private Integer setOrder = 0;
}

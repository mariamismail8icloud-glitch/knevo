package com.knevo.model;

import jakarta.persistence.*;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;
import java.util.UUID;

@Data
@NoArgsConstructor
@Entity
@Table(name = "sensor_readings")
public class SensorReading {
    @Id
    @GeneratedValue(strategy = GenerationType.UUID)
    private UUID id;

    @ManyToOne(fetch = FetchType.LAZY)
    @JoinColumn(name = "therapy_set_record_id", nullable = false)
    private TherapySetRecord therapySetRecord;

    @Column(name = "timestamp_us")
    private Long timestampUs;

    @Column(name = "sample_id")
    private Integer sampleId;

    @Column(name = "foot_ax_g")
    private BigDecimal footAxG;

    @Column(name = "foot_ay_g")
    private BigDecimal footAyG;

    @Column(name = "foot_az_g")
    private BigDecimal footAzG;

    @Column(name = "foot_gx_rad_s")
    private BigDecimal footGxRadS;

    @Column(name = "foot_gy_rad_s")
    private BigDecimal footGyRadS;

    @Column(name = "foot_gz_rad_s")
    private BigDecimal footGzRadS;

    @Column(name = "shank_ax_g")
    private BigDecimal shankAxG;

    @Column(name = "shank_ay_g")
    private BigDecimal shankAyG;

    @Column(name = "shank_az_g")
    private BigDecimal shankAzG;

    @Column(name = "shank_gx_rad_s")
    private BigDecimal shankGxRadS;

    @Column(name = "shank_gy_rad_s")
    private BigDecimal shankGyRadS;

    @Column(name = "shank_gz_rad_s")
    private BigDecimal shankGzRadS;

    @Column(name = "thigh_ax_g")
    private BigDecimal thighAxG;

    @Column(name = "thigh_ay_g")
    private BigDecimal thighAyG;

    @Column(name = "thigh_az_g")
    private BigDecimal thighAzG;

    @Column(name = "thigh_gx_rad_s")
    private BigDecimal thighGxRadS;

    @Column(name = "thigh_gy_rad_s")
    private BigDecimal thighGyRadS;

    @Column(name = "thigh_gz_rad_s")
    private BigDecimal thighGzRadS;

    @Column(name = "heel_fsr_raw")
    private Integer heelFsrRaw;

    @Column(name = "midfoot_fsr_raw")
    private Integer midfootFsrRaw;

    // Computed gait fields — not sent in Phase 2; default to DB defaults (-1 / null).
    @Column(name = "heel_contact")
    private Short heelContact = -1;

    @Column(name = "midfoot_contact")
    private Short midfootContact = -1;

    @Column(name = "gait_phase_id")
    private Integer gaitPhaseId = -1;

    @Column(name = "gait_phase_label")
    private String gaitPhaseLabel;

    @Column(name = "knee_angle_est_deg")
    private BigDecimal kneeAngleEstDeg;
}

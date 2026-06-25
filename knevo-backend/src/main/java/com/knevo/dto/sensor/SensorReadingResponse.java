package com.knevo.dto.sensor;

import lombok.AllArgsConstructor;
import lombok.Data;
import lombok.NoArgsConstructor;

import java.math.BigDecimal;

/**
 * One sensor sample as returned to the doctor portal for graphing
 * (decisions §5.2). Carries the FSR channels and a placeholder for the
 * Phase 3 computed knee angle (always {@code null} in Phase 2), plus the
 * raw IMU channels for completeness.
 */
@Data
@NoArgsConstructor
@AllArgsConstructor
public class SensorReadingResponse {
    private Long timestampUs;
    private Integer sampleId;

    private Integer heelFsrRaw;
    private Integer midfootFsrRaw;

    // Phase 3 (M14) computed field. Always null in Phase 2.
    private BigDecimal kneeAngleEstDeg;

    // Raw IMU channels — optional for the FSR/knee graphs but useful for
    // future analytics; the doctor portal may ignore them.
    private BigDecimal footAxG;
    private BigDecimal footAyG;
    private BigDecimal footAzG;
    private BigDecimal shankAxG;
    private BigDecimal shankAyG;
    private BigDecimal shankAzG;
    private BigDecimal thighAxG;
    private BigDecimal thighAyG;
    private BigDecimal thighAzG;
}

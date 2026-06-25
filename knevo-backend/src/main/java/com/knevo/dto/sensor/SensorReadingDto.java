package com.knevo.dto.sensor;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

/**
 * One raw sensor sample as uploaded by the patient app post-set (decisions §5.1).
 * Phase 2 sends only the raw channels; computed gait fields are filled by the
 * backend with DB defaults.
 */
@Data
public class SensorReadingDto {
    @NotNull
    private Long timestampUs;

    @NotNull
    private Integer sampleId;

    private BigDecimal footAxG;
    private BigDecimal footAyG;
    private BigDecimal footAzG;
    private BigDecimal footGxRadS;
    private BigDecimal footGyRadS;
    private BigDecimal footGzRadS;

    private BigDecimal shankAxG;
    private BigDecimal shankAyG;
    private BigDecimal shankAzG;
    private BigDecimal shankGxRadS;
    private BigDecimal shankGyRadS;
    private BigDecimal shankGzRadS;

    private BigDecimal thighAxG;
    private BigDecimal thighAyG;
    private BigDecimal thighAzG;
    private BigDecimal thighGxRadS;
    private BigDecimal thighGyRadS;
    private BigDecimal thighGzRadS;

    @NotNull
    @Min(0)
    @Max(4095)
    private Integer heelFsrRaw;

    @NotNull
    @Min(0)
    @Max(4095)
    private Integer midfootFsrRaw;
}

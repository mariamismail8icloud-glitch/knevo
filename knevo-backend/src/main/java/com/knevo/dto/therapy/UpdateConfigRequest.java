package com.knevo.dto.therapy;

import jakarta.validation.constraints.DecimalMax;
import jakarta.validation.constraints.DecimalMin;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.math.BigDecimal;

@Data
public class UpdateConfigRequest {
    // Safety limits — required; ranges kept in sync with TherapyDefaults.
    @NotNull(message = "Max speed is required")
    @DecimalMin(value = "1", message = "Max speed must be between 1 and 12")
    @DecimalMax(value = "12", message = "Max speed must be between 1 and 12")
    private BigDecimal maxSpeed;

    @NotNull(message = "Max extension is required")
    @DecimalMin(value = "1", message = "Max extension must be between 1 and 5")
    @DecimalMax(value = "5", message = "Max extension must be between 1 and 5")
    private BigDecimal maxExtensionAngleDeg;

    @NotNull(message = "Max flexion is required")
    @DecimalMin(value = "30", message = "Max flexion must be between 30 and 65")
    @DecimalMax(value = "65", message = "Max flexion must be between 30 and 65")
    private BigDecimal maxFlexionAngleDeg;

    private Integer sessionsPerWeek;
    private String schedule;
    private Integer totalSessionsNum;
    private String comment;
}

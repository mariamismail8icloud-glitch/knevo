package com.knevo.dto.therapy;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;
import java.math.BigDecimal;
import java.util.List;
import java.util.UUID;

@Data
public class CreatePlanRequest {
    @NotBlank
    private String title;

    private String goal;
    private String startDate;
    private String endDate;
    private String notes;

    // TherapyConfig fields
    private BigDecimal maxSpeed;
    private BigDecimal maxExtensionAngleDeg;
    private BigDecimal maxFlexionAngleDeg;
    private Integer sessionsPerWeek;
    private String schedule;
    private Integer totalSessionsNum;
    private String comment;

    // Set from path variable by controller; not validated here
    private UUID patientId;

    private List<SetConfigRequest> sets;
}

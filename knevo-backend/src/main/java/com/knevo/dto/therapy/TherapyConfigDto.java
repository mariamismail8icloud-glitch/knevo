package com.knevo.dto.therapy;

import lombok.Data;
import java.math.BigDecimal;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Data
public class TherapyConfigDto {
    private UUID id;
    private UUID patientId;
    private UUID issuedById;
    private UUID rehabPlanId;
    private BigDecimal maxSpeed;
    private BigDecimal maxExtensionAngleDeg;
    private BigDecimal maxFlexionAngleDeg;
    private Integer sessionsPerWeek;
    private String schedule;
    private Integer totalSessionsNum;
    private String status;
    private String comment;
    private OffsetDateTime createdAt;
    private OffsetDateTime deliveredAt;
    private List<TherapySetConfigDto> sets;
}

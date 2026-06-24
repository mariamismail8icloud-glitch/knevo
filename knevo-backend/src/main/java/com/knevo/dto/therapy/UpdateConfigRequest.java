package com.knevo.dto.therapy;

import lombok.Data;

import java.math.BigDecimal;

@Data
public class UpdateConfigRequest {
    private BigDecimal maxSpeed;
    private BigDecimal maxExtensionAngleDeg;
    private BigDecimal maxFlexionAngleDeg;
    private Integer sessionsPerWeek;
    private String schedule;
    private Integer totalSessionsNum;
    private String comment;
}

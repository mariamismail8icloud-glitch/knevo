package com.knevo.dto.therapy;

import java.math.BigDecimal;

/**
 * Backend-defined defaults and acceptable ranges for the doctor-tunable therapy
 * config fields. Served to the web form so it can pre-populate the inputs and
 * surface the valid range. Backed by {@link com.knevo.util.TherapyDefaults}.
 */
public record TherapyDefaultsDto(
    FieldRange maxSpeed,
    FieldRange maxExtensionAngleDeg,
    FieldRange maxFlexionAngleDeg
) {
    public record FieldRange(BigDecimal defaultValue, BigDecimal min, BigDecimal max) {}
}

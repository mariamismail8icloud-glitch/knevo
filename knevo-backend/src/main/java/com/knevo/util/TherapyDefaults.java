package com.knevo.util;

import java.math.BigDecimal;

/**
 * Single source of truth for the doctor-tunable therapy-config safety limits:
 * their default values and acceptable ranges. The web form pre-populates with
 * the defaults (via the /api/therapy-config/defaults endpoint) and the same
 * ranges are enforced by Bean Validation on the request DTOs.
 *
 * NOTE: the matching {@code @DecimalMin}/{@code @DecimalMax} literals on the DTOs
 * must be kept in sync with these values — annotation arguments must be compile
 * time constants, so they cannot reference these {@link BigDecimal} fields.
 */
public final class TherapyDefaults {
    private TherapyDefaults() {}

    public static final BigDecimal SPEED_DEFAULT = BigDecimal.valueOf(5);
    public static final BigDecimal SPEED_MIN = BigDecimal.valueOf(1);
    public static final BigDecimal SPEED_MAX = BigDecimal.valueOf(12);

    public static final BigDecimal EXTENSION_DEFAULT = BigDecimal.valueOf(5);
    public static final BigDecimal EXTENSION_MIN = BigDecimal.valueOf(1);
    public static final BigDecimal EXTENSION_MAX = BigDecimal.valueOf(5);

    public static final BigDecimal FLEXION_DEFAULT = BigDecimal.valueOf(60);
    public static final BigDecimal FLEXION_MIN = BigDecimal.valueOf(30);
    public static final BigDecimal FLEXION_MAX = BigDecimal.valueOf(65);
}

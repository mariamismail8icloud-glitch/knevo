package com.knevo.dto.therapy;

import jakarta.validation.constraints.NotNull;
import lombok.Data;
import java.util.UUID;

@Data
public class SetConfigRequest {
    @NotNull
    private UUID exerciseId;
    private boolean deviceAssisted;
    private Integer durationMin;
    private Integer restDurationMin;
    private Integer setOrder;
}

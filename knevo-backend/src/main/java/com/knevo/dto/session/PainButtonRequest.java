package com.knevo.dto.session;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

@Data
public class PainButtonRequest {
    @NotNull
    @Min(0)
    @Max(10)
    private Integer painLevel;
}

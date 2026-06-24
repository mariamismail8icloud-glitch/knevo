package com.knevo.dto.session;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import lombok.Data;

@Data
public class CompleteSessionRequest {
    @Min(0)
    @Max(10)
    private Integer painAfter;
}

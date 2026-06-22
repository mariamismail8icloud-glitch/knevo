package com.knevo.dto.session;

import jakarta.validation.constraints.Max;
import jakarta.validation.constraints.Min;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class StopSetRequest {
    @NotNull
    private UUID therapySetRecordId;

    @Min(0)
    @Max(10)
    private Integer painLevel;

    private String feedback;
}

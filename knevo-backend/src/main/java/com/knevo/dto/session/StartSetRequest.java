package com.knevo.dto.session;

import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class StartSetRequest {
    @NotNull
    private UUID therapySetConfigId;
}

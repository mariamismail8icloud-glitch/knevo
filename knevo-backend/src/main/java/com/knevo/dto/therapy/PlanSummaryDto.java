package com.knevo.dto.therapy;

import lombok.Data;
import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class PlanSummaryDto {
    private UUID planId;
    private String title;
    private String status;
    private UUID therapyConfigId;
    private OffsetDateTime createdAt;
    private LocalDate startDate;
    private LocalDate endDate;
}

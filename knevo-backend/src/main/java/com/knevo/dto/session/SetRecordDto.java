package com.knevo.dto.session;

import lombok.Data;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class SetRecordDto {
    private UUID id;
    private UUID therapySetConfigId;
    private OffsetDateTime startDatetime;
    private OffsetDateTime stopDatetime;
    private Integer painLevel;
    private String feedback;
    private String status;
}

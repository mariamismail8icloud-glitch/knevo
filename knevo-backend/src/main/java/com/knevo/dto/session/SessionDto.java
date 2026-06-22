package com.knevo.dto.session;

import lombok.Data;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Data
public class SessionDto {
    private UUID id;
    private UUID patientId;
    private UUID therapyConfigId;
    private String status;
    private OffsetDateTime startedAt;
    private OffsetDateTime endedAt;
    private Integer painBefore;
    private Integer painDuring;
    private Integer painAfter;
    private List<SetRecordDto> setRecords;
}

package com.knevo.dto.admin;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
@AllArgsConstructor
public class DoctorSummaryDto {
    private UUID id;
    private String name;
    private String email;
    private String clinicName;
    private String specialization;
    private String doctorStatus;
    private OffsetDateTime createdAt;
}

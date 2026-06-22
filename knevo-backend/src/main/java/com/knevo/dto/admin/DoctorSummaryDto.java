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
    private String phone;
    private String clinicName;
    private String specialization;
    private String professionalLicense;
    private Integer yearsExperience;
    private String doctorStatus;
    private String rejectionReason;
    private OffsetDateTime createdAt;
}

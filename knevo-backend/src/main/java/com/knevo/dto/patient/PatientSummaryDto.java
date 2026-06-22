package com.knevo.dto.patient;

import lombok.AllArgsConstructor;
import lombok.Data;
import java.util.UUID;

@Data
@AllArgsConstructor
public class PatientSummaryDto {
    private UUID id;
    private String name;
    private String email;
    private String phone;
    private String enrollmentCode;
}

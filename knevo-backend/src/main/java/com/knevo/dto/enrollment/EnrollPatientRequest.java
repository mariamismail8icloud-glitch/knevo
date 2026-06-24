package com.knevo.dto.enrollment;

import jakarta.validation.constraints.NotBlank;
import lombok.Data;

@Data
public class EnrollPatientRequest {
    @NotBlank
    private String enrollmentCode;
}

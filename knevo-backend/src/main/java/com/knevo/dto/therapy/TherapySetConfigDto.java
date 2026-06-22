package com.knevo.dto.therapy;

import lombok.Data;
import java.util.UUID;

@Data
public class TherapySetConfigDto {
    private UUID id;
    private ExerciseDto exercise;
    private boolean deviceAssisted;
    private Integer durationMin;
    private Integer restDurationMin;
    private Integer setOrder;
}

package com.knevo.dto.therapy;

import lombok.Data;
import java.math.BigDecimal;
import java.util.UUID;

@Data
public class ExerciseDto {
    private UUID id;
    private String name;
    private String category;
    private String activityType;
    private String mode;
    private String difficulty;
    private String description;
    private String patientInstructions;
    private String doctorInstructions;
    private Integer defaultSets;
    private Integer defaultReps;
    private Integer defaultRestSeconds;
    private BigDecimal defaultMinRomDeg;
    private BigDecimal defaultMaxRomDeg;
    private BigDecimal defaultMaxAngularVelocityDegS;
    private Integer defaultPainStopThreshold;
    private String safetyNotes;
    private String targetJoint;
    private String videoUrl;
    private String imageUrl;
}

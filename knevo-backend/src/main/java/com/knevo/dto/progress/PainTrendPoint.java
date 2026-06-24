package com.knevo.dto.progress;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class PainTrendPoint {
    private String sessionDate;
    private double avgPainBefore;
}

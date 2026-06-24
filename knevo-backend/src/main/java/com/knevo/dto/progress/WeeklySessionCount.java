package com.knevo.dto.progress;

import lombok.AllArgsConstructor;
import lombok.Data;

@Data
@AllArgsConstructor
public class WeeklySessionCount {
    private String weekLabel;
    private long count;
}

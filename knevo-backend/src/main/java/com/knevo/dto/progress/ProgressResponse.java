package com.knevo.dto.progress;

import lombok.Data;

import java.util.List;

@Data
public class ProgressResponse {
    private List<WeeklySessionCount> sessionsPerWeek;
    private List<PainTrendPoint> painTrend;
    private double adherenceRate;
    private long missedSessionsCount;
    private long totalSessionsCompleted;
    private long totalSessionsPrescribed;
}

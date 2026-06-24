package com.knevo.service;

import com.knevo.dto.progress.PainTrendPoint;
import com.knevo.dto.progress.ProgressResponse;
import com.knevo.dto.progress.WeeklySessionCount;
import com.knevo.model.Session;
import com.knevo.repository.SessionRepository;
import com.knevo.repository.TherapyConfigRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.stereotype.Service;

import java.time.LocalDate;
import java.time.ZoneOffset;
import java.time.temporal.IsoFields;
import java.util.Collections;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class ProgressService {

    private final SessionRepository sessionRepository;
    private final TherapyConfigRepository therapyConfigRepository;

    public ProgressResponse getProgress(UUID patientId) {
        List<Session> allSessions = sessionRepository
                .findByPatient_IdOrderByStartedAtDesc(patientId);

        // Sessions per week — last 8 weeks
        LocalDate today = LocalDate.now(ZoneOffset.UTC);
        LocalDate eightWeeksAgo = today.minusWeeks(8);

        Map<String, Long> weekCounts = new LinkedHashMap<>();
        // Pre-fill 8 weeks (oldest to newest)
        for (int i = 7; i >= 0; i--) {
            LocalDate weekStart = today.minusWeeks(i);
            String label = weekStart.getYear() + "-W"
                    + String.format("%02d", weekStart.get(IsoFields.WEEK_OF_WEEK_BASED_YEAR));
            weekCounts.put(label, 0L);
        }

        allSessions.stream()
                .filter(s -> s.getStartedAt() != null
                        && s.getStartedAt().toLocalDate().isAfter(eightWeeksAgo))
                .forEach(s -> {
                    LocalDate date = s.getStartedAt().toLocalDate();
                    String label = date.getYear() + "-W"
                            + String.format("%02d", date.get(IsoFields.WEEK_OF_WEEK_BASED_YEAR));
                    weekCounts.merge(label, 1L, Long::sum);
                });

        List<WeeklySessionCount> sessionsPerWeek = weekCounts.entrySet().stream()
                .map(e -> new WeeklySessionCount(e.getKey(), e.getValue()))
                .collect(Collectors.toList());

        // Pain trend — last 20 sessions
        List<PainTrendPoint> painTrend = allSessions.stream()
                .limit(20)
                .filter(s -> s.getStartedAt() != null)
                .map(s -> new PainTrendPoint(
                        s.getStartedAt().toLocalDate().toString(),
                        s.getPainBefore() != null ? s.getPainBefore().doubleValue() : 0.0
                ))
                .collect(Collectors.toList());
        Collections.reverse(painTrend);

        // Adherence
        long completed = allSessions.stream()
                .filter(s -> "COMPLETED".equals(s.getStatus())).count();

        // Prescribed from active config
        long prescribed = therapyConfigRepository.findByPatient_Id(patientId)
                .stream()
                .filter(c -> "INPROGRESS".equals(c.getStatus()))
                .mapToLong(c -> c.getTotalSessionsNum() != null ? c.getTotalSessionsNum() : 0)
                .sum();

        double adherence = prescribed > 0 ? Math.min(1.0, (double) completed / prescribed) : 0.0;
        long missed = Math.max(0, prescribed - completed);

        ProgressResponse response = new ProgressResponse();
        response.setSessionsPerWeek(sessionsPerWeek);
        response.setPainTrend(painTrend);
        response.setAdherenceRate(adherence);
        response.setMissedSessionsCount(missed);
        response.setTotalSessionsCompleted(completed);
        response.setTotalSessionsPrescribed(prescribed);
        return response;
    }
}

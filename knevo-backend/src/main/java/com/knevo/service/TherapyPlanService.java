package com.knevo.service;

import com.knevo.dto.therapy.*;
import com.knevo.dto.therapy.TherapyDefaultsDto.FieldRange;
import com.knevo.model.*;
import com.knevo.repository.*;
import com.knevo.util.TherapyDefaults;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.time.OffsetDateTime;
import java.util.List;
import java.util.Map;
import java.util.UUID;
import java.util.stream.Collectors;

@Service
@RequiredArgsConstructor
public class TherapyPlanService {

    private final UserRepository userRepository;
    private final ExerciseRepository exerciseRepository;
    private final RehabPlanRepository rehabPlanRepository;
    private final TherapyConfigRepository therapyConfigRepository;
    private final TherapySetConfigRepository setConfigRepository;
    private final SimpMessagingTemplate messagingTemplate;

    public List<ExerciseDto> getActiveExercises(String category, String mode) {
        List<Exercise> exercises;
        if (category != null && !category.isBlank()) {
            exercises = exerciseRepository.findByCategoryAndActiveTrue(category);
        } else if (mode != null && !mode.isBlank()) {
            exercises = exerciseRepository.findByModeAndActiveTrue(mode);
        } else {
            exercises = exerciseRepository.findByActiveTrue();
        }
        return exercises.stream().map(this::toExerciseDto).collect(Collectors.toList());
    }

    public ExerciseDto getExercise(UUID id) {
        return exerciseRepository.findById(id)
            .map(this::toExerciseDto)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Exercise not found"));
    }

    @Transactional
    public PlanSummaryDto createPlan(UUID doctorId, CreatePlanRequest req) {
        User patient = userRepository.findById(req.getPatientId())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Patient not found"));
        User doctor = userRepository.findById(doctorId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Doctor not found"));

        // Create rehab plan
        RehabPlan plan = new RehabPlan();
        plan.setPatient(patient);
        plan.setDoctor(doctor);
        plan.setTitle(req.getTitle());
        plan.setGoal(req.getGoal());
        plan.setNotes(req.getNotes());
        plan.setStatus("ACTIVE");
        if (req.getStartDate() != null && !req.getStartDate().isBlank()) {
            plan.setStartDate(LocalDate.parse(req.getStartDate()));
        }
        if (req.getEndDate() != null && !req.getEndDate().isBlank()) {
            plan.setEndDate(LocalDate.parse(req.getEndDate()));
        }
        plan = rehabPlanRepository.save(plan);

        // Create therapy config
        TherapyConfig config = new TherapyConfig();
        config.setPatient(patient);
        config.setIssuedBy(doctor);
        config.setRehabPlan(plan);
        config.setMaxSpeed(req.getMaxSpeed());
        config.setMaxExtensionAngleDeg(req.getMaxExtensionAngleDeg());
        config.setMaxFlexionAngleDeg(req.getMaxFlexionAngleDeg());
        config.setSessionsPerWeek(req.getSessionsPerWeek());
        config.setSchedule(req.getSchedule());
        config.setTotalSessionsNum(req.getTotalSessionsNum());
        config.setComment(req.getComment());
        config.setStatus("INPROGRESS");
        config = therapyConfigRepository.save(config);

        // Create set configs
        if (req.getSets() != null) {
            int order = 0;
            for (SetConfigRequest setReq : req.getSets()) {
                Exercise exercise = exerciseRepository.findById(setReq.getExerciseId())
                    .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Exercise not found: " + setReq.getExerciseId()));
                TherapySetConfig setConfig = new TherapySetConfig();
                setConfig.setTherapyConfig(config);
                setConfig.setExercise(exercise);
                setConfig.setDeviceAssisted(setReq.isDeviceAssisted());
                setConfig.setDurationMin(setReq.getDurationMin());
                setConfig.setRestDurationMin(setReq.getRestDurationMin());
                setConfig.setSetOrder(setReq.getSetOrder() != null ? setReq.getSetOrder() : order++);
                setConfigRepository.save(setConfig);
            }
        }

        PlanSummaryDto summary = new PlanSummaryDto();
        summary.setPlanId(plan.getId());
        summary.setTitle(plan.getTitle());
        summary.setStatus(plan.getStatus());
        summary.setTherapyConfigId(config.getId());
        summary.setCreatedAt(plan.getCreatedAt());
        summary.setStartDate(plan.getStartDate());
        summary.setEndDate(plan.getEndDate());
        return summary;
    }

    public TherapyDefaultsDto getConfigDefaults() {
        return new TherapyDefaultsDto(
            new FieldRange(TherapyDefaults.SPEED_DEFAULT, TherapyDefaults.SPEED_MIN, TherapyDefaults.SPEED_MAX),
            new FieldRange(TherapyDefaults.EXTENSION_DEFAULT, TherapyDefaults.EXTENSION_MIN, TherapyDefaults.EXTENSION_MAX),
            new FieldRange(TherapyDefaults.FLEXION_DEFAULT, TherapyDefaults.FLEXION_MIN, TherapyDefaults.FLEXION_MAX)
        );
    }

    @Transactional(readOnly = true)
    public TherapyConfigDto getActiveConfigForPatient(UUID patientId) {
        TherapyConfig config = therapyConfigRepository.findActiveConfigForPatient(patientId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "No active therapy plan"));
        return toConfigDto(config);
    }

    @Transactional(readOnly = true)
    public TherapyConfigDto getConfig(UUID configId) {
        TherapyConfig config = therapyConfigRepository.findById(configId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Config not found"));
        return toConfigDto(config);
    }

    @Transactional(readOnly = true)
    public List<PlanSummaryDto> getPlansForPatient(UUID patientId) {
        return rehabPlanRepository.findByPatient_Id(patientId).stream()
            .map(p -> {
                PlanSummaryDto dto = new PlanSummaryDto();
                dto.setPlanId(p.getId());
                dto.setTitle(p.getTitle());
                dto.setStatus(p.getStatus());
                dto.setCreatedAt(p.getCreatedAt());
                dto.setStartDate(p.getStartDate());
                dto.setEndDate(p.getEndDate());
                // Find associated config
                therapyConfigRepository.findByPatient_Id(patientId).stream()
                    .filter(c -> c.getRehabPlan() != null && c.getRehabPlan().getId().equals(p.getId()))
                    .findFirst()
                    .ifPresent(c -> dto.setTherapyConfigId(c.getId()));
                return dto;
            })
            .collect(Collectors.toList());
    }

    @Transactional
    public TherapyConfigDto updateConfig(UUID configId, UpdateConfigRequest req) {
        TherapyConfig config = therapyConfigRepository.findById(configId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Config not found"));

        if (req.getMaxSpeed() != null) config.setMaxSpeed(req.getMaxSpeed());
        if (req.getMaxExtensionAngleDeg() != null) config.setMaxExtensionAngleDeg(req.getMaxExtensionAngleDeg());
        if (req.getMaxFlexionAngleDeg() != null) config.setMaxFlexionAngleDeg(req.getMaxFlexionAngleDeg());
        if (req.getSessionsPerWeek() != null) config.setSessionsPerWeek(req.getSessionsPerWeek());
        if (req.getSchedule() != null) config.setSchedule(req.getSchedule());
        if (req.getTotalSessionsNum() != null) config.setTotalSessionsNum(req.getTotalSessionsNum());
        if (req.getComment() != null) config.setComment(req.getComment());

        config = therapyConfigRepository.save(config);

        String patientId = config.getPatient().getId().toString();
        messagingTemplate.convertAndSend(
            "/topic/patient/" + patientId + "/config-updated",
            Map.of("configId", configId.toString(), "patientId", patientId)
        );

        return toConfigDto(config);
    }

    @Transactional
    public void markDelivered(UUID configId) {
        TherapyConfig config = therapyConfigRepository.findById(configId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Config not found"));
        config.setDeliveredAt(OffsetDateTime.now());
        therapyConfigRepository.save(config);
    }

    private TherapyConfigDto toConfigDto(TherapyConfig config) {
        TherapyConfigDto dto = new TherapyConfigDto();
        dto.setId(config.getId());
        dto.setPatientId(config.getPatient().getId());
        dto.setIssuedById(config.getIssuedBy().getId());
        if (config.getRehabPlan() != null) dto.setRehabPlanId(config.getRehabPlan().getId());
        dto.setMaxSpeed(config.getMaxSpeed());
        dto.setMaxExtensionAngleDeg(config.getMaxExtensionAngleDeg());
        dto.setMaxFlexionAngleDeg(config.getMaxFlexionAngleDeg());
        dto.setSessionsPerWeek(config.getSessionsPerWeek());
        dto.setSchedule(config.getSchedule());
        dto.setTotalSessionsNum(config.getTotalSessionsNum());
        dto.setStatus(config.getStatus());
        dto.setComment(config.getComment());
        dto.setCreatedAt(config.getCreatedAt());
        dto.setDeliveredAt(config.getDeliveredAt());

        List<TherapySetConfigDto> sets = setConfigRepository
            .findByTherapyConfig_IdOrderBySetOrder(config.getId())
            .stream()
            .map(s -> {
                TherapySetConfigDto sdto = new TherapySetConfigDto();
                sdto.setId(s.getId());
                sdto.setExercise(toExerciseDto(s.getExercise()));
                sdto.setDeviceAssisted(s.isDeviceAssisted());
                sdto.setDurationMin(s.getDurationMin());
                sdto.setRestDurationMin(s.getRestDurationMin());
                sdto.setSetOrder(s.getSetOrder());
                return sdto;
            })
            .collect(Collectors.toList());
        dto.setSets(sets);
        return dto;
    }

    private ExerciseDto toExerciseDto(Exercise e) {
        ExerciseDto dto = new ExerciseDto();
        dto.setId(e.getId());
        dto.setName(e.getName());
        dto.setCategory(e.getCategory());
        dto.setActivityType(e.getActivityType());
        dto.setMode(e.getMode());
        dto.setDifficulty(e.getDifficulty());
        dto.setDescription(e.getDescription());
        dto.setPatientInstructions(e.getPatientInstructions());
        dto.setDoctorInstructions(e.getDoctorInstructions());
        dto.setDefaultSets(e.getDefaultSets());
        dto.setDefaultReps(e.getDefaultReps());
        dto.setDefaultRestSeconds(e.getDefaultRestSeconds());
        dto.setDefaultMinRomDeg(e.getDefaultMinRomDeg());
        dto.setDefaultMaxRomDeg(e.getDefaultMaxRomDeg());
        dto.setDefaultMaxAngularVelocityDegS(e.getDefaultMaxAngularVelocityDegS());
        dto.setDefaultPainStopThreshold(e.getDefaultPainStopThreshold());
        dto.setSafetyNotes(e.getSafetyNotes());
        dto.setTargetJoint(e.getTargetJoint());
        dto.setVideoUrl(e.getVideoUrl());
        dto.setImageUrl(e.getImageUrl());
        return dto;
    }
}

package com.knevo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.knevo.dto.therapy.CreatePlanRequest;
import com.knevo.dto.therapy.SetConfigRequest;
import com.knevo.model.User;
import com.knevo.repository.ExerciseRepository;
import com.knevo.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.List;

import static org.hamcrest.Matchers.*;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class TherapyPlanIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired UserRepository userRepository;
    @Autowired ExerciseRepository exerciseRepository;

    private User patient;
    private User doctor;

    @BeforeEach
    void setup() {
        doctor = new User();
        doctor.setEmail("therapydoctor@test.com");
        doctor.setUsername("therapydoctor");
        doctor.setPasswordHash("$2a$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi");
        doctor.setName("Therapy Doctor");
        doctor.setRole(User.Role.DOCTOR);
        doctor.setDoctorStatus(User.DoctorStatus.APPROVED);
        doctor = userRepository.save(doctor);

        patient = new User();
        patient.setEmail("therapypatient@test.com");
        patient.setUsername("therapypatient");
        patient.setPasswordHash("$2a$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi");
        patient.setName("Therapy Patient");
        patient.setRole(User.Role.PATIENT);
        patient.setDoctor(doctor);
        patient = userRepository.save(patient);
    }

    @Test
    void exerciseLibraryHasSeededData() throws Exception {
        mockMvc.perform(get("/api/exercises"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(15))));
    }

    @Test
    void createPlanWithSets() throws Exception {
        var exercise = exerciseRepository.findByActiveTrue().get(0);

        SetConfigRequest set = new SetConfigRequest();
        set.setExerciseId(exercise.getId());
        set.setDeviceAssisted(false);
        set.setDurationMin(10);
        set.setRestDurationMin(2);
        set.setSetOrder(0);

        CreatePlanRequest req = new CreatePlanRequest();
        req.setTitle("Recovery Plan Week 1");
        req.setGoal("Restore knee ROM to 90 degrees");
        req.setSessionsPerWeek(3);
        req.setTotalSessionsNum(12);
        req.setSets(List.of(set));

        mockMvc.perform(post("/api/doctor/patients/" + patient.getId() + "/plans")
                .with(user(doctor.getId().toString()).roles("DOCTOR"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.planId").isNotEmpty())
            .andExpect(jsonPath("$.therapyConfigId").isNotEmpty());
    }

    @Test
    void patientFetchesActivePlan() throws Exception {
        var exercise = exerciseRepository.findByActiveTrue().get(0);
        SetConfigRequest set = new SetConfigRequest();
        set.setExerciseId(exercise.getId());
        set.setDurationMin(10);
        set.setSetOrder(0);

        CreatePlanRequest req = new CreatePlanRequest();
        req.setTitle("Active Plan");
        req.setSets(List.of(set));

        mockMvc.perform(post("/api/doctor/patients/" + patient.getId() + "/plans")
                .with(user(doctor.getId().toString()).roles("DOCTOR"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)));

        mockMvc.perform(get("/api/patient/active-plan")
                .with(user(patient.getId().toString()).roles("PATIENT")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.patientId").value(patient.getId().toString()))
            .andExpect(jsonPath("$.sets", hasSize(1)));
    }

    @Test
    void noActivePlanReturns404() throws Exception {
        mockMvc.perform(get("/api/patient/active-plan")
                .with(user(patient.getId().toString()).roles("PATIENT")))
            .andExpect(status().isNotFound());
    }
}

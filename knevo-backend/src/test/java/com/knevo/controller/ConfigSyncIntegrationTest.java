package com.knevo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.knevo.dto.therapy.UpdateConfigRequest;
import com.knevo.model.TherapyConfig;
import com.knevo.model.User;
import com.knevo.repository.TherapyConfigRepository;
import com.knevo.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.boot.test.mock.mockito.MockBean;
import org.springframework.http.MediaType;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.math.BigDecimal;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class ConfigSyncIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired UserRepository userRepository;
    @Autowired TherapyConfigRepository therapyConfigRepository;

    @MockBean
    SimpMessagingTemplate messagingTemplate;

    private User doctor;
    private User patient;
    private TherapyConfig config;

    @BeforeEach
    void setup() {
        doctor = new User();
        doctor.setEmail("configsyncdoctor@test.com");
        doctor.setUsername("configsyncdoctor");
        doctor.setPasswordHash("hash");
        doctor.setName("Config Sync Doctor");
        doctor.setRole(User.Role.DOCTOR);
        doctor.setDoctorStatus(User.DoctorStatus.APPROVED);
        doctor = userRepository.save(doctor);

        patient = new User();
        patient.setEmail("configsyncpatient@test.com");
        patient.setUsername("configsyncpatient");
        patient.setPasswordHash("hash");
        patient.setName("Config Sync Patient");
        patient.setRole(User.Role.PATIENT);
        patient.setDoctor(doctor);
        patient = userRepository.save(patient);

        config = new TherapyConfig();
        config.setPatient(patient);
        config.setIssuedBy(doctor);
        config.setStatus("INPROGRESS");
        config.setSessionsPerWeek(2);
        config = therapyConfigRepository.save(config);
    }

    @Test
    void updateConfigReturnsUpdatedFields() throws Exception {
        UpdateConfigRequest req = new UpdateConfigRequest();
        req.setSessionsPerWeek(4);
        req.setMaxSpeed(new BigDecimal("1.5"));
        req.setMaxExtensionAngleDeg(new BigDecimal("5"));
        req.setMaxFlexionAngleDeg(new BigDecimal("60"));
        req.setComment("Increased frequency");

        mockMvc.perform(put("/api/therapy-config/" + config.getId())
                .with(user(doctor.getId().toString()).roles("DOCTOR"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.sessionsPerWeek").value(4))
            .andExpect(jsonPath("$.comment").value("Increased frequency"))
            .andExpect(jsonPath("$.id").value(config.getId().toString()));
    }

    @Test
    void markDeliveredReturns204() throws Exception {
        mockMvc.perform(patch("/api/therapy-config/" + config.getId() + "/delivered")
                .with(user(patient.getId().toString()).roles("PATIENT")))
            .andExpect(status().isNoContent());
    }

    @Test
    void updateConfigWithUnknownIdReturns404() throws Exception {
        UpdateConfigRequest req = new UpdateConfigRequest();
        req.setSessionsPerWeek(3);
        req.setMaxSpeed(new BigDecimal("5"));
        req.setMaxExtensionAngleDeg(new BigDecimal("5"));
        req.setMaxFlexionAngleDeg(new BigDecimal("60"));

        mockMvc.perform(put("/api/therapy-config/00000000-0000-0000-0000-000000000000")
                .with(user(doctor.getId().toString()).roles("DOCTOR"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isNotFound());
    }

    @Test
    void updateConfigRejectsOutOfRangeFlexion() throws Exception {
        UpdateConfigRequest req = new UpdateConfigRequest();
        req.setMaxSpeed(new BigDecimal("5"));
        req.setMaxExtensionAngleDeg(new BigDecimal("5"));
        req.setMaxFlexionAngleDeg(new BigDecimal("100")); // > 65

        mockMvc.perform(put("/api/therapy-config/" + config.getId())
                .with(user(doctor.getId().toString()).roles("DOCTOR"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isBadRequest())
            .andExpect(jsonPath("$.message", org.hamcrest.Matchers.containsString("Max flexion")));
    }

    @Test
    void markDeliveredWithUnknownIdReturns404() throws Exception {
        mockMvc.perform(patch("/api/therapy-config/00000000-0000-0000-0000-000000000000/delivered")
                .with(user(patient.getId().toString()).roles("PATIENT")))
            .andExpect(status().isNotFound());
    }
}

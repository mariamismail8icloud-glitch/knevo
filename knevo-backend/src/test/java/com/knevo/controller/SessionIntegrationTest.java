package com.knevo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.knevo.model.TherapyConfig;
import com.knevo.model.TherapySetConfig;
import com.knevo.model.User;
import com.knevo.repository.ExerciseRepository;
import com.knevo.repository.TherapyConfigRepository;
import com.knevo.repository.TherapySetConfigRepository;
import com.knevo.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.util.Map;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class SessionIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired UserRepository userRepository;
    @Autowired TherapyConfigRepository therapyConfigRepository;
    @Autowired ExerciseRepository exerciseRepository;
    @Autowired TherapySetConfigRepository setConfigRepository;

    private User patient;
    private TherapyConfig config;
    private TherapySetConfig setConfig;

    @BeforeEach
    void setup() {
        User doctor = new User();
        doctor.setEmail("sessiondoctor@test.com");
        doctor.setUsername("sessiondoctor");
        doctor.setPasswordHash("hash");
        doctor.setName("Session Doctor");
        doctor.setRole(User.Role.DOCTOR);
        doctor.setDoctorStatus(User.DoctorStatus.APPROVED);
        doctor = userRepository.save(doctor);

        patient = new User();
        patient.setEmail("sessionpatient@test.com");
        patient.setUsername("sessionpatient");
        patient.setPasswordHash("hash");
        patient.setName("Session Patient");
        patient.setRole(User.Role.PATIENT);
        patient.setDoctor(doctor);
        patient = userRepository.save(patient);

        config = new TherapyConfig();
        config.setPatient(patient);
        config.setIssuedBy(doctor);
        config.setStatus("INPROGRESS");
        config = therapyConfigRepository.save(config);

        var exercise = exerciseRepository.findByActiveTrue().get(0);
        setConfig = new TherapySetConfig();
        setConfig.setTherapyConfig(config);
        setConfig.setExercise(exercise);
        setConfig.setSetOrder(0);
        setConfig = setConfigRepository.save(setConfig);
    }

    @Test
    void happyPathSession() throws Exception {
        var patientAuth = user(patient.getId().toString()).roles("PATIENT");

        var startReq = Map.of("configId", config.getId().toString(), "painBefore", 3);
        var startResult = mockMvc.perform(post("/api/sessions/start")
                .with(patientAuth)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(startReq)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.status").value("IN_PROGRESS"))
            .andExpect(jsonPath("$.painBefore").value(3))
            .andReturn();

        var sessionId = objectMapper.readTree(
            startResult.getResponse().getContentAsString()).get("id").asText();

        var startSetReq = Map.of("therapySetConfigId", setConfig.getId().toString());
        var setResult = mockMvc.perform(post("/api/sessions/" + sessionId + "/start-set")
                .with(patientAuth)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(startSetReq)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.status").value("IN_PROGRESS"))
            .andReturn();

        var setRecordId = objectMapper.readTree(
            setResult.getResponse().getContentAsString()).get("id").asText();

        var stopSetReq = Map.of(
            "therapySetRecordId", setRecordId,
            "painLevel", 2,
            "feedback", "Felt good");
        mockMvc.perform(post("/api/sessions/" + sessionId + "/stop-set")
                .with(patientAuth)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(stopSetReq)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("COMPLETED"))
            .andExpect(jsonPath("$.feedback").value("Felt good"));

        var completeReq = Map.of("painAfter", 2);
        mockMvc.perform(post("/api/sessions/" + sessionId + "/complete")
                .with(patientAuth)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(completeReq)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("COMPLETED"))
            .andExpect(jsonPath("$.painAfter").value(2));
    }

    @Test
    void highPainBlocksSessionStart() throws Exception {
        var req = Map.of("configId", config.getId().toString(), "painBefore", 8);
        mockMvc.perform(post("/api/sessions/start")
                .with(user(patient.getId().toString()).roles("PATIENT"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isUnprocessableEntity());
    }

    @Test
    void painButtonTerminatesSession() throws Exception {
        var patientAuth = user(patient.getId().toString()).roles("PATIENT");

        var startReq = Map.of("configId", config.getId().toString(), "painBefore", 2);
        var startResult = mockMvc.perform(post("/api/sessions/start")
                .with(patientAuth)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(startReq)))
            .andExpect(status().isCreated())
            .andReturn();
        var sessionId = objectMapper.readTree(
            startResult.getResponse().getContentAsString()).get("id").asText();

        var painReq = Map.of("painLevel", 8);
        mockMvc.perform(post("/api/sessions/" + sessionId + "/pain-button")
                .with(patientAuth)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(painReq)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("STOPPED_DUE_TO_PAIN"))
            .andExpect(jsonPath("$.painDuring").value(8));
    }

    @Test
    void getSessionReturnsSetRecords() throws Exception {
        var patientAuth = user(patient.getId().toString()).roles("PATIENT");

        var startReq = Map.of("configId", config.getId().toString(), "painBefore", 1);
        var startResult = mockMvc.perform(post("/api/sessions/start")
                .with(patientAuth)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(startReq)))
            .andExpect(status().isCreated())
            .andReturn();
        var sessionId = objectMapper.readTree(
            startResult.getResponse().getContentAsString()).get("id").asText();

        mockMvc.perform(get("/api/sessions/" + sessionId)
                .with(patientAuth))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(sessionId))
            .andExpect(jsonPath("$.setRecords").isArray());
    }

    @Test
    void stopSessionByPatient() throws Exception {
        var patientAuth = user(patient.getId().toString()).roles("PATIENT");

        var startReq = Map.of("configId", config.getId().toString(), "painBefore", 2);
        var startResult = mockMvc.perform(post("/api/sessions/start")
                .with(patientAuth)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(startReq)))
            .andExpect(status().isCreated())
            .andReturn();
        var sessionId = objectMapper.readTree(
            startResult.getResponse().getContentAsString()).get("id").asText();

        mockMvc.perform(post("/api/sessions/" + sessionId + "/stop")
                .with(patientAuth))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.status").value("STOPPED_BY_PATIENT"));
    }

    @Test
    void getPatientSessionsList() throws Exception {
        var patientAuth = user(patient.getId().toString()).roles("PATIENT");

        var startReq = Map.of("configId", config.getId().toString(), "painBefore", 1);
        mockMvc.perform(post("/api/sessions/start")
                .with(patientAuth)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(startReq)))
            .andExpect(status().isCreated());

        mockMvc.perform(get("/api/patient/sessions")
                .with(patientAuth))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$").isArray());
    }
}

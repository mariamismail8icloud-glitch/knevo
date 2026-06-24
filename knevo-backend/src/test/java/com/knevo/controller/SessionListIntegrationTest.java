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
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class SessionListIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired UserRepository userRepository;
    @Autowired TherapyConfigRepository therapyConfigRepository;
    @Autowired ExerciseRepository exerciseRepository;
    @Autowired TherapySetConfigRepository setConfigRepository;

    private User doctor;
    private User patient;
    private TherapyConfig config;
    private TherapySetConfig setConfig;

    @BeforeEach
    void setup() {
        doctor = new User();
        doctor.setEmail("sessionlistdoctor@test.com");
        doctor.setUsername("sessionlistdoctor");
        doctor.setPasswordHash("hash");
        doctor.setName("SessionList Doctor");
        doctor.setRole(User.Role.DOCTOR);
        doctor.setDoctorStatus(User.DoctorStatus.APPROVED);
        doctor = userRepository.save(doctor);

        patient = new User();
        patient.setEmail("sessionlistpatient@test.com");
        patient.setUsername("sessionlistpatient");
        patient.setPasswordHash("hash");
        patient.setName("SessionList Patient");
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
    void doctorPatientSessionsReturnsListOrderedByNewest() throws Exception {
        var startReq = Map.of("configId", config.getId().toString(), "painBefore", 2);
        mockMvc.perform(post("/api/sessions/start")
                .with(user(patient.getId().toString()).roles("PATIENT"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(startReq)))
            .andExpect(status().isCreated());

        mockMvc.perform(get("/api/doctor/patients/" + patient.getId() + "/sessions")
                .with(user(doctor.getId().toString()).roles("DOCTOR")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$").isArray())
            .andExpect(jsonPath("$[0].status").value("IN_PROGRESS"))
            .andExpect(jsonPath("$[0].patientId").value(patient.getId().toString()));
    }

    @Test
    void doctorPatientSessionsEmptyWhenNoSessions() throws Exception {
        mockMvc.perform(get("/api/doctor/patients/" + patient.getId() + "/sessions")
                .with(user(doctor.getId().toString()).roles("DOCTOR")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$").isArray())
            .andExpect(jsonPath("$").isEmpty());
    }

    @Test
    void sessionDetailIncludesSetRecordsWithExerciseName() throws Exception {
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

        var startSetReq = Map.of("therapySetConfigId", setConfig.getId().toString());
        mockMvc.perform(post("/api/sessions/" + sessionId + "/start-set")
                .with(patientAuth)
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(startSetReq)))
            .andExpect(status().isCreated());

        mockMvc.perform(get("/api/sessions/" + sessionId)
                .with(user(doctor.getId().toString()).roles("DOCTOR")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.setRecords").isArray())
            .andExpect(jsonPath("$.setRecords[0].exerciseName").isString());
    }
}

package com.knevo.controller;

import com.knevo.model.Session;
import com.knevo.model.TherapyConfig;
import com.knevo.model.User;
import com.knevo.repository.SessionRepository;
import com.knevo.repository.TherapyConfigRepository;
import com.knevo.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import java.time.OffsetDateTime;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class ProgressIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired UserRepository userRepository;
    @Autowired TherapyConfigRepository therapyConfigRepository;
    @Autowired SessionRepository sessionRepository;

    private User patient;

    @BeforeEach
    void setup() {
        User doctor = new User();
        doctor.setEmail("progressdoctor@test.com");
        doctor.setUsername("progressdoctor");
        doctor.setPasswordHash("hash");
        doctor.setName("Progress Doctor");
        doctor.setRole(User.Role.DOCTOR);
        doctor.setDoctorStatus(User.DoctorStatus.APPROVED);
        doctor = userRepository.save(doctor);

        patient = new User();
        patient.setEmail("progresspatient@test.com");
        patient.setUsername("progresspatient");
        patient.setPasswordHash("hash");
        patient.setName("Progress Patient");
        patient.setRole(User.Role.PATIENT);
        patient.setDoctor(doctor);
        patient = userRepository.save(patient);

        TherapyConfig config = new TherapyConfig();
        config.setPatient(patient);
        config.setIssuedBy(doctor);
        config.setStatus("INPROGRESS");
        config.setTotalSessionsNum(6);
        therapyConfigRepository.save(config);

        // Create 3 completed sessions
        for (int i = 0; i < 3; i++) {
            Session session = new Session();
            session.setPatient(patient);
            session.setStatus("COMPLETED");
            session.setStartedAt(OffsetDateTime.now().minusDays(i));
            session.setEndedAt(OffsetDateTime.now().minusDays(i).plusMinutes(30));
            session.setPainBefore(3 + i);
            sessionRepository.save(session);
        }
    }

    @Test
    void getProgressReturnsCorrectAdherenceAndCounts() throws Exception {
        mockMvc.perform(get("/api/patients/{patientId}/progress", patient.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.sessionsPerWeek").isArray())
                .andExpect(jsonPath("$.sessionsPerWeek.length()").value(8))
                .andExpect(jsonPath("$.totalSessionsCompleted").value(3))
                .andExpect(jsonPath("$.totalSessionsPrescribed").value(6))
                .andExpect(jsonPath("$.adherenceRate").value(0.5))
                .andExpect(jsonPath("$.painTrend").isArray())
                .andExpect(jsonPath("$.painTrend.length()").value(3));
    }

    @Test
    void getMyProgressEndpointWorks() throws Exception {
        mockMvc.perform(get("/api/patient/progress")
                        .header("X-User-Id", patient.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.totalSessionsCompleted").value(3));
    }

    @Test
    void noSessionsReturnsZeroAdherence() throws Exception {
        User doctor2 = new User();
        doctor2.setEmail("progressdoctor2@test.com");
        doctor2.setUsername("progressdoctor2");
        doctor2.setPasswordHash("hash");
        doctor2.setName("Progress Doctor 2");
        doctor2.setRole(User.Role.DOCTOR);
        doctor2.setDoctorStatus(User.DoctorStatus.APPROVED);
        doctor2 = userRepository.save(doctor2);

        User emptyPatient = new User();
        emptyPatient.setEmail("emptypatient@test.com");
        emptyPatient.setUsername("emptypatient");
        emptyPatient.setPasswordHash("hash");
        emptyPatient.setName("Empty Patient");
        emptyPatient.setRole(User.Role.PATIENT);
        emptyPatient.setDoctor(doctor2);
        emptyPatient = userRepository.save(emptyPatient);

        mockMvc.perform(get("/api/patients/{patientId}/progress", emptyPatient.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.adherenceRate").value(0.0))
                .andExpect(jsonPath("$.totalSessionsCompleted").value(0))
                .andExpect(jsonPath("$.sessionsPerWeek.length()").value(8));
    }
}

package com.knevo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.knevo.dto.auth.PatientSignupRequest;
import com.knevo.dto.enrollment.EnrollPatientRequest;
import com.knevo.model.User;
import com.knevo.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class EnrollmentIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired UserRepository userRepository;

    private User patient;
    private User doctor;

    @BeforeEach
    void setup() throws Exception {
        // Create patient
        PatientSignupRequest patReq = new PatientSignupRequest();
        patReq.setUsername("enrollpatient");
        patReq.setEmail("enrollpatient@test.com");
        patReq.setPassword("Password123!");
        patReq.setName("Enroll Patient");
        patReq.setConsentGiven(true);

        mockMvc.perform(post("/api/auth/signup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(patReq)));

        patient = userRepository.findByEmail("enrollpatient@test.com").orElseThrow();

        // Create approved doctor
        doctor = new User();
        doctor.setEmail("enrolldoctor@test.com");
        doctor.setUsername("enrolldoctor");
        doctor.setPasswordHash("$2a$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi");
        doctor.setName("Enroll Doctor");
        doctor.setRole(User.Role.DOCTOR);
        doctor.setDoctorStatus(User.DoctorStatus.APPROVED);
        doctor = userRepository.save(doctor);
    }

    @Test
    void patientCanRegenerateCode() throws Exception {
        mockMvc.perform(post("/api/patients/enrollment-code")
                .header("X-User-Id", patient.getId()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.enrollmentCode").isNotEmpty());
    }

    @Test
    void doctorCanEnrollPatient() throws Exception {
        EnrollPatientRequest req = new EnrollPatientRequest();
        req.setEnrollmentCode(patient.getEnrollmentCode());

        mockMvc.perform(post("/api/doctor/enroll-patient")
                .header("X-User-Id", doctor.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value(patient.getId().toString()));
    }

    @Test
    void enrolledPatientAppearsInDoctorList() throws Exception {
        EnrollPatientRequest req = new EnrollPatientRequest();
        req.setEnrollmentCode(patient.getEnrollmentCode());

        mockMvc.perform(post("/api/doctor/enroll-patient")
                .header("X-User-Id", doctor.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)));

        mockMvc.perform(get("/api/doctor/patients")
                .header("X-User-Id", doctor.getId()))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$", hasSize(1)))
            .andExpect(jsonPath("$[0].email").value("enrollpatient@test.com"));
    }

    @Test
    void invalidCodeReturns404() throws Exception {
        EnrollPatientRequest req = new EnrollPatientRequest();
        req.setEnrollmentCode("BADCODE1");

        mockMvc.perform(post("/api/doctor/enroll-patient")
                .header("X-User-Id", doctor.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isNotFound());
    }

    @Test
    void doubleEnrollReturns409() throws Exception {
        EnrollPatientRequest req = new EnrollPatientRequest();
        req.setEnrollmentCode(patient.getEnrollmentCode());

        mockMvc.perform(post("/api/doctor/enroll-patient")
                .header("X-User-Id", doctor.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)));

        // Second doctor tries same code
        User doctor2 = new User();
        doctor2.setEmail("doctor2@test.com");
        doctor2.setUsername("doctor2");
        doctor2.setPasswordHash("$2a$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi");
        doctor2.setName("Doctor Two");
        doctor2.setRole(User.Role.DOCTOR);
        doctor2.setDoctorStatus(User.DoctorStatus.APPROVED);
        doctor2 = userRepository.save(doctor2);

        mockMvc.perform(post("/api/doctor/enroll-patient")
                .header("X-User-Id", doctor2.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isConflict());
    }
}

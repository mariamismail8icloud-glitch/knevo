package com.knevo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.knevo.dto.auth.DoctorSignupRequest;
import com.knevo.dto.auth.LoginRequest;
import com.knevo.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class DoctorApprovalIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired UserRepository userRepository;

    // Real seeded admin ID from V3 migration (admin@knevo.com)
    private String adminId;

    @BeforeEach
    void setup() {
        adminId = userRepository.findByEmail("admin@knevo.com")
            .map(u -> u.getId().toString())
            .orElseThrow(() -> new IllegalStateException("Seeded admin not found — check V3 migration"));
    }

    @Test
    void doctorSignupReturnsPending() throws Exception {
        DoctorSignupRequest req = doctorSignupReq("drpending@test.com", "drpending");

        mockMvc.perform(post("/api/auth/signup/doctor")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isAccepted());
    }

    @Test
    void unapprovedDoctorCannotLogin() throws Exception {
        DoctorSignupRequest req = doctorSignupReq("drblocked@test.com", "drblocked");
        mockMvc.perform(post("/api/auth/signup/doctor")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isAccepted());

        LoginRequest login = new LoginRequest();
        login.setEmail("drblocked@test.com");
        login.setPassword("Password123!");

        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(login)))
            .andExpect(status().isForbidden());
    }

    @Test
    void pendingDoctorAppearsInList() throws Exception {
        DoctorSignupRequest req = doctorSignupReq("drlist@test.com", "drlist");
        mockMvc.perform(post("/api/auth/signup/doctor")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isAccepted());

        mockMvc.perform(get("/api/admin/doctors/pending")
                .with(user(adminId).roles("ADMIN")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$[?(@.email=='drlist@test.com')]").exists());
    }

    @Test
    void approvedDoctorCanLogin() throws Exception {
        DoctorSignupRequest req = doctorSignupReq("drapproved@test.com", "drapproved");
        mockMvc.perform(post("/api/auth/signup/doctor")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isAccepted());

        var doctor = userRepository.findByEmail("drapproved@test.com").orElseThrow();

        mockMvc.perform(post("/api/admin/doctors/" + doctor.getId() + "/approve")
                .with(user(adminId).roles("ADMIN")))
            .andExpect(status().isOk());

        LoginRequest login = new LoginRequest();
        login.setEmail("drapproved@test.com");
        login.setPassword("Password123!");

        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(login)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.accessToken").isNotEmpty())
            .andExpect(jsonPath("$.role").value("DOCTOR"));
    }

    private DoctorSignupRequest doctorSignupReq(String email, String username) {
        DoctorSignupRequest req = new DoctorSignupRequest();
        req.setEmail(email);
        req.setUsername(username);
        req.setPassword("Password123!");
        req.setName("Dr Test");
        req.setClinicName("Test Clinic");
        req.setSpecialization("Physiotherapy");
        return req;
    }
}

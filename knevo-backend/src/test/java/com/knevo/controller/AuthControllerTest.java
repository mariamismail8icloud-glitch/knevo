package com.knevo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.knevo.dto.auth.LoginRequest;
import com.knevo.dto.auth.PatientSignupRequest;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class AuthControllerTest {

    @Autowired
    private MockMvc mockMvc;

    @Autowired
    private ObjectMapper objectMapper;

    @Test
    void signupNewPatient() throws Exception {
        PatientSignupRequest req = new PatientSignupRequest();
        req.setUsername("testpatient");
        req.setEmail("test@example.com");
        req.setPassword("Password123!");
        req.setName("Test Patient");
        req.setConsentGiven(true);

        mockMvc.perform(post("/api/auth/signup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.accessToken").isNotEmpty())
            .andExpect(jsonPath("$.refreshToken").isNotEmpty())
            .andExpect(jsonPath("$.enrollmentCode").isNotEmpty())
            .andExpect(jsonPath("$.role").value("PATIENT"));
    }

    @Test
    void signupDuplicateEmailReturns409() throws Exception {
        PatientSignupRequest req = new PatientSignupRequest();
        req.setUsername("user1");
        req.setEmail("dup@example.com");
        req.setPassword("Password123!");
        req.setName("User One");
        req.setConsentGiven(true);

        mockMvc.perform(post("/api/auth/signup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isCreated());

        req.setUsername("user2");
        mockMvc.perform(post("/api/auth/signup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isConflict());
    }

    @Test
    void loginWithWrongPasswordReturns401() throws Exception {
        LoginRequest req = new LoginRequest();
        req.setEmail("nobody@example.com");
        req.setPassword("wrongpassword");

        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
            .andExpect(status().isUnauthorized());
    }

    @Test
    void signupThenLoginReturnsTokens() throws Exception {
        PatientSignupRequest signupReq = new PatientSignupRequest();
        signupReq.setUsername("logintest");
        signupReq.setEmail("login@example.com");
        signupReq.setPassword("Password123!");
        signupReq.setName("Login User");
        signupReq.setConsentGiven(true);

        mockMvc.perform(post("/api/auth/signup")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(signupReq)))
            .andExpect(status().isCreated());

        LoginRequest loginReq = new LoginRequest();
        loginReq.setEmail("login@example.com");
        loginReq.setPassword("Password123!");

        mockMvc.perform(post("/api/auth/login")
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(loginReq)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.accessToken").isNotEmpty())
            .andExpect(jsonPath("$.role").value("PATIENT"));
    }
}

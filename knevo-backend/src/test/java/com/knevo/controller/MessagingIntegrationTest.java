package com.knevo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.knevo.dto.message.SendMessageRequest;
import com.knevo.model.User;
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
import org.springframework.test.web.servlet.MvcResult;
import org.springframework.transaction.annotation.Transactional;

import java.util.UUID;

import static org.hamcrest.Matchers.greaterThanOrEqualTo;
import static org.hamcrest.Matchers.hasSize;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.*;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.*;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class MessagingIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired UserRepository userRepository;

    @MockBean
    SimpMessagingTemplate messagingTemplate;

    private User doctor;
    private User patient;

    @BeforeEach
    void setup() {
        doctor = new User();
        doctor.setEmail("msg-doctor@test.com");
        doctor.setUsername("msg-doctor");
        doctor.setPasswordHash("$2a$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi");
        doctor.setName("Message Doctor");
        doctor.setRole(User.Role.DOCTOR);
        doctor.setDoctorStatus(User.DoctorStatus.APPROVED);
        doctor = userRepository.save(doctor);

        patient = new User();
        patient.setEmail("msg-patient@test.com");
        patient.setUsername("msg-patient");
        patient.setPasswordHash("$2a$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi");
        patient.setName("Message Patient");
        patient.setRole(User.Role.PATIENT);
        patient = userRepository.save(patient);
    }

    @Test
    void sendAndRetrieveThread() throws Exception {
        SendMessageRequest req = new SendMessageRequest();
        req.setBody("Hello patient");
        req.setReceiverId(patient.getId());

        mockMvc.perform(post("/api/messages")
                .header("X-User-Id", doctor.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andExpect(jsonPath("$.body").value("Hello patient"))
                .andExpect(jsonPath("$.senderId").value(doctor.getId().toString()))
                .andExpect(jsonPath("$.receiverId").value(patient.getId().toString()));

        mockMvc.perform(get("/api/messages")
                .header("X-User-Id", patient.getId())
                .param("partnerId", doctor.getId().toString()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$", hasSize(greaterThanOrEqualTo(1))))
                .andExpect(jsonPath("$[0].body").value("Hello patient"));
    }

    @Test
    void markMessageRead() throws Exception {
        SendMessageRequest req = new SendMessageRequest();
        req.setBody("Mark me read");
        req.setReceiverId(patient.getId());

        MvcResult result = mockMvc.perform(post("/api/messages")
                .header("X-User-Id", doctor.getId())
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(req)))
                .andExpect(status().isCreated())
                .andReturn();

        String body = result.getResponse().getContentAsString();
        String messageId = objectMapper.readTree(body).get("id").asText();

        mockMvc.perform(put("/api/messages/{id}/read", UUID.fromString(messageId))
                .header("X-User-Id", patient.getId()))
                .andExpect(status().isNoContent());
    }

    @Test
    void unreadCountDecreasesAfterRead() throws Exception {
        // Send 2 messages to patient
        for (int i = 1; i <= 2; i++) {
            SendMessageRequest req = new SendMessageRequest();
            req.setBody("Message " + i);
            req.setReceiverId(patient.getId());

            mockMvc.perform(post("/api/messages")
                    .header("X-User-Id", doctor.getId())
                    .contentType(MediaType.APPLICATION_JSON)
                    .content(objectMapper.writeValueAsString(req)))
                    .andExpect(status().isCreated());
        }

        // Verify unread count = 2
        mockMvc.perform(get("/api/messages/unread-count")
                .header("X-User-Id", patient.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.count").value(2));

        // Get the thread to find message IDs
        MvcResult threadResult = mockMvc.perform(get("/api/messages")
                .header("X-User-Id", patient.getId())
                .param("partnerId", doctor.getId().toString()))
                .andReturn();

        String firstMessageId = objectMapper.readTree(threadResult.getResponse().getContentAsString())
                .get(0).get("id").asText();

        // Mark one read
        mockMvc.perform(put("/api/messages/{id}/read", UUID.fromString(firstMessageId))
                .header("X-User-Id", patient.getId()))
                .andExpect(status().isNoContent());

        // Verify count = 1
        mockMvc.perform(get("/api/messages/unread-count")
                .header("X-User-Id", patient.getId()))
                .andExpect(status().isOk())
                .andExpect(jsonPath("$.count").value(1));
    }
}

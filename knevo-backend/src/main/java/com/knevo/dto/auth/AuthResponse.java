package com.knevo.dto.auth;

import lombok.AllArgsConstructor;
import lombok.Data;

import java.util.UUID;

@Data
@AllArgsConstructor
public class AuthResponse {
    private UUID userId;
    private String role;
    private String enrollmentCode;
    private String accessToken;
    private String refreshToken;
}

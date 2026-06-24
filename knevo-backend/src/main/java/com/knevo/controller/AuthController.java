package com.knevo.controller;

import com.knevo.dto.auth.AuthResponse;
import com.knevo.dto.auth.DoctorSignupRequest;
import com.knevo.dto.auth.LoginRequest;
import com.knevo.dto.auth.PatientSignupRequest;
import com.knevo.dto.auth.RefreshRequest;
import com.knevo.service.AuthService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

@RestController
@RequestMapping("/api/auth")
@RequiredArgsConstructor
public class AuthController {

    private final AuthService authService;

    @PostMapping("/signup")
    public ResponseEntity<AuthResponse> signup(@Valid @RequestBody PatientSignupRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(authService.signupPatient(req));
    }

    @PostMapping("/signup/doctor")
    public ResponseEntity<Void> signupDoctor(@Valid @RequestBody DoctorSignupRequest req) {
        authService.signupDoctor(req);
        return ResponseEntity.status(HttpStatus.ACCEPTED).build();
    }

    @PostMapping("/login")
    public ResponseEntity<AuthResponse> login(@Valid @RequestBody LoginRequest req) {
        return ResponseEntity.ok(authService.login(req));
    }

    @PostMapping("/refresh")
    public ResponseEntity<AuthResponse> refresh(@Valid @RequestBody RefreshRequest req) {
        return ResponseEntity.ok(authService.refresh(req));
    }

    @PostMapping("/logout")
    public ResponseEntity<Void> logout() {
        return ResponseEntity.noContent().build();
    }
}

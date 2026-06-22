package com.knevo.service;

import com.knevo.dto.auth.AuthResponse;
import com.knevo.dto.auth.DoctorSignupRequest;
import com.knevo.dto.auth.LoginRequest;
import com.knevo.dto.auth.PatientSignupRequest;
import com.knevo.dto.auth.RefreshRequest;
import com.knevo.model.User;
import com.knevo.repository.UserRepository;
import com.knevo.security.JwtService;
import com.knevo.util.EnrollmentCodeGenerator;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.security.crypto.password.PasswordEncoder;
import org.springframework.stereotype.Service;
import org.springframework.web.server.ResponseStatusException;

import java.time.LocalDate;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class AuthService {

    private final UserRepository userRepository;
    private final PasswordEncoder passwordEncoder;
    private final JwtService jwtService;
    private final EnrollmentCodeGenerator codeGenerator;

    public AuthResponse signupPatient(PatientSignupRequest req) {
        if (userRepository.existsByEmail(req.getEmail())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already in use");
        }
        if (userRepository.existsByUsername(req.getUsername())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Username already taken");
        }

        User user = new User();
        user.setEmail(req.getEmail().toLowerCase());
        user.setUsername(req.getUsername());
        user.setPasswordHash(passwordEncoder.encode(req.getPassword()));
        user.setName(req.getName());
        user.setRole(User.Role.PATIENT);
        user.setPhone(req.getPhone());
        user.setGender(req.getGender());
        if (req.getBirthDate() != null && !req.getBirthDate().isBlank()) {
            user.setBirthDate(LocalDate.parse(req.getBirthDate()));
        }
        user.setEmergencyContactName(req.getEmergencyContactName());
        user.setEmergencyContactPhone(req.getEmergencyContactPhone());
        user.setEnrollmentCode(codeGenerator.generate());

        User saved = userRepository.save(user);
        return buildAuthResponse(saved);
    }

    public void signupDoctor(DoctorSignupRequest req) {
        if (userRepository.existsByEmail(req.getEmail())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Email already in use");
        }
        if (userRepository.existsByUsername(req.getUsername())) {
            throw new ResponseStatusException(HttpStatus.CONFLICT, "Username already taken");
        }

        User user = new User();
        user.setEmail(req.getEmail().toLowerCase());
        user.setUsername(req.getUsername());
        user.setPasswordHash(passwordEncoder.encode(req.getPassword()));
        user.setName(req.getName());
        user.setRole(User.Role.DOCTOR);
        user.setDoctorStatus(User.DoctorStatus.PENDING);
        user.setPhone(req.getPhone());
        user.setClinicName(req.getClinicName());
        user.setSpecialization(req.getSpecialization());
        user.setProfessionalLicense(req.getProfessionalLicense());
        user.setYearsExperience(req.getYearsExperience());

        userRepository.save(user);
    }

    public AuthResponse login(LoginRequest req) {
        User user = userRepository.findByEmail(req.getEmail().toLowerCase())
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials"));

        if (!passwordEncoder.matches(req.getPassword(), user.getPasswordHash())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid credentials");
        }

        if (user.getRole() == User.Role.DOCTOR
                && user.getDoctorStatus() != User.DoctorStatus.APPROVED) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Account pending approval");
        }

        return buildAuthResponse(user);
    }

    public AuthResponse refresh(RefreshRequest req) {
        if (!jwtService.isValid(req.getRefreshToken())) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Invalid refresh token");
        }
        var claims = jwtService.parseToken(req.getRefreshToken());
        if (!"refresh".equals(claims.get("type"))) {
            throw new ResponseStatusException(HttpStatus.UNAUTHORIZED, "Not a refresh token");
        }
        var userId = UUID.fromString(claims.getSubject());
        User user = userRepository.findById(userId)
            .orElseThrow(() -> new ResponseStatusException(HttpStatus.UNAUTHORIZED, "User not found"));
        return buildAuthResponse(user);
    }

    private AuthResponse buildAuthResponse(User user) {
        String access = jwtService.generateAccessToken(user.getId(), user.getRole().name());
        String refresh = jwtService.generateRefreshToken(user.getId());
        return new AuthResponse(user.getId(), user.getRole().name(), user.getEnrollmentCode(), access, refresh);
    }
}

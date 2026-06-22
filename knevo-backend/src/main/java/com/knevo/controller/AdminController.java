package com.knevo.controller;

import com.knevo.dto.admin.DoctorSummaryDto;
import com.knevo.dto.admin.RejectRequest;
import com.knevo.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
@PreAuthorize("hasRole('ADMIN')")
public class AdminController {

    private final AdminService adminService;

    @GetMapping("/doctors")
    public ResponseEntity<List<DoctorSummaryDto>> allDoctors() {
        return ResponseEntity.ok(adminService.getAllDoctors());
    }

    @GetMapping("/doctors/pending")
    public ResponseEntity<List<DoctorSummaryDto>> pendingDoctors() {
        return ResponseEntity.ok(adminService.getPendingDoctors());
    }

    @PostMapping("/doctors/{id}/approve")
    public ResponseEntity<Void> approveDoctor(@PathVariable UUID id, Authentication auth) {
        adminService.approveDoctor(id, UUID.fromString(auth.getName()));
        return ResponseEntity.ok().build();
    }

    @PostMapping("/doctors/{id}/reject")
    public ResponseEntity<Void> rejectDoctor(@PathVariable UUID id,
                                              @RequestBody(required = false) RejectRequest req,
                                              Authentication auth) {
        adminService.rejectDoctor(id, UUID.fromString(auth.getName()), req != null ? req.getReason() : null);
        return ResponseEntity.ok().build();
    }
}

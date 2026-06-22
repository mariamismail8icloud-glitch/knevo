package com.knevo.controller;

import com.knevo.dto.admin.DoctorSummaryDto;
import com.knevo.dto.admin.RejectRequest;
import com.knevo.service.AdminService;
import lombok.RequiredArgsConstructor;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.UUID;

@RestController
@RequestMapping("/api/admin")
@RequiredArgsConstructor
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
    public ResponseEntity<Void> approveDoctor(@PathVariable UUID id) {
        // adminId is null until JWT extraction is wired in M7
        adminService.approveDoctor(id, null);
        return ResponseEntity.ok().build();
    }

    @PostMapping("/doctors/{id}/reject")
    public ResponseEntity<Void> rejectDoctor(@PathVariable UUID id,
                                              @RequestBody(required = false) RejectRequest req) {
        // adminId is null until JWT extraction is wired in M7
        adminService.rejectDoctor(id, null, req != null ? req.getReason() : null);
        return ResponseEntity.ok().build();
    }
}

package com.knevo.controller;

import com.knevo.dto.message.MessageDto;
import com.knevo.dto.message.SendMessageRequest;
import com.knevo.service.MessageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.security.access.prepost.PreAuthorize;
import org.springframework.security.core.Authentication;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
@PreAuthorize("hasRole('PATIENT') or hasRole('DOCTOR')")
public class MessageController {

    private final MessageService messageService;

    @PostMapping("/api/messages")
    public ResponseEntity<MessageDto> sendMessage(Authentication auth,
                                                  @Valid @RequestBody SendMessageRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED)
                .body(messageService.sendMessage(UUID.fromString(auth.getName()), req));
    }

    @GetMapping("/api/messages")
    public ResponseEntity<List<MessageDto>> getThread(Authentication auth,
                                                      @RequestParam UUID partnerId) {
        return ResponseEntity.ok(messageService.getThread(UUID.fromString(auth.getName()), partnerId));
    }

    @PutMapping("/api/messages/{id}/read")
    public ResponseEntity<Void> markRead(@PathVariable UUID id, Authentication auth) {
        messageService.markRead(id, UUID.fromString(auth.getName()));
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/api/messages/unread-count")
    public ResponseEntity<Map<String, Long>> unreadCount(Authentication auth) {
        return ResponseEntity.ok(Map.of("count", messageService.getUnreadCount(UUID.fromString(auth.getName()))));
    }
}

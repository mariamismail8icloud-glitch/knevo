package com.knevo.controller;

import com.knevo.dto.message.MessageDto;
import com.knevo.dto.message.SendMessageRequest;
import com.knevo.service.MessageService;
import jakarta.validation.Valid;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.*;

import java.util.List;
import java.util.Map;
import java.util.UUID;

@RestController
@RequiredArgsConstructor
public class MessageController {

    private final MessageService messageService;

    @PostMapping("/api/messages")
    public ResponseEntity<MessageDto> sendMessage(
            @RequestHeader("X-User-Id") UUID senderId,
            @Valid @RequestBody SendMessageRequest req) {
        return ResponseEntity.status(HttpStatus.CREATED).body(messageService.sendMessage(senderId, req));
    }

    @GetMapping("/api/messages")
    public ResponseEntity<List<MessageDto>> getThread(
            @RequestHeader("X-User-Id") UUID userId,
            @RequestParam UUID partnerId) {
        return ResponseEntity.ok(messageService.getThread(userId, partnerId));
    }

    @PutMapping("/api/messages/{id}/read")
    public ResponseEntity<Void> markRead(
            @PathVariable UUID id,
            @RequestHeader("X-User-Id") UUID readerId) {
        messageService.markRead(id, readerId);
        return ResponseEntity.noContent().build();
    }

    @GetMapping("/api/messages/unread-count")
    public ResponseEntity<Map<String, Long>> unreadCount(
            @RequestHeader("X-User-Id") UUID userId) {
        return ResponseEntity.ok(Map.of("count", messageService.getUnreadCount(userId)));
    }
}

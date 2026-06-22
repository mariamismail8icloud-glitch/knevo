package com.knevo.service;

import com.knevo.dto.message.MessageDto;
import com.knevo.dto.message.SendMessageRequest;
import com.knevo.model.Message;
import com.knevo.model.User;
import com.knevo.repository.MessageRepository;
import com.knevo.repository.UserRepository;
import lombok.RequiredArgsConstructor;
import org.springframework.http.HttpStatus;
import org.springframework.messaging.simp.SimpMessagingTemplate;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;
import org.springframework.web.server.ResponseStatusException;

import java.time.OffsetDateTime;
import java.util.List;
import java.util.UUID;

@Service
@RequiredArgsConstructor
public class MessageService {

    private final MessageRepository messageRepository;
    private final UserRepository userRepository;
    private final SimpMessagingTemplate messagingTemplate;

    @Transactional
    public MessageDto sendMessage(UUID senderId, SendMessageRequest req) {
        User sender = userRepository.findById(senderId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Sender not found"));
        User receiver = userRepository.findById(req.getReceiverId())
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Receiver not found"));

        String type = req.getMessageType() != null ? req.getMessageType() : "TEXT";

        Message message = new Message();
        message.setSender(sender);
        message.setReceiver(receiver);
        message.setBody(req.getBody());
        message.setMessageType(type);
        message = messageRepository.save(message);

        MessageDto dto = toDto(message);
        messagingTemplate.convertAndSend("/topic/messages/" + req.getReceiverId(), dto);
        return dto;
    }

    @Transactional(readOnly = true)
    public List<MessageDto> getThread(UUID userId, UUID partnerId) {
        return messageRepository.findThread(userId, partnerId).stream()
                .map(this::toDto)
                .toList();
    }

    @Transactional
    public void markRead(UUID messageId, UUID readerId) {
        Message message = messageRepository.findById(messageId)
                .orElseThrow(() -> new ResponseStatusException(HttpStatus.NOT_FOUND, "Message not found"));
        if (!message.getReceiver().getId().equals(readerId)) {
            throw new ResponseStatusException(HttpStatus.FORBIDDEN, "Not your message");
        }
        if (message.getReadAt() == null) {
            message.setReadAt(OffsetDateTime.now());
            messageRepository.save(message);
        }
    }

    public long getUnreadCount(UUID userId) {
        return messageRepository.countByReceiver_IdAndReadAtIsNull(userId);
    }

    private MessageDto toDto(Message m) {
        MessageDto dto = new MessageDto();
        dto.setId(m.getId());
        dto.setSenderId(m.getSender().getId());
        dto.setReceiverId(m.getReceiver().getId());
        dto.setSenderName(m.getSender().getName());
        dto.setBody(m.getBody());
        dto.setMessageType(m.getMessageType());
        dto.setSentAt(m.getCreatedAt());
        dto.setReadAt(m.getReadAt());
        return dto;
    }
}

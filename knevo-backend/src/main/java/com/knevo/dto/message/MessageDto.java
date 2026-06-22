package com.knevo.dto.message;

import lombok.Data;

import java.time.OffsetDateTime;
import java.util.UUID;

@Data
public class MessageDto {

    private UUID id;
    private UUID senderId;
    private UUID receiverId;
    private String senderName;
    private String body;
    private String messageType;
    private OffsetDateTime sentAt;
    private OffsetDateTime readAt;
}

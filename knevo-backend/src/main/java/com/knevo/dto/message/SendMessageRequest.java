package com.knevo.dto.message;

import jakarta.validation.constraints.NotBlank;
import jakarta.validation.constraints.NotNull;
import lombok.Data;

import java.util.UUID;

@Data
public class SendMessageRequest {

    @NotBlank
    private String body;

    @NotNull
    private UUID receiverId;

    private String messageType = "TEXT";
}

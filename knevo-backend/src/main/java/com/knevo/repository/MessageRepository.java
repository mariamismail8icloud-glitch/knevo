package com.knevo.repository;

import com.knevo.model.Message;
import org.springframework.data.jpa.repository.JpaRepository;
import org.springframework.data.jpa.repository.Query;
import org.springframework.data.repository.query.Param;

import java.util.List;
import java.util.UUID;

public interface MessageRepository extends JpaRepository<Message, UUID> {

    @Query("SELECT m FROM Message m WHERE (m.sender.id = :userId AND m.receiver.id = :partnerId) OR (m.sender.id = :partnerId AND m.receiver.id = :userId) ORDER BY m.createdAt ASC")
    List<Message> findThread(@Param("userId") UUID userId, @Param("partnerId") UUID partnerId);

    long countByReceiver_IdAndReadAtIsNull(UUID receiverId);
}

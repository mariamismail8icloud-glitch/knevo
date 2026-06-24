-- Replaces the admin seed password with a known value (Admin1234!).
-- V3's original hash had no documented plaintext; this corrects it.
UPDATE users
SET password_hash = '$2b$10$IN2rmB5fALEyKQ9OUIRkWOYGNQVqWkoQmv8wEyYQtKKLOibkHDEb.'
WHERE email = 'admin@knevo.com';

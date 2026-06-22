INSERT INTO users (id, email, username, password_hash, name, role, created_at)
VALUES (
    gen_random_uuid(),
    'admin@knevo.com',
    'admin',
    '$2b$10$IN2rmB5fALEyKQ9OUIRkWOYGNQVqWkoQmv8wEyYQtKKLOibkHDEb.',
    'Knevo Admin',
    'ADMIN',
    NOW()
)
ON CONFLICT (email) DO NOTHING;

INSERT INTO users (id, email, username, password_hash, name, role, created_at)
VALUES (
    gen_random_uuid(),
    'admin@knevo.com',
    'admin',
    '$2a$12$92IXUNpkjO0rOQ5byMi.Ye4oKoEa3Ro9llC/.og/at2.uheWG/igi',
    'Knevo Admin',
    'ADMIN',
    NOW()
)
ON CONFLICT (email) DO NOTHING;

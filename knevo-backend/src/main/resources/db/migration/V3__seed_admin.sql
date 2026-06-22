INSERT INTO users (id, email, username, password_hash, name, role, created_at)
VALUES (
    gen_random_uuid(),
    'admin@knevo.com',
    'admin',
    '$2a$10$i401yP4J4NMIMdU5Tk.XEu4y/8V9B7Ve.PV9QDnCjxMoCR6XdHGuK',
    'Knevo Admin',
    'ADMIN',
    NOW()
)
ON CONFLICT (email) DO NOTHING;

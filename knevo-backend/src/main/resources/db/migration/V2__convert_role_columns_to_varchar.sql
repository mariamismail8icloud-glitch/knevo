-- Convert enum columns to varchar for easier JPA mapping
ALTER TABLE users ALTER COLUMN role TYPE VARCHAR(20);
ALTER TABLE users ALTER COLUMN doctor_status TYPE VARCHAR(20);
ALTER TABLE users ALTER COLUMN gender TYPE VARCHAR(20);

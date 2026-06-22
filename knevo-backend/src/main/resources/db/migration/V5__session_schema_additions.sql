-- Convert sessions.status from PostgreSQL enum to VARCHAR for JPA string mapping
ALTER TABLE sessions ALTER COLUMN status TYPE VARCHAR(50);

-- Convert pain_logs.context from PostgreSQL enum to VARCHAR
ALTER TABLE pain_logs ALTER COLUMN context TYPE VARCHAR(50);

-- Convert alerts.type, severity, status from PostgreSQL enums to VARCHAR
ALTER TABLE alerts ALTER COLUMN type TYPE VARCHAR(50);
ALTER TABLE alerts ALTER COLUMN severity TYPE VARCHAR(50);
ALTER TABLE alerts ALTER COLUMN status TYPE VARCHAR(50);

-- Add status column to therapy_set_records (was missing in V1)
ALTER TABLE therapy_set_records ADD COLUMN status VARCHAR(50) NOT NULL DEFAULT 'IN_PROGRESS';

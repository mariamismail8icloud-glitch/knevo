-- Enum types
CREATE TYPE user_role AS ENUM ('PATIENT', 'DOCTOR', 'ADMIN');
CREATE TYPE user_gender AS ENUM ('MALE', 'FEMALE');
CREATE TYPE education_level AS ENUM ('NO_FORMAL_EDUCATION', 'PRIMARY', 'HIGH_SCHOOL', 'TECHNICAL_VOCATIONAL', 'GRADUATE', 'POST_GRADUATE');
CREATE TYPE doctor_status AS ENUM ('PENDING', 'APPROVED', 'REJECTED', 'SUSPENDED');
CREATE TYPE affected_side AS ENUM ('RIGHT', 'LEFT', 'BOTH');
CREATE TYPE walking_difficulty AS ENUM ('MILD', 'MODERATE', 'SEVERE');
CREATE TYPE walking_aid AS ENUM ('NONE', 'CANE', 'WALKER', 'OTHER');
CREATE TYPE therapy_config_status AS ENUM ('SCHEDULED', 'INPROGRESS', 'FINISHED', 'DISCONTINUED');
CREATE TYPE session_status AS ENUM ('IN_PROGRESS', 'COMPLETED', 'INTERRUPTED', 'STOPPED_BY_PATIENT', 'STOPPED_DUE_TO_PAIN', 'STOPPED_DUE_TO_DEVICE_FAULT');
CREATE TYPE target_joint AS ENUM ('KNEE', 'ANKLE', 'BOTH');
CREATE TYPE exercise_mode AS ENUM ('MOBILE_ONLY', 'DEVICE_ASSISTED');
CREATE TYPE exercise_difficulty AS ENUM ('BEGINNER', 'INTERMEDIATE', 'ADVANCED');
CREATE TYPE activity_type AS ENUM ('STANDING', 'WALKING', 'SEATED');
CREATE TYPE rehab_plan_status AS ENUM ('DRAFT', 'ACTIVE', 'PAUSED', 'COMPLETED', 'CANCELLED');
CREATE TYPE pain_context AS ENUM ('BEFORE_SESSION', 'DURING_SESSION', 'AFTER_SESSION', 'DAILY_LIFE');
CREATE TYPE alert_type AS ENUM ('HIGH_PAIN', 'SEVERE_PAIN', 'MISSED_SESSION', 'ROM_LIMIT_EXCEEDED', 'VELOCITY_EXCEEDED', 'MOTOR_OVERCURRENT', 'IMU_ERROR', 'CALIBRATION_FAILED', 'BLE_DISCONNECTED', 'LOW_BATTERY', 'EMERGENCY_STOP', 'NO_RECENT_SYNC');
CREATE TYPE alert_severity AS ENUM ('INFO', 'WARNING', 'URGENT', 'CRITICAL');
CREATE TYPE alert_status AS ENUM ('OPEN', 'REVIEWED', 'RESOLVED');
CREATE TYPE message_type AS ENUM ('TEXT', 'PAIN_REPORT', 'DEVICE_ISSUE', 'EXERCISE_ASSIGNMENT', 'APPOINTMENT', 'SYSTEM_ALERT');
CREATE TYPE calendar_event_type AS ENUM ('APPOINTMENT', 'EXERCISE', 'FOLLOW_UP', 'REPORT_REVIEW');
CREATE TYPE notification_channel AS ENUM ('IN_APP', 'EMAIL');
CREATE TYPE notification_status AS ENUM ('PENDING', 'SENT', 'FAILED');

-- Users
CREATE TABLE users (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email VARCHAR(255) UNIQUE NOT NULL,
    username VARCHAR(100) UNIQUE NOT NULL,
    password_hash VARCHAR(255) NOT NULL,
    name VARCHAR(255) NOT NULL,
    gender user_gender,
    birth_date DATE,
    education_level education_level,
    phone VARCHAR(50),
    emergency_contact_name VARCHAR(255),
    emergency_contact_phone VARCHAR(50),
    role user_role NOT NULL,
    enrollment_code VARCHAR(20) UNIQUE,
    doctor_id UUID REFERENCES users(id),
    doctor_status doctor_status,
    rejection_reason TEXT,
    clinic_name VARCHAR(255),
    specialization VARCHAR(255),
    professional_license VARCHAR(100),
    years_experience INTEGER,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Patient profiles
CREATE TABLE patient_profiles (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id),
    doctor_id UUID REFERENCES users(id),
    assessment_date DATE,
    weight_kg DECIMAL(5,2),
    height_cm DECIMAL(5,2),
    fim_score INTEGER CHECK (fim_score BETWEEN 1 AND 7),
    mmt_score INTEGER CHECK (mmt_score BETWEEN 0 AND 5),
    mmse_score INTEGER CHECK (mmse_score BETWEEN 0 AND 30),
    can_follow_instructions INTEGER CHECK (can_follow_instructions BETWEEN 0 AND 10),
    needs_supervision BOOLEAN DEFAULT FALSE,
    home_exercise_permission BOOLEAN DEFAULT FALSE,
    condition TEXT,
    affected_side affected_side,
    walking_difficulty walking_difficulty,
    walking_aid walking_aid,
    rehabilitation_history TEXT,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Devices (active_config_id FK added after therapy_configs)
CREATE TABLE devices (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID REFERENCES users(id),
    firmware_version VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Exercises
CREATE TABLE exercises (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    name VARCHAR(255) NOT NULL,
    category VARCHAR(100),
    activity_type activity_type,
    mode exercise_mode,
    difficulty exercise_difficulty,
    description TEXT,
    patient_instructions TEXT,
    doctor_instructions TEXT,
    default_sets INTEGER,
    default_reps INTEGER,
    default_rest_seconds INTEGER,
    default_min_rom_deg DECIMAL(5,2),
    default_max_rom_deg DECIMAL(5,2),
    default_max_angular_velocity_deg_s DECIMAL(5,2),
    default_pain_stop_threshold INTEGER,
    safety_notes TEXT,
    video_url VARCHAR(500),
    image_url VARCHAR(500),
    target_joint target_joint,
    is_active BOOLEAN NOT NULL DEFAULT TRUE,
    created_by_id UUID REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Therapy configs
CREATE TABLE therapy_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id),
    issued_by UUID NOT NULL REFERENCES users(id),
    rehab_plan_id UUID,
    max_speed DECIMAL(5,2),
    max_extension_angle_deg DECIMAL(5,2),
    max_flexion_angle_deg DECIMAL(5,2),
    sessions_per_week INTEGER,
    schedule VARCHAR(50),
    total_sessions_num INTEGER,
    status therapy_config_status NOT NULL DEFAULT 'SCHEDULED',
    comment TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    delivered_at TIMESTAMP WITH TIME ZONE
);

-- Therapy set configs
CREATE TABLE therapy_set_configs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    therapy_config_id UUID NOT NULL REFERENCES therapy_configs(id),
    exercise_id UUID NOT NULL REFERENCES exercises(id),
    device_assisted BOOLEAN NOT NULL DEFAULT FALSE,
    duration_min INTEGER,
    rest_duration_min INTEGER,
    set_order INTEGER NOT NULL DEFAULT 0
);

-- Rehab plans
CREATE TABLE rehab_plans (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id),
    doctor_id UUID NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    goal TEXT,
    start_date DATE,
    end_date DATE,
    status rehab_plan_status NOT NULL DEFAULT 'DRAFT',
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    updated_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

ALTER TABLE therapy_configs ADD CONSTRAINT fk_therapy_configs_rehab_plan
    FOREIGN KEY (rehab_plan_id) REFERENCES rehab_plans(id);

ALTER TABLE devices ADD COLUMN active_config_id UUID REFERENCES therapy_configs(id);

-- Sessions
CREATE TABLE sessions (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id),
    device_id UUID REFERENCES devices(id),
    config_id UUID REFERENCES therapy_configs(id),
    started_at TIMESTAMP WITH TIME ZONE,
    ended_at TIMESTAMP WITH TIME ZONE,
    status session_status NOT NULL DEFAULT 'IN_PROGRESS',
    pain_before INTEGER CHECK (pain_before BETWEEN 0 AND 10),
    pain_during INTEGER CHECK (pain_during BETWEEN 0 AND 10),
    pain_after INTEGER CHECK (pain_after BETWEEN 0 AND 10),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Therapy set records
CREATE TABLE therapy_set_records (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL REFERENCES sessions(id),
    therapy_set_config_id UUID REFERENCES therapy_set_configs(id),
    exercise_id UUID NOT NULL REFERENCES exercises(id),
    device_assisted BOOLEAN NOT NULL DEFAULT FALSE,
    planned_duration_min INTEGER,
    planned_rest_duration_min INTEGER,
    start_datetime TIMESTAMP WITH TIME ZONE,
    stop_datetime TIMESTAMP WITH TIME ZONE,
    pain_level INTEGER CHECK (pain_level BETWEEN 0 AND 10),
    patient_feedback TEXT
);

-- Sensor readings
CREATE TABLE sensor_readings (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    therapy_set_record_id UUID NOT NULL REFERENCES therapy_set_records(id),
    timestamp_us BIGINT,
    sample_id INTEGER,
    foot_ax_g DECIMAL(8,4),
    foot_ay_g DECIMAL(8,4),
    foot_az_g DECIMAL(8,4),
    foot_gx_rad_s DECIMAL(8,4),
    foot_gy_rad_s DECIMAL(8,4),
    foot_gz_rad_s DECIMAL(8,4),
    shank_ax_g DECIMAL(8,4),
    shank_ay_g DECIMAL(8,4),
    shank_az_g DECIMAL(8,4),
    shank_gx_rad_s DECIMAL(8,4),
    shank_gy_rad_s DECIMAL(8,4),
    shank_gz_rad_s DECIMAL(8,4),
    thigh_ax_g DECIMAL(8,4),
    thigh_ay_g DECIMAL(8,4),
    thigh_az_g DECIMAL(8,4),
    thigh_gx_rad_s DECIMAL(8,4),
    thigh_gy_rad_s DECIMAL(8,4),
    thigh_gz_rad_s DECIMAL(8,4),
    heel_fsr_raw INTEGER,
    midfoot_fsr_raw INTEGER,
    heel_contact SMALLINT DEFAULT -1,
    midfoot_contact SMALLINT DEFAULT -1,
    gait_phase_id INTEGER DEFAULT -1,
    gait_phase_label VARCHAR(50),
    knee_angle_est_deg DECIMAL(6,2)
);

-- Session insights
CREATE TABLE session_insights (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    session_id UUID NOT NULL UNIQUE REFERENCES sessions(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Pain logs
CREATE TABLE pain_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id),
    session_id UUID REFERENCES sessions(id),
    pain_level INTEGER NOT NULL CHECK (pain_level BETWEEN 0 AND 10),
    context pain_context NOT NULL,
    notes TEXT,
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Alerts
CREATE TABLE alerts (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id),
    session_id UUID REFERENCES sessions(id),
    device_id UUID REFERENCES devices(id),
    type alert_type NOT NULL,
    severity alert_severity NOT NULL,
    message TEXT,
    status alert_status NOT NULL DEFAULT 'OPEN',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    reviewed_at TIMESTAMP WITH TIME ZONE,
    resolved_at TIMESTAMP WITH TIME ZONE,
    resolved_by UUID REFERENCES users(id)
);

-- Messages
CREATE TABLE messages (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    sender_id UUID NOT NULL REFERENCES users(id),
    receiver_id UUID NOT NULL REFERENCES users(id),
    message_type message_type NOT NULL DEFAULT 'TEXT',
    body TEXT NOT NULL,
    attachment_url VARCHAR(500),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    read_at TIMESTAMP WITH TIME ZONE
);

-- Calendar events
CREATE TABLE calendar_events (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    patient_id UUID NOT NULL REFERENCES users(id),
    doctor_id UUID NOT NULL REFERENCES users(id),
    title VARCHAR(255) NOT NULL,
    event_type calendar_event_type NOT NULL,
    start_time TIMESTAMP WITH TIME ZONE NOT NULL,
    end_time TIMESTAMP WITH TIME ZONE NOT NULL,
    location VARCHAR(500),
    online_link VARCHAR(500),
    notes TEXT,
    reminder_time TIMESTAMP WITH TIME ZONE,
    created_by UUID NOT NULL REFERENCES users(id),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Notifications
CREATE TABLE notifications (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID NOT NULL REFERENCES users(id),
    type VARCHAR(100) NOT NULL,
    title VARCHAR(255) NOT NULL,
    body TEXT,
    channel notification_channel NOT NULL DEFAULT 'IN_APP',
    status notification_status NOT NULL DEFAULT 'PENDING',
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW(),
    sent_at TIMESTAMP WITH TIME ZONE,
    read_at TIMESTAMP WITH TIME ZONE
);

-- Audit logs (never deleted)
CREATE TABLE audit_logs (
    id UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    user_id UUID REFERENCES users(id),
    role VARCHAR(50),
    action VARCHAR(500) NOT NULL,
    entity_type VARCHAR(100),
    entity_id UUID,
    patient_id UUID REFERENCES users(id),
    old_value JSONB,
    new_value JSONB,
    reason TEXT,
    ip_address VARCHAR(50),
    created_at TIMESTAMP WITH TIME ZONE DEFAULT NOW()
);

-- Performance indexes
CREATE INDEX idx_users_email ON users(email);
CREATE INDEX idx_users_enrollment_code ON users(enrollment_code) WHERE enrollment_code IS NOT NULL;
CREATE INDEX idx_users_doctor_id ON users(doctor_id) WHERE doctor_id IS NOT NULL;
CREATE INDEX idx_sessions_patient_id ON sessions(patient_id);
CREATE INDEX idx_sessions_config_id ON sessions(config_id);
CREATE INDEX idx_therapy_set_records_session_id ON therapy_set_records(session_id);
CREATE INDEX idx_sensor_readings_record_id ON sensor_readings(therapy_set_record_id);
CREATE INDEX idx_messages_sender_receiver ON messages(sender_id, receiver_id);
CREATE INDEX idx_alerts_patient_id ON alerts(patient_id);
CREATE INDEX idx_notifications_user_id ON notifications(user_id);
CREATE INDEX idx_audit_logs_user_id ON audit_logs(user_id);

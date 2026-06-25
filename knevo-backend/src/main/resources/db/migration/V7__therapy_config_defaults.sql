-- Backfill missing therapy-config safety limits with the backend defaults
-- (speed 5, max extension 5, max flexion 60). Only MISSING values are filled —
-- NULL or 0 (the sentinel left behind when a doctor omitted the field). Present
-- out-of-range values are intentionally left untouched (out of scope for this
-- backfill; the doctor will be forced to correct them on the next edit because
-- the form now validates the ranges).

UPDATE therapy_configs SET max_speed = 5
    WHERE max_speed IS NULL OR max_speed = 0;

UPDATE therapy_configs SET max_extension_angle_deg = 5
    WHERE max_extension_angle_deg IS NULL OR max_extension_angle_deg = 0;

UPDATE therapy_configs SET max_flexion_angle_deg = 60
    WHERE max_flexion_angle_deg IS NULL OR max_flexion_angle_deg = 0;

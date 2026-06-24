-- Convert PostgreSQL enum columns to varchar for JPA String mapping compatibility
ALTER TABLE exercises ALTER COLUMN activity_type TYPE VARCHAR(20);
ALTER TABLE exercises ALTER COLUMN mode TYPE VARCHAR(20);
ALTER TABLE exercises ALTER COLUMN difficulty TYPE VARCHAR(20);
ALTER TABLE exercises ALTER COLUMN target_joint TYPE VARCHAR(20);
ALTER TABLE therapy_configs ALTER COLUMN status TYPE VARCHAR(20);
ALTER TABLE rehab_plans ALTER COLUMN status TYPE VARCHAR(20);

INSERT INTO exercises (id, name, category, activity_type, mode, difficulty, description, patient_instructions, doctor_instructions, default_sets, default_reps, default_rest_seconds, default_min_rom_deg, default_max_rom_deg, default_max_angular_velocity_deg_s, default_pain_stop_threshold, safety_notes, target_joint, is_active, created_at, updated_at) VALUES

(gen_random_uuid(), 'Standing Weight Shift', 'Standing exercises', 'STANDING', 'MOBILE_ONLY', 'BEGINNER',
 'Shift body weight side to side while standing, improving balance and proprioception.',
 'Stand with feet shoulder-width apart. Slowly shift your weight to the right foot, hold 3 seconds, then shift to the left.',
 'Monitor balance and ensure patient does not compensate with trunk lateral flexion.',
 3, 10, 60, NULL, NULL, NULL, 6,
 'Ensure patient has stable support nearby. Stop if knee gives way.',
 'KNEE', true, NOW(), NOW()),

(gen_random_uuid(), 'Assisted Knee Extension', 'Knee control exercises', 'SEATED', 'DEVICE_ASSISTED', 'BEGINNER',
 'Motor-assisted extension of the knee from 90 degrees to full extension.',
 'Sit upright in the chair. Relax your leg and let the brace guide it to full extension. Hold at the top for 2 seconds.',
 'Set ROM limit to patient-prescribed max extension. Monitor for pain or compensation.',
 3, 12, 90, 0, 90, 30, 5,
 'Do not exceed prescribed ROM. Stop if patient reports pain ≥5.',
 'KNEE', true, NOW(), NOW()),

(gen_random_uuid(), 'Assisted Knee Flexion', 'Knee control exercises', 'SEATED', 'DEVICE_ASSISTED', 'BEGINNER',
 'Motor-assisted flexion of the knee from full extension to prescribed angle.',
 'Sit upright. Relax your leg and allow the brace to bend your knee gently.',
 'Monitor flexion ROM carefully. Some patients may resist — reduce speed if needed.',
 3, 12, 90, 0, 80, 25, 5,
 'Avoid forcing flexion beyond comfort. Stop on any sharp pain report.',
 'KNEE', true, NOW(), NOW()),

(gen_random_uuid(), 'Gait Training — Supervised Walk', 'Walking / gait exercises', 'WALKING', 'MOBILE_ONLY', 'INTERMEDIATE',
 'Supervised walking along a measured course to improve gait pattern and endurance.',
 'Walk slowly along the marked path. Try to step heel-first and roll through to your toes.',
 'Observe step symmetry, trunk stability, and cadence. Note any foot drop or circumduction.',
 2, 1, 120, NULL, NULL, NULL, 5,
 'Patient must have supervision. Use walking aid as prescribed.',
 'KNEE', true, NOW(), NOW()),

(gen_random_uuid(), 'Heel-to-Toe Walk', 'Walking / gait exercises', 'WALKING', 'MOBILE_ONLY', 'INTERMEDIATE',
 'Walk placing heel of front foot directly in front of toe of back foot, improving balance.',
 'Look straight ahead. Place your right heel directly in front of your left toes, then repeat with left heel.',
 'Assess proprioception and balance. Suitable once patient achieves stable unassisted standing.',
 3, 10, 60, NULL, NULL, NULL, 5,
 'Ensure mat or clear path. Patient may need lateral support.',
 'KNEE', true, NOW(), NOW()),

(gen_random_uuid(), 'Single-Leg Balance', 'Balance exercises', 'STANDING', 'MOBILE_ONLY', 'INTERMEDIATE',
 'Stand on one leg to improve balance, proprioception, and knee stability.',
 'Hold onto a chair lightly. Lift your non-affected leg slightly. Hold for 10 seconds. Rest and repeat.',
 'Start with affected leg only if patient is stable. Progress to unassisted as tolerated.',
 3, 5, 60, NULL, NULL, NULL, 5,
 'Ensure support is within reach. Stop if patient cannot maintain safe posture.',
 'KNEE', true, NOW(), NOW()),

(gen_random_uuid(), 'Seated Knee Strengthening', 'Strength exercises', 'SEATED', 'MOBILE_ONLY', 'BEGINNER',
 'Seated leg extension against gravity to strengthen quadriceps.',
 'Sit in a chair, back straight. Slowly lift your right leg to extend your knee. Hold 3 seconds, lower slowly.',
 'Progress resistance with ankle weights once patient achieves 3 sets of 12 with ease.',
 3, 12, 90, NULL, NULL, NULL, 6,
 'Avoid jerky movements. Patient should not hold breath.',
 'KNEE', true, NOW(), NOW()),

(gen_random_uuid(), 'Active-Assisted ROM', 'Range of motion exercises', 'SEATED', 'MOBILE_ONLY', 'BEGINNER',
 'Patient assists own knee flexion/extension using a towel loop for range of motion recovery.',
 'Sit at edge of chair. Loop towel under your foot. Gently pull to increase knee flexion. Hold 5 seconds.',
 'Record max flexion angle at each session. Goal is progressive gain without pain.',
 3, 8, 60, 0, 120, NULL, 5,
 'Do not force beyond comfort. Mild discomfort is acceptable, pain is not.',
 'KNEE', true, NOW(), NOW()),

(gen_random_uuid(), 'Step-Up Exercise', 'Functional exercises', 'STANDING', 'MOBILE_ONLY', 'INTERMEDIATE',
 'Step up and down on a low step to improve functional leg strength and coordination.',
 'Face the step. Step up with your right foot, bring left foot up, then step down right then left. Repeat.',
 'Use 10 cm step initially. Progress height as strength improves.',
 3, 8, 90, NULL, NULL, NULL, 5,
 'Ensure step is non-slip and stable. Supervise first session.',
 'KNEE', true, NOW(), NOW()),

(gen_random_uuid(), 'Standing Warm-Up March', 'Warm-up exercises', 'STANDING', 'MOBILE_ONLY', 'BEGINNER',
 'Light marching in place to warm up lower limb muscles before therapy.',
 'Stand holding chair. Lift each knee to hip height alternately, like marching. Keep a gentle rhythm.',
 'Perform before device-assisted sets. Observe hip flexor and knee engagement.',
 1, 20, 30, NULL, NULL, NULL, 4,
 'Low intensity only. Patient must be fully alert and oriented.',
 'KNEE', true, NOW(), NOW()),

(gen_random_uuid(), 'Cool-Down Seated Stretch', 'Cool-down exercises', 'SEATED', 'MOBILE_ONLY', 'BEGINNER',
 'Gentle seated hamstring stretch to reduce post-exercise tightness.',
 'Sit at edge of chair, extend right leg, flex foot, lean forward gently. Hold 20 seconds each side.',
 'Perform after active exercises. Ensure patient does not round back excessively.',
 2, 3, 30, NULL, NULL, NULL, 3,
 'No bouncing. Mild pull is acceptable.',
 'KNEE', true, NOW(), NOW()),

(gen_random_uuid(), 'Ankle Circles', 'Range of motion exercises', 'SEATED', 'MOBILE_ONLY', 'BEGINNER',
 'Circular ankle movements to improve ankle mobility and distal circulation.',
 'Sit comfortably. Lift one foot slightly. Slowly rotate your ankle in a large circle 10 times each direction.',
 'Useful warm-up for patients with lower limb stiffness. Note any crepitus or pain.',
 2, 10, 30, NULL, NULL, NULL, 3,
 'Gentle range only. Avoid forced rotation.',
 'ANKLE', true, NOW(), NOW()),

(gen_random_uuid(), 'Assessment Walk', 'Assessment exercises', 'WALKING', 'MOBILE_ONLY', 'BEGINNER',
 '10-meter walk at self-selected speed to assess baseline gait and endurance.',
 'Walk from the start marker to the end marker at your comfortable pace. Do not rush.',
 'Time the walk. Record step count, gait deviations, and any assistive device used. Baseline only.',
 1, 1, 180, NULL, NULL, NULL, 4,
 'Ensure clear 15-meter path including acceleration/deceleration zones.',
 'KNEE', true, NOW(), NOW()),

(gen_random_uuid(), 'Assisted Gait with Brace', 'Walking / gait exercises', 'WALKING', 'DEVICE_ASSISTED', 'ADVANCED',
 'Walking with motor-assisted knee support to reduce fatigue and enable greater distance.',
 'Walk normally. The brace will assist your knee during the swing phase. Focus on heel strike.',
 'Set assistance level per prescription. Monitor for over-reliance on motor assistance.',
 2, 1, 180, 0, 60, 45, 5,
 'Ensure brace is properly fitted before starting. Check battery level. Supervision required.',
 'KNEE', true, NOW(), NOW()),

(gen_random_uuid(), 'Knee Bend — Partial Squat', 'Knee control exercises', 'STANDING', 'MOBILE_ONLY', 'INTERMEDIATE',
 'Partial squat to 45 degrees to strengthen quadriceps and knee stabilisers.',
 'Stand with feet shoulder-width apart, hands on chair back. Slowly bend knees to about 45 degrees. Hold 2 seconds.',
 'Do not allow knees to go past toes. Watch for valgus collapse. Stop at pain.',
 3, 10, 90, NULL, 45, NULL, 5,
 'Avoid full depth squat. Use chair back for balance support.',
 'KNEE', true, NOW(), NOW());

package com.knevo.controller;

import com.fasterxml.jackson.databind.ObjectMapper;
import com.knevo.model.Session;
import com.knevo.model.TherapyConfig;
import com.knevo.model.TherapySetConfig;
import com.knevo.model.TherapySetRecord;
import com.knevo.model.User;
import com.knevo.repository.ExerciseRepository;
import com.knevo.repository.SessionRepository;
import com.knevo.repository.TherapyConfigRepository;
import com.knevo.repository.TherapySetConfigRepository;
import com.knevo.repository.TherapySetRecordRepository;
import com.knevo.repository.UserRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.boot.test.autoconfigure.web.servlet.AutoConfigureMockMvc;
import org.springframework.boot.test.context.SpringBootTest;
import org.springframework.http.MediaType;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.transaction.annotation.Transactional;

import jakarta.persistence.EntityManager;
import jakarta.persistence.PersistenceContext;

import java.time.OffsetDateTime;
import java.util.ArrayList;
import java.util.List;
import java.util.Map;
import java.util.UUID;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.springframework.security.test.web.servlet.request.SecurityMockMvcRequestPostProcessors.user;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

@SpringBootTest
@AutoConfigureMockMvc
@Transactional
class SensorReadingIntegrationTest {

    @Autowired MockMvc mockMvc;
    @Autowired ObjectMapper objectMapper;
    @Autowired UserRepository userRepository;
    @Autowired TherapyConfigRepository therapyConfigRepository;
    @Autowired ExerciseRepository exerciseRepository;
    @Autowired TherapySetConfigRepository setConfigRepository;
    @Autowired SessionRepository sessionRepository;
    @Autowired TherapySetRecordRepository setRecordRepository;
    @Autowired JdbcTemplate jdbcTemplate;
    @PersistenceContext EntityManager entityManager;

    private User doctor;
    private User patient;
    private Session session;
    private TherapySetRecord setRecord;

    @BeforeEach
    void setup() {
        doctor = new User();
        doctor.setEmail("sensordoctor@test.com");
        doctor.setUsername("sensordoctor");
        doctor.setPasswordHash("hash");
        doctor.setName("Sensor Doctor");
        doctor.setRole(User.Role.DOCTOR);
        doctor.setDoctorStatus(User.DoctorStatus.APPROVED);
        doctor = userRepository.save(doctor);

        patient = new User();
        patient.setEmail("sensorpatient@test.com");
        patient.setUsername("sensorpatient");
        patient.setPasswordHash("hash");
        patient.setName("Sensor Patient");
        patient.setRole(User.Role.PATIENT);
        patient.setDoctor(doctor);
        patient = userRepository.save(patient);

        TherapyConfig config = new TherapyConfig();
        config.setPatient(patient);
        config.setIssuedBy(doctor);
        config.setStatus("INPROGRESS");
        config = therapyConfigRepository.save(config);

        var exercise = exerciseRepository.findByActiveTrue().get(0);
        TherapySetConfig setConfig = new TherapySetConfig();
        setConfig.setTherapyConfig(config);
        setConfig.setExercise(exercise);
        setConfig.setSetOrder(0);
        setConfig = setConfigRepository.save(setConfig);

        session = new Session();
        session.setPatient(patient);
        session.setTherapyConfig(config);
        session.setStatus("IN_PROGRESS");
        session.setStartedAt(OffsetDateTime.now());
        session = sessionRepository.save(session);

        setRecord = new TherapySetRecord();
        setRecord.setSession(session);
        setRecord.setTherapySetConfig(setConfig);
        setRecord.setExercise(exercise);
        setRecord.setStartDatetime(OffsetDateTime.now());
        setRecord.setStatus("COMPLETED");
        setRecord = setRecordRepository.save(setRecord);

        // Flush JPA inserts so the raw JDBC batch in the ingest path sees the
        // seeded rows within this shared test transaction (FK target must exist).
        entityManager.flush();
    }

    private Map<String, Object> sampleReading(int sampleId, int heelFsr, int midfootFsr) {
        Map<String, Object> m = new java.util.HashMap<>();
        m.put("timestampUs", 1719300000000000L + sampleId);
        m.put("sampleId", sampleId);
        m.put("footAxG", 0.0123);
        m.put("footAyG", -0.98);
        m.put("footAzG", 0.10);
        m.put("footGxRadS", 0.01);
        m.put("footGyRadS", 0.00);
        m.put("footGzRadS", -0.02);
        m.put("shankAxG", 0.0);
        m.put("shankAyG", 0.0);
        m.put("shankAzG", 0.0);
        m.put("shankGxRadS", 0.0);
        m.put("shankGyRadS", 0.0);
        m.put("shankGzRadS", 0.0);
        m.put("thighAxG", 0.0);
        m.put("thighAyG", 0.0);
        m.put("thighAzG", 0.0);
        m.put("thighGxRadS", 0.0);
        m.put("thighGyRadS", 0.0);
        m.put("thighGzRadS", 0.0);
        m.put("heelFsrRaw", heelFsr);
        m.put("midfootFsrRaw", midfootFsr);
        return m;
    }

    private long countRows(UUID setRecordId) {
        Long c = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM sensor_readings WHERE therapy_set_record_id = ?",
            Long.class, setRecordId);
        return c == null ? 0 : c;
    }

    @Test
    void happyPathInsertsAllRows() throws Exception {
        int n = 50;
        List<Map<String, Object>> readings = new ArrayList<>();
        for (int i = 0; i < n; i++) {
            readings.add(sampleReading(i, 1024, 256));
        }

        long before = countRows(setRecord.getId());

        mockMvc.perform(post("/api/sessions/" + session.getId()
                + "/sets/" + setRecord.getId() + "/sensor-readings")
                .with(user(patient.getId().toString()).roles("PATIENT"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(readings)))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.inserted").value(n));

        assertEquals(before + n, countRows(setRecord.getId()));
    }

    @Test
    void otherPatientIsForbidden() throws Exception {
        User otherPatient = new User();
        otherPatient.setEmail("sensorother@test.com");
        otherPatient.setUsername("sensorother");
        otherPatient.setPasswordHash("hash");
        otherPatient.setName("Other Patient");
        otherPatient.setRole(User.Role.PATIENT);
        otherPatient = userRepository.save(otherPatient);

        List<Map<String, Object>> readings = List.of(sampleReading(0, 1024, 256));

        mockMvc.perform(post("/api/sessions/" + session.getId()
                + "/sets/" + setRecord.getId() + "/sensor-readings")
                .with(user(otherPatient.getId().toString()).roles("PATIENT"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(readings)))
            .andExpect(status().isForbidden());
    }

    @Test
    void setRecordNotInSessionIsNotFound() throws Exception {
        List<Map<String, Object>> readings = List.of(sampleReading(0, 1024, 256));

        mockMvc.perform(post("/api/sessions/" + UUID.randomUUID()
                + "/sets/" + setRecord.getId() + "/sensor-readings")
                .with(user(patient.getId().toString()).roles("PATIENT"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(readings)))
            .andExpect(status().isNotFound());
    }

    @Test
    void fsrOutOfRangeIsBadRequest() throws Exception {
        List<Map<String, Object>> readings = List.of(sampleReading(0, 5000, 256));

        mockMvc.perform(post("/api/sessions/" + session.getId()
                + "/sets/" + setRecord.getId() + "/sensor-readings")
                .with(user(patient.getId().toString()).roles("PATIENT"))
                .contentType(MediaType.APPLICATION_JSON)
                .content(objectMapper.writeValueAsString(readings)))
            .andExpect(status().isBadRequest());

        assertEquals(0, countRows(setRecord.getId()));
    }

    /** Inserts {@code n} readings directly via JDBC for the GET (graph) tests. */
    private void seedReadings(UUID setRecordId, int n) {
        for (int i = 0; i < n; i++) {
            jdbcTemplate.update(
                "INSERT INTO sensor_readings (therapy_set_record_id, timestamp_us, sample_id, "
                    + "heel_fsr_raw, midfoot_fsr_raw) VALUES (?, ?, ?, ?, ?)",
                setRecordId, 1719300000000000L + i, i, 1000 + i, 200 + i);
        }
    }

    @Test
    void owningDoctorGetsReadings() throws Exception {
        seedReadings(setRecord.getId(), 30);
        entityManager.flush();

        mockMvc.perform(get("/api/sessions/" + session.getId() + "/sensor-readings")
                .with(user(doctor.getId().toString()).roles("DOCTOR")))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.length()").value(30))
            .andExpect(jsonPath("$[0].sampleId").value(0))
            .andExpect(jsonPath("$[0].heelFsrRaw").value(1000))
            // knee angle is null in Phase 2
            .andExpect(jsonPath("$[0].kneeAngleEstDeg").doesNotExist());
    }

    @Test
    void nonOwningDoctorIsForbidden() throws Exception {
        seedReadings(setRecord.getId(), 5);
        entityManager.flush();

        User otherDoctor = new User();
        otherDoctor.setEmail("sensorotherdoc@test.com");
        otherDoctor.setUsername("sensorotherdoc");
        otherDoctor.setPasswordHash("hash");
        otherDoctor.setName("Other Doctor");
        otherDoctor.setRole(User.Role.DOCTOR);
        otherDoctor.setDoctorStatus(User.DoctorStatus.APPROVED);
        otherDoctor = userRepository.save(otherDoctor);
        entityManager.flush();

        mockMvc.perform(get("/api/sessions/" + session.getId() + "/sensor-readings")
                .with(user(otherDoctor.getId().toString()).roles("DOCTOR")))
            .andExpect(status().isForbidden());
    }

    @Test
    void downsamplingReducesCount() throws Exception {
        seedReadings(setRecord.getId(), 100);
        entityManager.flush();

        // maxPoints=10 over 100 rows → stride 10 → 10 returned points.
        var result = mockMvc.perform(get("/api/sessions/" + session.getId()
                + "/sensor-readings")
                .param("maxPoints", "10")
                .with(user(doctor.getId().toString()).roles("DOCTOR")))
            .andExpect(status().isOk())
            .andReturn();

        var nodes = objectMapper.readTree(result.getResponse().getContentAsString());
        assertEquals(10, nodes.size());
        // strictly fewer than the full series proves downsampling happened
        assertTrue(nodes.size() < 100);
    }
}

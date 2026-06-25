package com.knevo.repository;

import com.knevo.dto.sensor.SensorReadingDto;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.stereotype.Repository;

import java.math.BigDecimal;
import java.sql.Types;
import java.util.List;
import java.util.UUID;

/**
 * Bulk insert of raw sensor readings via a single JDBC batch. A ~20-min set is
 * ~120k rows, so we avoid the per-row overhead of JPA {@code saveAll}.
 *
 * <p>Computed gait columns (heel_contact, midfoot_contact, gait_phase_id,
 * gait_phase_label, knee_angle_est_deg) are intentionally omitted so the table
 * DB defaults (-1 / null) apply (decisions §5.1, Phase 2).
 */
@Repository
@RequiredArgsConstructor
public class SensorReadingRepository {

    private static final String INSERT_SQL =
        "INSERT INTO sensor_readings (" +
            "therapy_set_record_id, timestamp_us, sample_id, " +
            "foot_ax_g, foot_ay_g, foot_az_g, foot_gx_rad_s, foot_gy_rad_s, foot_gz_rad_s, " +
            "shank_ax_g, shank_ay_g, shank_az_g, shank_gx_rad_s, shank_gy_rad_s, shank_gz_rad_s, " +
            "thigh_ax_g, thigh_ay_g, thigh_az_g, thigh_gx_rad_s, thigh_gy_rad_s, thigh_gz_rad_s, " +
            "heel_fsr_raw, midfoot_fsr_raw" +
            ") VALUES (?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?, ?)";

    private final JdbcTemplate jdbcTemplate;

    public int batchInsert(UUID therapySetRecordId, List<SensorReadingDto> readings) {
        // batchUpdate executes the inserts; we count the input rows rather than
        // summing the returned update counts, because some JDBC drivers report
        // Statement.SUCCESS_NO_INFO (-2) per row in a batch.
        jdbcTemplate.batchUpdate(INSERT_SQL, readings, readings.size(),
            (ps, r) -> {
                ps.setObject(1, therapySetRecordId);
                setNullable(ps, 2, r.getTimestampUs(), Types.BIGINT);
                setNullable(ps, 3, r.getSampleId(), Types.INTEGER);
                setDecimal(ps, 4, r.getFootAxG());
                setDecimal(ps, 5, r.getFootAyG());
                setDecimal(ps, 6, r.getFootAzG());
                setDecimal(ps, 7, r.getFootGxRadS());
                setDecimal(ps, 8, r.getFootGyRadS());
                setDecimal(ps, 9, r.getFootGzRadS());
                setDecimal(ps, 10, r.getShankAxG());
                setDecimal(ps, 11, r.getShankAyG());
                setDecimal(ps, 12, r.getShankAzG());
                setDecimal(ps, 13, r.getShankGxRadS());
                setDecimal(ps, 14, r.getShankGyRadS());
                setDecimal(ps, 15, r.getShankGzRadS());
                setDecimal(ps, 16, r.getThighAxG());
                setDecimal(ps, 17, r.getThighAyG());
                setDecimal(ps, 18, r.getThighAzG());
                setDecimal(ps, 19, r.getThighGxRadS());
                setDecimal(ps, 20, r.getThighGyRadS());
                setDecimal(ps, 21, r.getThighGzRadS());
                setNullable(ps, 22, r.getHeelFsrRaw(), Types.INTEGER);
                setNullable(ps, 23, r.getMidfootFsrRaw(), Types.INTEGER);
            });

        return readings.size();
    }

    private static void setDecimal(java.sql.PreparedStatement ps, int idx, BigDecimal value)
        throws java.sql.SQLException {
        if (value == null) {
            ps.setNull(idx, Types.DECIMAL);
        } else {
            ps.setBigDecimal(idx, value);
        }
    }

    private static void setNullable(java.sql.PreparedStatement ps, int idx, Object value, int sqlType)
        throws java.sql.SQLException {
        if (value == null) {
            ps.setNull(idx, sqlType);
        } else {
            ps.setObject(idx, value);
        }
    }
}

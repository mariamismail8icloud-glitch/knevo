package com.knevo.repository;

import com.knevo.dto.sensor.SensorReadingDto;
import com.knevo.dto.sensor.SensorReadingResponse;
import lombok.RequiredArgsConstructor;
import org.springframework.jdbc.core.JdbcTemplate;
import org.springframework.jdbc.core.RowMapper;
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

    private static final String SELECT_COLUMNS =
        "sample_id, timestamp_us, heel_fsr_raw, midfoot_fsr_raw, knee_angle_est_deg, " +
        "foot_ax_g, foot_ay_g, foot_az_g, shank_ax_g, shank_ay_g, shank_az_g, " +
        "thigh_ax_g, thigh_ay_g, thigh_az_g";

    private static final RowMapper<SensorReadingResponse> RESPONSE_MAPPER = (rs, rowNum) -> {
        SensorReadingResponse r = new SensorReadingResponse();
        r.setSampleId((Integer) rs.getObject("sample_id"));
        r.setTimestampUs((Long) rs.getObject("timestamp_us"));
        r.setHeelFsrRaw((Integer) rs.getObject("heel_fsr_raw"));
        r.setMidfootFsrRaw((Integer) rs.getObject("midfoot_fsr_raw"));
        r.setKneeAngleEstDeg(rs.getBigDecimal("knee_angle_est_deg"));
        r.setFootAxG(rs.getBigDecimal("foot_ax_g"));
        r.setFootAyG(rs.getBigDecimal("foot_ay_g"));
        r.setFootAzG(rs.getBigDecimal("foot_az_g"));
        r.setShankAxG(rs.getBigDecimal("shank_ax_g"));
        r.setShankAyG(rs.getBigDecimal("shank_ay_g"));
        r.setShankAzG(rs.getBigDecimal("shank_az_g"));
        r.setThighAxG(rs.getBigDecimal("thigh_ax_g"));
        r.setThighAyG(rs.getBigDecimal("thigh_ay_g"));
        r.setThighAzG(rs.getBigDecimal("thigh_az_g"));
        return r;
    };

    /** Count rows for the given set record, used to compute a downsample stride. */
    public long countForSet(UUID therapySetRecordId) {
        Long c = jdbcTemplate.queryForObject(
            "SELECT COUNT(*) FROM sensor_readings WHERE therapy_set_record_id = ?",
            Long.class, therapySetRecordId);
        return c == null ? 0 : c;
    }

    /**
     * Returns readings for a set ordered by sample_id, keeping every {@code stride}-th
     * row (stride 1 = all rows). Downsampling is applied with a window function over
     * the natural sample order so the series is evenly thinned regardless of gaps in
     * sample_id. Decisions §5.2.
     */
    public List<SensorReadingResponse> findForGraph(UUID therapySetRecordId, int stride) {
        int safeStride = Math.max(1, stride);
        if (safeStride == 1) {
            return jdbcTemplate.query(
                "SELECT " + SELECT_COLUMNS + " FROM sensor_readings " +
                    "WHERE therapy_set_record_id = ? ORDER BY sample_id",
                RESPONSE_MAPPER, therapySetRecordId);
        }
        // ROW_NUMBER lets us keep every Nth ordered row deterministically.
        String sql =
            "SELECT " + SELECT_COLUMNS + " FROM (" +
                "  SELECT " + SELECT_COLUMNS + ", " +
                "    ROW_NUMBER() OVER (ORDER BY sample_id) - 1 AS rn " +
                "  FROM sensor_readings WHERE therapy_set_record_id = ?" +
                ") t WHERE rn % ? = 0 ORDER BY sample_id";
        return jdbcTemplate.query(sql, RESPONSE_MAPPER, therapySetRecordId, safeStride);
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

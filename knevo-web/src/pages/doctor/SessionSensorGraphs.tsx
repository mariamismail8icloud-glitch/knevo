import { useQuery } from '@tanstack/react-query';
import {
  LineChart,
  Line,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  CartesianGrid,
  Legend,
} from 'recharts';
import { getSessionSensorReadings } from '../../api/doctorApi';

interface Props {
  sessionId: string;
}

/**
 * Doctor-facing sensor graphs for a completed device-assisted session (M12).
 * Renders FSR load over time, plus a knee-angle scaffold that stays empty
 * until Phase 3 analytics fill kneeAngleEstDeg.
 */
export default function SessionSensorGraphs({ sessionId }: Props) {
  const { data, isLoading, isError } = useQuery({
    queryKey: ['session-sensor-readings', sessionId],
    queryFn: () => getSessionSensorReadings(sessionId, { maxPoints: 2000 }),
    enabled: !!sessionId,
  });

  if (isLoading) {
    return <p className="text-[#64748b] text-sm">Loading sensor data…</p>;
  }

  // No readings → not a device-assisted session with data; keep it tasteful.
  if (isError || !data || data.length === 0) {
    return (
      <p className="text-[#64748b] text-sm">
        No sensor data for this session.
      </p>
    );
  }

  const chartData = data.map((r, idx) => ({
    x: r.sampleId ?? idx,
    heel: r.heelFsrRaw,
    midfoot: r.midfootFsrRaw,
    knee: r.kneeAngleEstDeg,
  }));

  const hasKneeAngle = data.some(r => r.kneeAngleEstDeg != null);

  return (
    <div className="space-y-4" data-testid="sensor-graphs">
      {/* FSR load over time */}
      <div className="bg-white rounded-2xl border border-[#f0d6e8] p-6 shadow-knevo">
        <h4 className="font-semibold text-[#0f172a] mb-4">FSR load over time</h4>
        <ResponsiveContainer width="100%" height={220}>
          <LineChart
            data={chartData}
            margin={{ top: 5, right: 10, left: -20, bottom: 5 }}
          >
            <CartesianGrid strokeDasharray="3 3" stroke="#f0d6e8" />
            <XAxis
              dataKey="x"
              tick={{ fontSize: 11 }}
              label={{ value: 'sample', position: 'insideBottom', offset: -2, fontSize: 11 }}
            />
            <YAxis domain={[0, 4095]} tick={{ fontSize: 11 }} />
            <Tooltip />
            <Legend wrapperStyle={{ fontSize: 12 }} />
            <Line
              type="monotone"
              dataKey="heel"
              name="Heel"
              stroke="#E8007D"
              strokeWidth={2}
              dot={false}
            />
            <Line
              type="monotone"
              dataKey="midfoot"
              name="Midfoot"
              stroke="#8B1A6B"
              strokeWidth={2}
              dot={false}
            />
          </LineChart>
        </ResponsiveContainer>
      </div>

      {/* Knee angle over time — scaffold until Phase 3 */}
      <div className="bg-white rounded-2xl border border-[#f0d6e8] p-6 shadow-knevo">
        <h4 className="font-semibold text-[#0f172a] mb-4">Knee angle over time</h4>
        {hasKneeAngle ? (
          <ResponsiveContainer width="100%" height={220}>
            <LineChart
              data={chartData}
              margin={{ top: 5, right: 10, left: -20, bottom: 5 }}
            >
              <CartesianGrid strokeDasharray="3 3" stroke="#f0d6e8" />
              <XAxis dataKey="x" tick={{ fontSize: 11 }} />
              <YAxis tick={{ fontSize: 11 }} />
              <Tooltip />
              <Line
                type="monotone"
                dataKey="knee"
                name="Knee angle (deg)"
                stroke="#E8007D"
                strokeWidth={2}
                dot={false}
              />
            </LineChart>
          </ResponsiveContainer>
        ) : (
          <div className="h-[220px] flex items-center justify-center rounded-xl border border-dashed border-[#f0d6e8] bg-[#fdf5f9]">
            <p className="text-[#64748b] text-sm text-center px-4">
              Available after Phase 3 analytics.
            </p>
          </div>
        )}
      </div>
    </div>
  );
}

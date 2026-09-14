import { useQuery } from '@tanstack/react-query';
import { getPatientProgress } from '../../api/doctorApi';
import {
  BarChart,
  Bar,
  XAxis,
  YAxis,
  Tooltip,
  ResponsiveContainer,
  LineChart,
  Line,
  CartesianGrid,
} from 'recharts';

interface Props {
  patientId: string;
}

export default function PatientProgressTab({ patientId }: Props) {
  const { data, isLoading } = useQuery({
    queryKey: ['patient-progress', patientId],
    queryFn: () => getPatientProgress(patientId),
    enabled: !!patientId,
  });

  if (isLoading) return <div className="py-12 text-center text-[#64748b]">Loading progress…</div>;
  if (!data) return <div className="py-12 text-center text-[#64748b]">No progress data yet.</div>;

  const adherencePct = Math.round(data.adherenceRate * 100);

  return (
    <div className="space-y-6">
      {/* Metric cards */}
      <div className="grid grid-cols-2 md:grid-cols-4 gap-4">
        <MetricCard label="Completed" value={data.totalSessionsCompleted.toString()} />
        <MetricCard label="Prescribed" value={data.totalSessionsPrescribed.toString()} />
        <MetricCard
          label="Remaining"
          value={Math.max(0, data.totalSessionsPrescribed - data.totalSessionsCompleted).toString()}
        />
        <MetricCard label="Adherence" value={`${adherencePct}%`} accent />
      </div>

      {/* Sessions per week bar chart */}
      <div className="bg-white rounded-2xl border border-[#f0d6e8] p-6 shadow-knevo">
        <h3 className="font-semibold text-[#0f172a] mb-4">Sessions per week (last 8 weeks)</h3>
        {data.sessionsPerWeek.every(w => w.count === 0) ? (
          <p className="text-[#64748b] text-sm">No sessions in the last 8 weeks.</p>
        ) : (
          <ResponsiveContainer width="100%" height={200}>
            <BarChart
              data={data.sessionsPerWeek}
              margin={{ top: 5, right: 10, left: -20, bottom: 5 }}
            >
              <XAxis dataKey="weekLabel" tick={{ fontSize: 11 }} />
              <YAxis allowDecimals={false} tick={{ fontSize: 11 }} />
              <Tooltip />
              <Bar dataKey="count" fill="#E8007D" radius={[4, 4, 0, 0]} />
            </BarChart>
          </ResponsiveContainer>
        )}
      </div>

      {/* Pain trend line chart */}
      <div className="bg-white rounded-2xl border border-[#f0d6e8] p-6 shadow-knevo">
        <h3 className="font-semibold text-[#0f172a] mb-4">Pain trend (last 20 sessions)</h3>
        {data.painTrend.length === 0 ? (
          <p className="text-[#64748b] text-sm">No pain data yet.</p>
        ) : (
          <ResponsiveContainer width="100%" height={200}>
            <LineChart
              data={data.painTrend}
              margin={{ top: 5, right: 10, left: -20, bottom: 5 }}
            >
              <CartesianGrid strokeDasharray="3 3" stroke="#f0d6e8" />
              <XAxis dataKey="sessionDate" tick={{ fontSize: 11 }} />
              <YAxis domain={[0, 10]} tick={{ fontSize: 11 }} />
              <Tooltip />
              <Line
                type="monotone"
                dataKey="avgPainBefore"
                stroke="#E8007D"
                strokeWidth={2}
                dot={{ r: 3 }}
              />
            </LineChart>
          </ResponsiveContainer>
        )}
      </div>
    </div>
  );
}

function MetricCard({
  label,
  value,
  accent,
  warn,
}: {
  label: string;
  value: string;
  accent?: boolean;
  warn?: boolean;
}) {
  return (
    <div
      className={`rounded-2xl border p-4 ${
        accent
          ? 'border-[#E8007D] bg-[#fdf5f9]'
          : warn
            ? 'border-orange-200 bg-orange-50'
            : 'border-[#f0d6e8] bg-white'
      }`}
    >
      <p className="text-xs text-[#64748b] mb-1">{label}</p>
      <p
        className={`text-2xl font-bold ${
          accent ? 'text-[#E8007D]' : warn ? 'text-orange-600' : 'text-[#0f172a]'
        }`}
      >
        {value}
      </p>
    </div>
  );
}

import { useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import { getPatientPlans, getTherapyConfig } from '../../api/doctorApi';

export default function PatientDetailPage() {
  const { patientId = '' } = useParams();

  const { data: plans = [], isLoading: plansLoading } = useQuery({
    queryKey: ['patient-plans', patientId],
    queryFn: () => getPatientPlans(patientId),
    enabled: !!patientId,
  });

  const activePlan = plans.find(p => p.status === 'ACTIVE');

  const { data: config, isLoading: configLoading } = useQuery({
    queryKey: ['therapy-config', activePlan?.therapyConfigId],
    queryFn: () => getTherapyConfig(activePlan!.therapyConfigId),
    enabled: !!activePlan?.therapyConfigId,
  });

  return (
    <div className="min-h-screen bg-[#fdf5f9] p-8">
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <a href="/patients" className="text-[#64748b] hover:text-[#E8007D] text-sm">← All patients</a>
          <a href={`/create-plan?patientId=${patientId}`}
            className="px-5 py-2.5 rounded-xl bg-[#E8007D] text-white text-sm font-semibold hover:bg-[#cc006e] transition-colors">
            + New plan
          </a>
        </div>

        <h1 className="text-2xl font-bold text-[#0f172a] mb-6">Patient</h1>

        {plansLoading ? (
          <p className="text-[#64748b]">Loading…</p>
        ) : plans.length === 0 ? (
          <div className="bg-white rounded-2xl border border-[#f0d6e8] p-8 text-center shadow-knevo">
            <p className="text-[#64748b] mb-4">No therapy plans yet.</p>
            <a href={`/create-plan?patientId=${patientId}`} className="text-[#E8007D] font-semibold hover:underline text-sm">Create first plan →</a>
          </div>
        ) : (
          <div className="space-y-4">
            {activePlan && config && (
              <div className="bg-white rounded-2xl border border-[#E8007D] p-6 shadow-knevo">
                <div className="flex items-center justify-between mb-4">
                  <h2 className="text-lg font-semibold text-[#0f172a]">Active plan: {activePlan.title}</h2>
                  <span className="px-3 py-1 rounded-lg text-xs font-semibold bg-[#fce8f3] text-[#E8007D]">ACTIVE</span>
                </div>
                <div className="grid grid-cols-2 md:grid-cols-4 gap-4 mb-6 text-sm">
                  {config.sessionsPerWeek && <div><p className="text-[#64748b]">Sessions/week</p><p className="font-semibold text-[#0f172a]">{config.sessionsPerWeek}</p></div>}
                  {config.totalSessionsNum && <div><p className="text-[#64748b]">Total sessions</p><p className="font-semibold text-[#0f172a]">{config.totalSessionsNum}</p></div>}
                  {config.schedule && <div><p className="text-[#64748b]">Schedule</p><p className="font-semibold text-[#0f172a]">{config.schedule}</p></div>}
                  {config.maxFlexionAngleDeg && <div><p className="text-[#64748b]">Max flexion</p><p className="font-semibold text-[#0f172a]">{config.maxFlexionAngleDeg}°</p></div>}
                </div>
                {configLoading ? <p className="text-[#64748b] text-sm">Loading sets…</p> : (
                  <div className="space-y-2">
                    <p className="text-sm font-semibold text-[#334155] mb-3">Sets ({config.sets.length})</p>
                    {config.sets.map((s, i) => (
                      <div key={s.id} className="flex items-center gap-4 px-4 py-3 bg-[#fdf5f9] rounded-xl border border-[#f0d6e8]">
                        <span className="w-6 h-6 rounded-full bg-[#E8007D] text-white text-xs flex items-center justify-center font-bold">{i + 1}</span>
                        <div className="flex-1">
                          <p className="font-medium text-[#0f172a] text-sm">{s.exercise.name}</p>
                          <p className="text-xs text-[#64748b]">{s.durationMin} min · {s.restDurationMin ?? 0} min rest · {s.deviceAssisted ? 'Device-assisted' : 'Mobile only'}</p>
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        )}
      </div>
    </div>
  );
}

import { useState } from 'react';
import { useParams } from 'react-router-dom';
import { useQuery } from '@tanstack/react-query';
import {
  getPatientPlans,
  getTherapyConfig,
  getPatientSessions,
  getSessionDetail,
} from '../../api/doctorApi';
import EditConfigModal from './EditConfigModal';
import PatientProgressTab from './PatientProgressTab';

function formatDuration(start: string | null, end: string | null): string {
  if (!start || !end) return '—';
  const mins = Math.round((new Date(end).getTime() - new Date(start).getTime()) / 60000);
  return `${mins} min`;
}

function formatDate(iso: string | null): string {
  if (!iso) return '—';
  return new Date(iso).toLocaleDateString(undefined, { year: 'numeric', month: 'short', day: 'numeric' });
}

function StatusBadge({ status }: { status: string }) {
  const colorMap: Record<string, string> = {
    COMPLETED: 'bg-green-100 text-green-700',
    STOPPED_DUE_TO_PAIN: 'bg-red-100 text-red-700',
    STOPPED_BY_PATIENT: 'bg-orange-100 text-orange-700',
    IN_PROGRESS: 'bg-blue-100 text-blue-700',
  };
  const cls = colorMap[status] ?? 'bg-gray-100 text-gray-700';
  return (
    <span className={`px-2 py-0.5 rounded-lg text-xs font-semibold ${cls}`}>
      {status.replace(/_/g, ' ')}
    </span>
  );
}

export default function PatientDetailPage() {
  const { patientId = '' } = useParams();
  const [tab, setTab] = useState<'plan' | 'sessions' | 'progress'>('plan');
  const [selectedSessionId, setSelectedSessionId] = useState<string | null>(null);
  const [editingConfig, setEditingConfig] = useState(false);

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

  const { data: sessions = [] } = useQuery({
    queryKey: ['patient-sessions', patientId],
    queryFn: () => getPatientSessions(patientId),
    enabled: tab === 'sessions' && !!patientId,
  });

  const { data: sessionDetail } = useQuery({
    queryKey: ['session-detail', selectedSessionId],
    queryFn: () => getSessionDetail(selectedSessionId!),
    enabled: !!selectedSessionId,
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

        {/* Tab bar */}
        <div className="flex gap-2 mb-6">
          {(['plan', 'sessions', 'progress'] as const).map(t => (
            <button
              key={t}
              onClick={() => { setTab(t); setSelectedSessionId(null); }}
              className={`px-5 py-2 rounded-xl text-sm font-semibold capitalize transition-colors ${
                tab === t
                  ? 'bg-[#E8007D] text-white'
                  : 'bg-white border border-[#f0d6e8] text-[#64748b] hover:border-[#E8007D]'
              }`}
            >
              {t === 'plan' ? 'Therapy Plan' : t === 'sessions' ? 'Sessions' : 'Progress'}
            </button>
          ))}
        </div>

        {/* Plan tab */}
        {tab === 'plan' && (
          plansLoading ? (
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
                    <div className="flex items-center gap-2">
                      <span className="px-3 py-1 rounded-lg text-xs font-semibold bg-[#fce8f3] text-[#E8007D]">ACTIVE</span>
                      <button onClick={() => setEditingConfig(true)}
                        className="px-3 py-1 rounded-lg text-xs font-semibold bg-white border border-[#f0d6e8] text-[#64748b] hover:border-[#E8007D] hover:text-[#E8007D] transition-colors">
                        Edit config
                      </button>
                    </div>
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
          )
        )}

        {/* Sessions tab */}
        {tab === 'sessions' && (
          <div>
            {sessions.length === 0 ? (
              <div className="bg-white rounded-2xl border border-[#f0d6e8] p-8 text-center shadow-knevo">
                <p className="text-[#64748b]">No sessions yet.</p>
              </div>
            ) : (
              <div className="space-y-3">
                {sessions.map(session => (
                  <button
                    key={session.id}
                    onClick={() => setSelectedSessionId(
                      selectedSessionId === session.id ? null : session.id
                    )}
                    className={`w-full text-left bg-white rounded-2xl border p-5 shadow-knevo transition-colors ${
                      selectedSessionId === session.id
                        ? 'border-[#E8007D]'
                        : 'border-[#f0d6e8] hover:border-[#E8007D]'
                    }`}
                  >
                    <div className="flex items-center justify-between mb-2">
                      <span className="text-sm font-semibold text-[#0f172a]">
                        {formatDate(session.startedAt)}
                      </span>
                      <StatusBadge status={session.status} />
                    </div>
                    <div className="flex gap-6 text-xs text-[#64748b]">
                      <span>Duration: {formatDuration(session.startedAt, session.endedAt)}</span>
                      {session.painBefore != null && (
                        <span>Pain before: <span className="font-semibold text-[#0f172a]">{session.painBefore}</span></span>
                      )}
                      {session.painAfter != null && (
                        <span>Pain after: <span className="font-semibold text-[#0f172a]">{session.painAfter}</span></span>
                      )}
                    </div>
                  </button>
                ))}
              </div>
            )}

            {/* Session detail panel */}
            {selectedSessionId && sessionDetail && (
              <div className="mt-6 bg-white rounded-2xl border border-[#f0d6e8] p-6 shadow-knevo">
                <h3 className="text-base font-semibold text-[#0f172a] mb-4">Session detail</h3>
                {!sessionDetail.setRecords || sessionDetail.setRecords.length === 0 ? (
                  <p className="text-[#64748b] text-sm">No set records for this session.</p>
                ) : (
                  <div className="space-y-3">
                    {sessionDetail.setRecords.map((rec, i) => (
                      <div key={rec.id} className="px-4 py-3 bg-[#fdf5f9] rounded-xl border border-[#f0d6e8]">
                        <div className="flex items-center gap-3 mb-1">
                          <span className="w-5 h-5 rounded-full bg-[#E8007D] text-white text-xs flex items-center justify-center font-bold">{i + 1}</span>
                          <span className="font-medium text-[#0f172a] text-sm">
                            {rec.exerciseName ?? 'Exercise'}
                          </span>
                          <StatusBadge status={rec.status} />
                        </div>
                        <div className="flex gap-4 text-xs text-[#64748b] ml-8">
                          <span>Duration: {formatDuration(rec.startDatetime, rec.stopDatetime)}</span>
                          {rec.painLevel != null && (
                            <span>Pain: <span className="font-semibold text-[#0f172a]">{rec.painLevel}</span></span>
                          )}
                          {rec.feedback && (
                            <span>"{rec.feedback}"</span>
                          )}
                        </div>
                      </div>
                    ))}
                  </div>
                )}
              </div>
            )}
          </div>
        )}

        {/* Progress tab */}
        {tab === 'progress' && <PatientProgressTab patientId={patientId} />}
      </div>

      {editingConfig && config && (
        <EditConfigModal config={config} patientId={patientId} onClose={() => setEditingConfig(false)} />
      )}
    </div>
  );
}

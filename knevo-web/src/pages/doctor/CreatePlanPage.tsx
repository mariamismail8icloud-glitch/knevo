import { useEffect, useState } from 'react';
import { useNavigate, useSearchParams } from 'react-router-dom';
import { useMutation, useQuery } from '@tanstack/react-query';
import { getExercises, createPlan, getTherapyDefaults, type Exercise, type SetConfigRequest } from '../../api/doctorApi';
import { validateTherapyLimits } from '../../utils/therapyLimits';

interface SelectedSet extends SetConfigRequest {
  exerciseName: string;
}

export default function CreatePlanPage() {
  const [searchParams] = useSearchParams();
  const patientId = searchParams.get('patientId') ?? '';
  const navigate = useNavigate();
  const [step, setStep] = useState(1);
  const [error, setError] = useState('');

  // Step 1
  const [title, setTitle] = useState('');
  const [goal, setGoal] = useState('');
  const [startDate, setStartDate] = useState('');
  const [endDate, setEndDate] = useState('');

  // Step 2
  const [sets, setSets] = useState<SelectedSet[]>([]);
  const [exSearch, setExSearch] = useState('');

  // Step 3
  const [sessionsPerWeek, setSessionsPerWeek] = useState('');
  const [totalSessions, setTotalSessions] = useState('');
  const [schedule, setSchedule] = useState('');
  const [maxFlexion, setMaxFlexion] = useState('');
  const [maxExtension, setMaxExtension] = useState('');
  const [maxSpeed, setMaxSpeed] = useState('');

  const { data: exercises = [] } = useQuery({
    queryKey: ['exercises'],
    queryFn: () => getExercises(),
  });

  const { data: defaults } = useQuery({
    queryKey: ['therapy-defaults'],
    queryFn: () => getTherapyDefaults(),
    // Static server config: cache for the whole session so it never flickers
    // back to undefined on remount and never dead-ends submission.
    staleTime: Infinity,
    gcTime: Infinity,
  });

  // Pre-populate the safety limits with the backend defaults once they load.
  useEffect(() => {
    if (!defaults) return;
    setMaxSpeed(prev => (prev === '' ? String(defaults.maxSpeed.defaultValue) : prev));
    setMaxExtension(prev => (prev === '' ? String(defaults.maxExtensionAngleDeg.defaultValue) : prev));
    setMaxFlexion(prev => (prev === '' ? String(defaults.maxFlexionAngleDeg.defaultValue) : prev));
  }, [defaults]);

  const filteredEx = exercises.filter(e =>
    e.name.toLowerCase().includes(exSearch.toLowerCase())
  );

  const mutation = useMutation({
    mutationFn: () => createPlan(patientId, {
      title, goal, startDate: startDate || undefined, endDate: endDate || undefined,
      sessionsPerWeek: sessionsPerWeek ? parseInt(sessionsPerWeek) : undefined,
      totalSessionsNum: totalSessions ? parseInt(totalSessions) : undefined,
      schedule: schedule || undefined,
      maxFlexionAngleDeg: parseFloat(maxFlexion),
      maxExtensionAngleDeg: parseFloat(maxExtension),
      maxSpeed: parseFloat(maxSpeed),
      sets: sets.map(s => ({
        exerciseId: s.exerciseId,
        deviceAssisted: s.deviceAssisted,
        durationMin: s.durationMin,
        restDurationMin: s.restDurationMin,
        setOrder: s.setOrder,
      })),
    }),
    onSuccess: () => navigate(`/patients/${patientId}`),
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setError(msg ?? 'Failed to create plan');
    },
  });

  const addSet = (ex: Exercise) => {
    setSets(prev => [...prev, {
      exerciseId: ex.id,
      exerciseName: ex.name,
      deviceAssisted: ex.mode === 'DEVICE_ASSISTED',
      durationMin: ex.defaultSets ? 10 : 10,
      restDurationMin: 2,
      setOrder: prev.length,
    }]);
  };

  const removeSet = (index: number) => setSets(prev => prev.filter((_, i) => i !== index));

  const submitPlan = () => {
    // Client-side range check is a nicety when defaults have loaded; the backend
    // validates the same ranges authoritatively, so never block the doctor if
    // the defaults query hasn't resolved.
    if (defaults) {
      const limitError = validateTherapyLimits({ maxSpeed, maxExtension, maxFlexion }, defaults);
      if (limitError) {
        setError(limitError);
        return;
      }
    }
    setError('');
    mutation.mutate();
  };

  return (
    <div className="min-h-screen bg-[#fdf5f9] p-8">
      <div className="max-w-2xl mx-auto">
        <div className="flex items-center gap-3 mb-6">
          <a href={`/patients/${patientId}`} className="text-[#64748b] hover:text-[#E8007D] text-sm">← Back to patient</a>
        </div>
        <h1 className="text-2xl font-bold text-[#0f172a] mb-2">Create therapy plan</h1>
        <p className="text-[#64748b] mb-8">Step {step} of 3</p>
        <div className="h-1.5 rounded-full bg-[#f0d6e8] mb-8">
          <div className="h-1.5 rounded-full bg-[#E8007D] transition-all" style={{ width: `${(step / 3) * 100}%` }} />
        </div>

        {error && <div className="mb-4 px-4 py-3 bg-red-50 border border-red-200 rounded-2xl text-red-700 text-sm">{error}</div>}

        <div className="bg-white rounded-2xl border border-[#f0d6e8] p-8 shadow-knevo">
          {step === 1 && (
            <div className="space-y-5">
              <h2 className="text-lg font-semibold text-[#0f172a]">Plan details</h2>
              {[
                { label: 'Plan title', value: title, set: setTitle, required: true },
                { label: 'Clinical goal', value: goal, set: setGoal },
                { label: 'Start date', value: startDate, set: setStartDate, type: 'date' },
                { label: 'End date', value: endDate, set: setEndDate, type: 'date' },
              ].map(({ label, value, set, required, type }) => (
                <div key={label}>
                  <label className="block text-sm font-semibold text-[#334155] mb-2">{label}{required ? '' : ' (optional)'}</label>
                  <input type={type ?? 'text'} value={value} onChange={e => set(e.target.value)} required={required}
                    className="w-full px-4 py-3 rounded-2xl border border-[#f0d6e8] bg-[#fdf5f9] focus:outline-none focus:ring-2 focus:ring-[#E8007D]/30 focus:border-[#E8007D] text-[#0f172a]" />
                </div>
              ))}
              <button onClick={() => title.trim() ? setStep(2) : setError('Plan title is required')}
                className="w-full py-3 rounded-2xl bg-[#E8007D] text-white font-semibold hover:bg-[#cc006e] transition-colors">
                Continue →
              </button>
            </div>
          )}

          {step === 2 && (
            <div className="space-y-4">
              <h2 className="text-lg font-semibold text-[#0f172a]">Add sets</h2>
              {sets.length > 0 && (
                <div className="space-y-2 mb-4">
                  {sets.map((s, i) => (
                    <div key={i} className="flex items-center justify-between px-4 py-3 bg-[#fdf5f9] rounded-xl border border-[#f0d6e8]">
                      <div>
                        <p className="font-medium text-[#0f172a] text-sm">{s.exerciseName}</p>
                        <p className="text-xs text-[#64748b]">{s.durationMin} min · {s.restDurationMin} min rest · {s.deviceAssisted ? 'Device' : 'Mobile'}</p>
                      </div>
                      <button onClick={() => removeSet(i)} className="text-[#64748b] hover:text-red-500 text-sm">Remove</button>
                    </div>
                  ))}
                </div>
              )}
              <input type="text" placeholder="Search exercises to add…" value={exSearch} onChange={e => setExSearch(e.target.value)}
                className="w-full px-4 py-3 rounded-2xl border border-[#f0d6e8] bg-[#fdf5f9] focus:outline-none focus:ring-2 focus:ring-[#E8007D]/30 focus:border-[#E8007D] text-[#0f172a]" />
              <div className="max-h-60 overflow-y-auto space-y-2">
                {filteredEx.slice(0, 10).map(ex => (
                  <div key={ex.id} className="flex items-center justify-between px-4 py-3 bg-[#fdf5f9] rounded-xl border border-[#f0d6e8] hover:border-[#E8007D] cursor-pointer" onClick={() => addSet(ex)}>
                    <div>
                      <p className="font-medium text-[#0f172a] text-sm">{ex.name}</p>
                      <p className="text-xs text-[#64748b]">{ex.category} · {ex.mode === 'DEVICE_ASSISTED' ? 'Device' : 'Mobile'}</p>
                    </div>
                    <span className="text-[#E8007D] text-sm font-semibold">+ Add</span>
                  </div>
                ))}
              </div>
              <div className="flex gap-3">
                <button onClick={() => setStep(1)} className="flex-1 py-3 rounded-2xl border border-[#f0d6e8] text-[#64748b] font-semibold">← Back</button>
                <button onClick={() => setStep(3)} className="flex-1 py-3 rounded-2xl bg-[#E8007D] text-white font-semibold hover:bg-[#cc006e]">Continue →</button>
              </div>
            </div>
          )}

          {step === 3 && (
            <div className="space-y-5">
              <h2 className="text-lg font-semibold text-[#0f172a]">Schedule & safety limits</h2>
              {[
                { label: 'Sessions per week', value: sessionsPerWeek, set: setSessionsPerWeek, type: 'number' },
                { label: 'Total sessions', value: totalSessions, set: setTotalSessions, type: 'number' },
                { label: 'Schedule (e.g. MON,WED,FRI)', value: schedule, set: setSchedule },
              ].map(({ label, value, set, type }) => (
                <div key={label}>
                  <label className="block text-sm font-semibold text-[#334155] mb-2">{label} <span className="text-[#64748b] font-normal">(optional)</span></label>
                  <input type={type ?? 'text'} value={value} onChange={e => set(e.target.value)}
                    className="w-full px-4 py-3 rounded-2xl border border-[#f0d6e8] bg-[#fdf5f9] focus:outline-none focus:ring-2 focus:ring-[#E8007D]/30 focus:border-[#E8007D] text-[#0f172a]" />
                </div>
              ))}
              {[
                { label: 'Max speed', value: maxSpeed, set: setMaxSpeed, range: defaults?.maxSpeed },
                { label: 'Max extension angle (°)', value: maxExtension, set: setMaxExtension, range: defaults?.maxExtensionAngleDeg },
                { label: 'Max flexion angle (°)', value: maxFlexion, set: setMaxFlexion, range: defaults?.maxFlexionAngleDeg },
              ].map(({ label, value, set, range }) => (
                <div key={label}>
                  <label className="block text-sm font-semibold text-[#334155] mb-2">
                    {label}{range ? <span className="text-[#64748b] font-normal"> ({range.min}–{range.max})</span> : null}
                  </label>
                  <input type="number" value={value} onChange={e => set(e.target.value)} required
                    min={range?.min} max={range?.max} step="0.1"
                    className="w-full px-4 py-3 rounded-2xl border border-[#f0d6e8] bg-[#fdf5f9] focus:outline-none focus:ring-2 focus:ring-[#E8007D]/30 focus:border-[#E8007D] text-[#0f172a]" />
                </div>
              ))}
              <div className="flex gap-3">
                <button onClick={() => setStep(2)} className="flex-1 py-3 rounded-2xl border border-[#f0d6e8] text-[#64748b] font-semibold">← Back</button>
                <button onClick={submitPlan} disabled={mutation.isPending}
                  className="flex-1 py-3 rounded-2xl bg-[#E8007D] text-white font-semibold hover:bg-[#cc006e] disabled:opacity-60">
                  {mutation.isPending ? 'Creating…' : 'Create plan'}
                </button>
              </div>
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

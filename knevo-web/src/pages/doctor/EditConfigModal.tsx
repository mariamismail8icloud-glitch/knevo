import { useState } from 'react';
import { useMutation, useQueryClient } from '@tanstack/react-query';
import { updateTherapyConfig, type TherapyConfig, type UpdateConfigRequest } from '../../api/doctorApi';

interface Props {
  config: TherapyConfig;
  patientId: string;
  onClose: () => void;
}

export default function EditConfigModal({ config, patientId, onClose }: Props) {
  const qc = useQueryClient();
  const [sessionsPerWeek, setSessionsPerWeek] = useState(config.sessionsPerWeek?.toString() ?? '');
  const [totalSessions, setTotalSessions] = useState(config.totalSessionsNum?.toString() ?? '');
  const [schedule, setSchedule] = useState(config.schedule ?? '');
  const [maxFlexion, setMaxFlexion] = useState(config.maxFlexionAngleDeg?.toString() ?? '');
  const [maxExtension, setMaxExtension] = useState(config.maxExtensionAngleDeg?.toString() ?? '');
  const [maxSpeed, setMaxSpeed] = useState(config.maxSpeed?.toString() ?? '');
  const [comment, setComment] = useState('');
  const [success, setSuccess] = useState(false);

  const mutation = useMutation({
    mutationFn: () => {
      const req: UpdateConfigRequest = {};
      if (sessionsPerWeek) req.sessionsPerWeek = parseInt(sessionsPerWeek);
      if (totalSessions) req.totalSessionsNum = parseInt(totalSessions);
      if (schedule) req.schedule = schedule;
      if (maxFlexion) req.maxFlexionAngleDeg = parseFloat(maxFlexion);
      if (maxExtension) req.maxExtensionAngleDeg = parseFloat(maxExtension);
      if (maxSpeed) req.maxSpeed = parseFloat(maxSpeed);
      if (comment) req.comment = comment;
      return updateTherapyConfig(config.id, req);
    },
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['therapy-config'] });
      qc.invalidateQueries({ queryKey: ['patient-plans', patientId] });
      setSuccess(true);
      setTimeout(onClose, 1200);
    },
  });

  return (
    <div className="fixed inset-0 bg-black/30 flex items-center justify-center p-6 z-50">
      <div className="w-full max-w-lg bg-white rounded-3xl p-8 shadow-2xl max-h-[80vh] overflow-y-auto"
           onClick={e => e.stopPropagation()}>
        <div className="flex items-start justify-between mb-6">
          <h2 className="text-xl font-bold text-[#0f172a]">Edit Therapy Config</h2>
          <button onClick={onClose} className="text-[#64748b] hover:text-[#0f172a]">&#x2715;</button>
        </div>

        {success && (
          <div className="mb-4 px-4 py-3 bg-green-50 border border-green-200 rounded-2xl text-green-700 text-sm">
            Config updated — patient will be notified.
          </div>
        )}

        {mutation.isError && (
          <div className="mb-4 px-4 py-3 bg-red-50 border border-red-200 rounded-2xl text-red-700 text-sm">
            Failed to update config.
          </div>
        )}

        <div className="space-y-4">
          {[
            { label: 'Sessions per week', value: sessionsPerWeek, set: setSessionsPerWeek, type: 'number' },
            { label: 'Total sessions', value: totalSessions, set: setTotalSessions, type: 'number' },
            { label: 'Schedule (e.g. MON,WED,FRI)', value: schedule, set: setSchedule },
            { label: 'Max flexion angle (°)', value: maxFlexion, set: setMaxFlexion, type: 'number' },
            { label: 'Max extension angle (°)', value: maxExtension, set: setMaxExtension, type: 'number' },
            { label: 'Max speed', value: maxSpeed, set: setMaxSpeed, type: 'number' },
            { label: 'Comment', value: comment, set: setComment },
          ].map(({ label, value, set, type }) => (
            <div key={label}>
              <label className="block text-sm font-semibold text-[#334155] mb-2">{label}</label>
              <input type={type ?? 'text'} value={value} onChange={e => set(e.target.value)}
                className="w-full px-4 py-3 rounded-2xl border border-[#f0d6e8] bg-[#fdf5f9] focus:outline-none focus:ring-2 focus:ring-[#E8007D]/30 focus:border-[#E8007D] text-[#0f172a]" />
            </div>
          ))}
        </div>

        <div className="flex gap-3 mt-6">
          <button onClick={onClose}
            className="flex-1 py-3 rounded-2xl border border-[#f0d6e8] text-[#64748b] font-semibold">
            Cancel
          </button>
          <button onClick={() => mutation.mutate()} disabled={mutation.isPending}
            className="flex-1 py-3 rounded-2xl bg-[#E8007D] text-white font-semibold hover:bg-[#cc006e] disabled:opacity-60">
            {mutation.isPending ? 'Saving…' : 'Save Changes'}
          </button>
        </div>
      </div>
    </div>
  );
}

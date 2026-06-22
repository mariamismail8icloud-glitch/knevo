import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getMyPatients, enrollPatient, type Patient } from '../../api/doctorApi';
import { getAdminPatients } from '../../api/adminApi';
import { useAuth } from '../../context/AuthContext';

export default function PatientListPage() {
  const { role } = useAuth();
  const qc = useQueryClient();
  const [showEnroll, setShowEnroll] = useState(false);
  const [code, setCode] = useState('');
  const [enrollError, setEnrollError] = useState('');

  const { data: patients = [], isLoading, isError } = useQuery({
    queryKey: role === 'ADMIN' ? ['admin-patients'] : ['my-patients'],
    queryFn: role === 'ADMIN' ? getAdminPatients : getMyPatients,
    retry: false,
  });

  const enrollMutation = useMutation({
    mutationFn: enrollPatient,
    onSuccess: () => {
      qc.invalidateQueries({ queryKey: ['my-patients'] });
      setShowEnroll(false);
      setCode('');
      setEnrollError('');
    },
    onError: (err: unknown) => {
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setEnrollError(msg ?? 'Enrollment failed. Check the code and try again.');
    },
  });

  return (
    <div className="min-h-screen bg-[#fdf5f9] p-8">
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center gap-3">
            <a href={role === 'ADMIN' ? '/admin' : '/dashboard'} className="text-[#64748b] hover:text-[#E8007D] transition-colors text-sm">
              {role === 'ADMIN' ? '← Admin' : '← Dashboard'}
            </a>
          </div>
          <button
            onClick={() => setShowEnroll(true)}
            className="px-5 py-2.5 rounded-xl bg-[#E8007D] text-white text-sm font-semibold hover:bg-[#cc006e] transition-colors"
          >
            + Enroll patient
          </button>
        </div>

        <h1 className="text-2xl font-bold text-[#0f172a] mb-6">My Patients</h1>

        {/* Enroll modal */}
        {showEnroll && (
          <div className="fixed inset-0 bg-black/30 flex items-center justify-center p-6 z-50">
            <div className="w-full max-w-md bg-white rounded-3xl p-8 shadow-2xl">
              <h2 className="text-xl font-bold text-[#0f172a] mb-2">Enroll a patient</h2>
              <p className="text-[#64748b] text-sm mb-6">Ask your patient for their 8-character enrollment code from the Knevo app.</p>
              {enrollError && (
                <div className="mb-4 px-4 py-3 bg-red-50 border border-red-200 rounded-2xl text-red-700 text-sm">{enrollError}</div>
              )}
              <input
                type="text"
                value={code}
                onChange={e => setCode(e.target.value.toUpperCase())}
                placeholder="e.g. AB3X7Y2Z"
                maxLength={8}
                className="w-full px-4 py-3 rounded-2xl border border-[#f0d6e8] bg-[#fdf5f9] focus:outline-none focus:ring-2 focus:ring-[#E8007D]/30 focus:border-[#E8007D] text-[#0f172a] font-mono text-lg tracking-widest text-center mb-4"
              />
              <div className="flex gap-3">
                <button
                  onClick={() => { setShowEnroll(false); setCode(''); setEnrollError(''); }}
                  className="flex-1 py-3 rounded-2xl border border-[#f0d6e8] text-[#64748b] font-semibold hover:bg-[#fdf5f9] transition-colors"
                >
                  Cancel
                </button>
                <button
                  onClick={() => enrollMutation.mutate(code)}
                  disabled={code.length < 6 || enrollMutation.isPending}
                  className="flex-1 py-3 rounded-2xl bg-[#E8007D] text-white font-semibold hover:bg-[#cc006e] transition-colors disabled:opacity-60"
                >
                  {enrollMutation.isPending ? 'Linking…' : 'Link patient'}
                </button>
              </div>
            </div>
          </div>
        )}

        {/* Patient list */}
        <div className="bg-white rounded-2xl border border-[#f0d6e8] shadow-knevo overflow-hidden">
          {isLoading ? (
            <div className="p-8 text-center text-[#64748b]">Loading patients…</div>
          ) : isError ? (
            <div className="p-12 text-center text-red-600 text-sm">Failed to load patients.</div>
          ) : patients.length === 0 ? (
            <div className="p-12 text-center">
              <p className="text-[#64748b] mb-4">No patients yet.</p>
              <button onClick={() => setShowEnroll(true)} className="text-[#E8007D] font-semibold hover:underline text-sm">
                Enroll your first patient →
              </button>
            </div>
          ) : (
            <table className="w-full">
              <thead className="bg-[#fdf5f9] border-b border-[#f0d6e8]">
                <tr>
                  <th className="text-left px-6 py-4 text-sm font-semibold text-[#334155]">Name</th>
                  <th className="text-left px-6 py-4 text-sm font-semibold text-[#334155]">Email</th>
                  <th className="text-left px-6 py-4 text-sm font-semibold text-[#334155]">Phone</th>
                  <th className="px-6 py-4"></th>
                </tr>
              </thead>
              <tbody className="divide-y divide-[#f0d6e8]">
                {patients.map((p: Patient) => (
                  <tr key={p.id} className="hover:bg-[#fdf5f9] transition-colors">
                    <td className="px-6 py-4 font-medium text-[#0f172a]">{p.name}</td>
                    <td className="px-6 py-4 text-[#64748b]">{p.email}</td>
                    <td className="px-6 py-4 text-[#64748b]">{p.phone ?? '—'}</td>
                    <td className="px-6 py-4 text-right">
                      <a href={`/patients/${p.id}`} className="text-[#E8007D] text-sm font-semibold hover:underline">View →</a>
                    </td>
                  </tr>
                ))}
              </tbody>
            </table>
          )}
        </div>
      </div>
    </div>
  );
}

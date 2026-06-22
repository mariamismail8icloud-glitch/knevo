import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { getPendingDoctors, approveDoctor, rejectDoctor, type PendingDoctor } from '../../api/adminApi';

export default function AdminDashboardPage() {
  const qc = useQueryClient();
  const { data: doctors = [], isLoading } = useQuery({
    queryKey: ['pending-doctors'],
    queryFn: getPendingDoctors,
  });

  const approveMutation = useMutation({
    mutationFn: approveDoctor,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['pending-doctors'] }),
  });

  const rejectMutation = useMutation({
    mutationFn: (id: string) => rejectDoctor(id),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['pending-doctors'] }),
  });

  return (
    <div className="min-h-screen bg-[#fdf5f9] p-8">
      <div className="max-w-4xl mx-auto">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#ff4da6] to-[#E8007D] flex items-center justify-center text-white font-bold">K</div>
          <h1 className="text-2xl font-bold text-[#0f172a]">Admin Dashboard</h1>
        </div>

        <div className="bg-white rounded-2xl border border-[#f0d6e8] p-6 shadow-knevo">
          <h2 className="text-lg font-semibold text-[#0f172a] mb-4">Pending Doctor Approvals</h2>
          {isLoading ? (
            <p className="text-[#64748b]">Loading…</p>
          ) : doctors.length === 0 ? (
            <p className="text-[#64748b]">No pending doctors.</p>
          ) : (
            <div className="space-y-3">
              {doctors.map((doc: PendingDoctor) => (
                <div key={doc.id} className="flex items-center justify-between p-4 rounded-xl border border-[#f0d6e8] bg-[#fdf5f9]">
                  <div>
                    <p className="font-semibold text-[#0f172a]">{doc.name}</p>
                    <p className="text-sm text-[#64748b]">{doc.email} · {doc.specialization} · {doc.clinicName}</p>
                  </div>
                  <div className="flex gap-2">
                    <button
                      onClick={() => approveMutation.mutate(doc.id)}
                      disabled={approveMutation.isPending}
                      className="px-4 py-2 rounded-xl bg-[#E8007D] text-white text-sm font-semibold hover:bg-[#cc006e] transition-colors disabled:opacity-60"
                    >
                      Approve
                    </button>
                    <button
                      onClick={() => rejectMutation.mutate(doc.id)}
                      disabled={rejectMutation.isPending}
                      className="px-4 py-2 rounded-xl border border-[#f0d6e8] text-[#64748b] text-sm font-semibold hover:bg-red-50 hover:text-red-600 hover:border-red-200 transition-colors disabled:opacity-60"
                    >
                      Reject
                    </button>
                  </div>
                </div>
              ))}
            </div>
          )}
        </div>
      </div>
    </div>
  );
}

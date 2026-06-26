import { useState } from 'react';
import { useQuery, useMutation, useQueryClient } from '@tanstack/react-query';
import { useNavigate } from 'react-router-dom';
import { getAllDoctors, approveDoctor, rejectDoctor, type Doctor } from '../../api/adminApi';
import { useAuth } from '../../context/AuthContext';

type Tab = 'PENDING' | 'APPROVED' | 'REJECTED';

const STATUS_BADGE: Record<string, string> = {
  PENDING:  'bg-amber-50 text-amber-700 border border-amber-200',
  APPROVED: 'bg-green-50 text-green-700 border border-green-200',
  REJECTED: 'bg-red-50 text-red-700 border border-red-200',
};

function fmt(iso: string) {
  return new Date(iso).toLocaleDateString('en-GB', { day: 'numeric', month: 'short', year: 'numeric' });
}

function DoctorCard({ doc, onApprove, onReject, approving, rejecting }: {
  doc: Doctor;
  onApprove?: () => void;
  onReject?: (reason: string) => void;
  approving?: boolean;
  rejecting?: boolean;
}) {
  const [showReject, setShowReject] = useState(false);
  const [reason, setReason] = useState('');
  const isPending = doc.doctorStatus === 'PENDING';

  return (
    <div className="bg-white rounded-2xl border border-[#f0d6e8] p-6 space-y-4">
      {/* Header row */}
      <div className="flex items-start justify-between gap-4">
        <div className="flex items-center gap-3">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#ff4da6] to-[#E8007D] flex items-center justify-center text-white font-bold text-sm flex-shrink-0">
            {doc.name.charAt(0).toUpperCase()}
          </div>
          <div>
            <p className="font-semibold text-[#0f172a]">{doc.name}</p>
            <p className="text-sm text-[#64748b]">{doc.email}</p>
          </div>
        </div>
        <span className={`text-xs font-semibold px-3 py-1 rounded-full whitespace-nowrap ${STATUS_BADGE[doc.doctorStatus] ?? ''}`}>
          {doc.doctorStatus}
        </span>
      </div>

      {/* Details grid */}
      <div className="grid grid-cols-2 gap-x-6 gap-y-2 text-sm">
        <Detail label="Clinic" value={doc.clinicName} />
        <Detail label="Specialization" value={doc.specialization} />
        {doc.phone && <Detail label="Phone" value={doc.phone} />}
        {doc.professionalLicense && <Detail label="License" value={doc.professionalLicense} />}
        {doc.yearsExperience != null && <Detail label="Experience" value={`${doc.yearsExperience} yrs`} />}
        <Detail label="Applied" value={fmt(doc.createdAt)} />
      </div>

      {/* Rejection reason (for rejected doctors) */}
      {doc.doctorStatus === 'REJECTED' && doc.rejectionReason && (
        <div className="px-4 py-3 bg-red-50 border border-red-100 rounded-xl text-sm text-red-700">
          <span className="font-semibold">Rejection reason: </span>{doc.rejectionReason}
        </div>
      )}

      {/* Pending actions */}
      {isPending && !showReject && (
        <div className="flex gap-2 pt-1">
          <button
            onClick={onApprove}
            disabled={approving}
            className="flex-1 py-2 rounded-xl bg-[#E8007D] text-white text-sm font-semibold hover:bg-[#cc006e] transition-colors disabled:opacity-50"
          >
            {approving ? 'Approving…' : 'Approve'}
          </button>
          <button
            onClick={() => setShowReject(true)}
            className="flex-1 py-2 rounded-xl border border-red-200 text-red-600 text-sm font-semibold hover:bg-red-50 transition-colors"
          >
            Reject
          </button>
        </div>
      )}

      {/* Inline reject form */}
      {isPending && showReject && (
        <div className="space-y-3 pt-1">
          <textarea
            value={reason}
            onChange={e => setReason(e.target.value)}
            placeholder="Reason for rejection (optional)"
            rows={2}
            className="w-full px-4 py-2 rounded-xl border border-[#f0d6e8] bg-[#fdf5f9] text-sm text-[#0f172a] focus:outline-none focus:ring-2 focus:ring-[#E8007D]/30 focus:border-[#E8007D] resize-none"
          />
          <div className="flex gap-2">
            <button
              onClick={() => { onReject?.(reason); setShowReject(false); setReason(''); }}
              disabled={rejecting}
              className="flex-1 py-2 rounded-xl bg-red-600 text-white text-sm font-semibold hover:bg-red-700 transition-colors disabled:opacity-50"
            >
              {rejecting ? 'Rejecting…' : 'Confirm rejection'}
            </button>
            <button
              onClick={() => { setShowReject(false); setReason(''); }}
              className="flex-1 py-2 rounded-xl border border-[#f0d6e8] text-[#64748b] text-sm font-semibold hover:bg-[#fdf5f9] transition-colors"
            >
              Cancel
            </button>
          </div>
        </div>
      )}
    </div>
  );
}

function Detail({ label, value }: { label: string; value: string }) {
  return (
    <div>
      <p className="text-[#64748b] text-xs">{label}</p>
      <p className="text-[#0f172a] font-medium">{value}</p>
    </div>
  );
}

export default function AdminDashboardPage() {
  const [tab, setTab] = useState<Tab>('PENDING');
  const { clearAuth } = useAuth();
  const navigate = useNavigate();
  const qc = useQueryClient();

  const { data: all = [], isLoading, isError } = useQuery({
    queryKey: ['admin-doctors'],
    queryFn: getAllDoctors,
  });

  const approveMutation = useMutation({
    mutationFn: approveDoctor,
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-doctors'] }),
  });

  const rejectMutation = useMutation({
    mutationFn: ({ id, reason }: { id: string; reason: string }) => rejectDoctor(id, reason),
    onSuccess: () => qc.invalidateQueries({ queryKey: ['admin-doctors'] }),
  });

  const byStatus = (status: Tab) => all.filter(d => d.doctorStatus === status);

  const TABS: { key: Tab; label: string }[] = [
    { key: 'PENDING',  label: 'Pending' },
    { key: 'APPROVED', label: 'Approved' },
    { key: 'REJECTED', label: 'Rejected' },
  ];

  const visible = byStatus(tab);

  return (
    <div className="min-h-screen bg-[#fdf5f9]">
      {/* Top bar */}
      <div className="bg-white border-b border-[#f0d6e8] px-8 py-4 flex items-center justify-between">
        <div className="flex items-center gap-3">
          <img src="/knevo-logo.png" alt="Knevo" className="w-9 h-9 rounded-xl object-cover" />
          <div>
            <p className="font-semibold text-[#0f172a] leading-tight">Knevo Admin</p>
            <p className="text-xs text-[#64748b]">Doctor management</p>
          </div>
        </div>
        <button
          onClick={() => { clearAuth(); navigate('/login'); }}
          className="text-sm text-[#64748b] hover:text-[#E8007D] font-medium transition-colors"
        >
          Sign out
        </button>
      </div>

      <div className="max-w-3xl mx-auto px-6 py-8">
        {/* Quick-access cards (same as doctor dashboard) */}
        <div className="grid grid-cols-3 gap-4 mb-8">
          {[
            { href: '/patients',  sub: 'Patients',  title: 'Patient list' },
            { href: '/exercises', sub: 'Library',   title: 'Exercise library' },
          ].map(({ href, sub, title }) => (
            <a key={href} href={href}
              className="block p-5 rounded-2xl border border-[#f0d6e8] bg-white hover:border-[#E8007D] hover:shadow-knevo transition-all">
              <p className="text-xs text-[#64748b] mb-1">{sub}</p>
              <p className="font-bold text-[#0f172a]">{title}</p>
              <p className="text-[#E8007D] text-xs font-semibold mt-2">Open →</p>
            </a>
          ))}
        </div>

        <h1 className="text-2xl font-bold text-[#0f172a] mb-6">Doctor Accounts</h1>

        {/* Tabs */}
        <div className="flex gap-1 bg-white border border-[#f0d6e8] rounded-2xl p-1 mb-6 w-fit">
          {TABS.map(({ key, label }) => (
            <button
              key={key}
              onClick={() => setTab(key)}
              className={`px-5 py-2 rounded-xl text-sm font-semibold transition-colors ${
                tab === key
                  ? 'bg-[#E8007D] text-white shadow-sm'
                  : 'text-[#64748b] hover:text-[#0f172a]'
              }`}
            >
              {label}
              {byStatus(key).length > 0 && (
                <span className={`ml-2 text-xs px-1.5 py-0.5 rounded-full ${
                  tab === key ? 'bg-white/20' : 'bg-[#f0d6e8] text-[#E8007D]'
                }`}>
                  {byStatus(key).length}
                </span>
              )}
            </button>
          ))}
        </div>

        {/* Content */}
        {isLoading && <p className="text-[#64748b]">Loading…</p>}
        {isError  && <p className="text-red-600 text-sm">Failed to load doctors. Make sure you are signed in as admin.</p>}

        {!isLoading && !isError && visible.length === 0 && (
          <div className="bg-white rounded-2xl border border-[#f0d6e8] p-10 text-center">
            <p className="text-[#64748b]">No {tab.toLowerCase()} doctors.</p>
          </div>
        )}

        <div className="space-y-4">
          {visible.map(doc => (
            <DoctorCard
              key={doc.id}
              doc={doc}
              onApprove={() => approveMutation.mutate(doc.id)}
              onReject={(reason) => rejectMutation.mutate({ id: doc.id, reason })}
              approving={approveMutation.isPending && approveMutation.variables === doc.id}
              rejecting={rejectMutation.isPending && rejectMutation.variables?.id === doc.id}
            />
          ))}
        </div>
      </div>
    </div>
  );
}

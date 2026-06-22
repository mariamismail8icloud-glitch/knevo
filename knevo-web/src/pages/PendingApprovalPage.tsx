export default function PendingApprovalPage() {
  return (
    <div className="min-h-screen flex items-center justify-center p-6" style={{ background: 'linear-gradient(to bottom, #fff5fa, #fdf5f9)' }}>
      <div className="w-full max-w-md bg-white/90 backdrop-blur border border-[#f0d6e8] rounded-3xl p-9 shadow-knevo text-center">
        <div className="w-16 h-16 rounded-full bg-[#fce8f3] flex items-center justify-center mx-auto mb-6">
          <svg className="w-8 h-8 text-[#E8007D]" fill="none" viewBox="0 0 24 24" stroke="currentColor">
            <path strokeLinecap="round" strokeLinejoin="round" strokeWidth={2} d="M12 8v4l3 3m6-3a9 9 0 11-18 0 9 9 0 0118 0z" />
          </svg>
        </div>
        <h2 className="text-2xl font-bold text-[#0f172a] mb-3">Account under review</h2>
        <p className="text-[#64748b] mb-6">Your registration has been submitted. The clinic admin will review your account. You will be able to log in once approved.</p>
        <a href="/login" className="text-[#E8007D] font-semibold hover:underline text-sm">Back to login</a>
      </div>
    </div>
  );
}

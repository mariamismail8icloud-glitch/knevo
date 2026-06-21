export default function SignupPage() {
  return (
    <div className="min-h-screen flex items-center justify-center p-6" style={{background: 'linear-gradient(to bottom, #fff5fa, #fdf5f9)'}}>
      <div className="w-full max-w-md bg-white/90 backdrop-blur border border-[#f0d6e8] rounded-3xl p-9 shadow-knevo">
        <div className="flex items-center gap-3 mb-6">
          <div className="w-12 h-12 rounded-2xl bg-gradient-to-br from-[#ff4da6] to-[#E8007D] flex items-center justify-center text-white font-bold text-xl">K</div>
          <div>
            <h1 className="text-xl font-semibold text-[#0f172a]">Knevo</h1>
            <p className="text-sm text-[#64748b]">Doctor Portal</p>
          </div>
        </div>
        <h2 className="text-2xl font-bold text-[#0f172a] mb-2">Create account</h2>
        <p className="text-[#64748b] mb-6">Register as a physiotherapist</p>
        <p className="text-[#64748b] text-sm">Signup form coming in M2.</p>
        <p className="text-center text-sm text-[#64748b] mt-6">
          Already have an account?{' '}
          <a href="/login" className="text-[#E8007D] font-semibold hover:underline">Sign In</a>
        </p>
      </div>
    </div>
  );
}

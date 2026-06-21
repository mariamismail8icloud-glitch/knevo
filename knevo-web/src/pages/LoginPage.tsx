export default function LoginPage() {
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
        <h2 className="text-2xl font-bold text-[#0f172a] mb-2">Welcome back</h2>
        <p className="text-[#64748b] mb-6">Sign in to your account</p>
        <div className="space-y-4">
          <div>
            <label className="block text-sm font-semibold text-[#334155] mb-2">Email</label>
            <input type="email" placeholder="doctor@clinic.com" className="w-full px-4 py-3 rounded-2xl border border-[#f0d6e8] bg-[#fdf5f9] focus:outline-none focus:ring-2 focus:ring-[#E8007D]/30 focus:border-[#E8007D] text-[#0f172a]" />
          </div>
          <div>
            <label className="block text-sm font-semibold text-[#334155] mb-2">Password</label>
            <input type="password" placeholder="••••••••" className="w-full px-4 py-3 rounded-2xl border border-[#f0d6e8] bg-[#fdf5f9] focus:outline-none focus:ring-2 focus:ring-[#E8007D]/30 focus:border-[#E8007D] text-[#0f172a]" />
          </div>
          <button className="w-full py-3 rounded-2xl bg-[#E8007D] text-white font-semibold hover:bg-[#cc006e] transition-colors mt-2">
            Sign In
          </button>
        </div>
        <p className="text-center text-sm text-[#64748b] mt-6">
          Don&apos;t have an account?{' '}
          <a href="/signup" className="text-[#E8007D] font-semibold hover:underline">Sign Up</a>
        </p>
      </div>
    </div>
  );
}

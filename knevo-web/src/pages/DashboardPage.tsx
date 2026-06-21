export default function DashboardPage() {
  return (
    <div className="min-h-screen bg-[#fdf5f9] p-8">
      <div className="max-w-6xl mx-auto">
        <div className="flex items-center gap-3 mb-8">
          <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#ff4da6] to-[#E8007D] flex items-center justify-center text-white font-bold">K</div>
          <h1 className="text-2xl font-bold text-[#0f172a]">Knevo Dashboard</h1>
        </div>
        <div className="bg-white rounded-2xl border border-[#f0d6e8] p-8 shadow-knevo">
          <h2 className="text-lg font-semibold text-[#0f172a] mb-2">Welcome</h2>
          <p className="text-[#64748b]">Dashboard content coming soon.</p>
        </div>
      </div>
    </div>
  );
}

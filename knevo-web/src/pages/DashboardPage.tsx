import { useAuth } from '../context/AuthContext';
import { useNavigate } from 'react-router-dom';

export default function DashboardPage() {
  const { userId, role, clearAuth } = useAuth();
  const navigate = useNavigate();

  const handleLogout = () => {
    clearAuth();
    navigate('/login');
  };

  return (
    <div className="min-h-screen bg-[#fdf5f9] p-8">
      <div className="max-w-6xl mx-auto">
        <div className="flex items-center justify-between mb-8">
          <div className="flex items-center gap-3">
            <div className="w-10 h-10 rounded-xl bg-gradient-to-br from-[#ff4da6] to-[#E8007D] flex items-center justify-center text-white font-bold">K</div>
            <h1 className="text-2xl font-bold text-[#0f172a]">Knevo</h1>
          </div>
          <button
            onClick={handleLogout}
            className="px-4 py-2 rounded-xl border border-[#f0d6e8] text-[#64748b] hover:bg-[#fce8f3] hover:text-[#E8007D] transition-colors text-sm font-medium"
          >
            Sign Out
          </button>
        </div>
        <div className="bg-white rounded-2xl border border-[#f0d6e8] p-8 shadow-knevo">
          <h2 className="text-lg font-semibold text-[#0f172a] mb-2">Dashboard</h2>
          {userId ? (
            <p className="text-[#64748b]">Signed in as <strong>{role}</strong> ({userId})</p>
          ) : (
            <p className="text-[#64748b]">Loading…</p>
          )}
        </div>
        <div className="grid grid-cols-1 md:grid-cols-2 gap-4 mt-4">
          <a href="/patients" className="block p-6 rounded-2xl border border-[#f0d6e8] bg-white hover:border-[#E8007D] hover:shadow-knevo transition-all">
            <p className="text-sm text-[#64748b] mb-1">Patients</p>
            <p className="text-2xl font-bold text-[#0f172a]">My patients</p>
            <p className="text-[#E8007D] text-sm font-semibold mt-2">View all →</p>
          </a>
          <a href="/exercises" className="block p-6 rounded-2xl border border-[#f0d6e8] bg-white hover:border-[#E8007D] hover:shadow-knevo transition-all">
            <p className="text-sm text-[#64748b] mb-1">Library</p>
            <p className="text-2xl font-bold text-[#0f172a]">Exercise library</p>
            <p className="text-[#E8007D] text-sm font-semibold mt-2">Browse →</p>
          </a>
        </div>
      </div>
    </div>
  );
}

import { useState } from 'react';
import { useNavigate } from 'react-router-dom';
import { useMutation } from '@tanstack/react-query';
import { login } from '../api/authApi';
import { useAuth } from '../context/AuthContext';

export default function LoginPage() {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const { setAuth } = useAuth();
  const navigate = useNavigate();

  const mutation = useMutation({
    mutationFn: login,
    onSuccess: (data) => {
      setAuth({ accessToken: data.accessToken, userId: data.userId, role: data.role, name: data.name, refreshToken: data.refreshToken });
      navigate(data.role === 'ADMIN' ? '/admin' : '/dashboard');
    },
    onError: (err: unknown) => {
      const status = (err as { response?: { status?: number; data?: { message?: string } } })?.response?.status;
      if (status === 403) {
        navigate('/pending-approval');
        return;
      }
      const msg = (err as { response?: { data?: { message?: string } } })?.response?.data?.message;
      setError(msg ?? 'Invalid email or password');
    },
  });

  const handleSubmit = (e: React.FormEvent) => {
    e.preventDefault();
    setError('');
    mutation.mutate({ email, password });
  };

  return (
    <div className="min-h-screen flex items-center justify-center p-6" style={{ background: 'linear-gradient(to bottom, #fff5fa, #fdf5f9)' }}>
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

        {error && (
          <div className="mb-4 px-4 py-3 bg-red-50 border border-red-200 rounded-2xl text-red-700 text-sm">{error}</div>
        )}

        <form onSubmit={handleSubmit} className="space-y-4">
          <div>
            <label className="block text-sm font-semibold text-[#334155] mb-2">Email</label>
            <input
              type="email"
              value={email}
              onChange={e => setEmail(e.target.value)}
              placeholder="doctor@clinic.com"
              required
              className="w-full px-4 py-3 rounded-2xl border border-[#f0d6e8] bg-[#fdf5f9] focus:outline-none focus:ring-2 focus:ring-[#E8007D]/30 focus:border-[#E8007D] text-[#0f172a]"
            />
          </div>
          <div>
            <label className="block text-sm font-semibold text-[#334155] mb-2">Password</label>
            <input
              type="password"
              value={password}
              onChange={e => setPassword(e.target.value)}
              placeholder="••••••••"
              required
              className="w-full px-4 py-3 rounded-2xl border border-[#f0d6e8] bg-[#fdf5f9] focus:outline-none focus:ring-2 focus:ring-[#E8007D]/30 focus:border-[#E8007D] text-[#0f172a]"
            />
          </div>
          <button
            type="submit"
            disabled={mutation.isPending}
            className="w-full py-3 rounded-2xl bg-[#E8007D] text-white font-semibold hover:bg-[#cc006e] transition-colors mt-2 disabled:opacity-60"
          >
            {mutation.isPending ? 'Signing in…' : 'Sign In'}
          </button>
        </form>
        <p className="text-center text-sm text-[#64748b] mt-6">
          Don&apos;t have an account?{' '}
          <a href="/doctor-signup" className="text-[#E8007D] font-semibold hover:underline">Sign Up</a>
        </p>
      </div>
    </div>
  );
}

import { Navigate, Outlet } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';

export default function PrivateRoute() {
  const { isAuthenticated } = useAuth();
  return isAuthenticated ? <Outlet /> : <Navigate to="/login" replace />;
}

export function RoleRoute({ allowed }: { allowed: string[] }) {
  const { isAuthenticated, role } = useAuth();
  if (!isAuthenticated) return <Navigate to="/login" replace />;
  if (!role || !allowed.includes(role)) return <Navigate to={role === 'ADMIN' ? '/admin' : '/dashboard'} replace />;
  return <Outlet />;
}

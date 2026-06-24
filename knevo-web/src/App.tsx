import { useEffect } from 'react';
import { BrowserRouter, Routes, Route, Navigate, useNavigate } from 'react-router-dom';
import { QueryClientProvider } from '@tanstack/react-query';
import { queryClient } from './lib/queryClient';
import { AuthProvider, useAuth } from './context/AuthContext';
import { registerUnauthorizedHandler } from './api/client';
import PrivateRoute, { RoleRoute } from './components/PrivateRoute';
import LoginPage from './pages/LoginPage';
import SignupPage from './pages/SignupPage';
import DashboardPage from './pages/DashboardPage';
import DoctorSignupPage from './pages/DoctorSignupPage';
import PendingApprovalPage from './pages/PendingApprovalPage';
import AdminDashboardPage from './pages/admin/AdminDashboardPage';
import PatientListPage from './pages/doctor/PatientListPage';
import ExerciseLibraryPage from './pages/doctor/ExerciseLibraryPage';
import CreatePlanPage from './pages/doctor/CreatePlanPage';
import PatientDetailPage from './pages/doctor/PatientDetailPage';
import MessagesPage from './pages/doctor/MessagesPage';

function AppRoutes() {
  const { clearAuth } = useAuth();
  const navigate = useNavigate();

  useEffect(() => {
    registerUnauthorizedHandler(() => {
      clearAuth();
      navigate('/login', { replace: true });
    });
  }, [clearAuth, navigate]);

  return (
    <Routes>
      <Route path="/login" element={<LoginPage />} />
      <Route path="/signup" element={<SignupPage />} />
      <Route path="/doctor-signup" element={<DoctorSignupPage />} />
      <Route path="/pending-approval" element={<PendingApprovalPage />} />

      <Route element={<PrivateRoute />}>
        <Route path="/dashboard" element={<DashboardPage />} />
        <Route path="/admin" element={<AdminDashboardPage />} />
        <Route path="/admin/dashboard" element={<AdminDashboardPage />} />
        <Route path="/patients" element={<PatientListPage />} />
        <Route path="/patients/:patientId" element={<PatientDetailPage />} />
        <Route path="/exercises" element={<ExerciseLibraryPage />} />
        <Route path="/create-plan" element={<CreatePlanPage />} />
        <Route element={<RoleRoute allowed={['DOCTOR', 'PATIENT']} />}>
          <Route path="/messages" element={<MessagesPage />} />
        </Route>
      </Route>

      <Route path="/" element={<Navigate to="/login" replace />} />
    </Routes>
  );
}

function App() {
  return (
    <QueryClientProvider client={queryClient}>
      <AuthProvider>
        <BrowserRouter>
          <AppRoutes />
        </BrowserRouter>
      </AuthProvider>
    </QueryClientProvider>
  );
}

export default App;

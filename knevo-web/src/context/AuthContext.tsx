/* eslint-disable react-refresh/only-export-components */
import { createContext, useContext, useState } from 'react';
import type { ReactNode } from 'react';
import { queryClient } from '../lib/queryClient';

interface AuthState {
  accessToken: string | null;
  userId: string | null;
  role: string | null;
}

interface AuthContextType extends AuthState {
  setAuth: (state: AuthState) => void;
  clearAuth: () => void;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  const [auth, setAuthState] = useState<AuthState>({
    accessToken: sessionStorage.getItem('accessToken'),
    userId: sessionStorage.getItem('userId'),
    role: sessionStorage.getItem('role'),
  });

  const setAuth = (state: AuthState) => {
    setAuthState(state);
    if (state.accessToken) {
      sessionStorage.setItem('accessToken', state.accessToken);
      if (state.userId) sessionStorage.setItem('userId', state.userId);
      if (state.role) sessionStorage.setItem('role', state.role);
    } else {
      sessionStorage.removeItem('accessToken');
      sessionStorage.removeItem('userId');
      sessionStorage.removeItem('role');
    }
  };

  const clearAuth = () => {
    setAuthState({ accessToken: null, userId: null, role: null });
    sessionStorage.removeItem('accessToken');
    sessionStorage.removeItem('userId');
    sessionStorage.removeItem('role');
    queryClient.clear();
  };

  return (
    <AuthContext.Provider value={{ ...auth, setAuth, clearAuth, isAuthenticated: !!auth.accessToken }}>
      {children}
    </AuthContext.Provider>
  );
}

export function useAuth() {
  const ctx = useContext(AuthContext);
  if (!ctx) throw new Error('useAuth must be used within AuthProvider');
  return ctx;
}

/* eslint-disable react-refresh/only-export-components */
import { createContext, useContext, useState, useEffect, useCallback } from 'react';
import type { ReactNode } from 'react';
import { queryClient } from '../lib/queryClient';
import { setAccessToken, registerRefreshHandler } from '../api/client';
import { refreshTokens } from '../api/authApi';

interface AuthState {
  accessToken: string | null;
  userId: string | null;
  role: string | null;
  name: string | null;
}

interface SetAuthPayload extends AuthState {
  refreshToken?: string;
}

interface AuthContextType extends AuthState {
  setAuth: (payload: SetAuthPayload) => void;
  clearAuth: () => void;
  isAuthenticated: boolean;
}

const AuthContext = createContext<AuthContextType | null>(null);

export function AuthProvider({ children }: { children: ReactNode }) {
  // Access token is intentionally NOT persisted to storage — B3 fix.
  // userId/role are non-sensitive metadata kept in sessionStorage for UX continuity.
  const [auth, setAuthState] = useState<AuthState>({
    accessToken: null,
    userId: sessionStorage.getItem('userId'),
    role: sessionStorage.getItem('role'),
    name: sessionStorage.getItem('name'),
  });

  // True while we wait for an auto-refresh attempt on page load.
  const [isLoading, setIsLoading] = useState(!!localStorage.getItem('refreshToken'));

  const setAuth = useCallback((payload: SetAuthPayload) => {
    const { refreshToken, ...state } = payload;
    setAuthState(state);
    setAccessToken(state.accessToken);
    if (state.userId) sessionStorage.setItem('userId', state.userId);
    if (state.role) sessionStorage.setItem('role', state.role);
    if (state.name) sessionStorage.setItem('name', state.name);
    if (refreshToken) localStorage.setItem('refreshToken', refreshToken);
  }, []);

  const clearAuth = useCallback(() => {
    setAuthState({ accessToken: null, userId: null, role: null, name: null });
    setAccessToken(null);
    sessionStorage.removeItem('userId');
    sessionStorage.removeItem('role');
    sessionStorage.removeItem('name');
    localStorage.removeItem('refreshToken');
    queryClient.clear();
  }, []);

  // On page load: restore session from stored refresh token.
  useEffect(() => {
    const stored = localStorage.getItem('refreshToken');
    if (!stored) return;

    refreshTokens(stored)
      .then(res => {
        setAuth({
          accessToken: res.accessToken,
          userId: res.userId,
          role: res.role,
          name: res.name,
          refreshToken: res.refreshToken,
        });
      })
      .catch(() => clearAuth())
      .finally(() => setIsLoading(false));
  }, []); // eslint-disable-line react-hooks/exhaustive-deps

  // Register the token-refresh handler used by the 401 interceptor.
  useEffect(() => {
    registerRefreshHandler(async () => {
      const stored = localStorage.getItem('refreshToken');
      if (!stored) return null;
      try {
        const res = await refreshTokens(stored);
        setAuth({
          accessToken: res.accessToken,
          userId: res.userId,
          role: res.role,
          name: res.name,
          refreshToken: res.refreshToken,
        });
        return res.accessToken;
      } catch {
        return null;
      }
    });
  }, [setAuth]);

  if (isLoading) {
    return (
      <div className="flex items-center justify-center min-h-screen bg-[#fdf5f9]">
        <div className="w-8 h-8 border-4 border-[#E8007D] border-t-transparent rounded-full animate-spin" />
      </div>
    );
  }

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

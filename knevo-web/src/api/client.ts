import axios from 'axios';
import { API_BASE_URL } from '../config/api';

// Module-level token — avoids reading access token from storage on every request
let currentAccessToken: string | null = null;

type RefreshFn = () => Promise<string | null>;
let refreshFn: RefreshFn | null = null;
let unauthorizedFn: (() => void) | null = null;

export function setAccessToken(token: string | null) {
  currentAccessToken = token;
}

export function registerRefreshHandler(fn: RefreshFn) {
  refreshFn = fn;
}

export function registerUnauthorizedHandler(fn: () => void) {
  unauthorizedFn = fn;
}

const client = axios.create({ baseURL: API_BASE_URL });

client.interceptors.request.use(config => {
  if (currentAccessToken) config.headers.Authorization = `Bearer ${currentAccessToken}`;
  return config;
});

client.interceptors.response.use(
  response => response,
  async error => {
    const original = error.config;
    if (error.response?.status === 401 && !original._retry) {
      original._retry = true;
      if (refreshFn) {
        const newToken = await refreshFn();
        if (newToken) {
          original.headers.Authorization = `Bearer ${newToken}`;
          return client(original);
        }
      }
      if (unauthorizedFn) unauthorizedFn();
    }
    return Promise.reject(error);
  }
);

export default client;

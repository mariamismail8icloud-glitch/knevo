import axios from 'axios';
import { API_BASE_URL } from '../config/api';

type Handler = () => void;
let unauthorizedHandler: Handler | null = null;

export function registerUnauthorizedHandler(fn: Handler) {
  unauthorizedHandler = fn;
}

const client = axios.create({ baseURL: API_BASE_URL });

client.interceptors.request.use(config => {
  const token = sessionStorage.getItem('accessToken');
  if (token) config.headers.Authorization = `Bearer ${token}`;
  return config;
});

client.interceptors.response.use(
  response => response,
  error => {
    if (error.response?.status === 401) {
      if (unauthorizedHandler) unauthorizedHandler();
    }
    return Promise.reject(error);
  }
);

export default client;

import '@testing-library/jest-dom';

// jsdom in this environment doesn't expose localStorage without a real origin.
// Provide a working in-memory mock so components that use localStorage compile
// and run correctly in unit tests.
const makeStorage = () => {
  let store: Record<string, string> = {};
  return {
    getItem: (k: string) => store[k] ?? null,
    setItem: (k: string, v: string) => { store[k] = String(v); },
    removeItem: (k: string) => { delete store[k]; },
    clear: () => { store = {}; },
    get length() { return Object.keys(store).length; },
    key: (i: number) => Object.keys(store)[i] ?? null,
  };
};

Object.defineProperty(window, 'localStorage', { value: makeStorage(), writable: true });

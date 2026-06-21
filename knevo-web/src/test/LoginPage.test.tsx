import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import LoginPage from '../pages/LoginPage';

describe('LoginPage', () => {
  it('renders sign in heading', () => {
    render(
      <MemoryRouter>
        <LoginPage />
      </MemoryRouter>
    );
    expect(screen.getByText('Welcome back')).toBeInTheDocument();
    expect(screen.getByText('Sign In')).toBeInTheDocument();
  });
});

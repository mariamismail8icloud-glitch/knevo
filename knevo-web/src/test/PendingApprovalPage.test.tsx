import { render, screen } from '@testing-library/react';
import { describe, it, expect } from 'vitest';
import { MemoryRouter } from 'react-router-dom';
import PendingApprovalPage from '../pages/PendingApprovalPage';

describe('PendingApprovalPage', () => {
  it('shows pending message', () => {
    render(<MemoryRouter><PendingApprovalPage /></MemoryRouter>);
    expect(screen.getByText('Account under review')).toBeInTheDocument();
  });
});

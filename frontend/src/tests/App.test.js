import { render, screen } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import TierGate from '../components/TierGate';
import { useAuth } from '../context/AuthContext';

jest.mock('../context/AuthContext', () => ({
  useAuth: jest.fn(),
}));

describe('TierGate', () => {
  beforeEach(() => {
    jest.clearAllMocks();
  });

  it('renders gated content when the user plan is allowed', () => {
    useAuth.mockReturnValue({ user: { plan: 'pro' }, loading: false });

    render(
      <MemoryRouter>
        <TierGate allowed={['pro', 'elite']} featureName="Investing">
          <div data-testid="gated-content">Gated Content</div>
        </TierGate>
      </MemoryRouter>
    );

    expect(screen.getByTestId('gated-content')).toBeInTheDocument();
    expect(screen.queryByText(/requires pro/i)).not.toBeInTheDocument();
  });

  it('shows the Pro upgrade prompt for a Basic user', () => {
    useAuth.mockReturnValue({ user: { plan: 'basic' }, loading: false });

    render(
      <MemoryRouter>
        <TierGate allowed={['pro', 'elite']} featureName="Investing">
          <div data-testid="gated-content">Gated Content</div>
        </TierGate>
      </MemoryRouter>
    );

    expect(screen.queryByTestId('gated-content')).not.toBeInTheDocument();
    expect(screen.getByText('Investing requires Pro')).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /upgrade to pro/i })).toHaveAttribute(
      'href',
      '/app/pricing'
    );
  });

  it('shows the Elite upgrade prompt for an Elite-only feature', () => {
    useAuth.mockReturnValue({ user: { plan: 'pro' }, loading: false });

    render(
      <MemoryRouter>
        <TierGate allowed={['elite']} featureName="Automatic Tax Filing">
          <div data-testid="gated-content">Gated Content</div>
        </TierGate>
      </MemoryRouter>
    );

    expect(screen.queryByTestId('gated-content')).not.toBeInTheDocument();
    expect(
      screen.getByText('Automatic Tax Filing requires Elite')
    ).toBeInTheDocument();
    expect(screen.getByRole('link', { name: /upgrade to elite/i })).toHaveAttribute(
      'href',
      '/app/pricing'
    );
  });
});

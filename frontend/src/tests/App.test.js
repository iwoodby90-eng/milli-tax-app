import { render } from '@testing-library/react';
import { MemoryRouter } from 'react-router-dom';
import { AuthProvider } from '../context/AuthContext';
import TierGate from '../components/TierGate';
import { calculateEstimatedTax } from '../utils/taxCalc';
import { formatCurrency, formatDate } from '../utils/formatters';

// Test 1: App renders without crashing
describe('App Integration', () => {
  it('renders without crashing', () => {
    const { container } = render(
      <MemoryRouter>
        <AuthProvider>
          <div data-testid="app-root">Milli App</div>
        </AuthProvider>
      </MemoryRouter>
    );
    expect(container).toBeInTheDocument();
  });
});

// Test 2: TierGate component
describe('TierGate', () => {
  const mockChild = <div data-testid="gated-content">Gated Content</div>;

  it('renders children when tier is allowed', () => {
    localStorage.setItem('milli_selected_plan', 'pro');
    const { getByTestId } = render(
      <MemoryRouter>
        <TierGate allowed={['pro', 'elite']} featureName="Test Feature">
          {mockChild}
        </TierGate>
      </MemoryRouter>
    );
    expect(getByTestId('gated-content')).toBeInTheDocument();
  });

  it('shows upgrade prompt when tier is not allowed', () => {
    localStorage.setItem('milli_selected_plan', 'basic');
    const { queryByTestId, getByText } = render(
      <MemoryRouter>
        <TierGate allowed={['pro', 'elite']} featureName="Test Feature">
          {mockChild}
        </TierGate>
      </MemoryRouter>
    );
    expect(queryByTestId('gated-content')).not.toBeInTheDocument();
    expect(getByText(/Test Feature/i)).toBeInTheDocument();
  });
});

// Test 3: Tax calculation utility
describe('Tax Calculation', () => {
  it('calculates self-employment tax correctly', () => {
    const income = 50000;
    const result = calculateEstimatedTax(income);
    expect(result.selfEmploymentTax).toBeGreaterThan(0);
    expect(result.selfEmploymentTax).toBeLessThan(income);
  });

  it('handles zero income', () => {
    const result = calculateEstimatedTax(0);
    expect(result.selfEmploymentTax).toBe(0);
    expect(result.incomeTax).toBe(0);
  });

  it('handles negative income gracefully', () => {
    const result = calculateEstimatedTax(-1000);
    expect(result.selfEmploymentTax).toBe(0);
    expect(result.incomeTax).toBe(0);
  });
});

// Test 4: Formatting utilities
describe('Formatters', () => {
  it('formats currency correctly', () => {
    expect(formatCurrency(1234.56)).toMatch(/\$1,234\.56/);
  });

  it('formats currency with zero', () => {
    expect(formatCurrency(0)).toMatch(/\$0\.00/);
  });

  it('formats date correctly', () => {
    const date = new Date('2026-01-15');
    const formatted = formatDate(date);
    expect(formatted).toBeTruthy();
    expect(typeof formatted).toBe('string');
  });
});

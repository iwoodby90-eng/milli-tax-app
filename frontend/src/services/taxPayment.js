/**
 * Tax Payment Processing Service
 * 
 * Handles federal and state tax payments via:
 * - IRS Direct Pay (bank account ACH)
 * - Card payments (debit/credit via payment processor)
 * - Quarterly estimated tax payments
 */

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8000';

/**
 * Process a tax payment via IRS Direct Pay (ACH bank transfer)
 * @param {Object} params - Payment parameters
 * @param {string} params.userId - User ID
 * @param {number} params.amount - Payment amount in dollars
 * @param {string} params.taxYear - Tax year (e.g. "2026")
 * @param {string} params.paymentType - 'estimated' | 'balance_due' | 'extension'
 * @param {string} params.quarter - Q1|Q2|Q3|Q4 (for estimated payments)
 * @param {Object} params.bankAccount - {routingNumber, accountNumber, accountType}
 * @returns {Promise<Object>} Payment confirmation
 */
export async function processIRSDirectPay({ userId, amount, taxYear, paymentType, quarter, bankAccount }) {
  const response = await fetch(`${API_BASE}/api/tax-payments/irs-direct`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      userId,
      amount,
      taxYear,
      paymentType,
      quarter,
      bankAccount: {
        routingNumber: bankAccount.routingNumber,
        accountNumber: bankAccount.accountNumber,
        accountType: bankAccount.accountType || 'checking',
      },
    }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Payment failed' }));
    throw new Error(error.detail || `IRS Direct Pay failed: ${response.statusText}`);
  }

  return response.json();
}

/**
 * Process a tax payment via card (debit/credit)
 * @param {Object} params - Payment parameters
 * @param {string} params.userId - User ID
 * @param {number} params.amount - Payment amount
 * @param {string} params.taxYear - Tax year
 * @param {string} params.paymentType - 'estimated' | 'balance_due' | 'extension'
 * @param {Object} params.card - {number, expMonth, expYear, cvv, zip}
 * @returns {Promise<Object>} Payment confirmation with confirmation number
 */
export async function processCardPayment({ userId, amount, taxYear, paymentType, card }) {
  const response = await fetch(`${API_BASE}/api/tax-payments/card`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      userId,
      amount,
      taxYear,
      paymentType,
      card: {
        number: card.number,
        expMonth: card.expMonth,
        expYear: card.expYear,
        cvv: card.cvv,
        zip: card.zip,
      },
    }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Card payment failed' }));
    throw new Error(error.detail || `Card payment failed: ${response.statusText}`);
  }

  return response.json();
}

/**
 * Get payment history for a user
 * @param {string} userId - User ID
 * @param {string} taxYear - Optional tax year filter
 * @returns {Promise<Array>} Payment history
 */
export async function getPaymentHistory(userId, taxYear = null) {
  const params = new URLSearchParams({ userId });
  if (taxYear) params.append('taxYear', taxYear);

  const response = await fetch(`${API_BASE}/api/tax-payments/history?${params}`);
  if (!response.ok) throw new Error('Failed to fetch payment history');
  return response.json();
}

/**
 * Schedule a future tax payment
 * @param {Object} params - Same as processIRSDirectPay plus paymentDate
 * @param {string} params.paymentDate - ISO date string for when to process
 * @returns {Promise<Object>} Scheduled payment confirmation
 */
export async function scheduleTaxPayment({ userId, amount, taxYear, paymentType, quarter, bankAccount, paymentDate }) {
  const response = await fetch(`${API_BASE}/api/tax-payments/schedule`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      userId,
      amount,
      taxYear,
      paymentType,
      quarter,
      bankAccount,
      paymentDate,
    }),
  });

  if (!response.ok) throw new Error('Failed to schedule payment');
  return response.json();
}

/**
 * Cancel a scheduled tax payment
 * @param {string} paymentId - Payment ID to cancel
 * @returns {Promise<Object>} Cancellation confirmation
 */
export async function cancelScheduledPayment(paymentId) {
  const response = await fetch(`${API_BASE}/api/tax-payments/${paymentId}/cancel`, {
    method: 'POST',
  });
  if (!response.ok) throw new Error('Failed to cancel payment');
  return response.json();
}

/**
 * Calculate quarterly estimated tax due dates
 * @param {number} year - Tax year
 * @returns {Array} Quarterly due dates
 */
export function getQuarterlyDueDates(year) {
  return [
    { quarter: 'Q1', label: 'Q1 (Jan-Mar)', dueDate: `${year}-04-15` },
    { quarter: 'Q2', label: 'Q2 (Apr-May)', dueDate: `${year}-06-15` },
    { quarter: 'Q3', label: 'Q3 (Jun-Aug)', dueDate: `${year}-09-15` },
    { quarter: 'Q4', label: 'Q4 (Sep-Dec)', dueDate: `${year + 1}-01-15` },
  ];
}

export default {
  processIRSDirectPay,
  processCardPayment,
  getPaymentHistory,
  scheduleTaxPayment,
  cancelScheduledPayment,
  getQuarterlyDueDates,
};
/**
 * E-Filing Service
 * 
 * Submits tax returns electronically via IRS Modernized e-File (MeF) API.
 * Supports Form 1040, Schedule C, Schedule SE, and state returns.
 */

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8000';

/**
 * Submit a federal tax return via e-file
 * @param {Object} params
 * @param {string} params.userId - User ID
 * @param {string} params.taxYear - Tax year
 * @param {Object} params.returnData - Full return data (1040 + schedules)
 * @param {Object} params.taxpayerInfo - {ssn, firstName, lastName, address, filingStatus}
 * @param {Object} params.bankInfo - Optional refund bank info for direct deposit
 * @returns {Promise<Object>} Filing confirmation with submission ID
 */
export async function submitFederalReturn({ userId, taxYear, returnData, taxpayerInfo, bankInfo }) {
  const response = await fetch(`${API_BASE}/api/efile/federal`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      userId,
      taxYear,
      returnData,
      taxpayer: {
        ssn: taxpayerInfo.ssn,
        firstName: taxpayerInfo.firstName,
        lastName: taxpayerInfo.lastName,
        address: taxpayerInfo.address,
        filingStatus: taxpayerInfo.filingStatus,
      },
      refundDeposit: bankInfo ? {
        routingNumber: bankInfo.routingNumber,
        accountNumber: bankInfo.accountNumber,
        accountType: bankInfo.accountType || 'checking',
      } : null,
    }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'E-file submission failed' }));
    throw new Error(error.detail || `E-file failed: ${response.statusText}`);
  }

  return response.json();
}

/**
 * Submit a state tax return via e-file
 * @param {Object} params
 * @param {string} params.userId - User ID
 * @param {string} params.state - Two-letter state code (e.g. 'CA')
 * @param {string} params.taxYear - Tax year
 * @param {Object} params.returnData - State return data
 * @returns {Promise<Object>} State filing confirmation
 */
export async function submitStateReturn({ userId, state, taxYear, returnData }) {
  const response = await fetch(`${API_BASE}/api/efile/state`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, state, taxYear, returnData }),
  });

  if (!response.ok) throw new Error('State e-file submission failed');
  return response.json();
}

/**
 * Check the status of a submitted return
 * @param {string} submissionId - IRS submission ID
 * @returns {Promise<Object>} Status update
 */
export async function checkFilingStatus(submissionId) {
  const response = await fetch(`${API_BASE}/api/efile/status/${submissionId}`);
  if (!response.ok) throw new Error('Failed to check filing status');
  return response.json();
}

/**
 * Get filing history for a user
 * @param {string} userId - User ID
 * @returns {Promise<Array>} Filing history
 */
export async function getFilingHistory(userId) {
  const response = await fetch(`${API_BASE}/api/efile/history?userId=${userId}`);
  if (!response.ok) throw new Error('Failed to fetch filing history');
  return response.json();
}

/**
 * Validate return data before submission
 * @param {Object} returnData - Return data to validate
 * @returns {Object} Validation result with errors/warnings
 */
export function validateReturn(returnData) {
  const errors = [];
  const warnings = [];

  if (!returnData.income || returnData.income < 0) {
    errors.push('Income must be a non-negative number');
  }
  if (!returnData.filingStatus) {
    errors.push('Filing status is required');
  }
  if (returnData.deductions && returnData.deductions < 0) {
    errors.push('Deductions cannot be negative');
  }
  if (returnData.income > 0 && !returnData.ssn) {
    errors.push('SSN is required for filing');
  }
  if (returnData.income > 100000 && !returnData.quarterlyPayments) {
    warnings.push('High income detected. Consider quarterly estimated tax payments.');
  }

  return { valid: errors.length === 0, errors, warnings };
}

export default {
  submitFederalReturn,
  submitStateReturn,
  checkFilingStatus,
  getFilingHistory,
  validateReturn,
};
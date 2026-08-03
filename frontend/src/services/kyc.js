/**
 * Identity Verification (KYC) Service
 * 
 * Integrates with Persona / Stripe Identity for:
 * - Government ID verification
 * - Selfie liveness check
 * - SSN verification
 * - Address verification
 * - Sanctions/PEP screening
 */

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8000';

/**
 * Start a KYC verification session
 * @param {string} userId - User ID
 * @param {Object} params - {firstName, lastName, dob, ssn, address}
 * @returns {Promise<Object>} Verification session with inquiry ID and redirect URL
 */
export async function startVerification(userId, { firstName, lastName, dob, ssn, address }) {
  const response = await fetch(`${API_BASE}/api/kyc/start`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({
      userId,
      firstName,
      lastName,
      dob,
      ssn,
      address,
    }),
  });

  if (!response.ok) throw new Error('Failed to start KYC verification');
  return response.json();
}

/**
 * Check KYC verification status
 * @param {string} userId - User ID
 * @returns {Promise<Object>} Verification status
 */
export async function checkVerificationStatus(userId) {
  const response = await fetch(`${API_BASE}/api/kyc/status?userId=${userId}`);
  if (!response.ok) throw new Error('Failed to check KYC status');
  return response.json();
}

/**
 * Get verification history
 * @param {string} userId - User ID
 * @returns {Promise<Array>} Verification history
 */
export async function getVerificationHistory(userId) {
  const response = await fetch(`${API_BASE}/api/kyc/history?userId=${userId}`);
  if (!response.ok) throw new Error('Failed to fetch KYC history');
  return response.json();
}

/**
 * Upload a document for manual verification
 * @param {string} userId - User ID
 * @param {Object} params - {documentType, documentImage (base64)}
 * @returns {Promise<Object>} Upload confirmation
 */
export async function uploadDocument(userId, { documentType, documentImage }) {
  const response = await fetch(`${API_BASE}/api/kyc/documents`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, documentType, documentImage }),
  });

  if (!response.ok) throw new Error('Failed to upload document');
  return response.json();
}

/**
 * Check if user is KYC verified (for gating features)
 * @param {string} userId - User ID
 * @returns {Promise<boolean>} True if verified
 */
export async function isVerified(userId) {
  try {
    const status = await checkVerificationStatus(userId);
    return status.status === 'verified' || status.status === 'completed';
  } catch {
    return false;
  }
}

export default {
  startVerification,
  checkVerificationStatus,
  getVerificationHistory,
  uploadDocument,
  isVerified,
};
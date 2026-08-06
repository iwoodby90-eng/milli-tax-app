/**
 * Biometric & MFA Authentication Service
 *
 * Provides:
 * - Face ID / Touch ID via Capacitor plugins
 * - TOTP-based MFA (Google Authenticator compatible)
 * - Social login (Apple, Google)
 * - Session management with refresh tokens
 */

import { Capacitor } from '@capacitor/core';

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8000';

/**
 * Check if biometric authentication is available on the device.
 * @returns {Promise<Object>} {available, biometryType}
 */
export async function checkBiometricAvailability() {
  if (!Capacitor.isNativePlatform()) {
    return { available: false, biometryType: 'none', reason: 'Web platform' };
  }

  try {
    const { NativeBiometric } = await import('@capgo/capacitor-native-biometric');
    const result = await NativeBiometric.isAvailable({ useFallback: true });

    return {
      available: Boolean(result.isAvailable),
      biometryType: result.biometryType ?? 0,
      authenticationStrength: result.authenticationStrength ?? 0,
      deviceIsSecure: Boolean(result.deviceIsSecure),
      strongBiometryIsAvailable: Boolean(result.strongBiometryIsAvailable),
      errorCode: result.errorCode,
    };
  } catch (error) {
    return {
      available: false,
      biometryType: 'none',
      reason: error instanceof Error ? error.message : 'Plugin not installed',
    };
  }
}

/**
 * Authenticate with biometrics (Face ID / Touch ID).
 * @returns {Promise<Object>} Authentication result
 */
export async function authenticateWithBiometrics() {
  if (!Capacitor.isNativePlatform()) {
    throw new Error('Biometric authentication is only available on native platforms');
  }

  const { NativeBiometric } = await import('@capgo/capacitor-native-biometric');

  await NativeBiometric.verifyIdentity({
    reason: 'Authenticate to access Milli',
    title: 'Unlock Milli',
    negativeButtonText: 'Cancel',
    useFallback: true,
    fallbackTitle: 'Use device passcode',
  });

  return { authenticated: true };
}

/**
 * Enable biometric login for the current user
 * @param {string} userId - User ID
 * @returns {Promise<Object>} Setup confirmation
 */
export async function enableBiometricLogin(userId) {
  const response = await fetch(`${API_BASE}/api/auth/biometric/enable`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId }),
  });

  if (!response.ok) throw new Error('Failed to enable biometric login');
  return response.json();
}

/**
 * Disable biometric login
 * @param {string} userId - User ID
 * @returns {Promise<Object>} Disable confirmation
 */
export async function disableBiometricLogin(userId) {
  const response = await fetch(`${API_BASE}/api/auth/biometric/disable`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId }),
  });

  if (!response.ok) throw new Error('Failed to disable biometric login');
  return response.json();
}

/**
 * Generate a TOTP secret for MFA setup
 * @param {string} userId - User ID
 * @returns {Promise<Object>} {secret, qrCodeUrl}
 */
export async function generateTOTPSecret(userId) {
  const response = await fetch(`${API_BASE}/api/auth/mfa/totp/setup`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId }),
  });

  if (!response.ok) throw new Error('Failed to generate TOTP secret');
  return response.json();
}

/**
 * Verify a TOTP code to complete MFA setup
 * @param {string} userId - User ID
 * @param {string} code - 6-digit TOTP code
 * @returns {Promise<Object>} Verification result
 */
export async function verifyTOTP(userId, code) {
  const response = await fetch(`${API_BASE}/api/auth/mfa/totp/verify`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, code }),
  });

  if (!response.ok) throw new Error('Invalid TOTP code');
  return response.json();
}

/**
 * Disable MFA for a user
 * @param {string} userId - User ID
 * @param {string} code - Current TOTP code for verification
 * @returns {Promise<Object>} Disable confirmation
 */
export async function disableMFA(userId, code) {
  const response = await fetch(`${API_BASE}/api/auth/mfa/disable`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, code }),
  });

  if (!response.ok) throw new Error('Failed to disable MFA');
  return response.json();
}

/**
 * Sign in with Apple
 * @param {Object} params - {identityToken, authorizationCode, user}
 * @returns {Promise<Object>} Auth tokens
 */
export async function signInWithApple({ identityToken, authorizationCode, user }) {
  const response = await fetch(`${API_BASE}/api/auth/apple`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ identityToken, authorizationCode, user }),
  });

  if (!response.ok) throw new Error('Apple sign-in failed');
  return response.json();
}

/**
 * Sign in with Google
 * @param {Object} params - {idToken, accessToken}
 * @returns {Promise<Object>} Auth tokens
 */
export async function signInWithGoogle({ idToken, accessToken }) {
  const response = await fetch(`${API_BASE}/api/auth/google`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ idToken, accessToken }),
  });

  if (!response.ok) throw new Error('Google sign-in failed');
  return response.json();
}

/**
 * Refresh auth token
 * @param {string} refreshToken - Refresh token
 * @returns {Promise<Object>} New auth tokens
 */
export async function refreshAuthToken(refreshToken) {
  const response = await fetch(`${API_BASE}/api/auth/refresh`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ refreshToken }),
  });

  if (!response.ok) throw new Error('Token refresh failed');
  return response.json();
}

/**
 * Check if biometric login is enabled for a user
 * @param {string} userId - User ID
 * @returns {Promise<boolean>} True if biometric is enabled
 */
export async function isBiometricEnabled(userId) {
  try {
    const response = await fetch(`${API_BASE}/api/auth/biometric/status?userId=${encodeURIComponent(userId)}`);
    if (!response.ok) return false;
    const data = await response.json();
    return Boolean(data.enabled);
  } catch {
    return false;
  }
}

export default {
  checkBiometricAvailability,
  authenticateWithBiometrics,
  enableBiometricLogin,
  disableBiometricLogin,
  generateTOTPSecret,
  verifyTOTP,
  disableMFA,
  signInWithApple,
  signInWithGoogle,
  refreshAuthToken,
  isBiometricEnabled,
};

import { Capacitor } from "@capacitor/core";
import { Preferences } from "@capacitor/preferences";

/**
 * Cross-platform persistence for non-secret application preferences.
 *
 * IMPORTANT: authentication tokens, bank credentials, and other secrets must
 * live in the iOS Keychain through a dedicated secure-storage plugin. This
 * module deliberately refuses keys that look secret so browser storage cannot
 * accidentally become the source of truth for sensitive data.
 */
const FORBIDDEN_KEY_PATTERN = /(token|secret|password|credential|refresh|access[_-]?key)/i;

function assertNonSecretKey(key) {
  if (!key || typeof key !== "string") {
    throw new TypeError("Storage key must be a non-empty string.");
  }
  if (FORBIDDEN_KEY_PATTERN.test(key)) {
    throw new Error(`Refusing to persist sensitive key '${key}' in Preferences.`);
  }
}

export async function getPreference(key) {
  assertNonSecretKey(key);

  if (Capacitor.isNativePlatform()) {
    const { value } = await Preferences.get({ key });
    return value;
  }

  try {
    return window.localStorage.getItem(key);
  } catch {
    return null;
  }
}

export async function setPreference(key, value) {
  assertNonSecretKey(key);
  const normalized = value == null ? "" : String(value);

  if (Capacitor.isNativePlatform()) {
    await Preferences.set({ key, value: normalized });
    return;
  }

  try {
    window.localStorage.setItem(key, normalized);
  } catch {
    // Private browsing and hardened browser contexts can reject persistence.
  }
}

export async function removePreference(key) {
  assertNonSecretKey(key);

  if (Capacitor.isNativePlatform()) {
    await Preferences.remove({ key });
    return;
  }

  try {
    window.localStorage.removeItem(key);
  } catch {
    // No-op when storage is unavailable.
  }
}

export async function getJSONPreference(key, fallback = null) {
  const value = await getPreference(key);
  if (!value) return fallback;

  try {
    return JSON.parse(value);
  } catch {
    await removePreference(key);
    return fallback;
  }
}

export async function setJSONPreference(key, value) {
  await setPreference(key, JSON.stringify(value));
}

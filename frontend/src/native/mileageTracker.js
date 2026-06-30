/**
 * Native background GPS mileage tracker (Capacitor).
 *
 * Uses @capacitor-community/background-geolocation for continuous tracking
 * while the app is in the background or screen is off (iOS + Android).
 * Falls back to a no-op on web — Mileage.jsx already handles the web case.
 */
import { Capacitor, registerPlugin } from '@capacitor/core';

// The plugin self-registers when imported as a named import, but we also
// grab the typed handle so we can call addWatcher / removeWatcher.
const BackgroundGeolocation = registerPlugin('BackgroundGeolocation');

const STORAGE_KEY = 'milli.activeTripWatcherId';

let onLocationCb = null;
let onErrorCb = null;

export function isNative() {
  return Capacitor.isNativePlatform();
}

/**
 * Start a background trip. The OS will keep the watcher alive even when the
 * app is backgrounded; iOS shows a persistent location indicator.
 *
 * @param {(loc:{latitude:number,longitude:number,speed:number,time:number}) => void} onLocation
 * @param {(err:Error) => void} onError
 * @returns {Promise<string>} watcher id
 */
export async function startTrip(onLocation, onError) {
  if (!isNative()) {
    throw new Error('Background GPS requires the native Milli app on iOS/Android.');
  }
  onLocationCb = onLocation;
  onErrorCb = onError;

  const id = await BackgroundGeolocation.addWatcher(
    {
      backgroundMessage: 'Milli is tracking your trip for tax-deductible miles.',
      backgroundTitle: 'Trip in progress',
      requestPermissions: true,
      stale: false,
      distanceFilter: 10, // meters
    },
    (location, error) => {
      if (error) {
        if (error.code === 'NOT_AUTHORIZED' && onErrorCb) {
          onErrorCb(new Error('Location permission denied. Enable “Always” in Settings.'));
        } else if (onErrorCb) {
          onErrorCb(error);
        }
        return;
      }
      if (location && onLocationCb) {
        onLocationCb({
          latitude: location.latitude,
          longitude: location.longitude,
          speed: location.speed ?? 0,
          time: location.time ?? Date.now(),
        });
      }
    }
  );

  window.localStorage.setItem(STORAGE_KEY, id);
  return id;
}

/** Stop the active trip watcher. */
export async function stopTrip() {
  if (!isNative()) return;
  const id = window.localStorage.getItem(STORAGE_KEY);
  if (!id) return;
  await BackgroundGeolocation.removeWatcher({ id });
  window.localStorage.removeItem(STORAGE_KEY);
  onLocationCb = null;
  onErrorCb = null;
}

/** Returns true if there is a persisted watcher id (trip was running). */
export function hasActiveTrip() {
  return !!window.localStorage.getItem(STORAGE_KEY);
}

/**
 * MilliVaultBridge — thin JS wrapper for the native iOS plugin.
 * On web this is a no-op so the same code paths work in preview.
 */
import { registerPlugin, Capacitor } from "@capacitor/core";

const noop = {
  async update(_v) { return { ok: false, web: true }; },
  async read()     { return { balance: 0, goal: 20000, month: 0, streak: 0, firstName: "", updated: 0 }; },
};

const MilliVaultBridge = Capacitor.isNativePlatform()
  ? registerPlugin("MilliVaultBridge")
  : noop;

export default MilliVaultBridge;

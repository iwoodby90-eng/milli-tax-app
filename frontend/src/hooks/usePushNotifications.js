/**
 * usePushNotifications — registers this device with APNs (or FCM) and
 * ships the token to /api/push/register so the backend can send
 * quarterly reminders, payout confirmations, and vault milestones.
 *
 * On the web (preview) this no-ops.
 */
import { useEffect } from "react";
import { Capacitor } from "@capacitor/core";
import { api } from "@/lib/api";

export function usePushNotifications(enabled = true) {
  useEffect(() => {
    if (!enabled) return;
    if (!Capacitor.isNativePlatform()) return;

    let mod;
    (async () => {
      try {
        mod = await import("@capacitor/push-notifications");
        const { PushNotifications } = mod;

        const perm = await PushNotifications.checkPermissions();
        let status = perm.receive;
        if (status !== "granted") {
          const r = await PushNotifications.requestPermissions();
          status = r.receive;
        }
        if (status !== "granted") return;

        await PushNotifications.register();

        PushNotifications.addListener("registration", async (t) => {
          try {
            await api.post("/push/register", {
              device_token: t.value,
              platform: Capacitor.getPlatform(),
            });
          } catch (_) { /* silent */ }
        });

        PushNotifications.addListener("registrationError", () => {
          /* silent — user can retry from Settings */
        });

        // In-app foreground handler (optional). Backend push service
        // will drive the actual notifications when apn cert is loaded.
        PushNotifications.addListener("pushNotificationReceived", () => {});
      } catch (_) { /* plugin missing = fine on web */ }
    })();
  }, [enabled]);
}

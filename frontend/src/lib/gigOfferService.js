import { api } from "@/lib/api";

export const OFFER_SOURCES = Object.freeze({
  OFFICIAL_API: "official_api",
  ANDROID_NOTIFICATION: "android_notification",
  IOS_SHARE: "ios_share",
  IOS_OCR: "ios_ocr",
  MANUAL: "manual",
});

const DEFAULT_ASSUMPTIONS = Object.freeze({
  gasPrice: 3.49,
  vehicleMpg: 24,
  taxRate: 25,
  vehicleCostPerMile: 0.18,
  minimumNetPerMile: 0.75,
  minimumNetPerHour: 20,
});

function number(value, fallback = 0) {
  const parsed = Number(value);
  return Number.isFinite(parsed) ? parsed : fallback;
}

export function normalizeGigOffer(raw = {}, assumptions = {}) {
  const merged = { ...DEFAULT_ASSUMPTIONS, ...assumptions };
  const pickupMiles = number(raw.pickupMiles ?? raw.pickup_miles);
  const routeMiles = number(raw.routeMiles ?? raw.route_miles ?? raw.deliveryMiles ?? raw.delivery_miles);
  const returnToBaseMiles = number(raw.returnToBaseMiles ?? raw.return_to_base_miles ?? raw.returnMiles);
  const estimatedMinutes = number(raw.estimatedMinutes ?? raw.estimated_minutes, 0);

  return {
    id: String(raw.id ?? raw.externalOfferId ?? raw.external_offer_id ?? `offer-${Date.now()}`),
    platform: String(raw.platform ?? "Connected platform"),
    offeredPay: number(raw.offeredPay ?? raw.offered_pay ?? raw.pay ?? raw.offerPrice),
    pickupMiles,
    routeMiles,
    returnToBaseMiles,
    estimatedMinutes,
    gasPrice: number(raw.gasPrice ?? raw.gas_price, merged.gasPrice),
    vehicleMpg: number(raw.vehicleMpg ?? raw.vehicle_mpg ?? raw.mpg, merged.vehicleMpg),
    taxRate: number(raw.taxRate ?? raw.tax_rate, merged.taxRate),
    vehicleCostPerMile: number(raw.vehicleCostPerMile ?? raw.vehicle_cost_per_mile, merged.vehicleCostPerMile),
    minimumNetPerMile: number(raw.minimumNetPerMile ?? raw.minimum_net_per_mile, merged.minimumNetPerMile),
    minimumNetPerHour: number(raw.minimumNetPerHour ?? raw.minimum_net_per_hour, merged.minimumNetPerHour),
    pickupLabel: raw.pickupLabel ?? raw.pickup_label ?? null,
    dropoffLabel: raw.dropoffLabel ?? raw.dropoff_label ?? null,
    detectedAt: raw.detectedAt ?? raw.detected_at ?? new Date().toISOString(),
    source: raw.source ?? OFFER_SOURCES.MANUAL,
    confidence: Math.max(0, Math.min(1, number(raw.confidence, raw.source === OFFER_SOURCES.OFFICIAL_API ? 1 : 0.75))),
    rawFields: raw.rawFields ?? raw.raw_fields ?? null,
  };
}

export async function fetchCurrentOffer() {
  const { data } = await api.get("/gig-offers/current");
  if (!data) return null;
  return normalizeGigOffer(data.offer ?? data, data.assumptions);
}

export async function fetchPlatformConnections() {
  const { data } = await api.get("/gig-platforms/connections");
  return Array.isArray(data) ? data : data?.connections ?? [];
}

export function subscribeToNativeOffers(onOffer) {
  const handler = (event) => {
    const payload = event?.detail;
    if (payload) onOffer(normalizeGigOffer(payload));
  };

  window.addEventListener("milli:gig-offer", handler);
  return () => window.removeEventListener("milli:gig-offer", handler);
}

export function sourceLabel(source) {
  switch (source) {
    case OFFER_SOURCES.OFFICIAL_API: return "Official platform connection";
    case OFFER_SOURCES.ANDROID_NOTIFICATION: return "Android offer notification";
    case OFFER_SOURCES.IOS_SHARE: return "Shared to Milli";
    case OFFER_SOURCES.IOS_OCR: return "Screenshot recognized on device";
    default: return "Manual offer";
  }
}

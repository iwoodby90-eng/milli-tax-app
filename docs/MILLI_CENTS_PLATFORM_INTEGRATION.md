# Milli Cents Platform Integration

Milli Cents accepts offers through one normalized contract regardless of source.

## Supported ingestion paths

1. `official_api` — OAuth or approved platform partner API.
2. `android_notification` — user-authorized Android NotificationListenerService parser.
3. `ios_share` — content explicitly shared to the Milli Share Extension.
4. `ios_ocr` — screenshot text recognized on-device with Apple Vision.
5. `manual` — user-entered fallback.

Milli must never silently scrape credentials, read another app's private storage, or automatically accept/decline an offer on the driver's behalf.

## Backend endpoints

### `GET /gig-platforms/connections`

Returns the user's connected or available platform adapters.

```json
{
  "connections": [
    {
      "id": "uber",
      "platform": "Uber",
      "display_name": "Uber",
      "connected": true,
      "capabilities": ["earnings", "trips", "live_offers"]
    }
  ]
}
```

### `GET /gig-offers/current`

Returns the newest unexpired offer and member-specific assumptions.

```json
{
  "offer": {
    "external_offer_id": "platform-offer-id",
    "platform": "Uber",
    "offered_pay": 28.5,
    "pickup_miles": 2.1,
    "route_miles": 12.3,
    "return_to_base_miles": 7.4,
    "estimated_minutes": 44,
    "source": "official_api",
    "confidence": 1,
    "detected_at": "2026-08-01T18:00:00Z"
  },
  "assumptions": {
    "gasPrice": 3.49,
    "vehicleMpg": 28,
    "taxRate": 25,
    "vehicleCostPerMile": 0.18,
    "minimumNetPerMile": 0.75,
    "minimumNetPerHour": 20
  }
}
```

## Native event bridge

Native adapters dispatch a WebView event named `milli:gig-offer` with the same normalized payload. The frontend subscribes through `subscribeToNativeOffers` and immediately recalculates the verdict.

## iOS implementation

- Add a Share Extension target accepting text and images.
- Use Vision text recognition for screenshots selected or shared by the user.
- Parse recognized text through platform-specific adapters.
- Write the normalized payload to an App Group container or open Milli through the registered URL scheme.
- Never claim silent notification interception on iOS.

## Android implementation

- Add a `NotificationListenerService` that the user explicitly enables in system settings.
- Allowlist supported gig-app package names.
- Parse only relevant offer notifications.
- Version each parser and attach a confidence score.
- Dispatch normalized offers to Milli; do not interact with the source app or accept offers.

## Decision authority

Milli produces an advisory verdict. The user always makes the final accept or decline action in the gig platform app.

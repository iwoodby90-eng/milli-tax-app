import { calculateProfit, verdict } from "@/lib/milli-cents";
import { normalizeGigOffer, OFFER_SOURCES } from "@/lib/gigOfferService";

describe("Milli Cents true-cycle engine", () => {
  test("includes pickup, route, return-to-base, fuel, vehicle cost, and tax", () => {
    const result = calculateProfit({
      offerPrice: 40,
      tripDistance: 20,
      deadheadDistance: 10,
      gasPrice: 3.5,
      vehicleMpg: 25,
      vehicleCostPerMile: 0.2,
      estimatedMinutes: 90,
      taxSlice: 0.25,
    });

    expect(result.totalMiles).toBe(30);
    expect(result.fuelCost).toBe(4.2);
    expect(result.operatingCost).toBe(6);
    expect(result.taxOwed).toBe(7.45);
    expect(result.profit).toBe(22.35);
    expect(result.netPerMile).toBe(0.75);
    expect(result.netPerHour).toBe(14.9);
  });

  test("uses member thresholds for the decision", () => {
    const result = calculateProfit({
      offerPrice: 55,
      tripDistance: 20,
      deadheadDistance: 5,
      gasPrice: 3.2,
      vehicleMpg: 28,
      vehicleCostPerMile: 0.16,
      estimatedMinutes: 60,
      taxSlice: 0.2,
    });

    expect(verdict(result, { minimumNetPerMile: 0.75, minimumNetPerHour: 20 })).toBe("ACCEPT");
    expect(verdict(result, { minimumNetPerMile: 2, minimumNetPerHour: 60 })).not.toBe("ACCEPT");
  });
});

describe("gig offer normalization", () => {
  test("normalizes backend snake_case into the Milli offer contract", () => {
    const offer = normalizeGigOffer({
      external_offer_id: "abc",
      platform: "Uber",
      offered_pay: 18.5,
      pickup_miles: 2.1,
      route_miles: 7.4,
      return_to_base_miles: 3.2,
      estimated_minutes: 32,
      source: OFFER_SOURCES.OFFICIAL_API,
    });

    expect(offer.id).toBe("abc");
    expect(offer.offeredPay).toBe(18.5);
    expect(offer.returnToBaseMiles).toBe(3.2);
    expect(offer.confidence).toBe(1);
  });
});

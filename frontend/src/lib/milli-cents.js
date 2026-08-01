/**
 * Milli Cents profitability engine.
 *
 * Models the complete work cycle: pickup, active route, unpaid return-to-base,
 * fuel, vehicle operating cost, estimated taxes, and time.
 */
export function calculateProfit(input) {
  const {
    offerPrice = 0,
    tripDistance = 0,
    deadheadDistance = 0,
    gasPrice = 0,
    vehicleMpg = 1,
    vehicleCostPerMile = 0,
    estimatedMinutes = 0,
    taxSlice = 0,
  } = input || {};

  const mpg = vehicleMpg > 0 ? vehicleMpg : 1;
  const totalMiles = Math.max(0, tripDistance) + Math.max(0, deadheadDistance);
  const fuelCost = (totalMiles / mpg) * Math.max(0, gasPrice);
  const operatingCost = totalMiles * Math.max(0, vehicleCostPerMile);
  const preTaxNet = offerPrice - fuelCost - operatingCost;
  const taxOwed = preTaxNet > 0 ? preTaxNet * Math.max(0, taxSlice) : 0;
  const profit = offerPrice - fuelCost - operatingCost - taxOwed;
  const totalCost = fuelCost + operatingCost + taxOwed;
  const costPerMile = totalMiles > 0 ? totalCost / totalMiles : 0;
  const grossPerMile = totalMiles > 0 ? offerPrice / totalMiles : 0;
  const netPerMile = totalMiles > 0 ? profit / totalMiles : 0;
  const netPerHour = estimatedMinutes > 0 ? profit / (estimatedMinutes / 60) : 0;
  const profitMargin = offerPrice > 0 ? (profit / offerPrice) * 100 : 0;

  return {
    profit: round2(profit),
    fuelCost: round2(fuelCost),
    operatingCost: round2(operatingCost),
    taxOwed: round2(taxOwed),
    totalCost: round2(totalCost),
    totalMiles: round2(totalMiles),
    costPerMile: round2(costPerMile),
    grossPerMile: round2(grossPerMile),
    netPerMile: round2(netPerMile),
    netPerHour: round2(netPerHour),
    profitMargin: round2(profitMargin),
    profitable: profit > 0,
  };
}

export function verdict(result, thresholds = {}) {
  if (!result) return "DECLINE";

  const minimumNetPerMile = Number(thresholds.minimumNetPerMile ?? 0.75);
  const minimumNetPerHour = Number(thresholds.minimumNetPerHour ?? 20);
  const hasTimeEstimate = result.netPerHour > 0;

  const clearsMileage = result.netPerMile >= minimumNetPerMile;
  const clearsHourly = !hasTimeEstimate || result.netPerHour >= minimumNetPerHour;
  const comfortablyProfitable = result.profitMargin >= 30 && clearsMileage && clearsHourly;

  if (comfortablyProfitable) return "ACCEPT";
  if (result.profit > 0 && result.netPerMile >= minimumNetPerMile * 0.7 && (!hasTimeEstimate || result.netPerHour >= minimumNetPerHour * 0.7)) {
    return "MARGINAL";
  }
  return "DECLINE";
}

function round2(n) {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

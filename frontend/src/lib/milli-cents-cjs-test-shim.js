// CJS test shim - re-exports the logic for node test runner
// (avoids needing ESM loader config for simple unit tests)

function round2(n) {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

function calculateProfit(input) {
  const {
    offerPrice = 0,
    tripDistance = 0,
    deadheadDistance = 0,
    gasPrice = 0,
    vehicleMpg = 1,
    taxSlice = 0,
  } = input || {};

  const mpg = vehicleMpg > 0 ? vehicleMpg : 1;
  const totalMiles = tripDistance + deadheadDistance;
  const fuelCost = (totalMiles / mpg) * gasPrice;
  const taxableNet = offerPrice - fuelCost;
  const taxOwed = taxableNet > 0 ? taxableNet * taxSlice : 0;
  const profit = offerPrice - fuelCost - taxOwed;
  const costPerMile = totalMiles > 0 ? (fuelCost + taxOwed) / totalMiles : 0;
  const profitMargin = offerPrice > 0 ? (profit / offerPrice) * 100 : 0;

  return {
    profit: round2(profit),
    fuelCost: round2(fuelCost),
    taxOwed: round2(taxOwed),
    totalMiles: round2(totalMiles),
    costPerMile: round2(costPerMile),
    profitMargin: round2(profitMargin),
    profitable: profit > 0,
  };
}

function verdict(result) {
  if (!result) return "DECLINE";
  if (result.profitMargin >= 40) return "ACCEPT";
  if (result.profitMargin >= 15) return "MARGINAL";
  return "DECLINE";
}

module.exports = { calculateProfit, verdict };

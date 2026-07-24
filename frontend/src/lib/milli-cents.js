/**
 * Milli-Cents Profitability Engine v1.9
 *
 * Calculates net profit on a gig delivery/ride offer after fuel cost
 * and tax obligation are deducted.
 *
 * Formula:
 *   fuelCost   = ((tripDistance + deadheadDistance) / vehicleMpg) * gasPrice
 *   taxableNet = offerPrice - fuelCost
 *   taxOwed    = taxableNet > 0 ? taxableNet * taxSlice : 0
 *   profit     = offerPrice - fuelCost - taxOwed
 */

/**
 * @typedef {Object} MilliCentsInput
 * @property {number} offerPrice      - Gross payout from the platform ($)
 * @property {number} tripDistance     - One-way trip distance (miles)
 * @property {number} deadheadDistance - Return/deadhead distance (miles)
 * @property {number} gasPrice         - Current gas price per gallon ($)
 * @property {number} vehicleMpg       - Vehicle fuel efficiency (miles per gallon)
 * @property {number} taxSlice         - Tax obligation percentage (0-1, e.g. 0.25 = 25%)
 */

/**
 * @typedef {Object} MilliCentsResult
 * @property {number} profit          - Net profit after fuel + tax ($)
 * @property {number} fuelCost        - Total fuel expense ($)
 * @property {number} taxOwed         - Tax liability on net earnings ($)
 * @property {number} totalMiles      - Combined trip + deadhead miles
 * @property {number} costPerMile     - Total cost per mile driven ($)
 * @property {number} profitMargin    - Profit as % of offer (0-100)
 * @property {boolean} profitable     - Whether the offer yields positive profit
 */

/**
 * Calculate profitability for a single gig offer.
 * @param {MilliCentsInput} input
 * @returns {MilliCentsResult}
 */
export function calculateProfit(input) {
  const {
    offerPrice = 0,
    tripDistance = 0,
    deadheadDistance = 0,
    gasPrice = 0,
    vehicleMpg = 1,
    taxSlice = 0,
  } = input || {};

  // Guard against division by zero
  const mpg = vehicleMpg > 0 ? vehicleMpg : 1;

  const totalMiles = tripDistance + deadheadDistance;
  const fuelCost = (totalMiles / mpg) * gasPrice;

  // Tax is only applied to positive net (no tax on a loss)
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

/**
 * Quick decision helper — returns a verdict string.
 * @param {MilliCentsResult} result
 * @returns {"ACCEPT"|"MARGINAL"|"DECLINE"}
 */
export function verdict(result) {
  if (!result) return "DECLINE";
  if (result.profitMargin >= 40) return "ACCEPT";
  if (result.profitMargin >= 15) return "MARGINAL";
  return "DECLINE";
}

/**
 * Round to 2 decimal places.
 */
function round2(n) {
  return Math.round((n + Number.EPSILON) * 100) / 100;
}

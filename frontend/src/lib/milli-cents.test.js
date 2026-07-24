/**
 * Tests for Milli-Cents Profitability Engine v1.9
 * Run with: node --experimental-vm-modules or simple node assert
 */

// Since this is a React project without jest configured for direct node,
// we'll use a simple assertion approach
const { calculateProfit, verdict } = require('./milli-cents-cjs-test-shim.js');

function assert(condition, msg) {
  if (!condition) throw new Error(`FAIL: ${msg}`);
  console.log(`  ✓ ${msg}`);
}

function assertClose(actual, expected, msg, tolerance = 0.01) {
  if (Math.abs(actual - expected) > tolerance) {
    throw new Error(`FAIL: ${msg} — expected ~${expected}, got ${actual}`);
  }
  console.log(`  ✓ ${msg}`);
}

console.log("\n━━━ Milli-Cents Engine Tests ━━━\n");

// Test 1: Basic profitable trip
console.log("Test 1: Basic profitable trip");
{
  const result = calculateProfit({
    offerPrice: 15,
    tripDistance: 5,
    deadheadDistance: 3,
    gasPrice: 3.50,
    vehicleMpg: 28,
    taxSlice: 0.25,
  });
  // fuelCost = (5+3)/28 * 3.50 = 8/28 * 3.50 = 1.00
  // taxableNet = 15 - 1.00 = 14.00
  // taxOwed = 14.00 * 0.25 = 3.50
  // profit = 15 - 1.00 - 3.50 = 10.50
  assertClose(result.fuelCost, 1.00, "Fuel cost = $1.00");
  assertClose(result.taxOwed, 3.50, "Tax owed = $3.50");
  assertClose(result.profit, 10.50, "Net profit = $10.50");
  assert(result.profitable === true, "Marked as profitable");
  assertClose(result.profitMargin, 70.0, "Profit margin = 70%");
  assert(result.totalMiles === 8, "Total miles = 8");
}

// Test 2: Break-even / losing trip
console.log("\nTest 2: Unprofitable trip");
{
  const result = calculateProfit({
    offerPrice: 3,
    tripDistance: 10,
    deadheadDistance: 10,
    gasPrice: 4.00,
    vehicleMpg: 20,
    taxSlice: 0.25,
  });
  // fuelCost = 20/20 * 4.00 = 4.00
  // taxableNet = 3 - 4 = -1 (negative, no tax)
  // taxOwed = 0
  // profit = 3 - 4 - 0 = -1
  assertClose(result.fuelCost, 4.00, "Fuel cost = $4.00");
  assertClose(result.taxOwed, 0, "Tax owed = $0 (loss)");
  assertClose(result.profit, -1.00, "Net profit = -$1.00");
  assert(result.profitable === false, "Marked as NOT profitable");
}

// Test 3: Zero input safeguards
console.log("\nTest 3: Zero/null inputs");
{
  const result = calculateProfit({});
  assertClose(result.profit, 0, "Zero inputs = $0 profit");
  assertClose(result.fuelCost, 0, "Zero inputs = $0 fuel");
  assert(result.profitable === false, "Zero is not profitable");
}

// Test 4: Division by zero MPG
console.log("\nTest 4: Zero MPG (guarded)");
{
  const result = calculateProfit({
    offerPrice: 10,
    tripDistance: 5,
    deadheadDistance: 0,
    gasPrice: 3.50,
    vehicleMpg: 0,
    taxSlice: 0.20,
  });
  // MPG guarded to 1: fuelCost = 5/1 * 3.50 = 17.50
  // taxableNet = 10 - 17.50 = -7.50 (negative, no tax)
  // profit = 10 - 17.50 - 0 = -7.50
  assertClose(result.fuelCost, 17.50, "MPG=0 guarded to 1, fuel=$17.50");
  assert(result.profitable === false, "Huge fuel cost = not profitable");
}

// Test 5: Verdict helper
console.log("\nTest 5: Verdict classification");
{
  assert(verdict({ profitMargin: 50 }) === "ACCEPT", "50% margin = ACCEPT");
  assert(verdict({ profitMargin: 40 }) === "ACCEPT", "40% margin = ACCEPT");
  assert(verdict({ profitMargin: 39 }) === "MARGINAL", "39% margin = MARGINAL");
  assert(verdict({ profitMargin: 15 }) === "MARGINAL", "15% margin = MARGINAL");
  assert(verdict({ profitMargin: 14 }) === "DECLINE", "14% margin = DECLINE");
  assert(verdict({ profitMargin: -5 }) === "DECLINE", "Negative margin = DECLINE");
  assert(verdict(null) === "DECLINE", "Null result = DECLINE");
}

// Test 6: Cost per mile
console.log("\nTest 6: Cost per mile");
{
  const result = calculateProfit({
    offerPrice: 20,
    tripDistance: 10,
    deadheadDistance: 5,
    gasPrice: 3.00,
    vehicleMpg: 30,
    taxSlice: 0.30,
  });
  // fuelCost = 15/30 * 3 = 1.50
  // taxableNet = 20 - 1.50 = 18.50
  // taxOwed = 18.50 * 0.30 = 5.55
  // costPerMile = (1.50 + 5.55) / 15 = 7.05 / 15 = 0.47
  assertClose(result.costPerMile, 0.47, "Cost/mile = $0.47");
}

console.log("\n━━━ ALL TESTS PASSED ━━━\n");

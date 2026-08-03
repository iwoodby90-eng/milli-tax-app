/**
 * Brokerage Integration Service
 * 
 * Integrates with Alpaca Markets API for commission-free stock/ETF trading.
 * Supports portfolio management, fractional shares, and dividend reinvestment.
 */

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8000';

/**
 * Link a brokerage account via Alpaca
 * @param {string} userId - User ID
 * @param {Object} params - {apiKey, secretKey} or OAuth code
 * @returns {Promise<Object>} Linked account info
 */
export async function linkBrokerageAccount(userId, { apiKey, secretKey } = {}) {
  const response = await fetch(`${API_BASE}/api/brokerage/link`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, apiKey, secretKey }),
  });

  if (!response.ok) throw new Error('Failed to link brokerage account');
  return response.json();
}

/**
 * Get portfolio overview (positions, buying power, equity)
 * @param {string} userId - User ID
 * @returns {Promise<Object>} Portfolio data
 */
export async function getPortfolio(userId) {
  const response = await fetch(`${API_BASE}/api/brokerage/portfolio?userId=${userId}`);
  if (!response.ok) throw new Error('Failed to fetch portfolio');
  return response.json();
}

/**
 * Get all open positions
 * @param {string} userId - User ID
 * @returns {Promise<Array>} Positions
 */
export async function getPositions(userId) {
  const response = await fetch(`${API_BASE}/api/brokerage/positions?userId=${userId}`);
  if (!response.ok) throw new Error('Failed to fetch positions');
  return response.json();
}

/**
 * Place a market order
 * @param {string} userId - User ID
 * @param {Object} params - {symbol, side, qty, type, timeInForce}
 * @returns {Promise<Object>} Order confirmation
 */
export async function placeOrder(userId, { symbol, side, qty, type = 'market', timeInForce = 'day' }) {
  const response = await fetch(`${API_BASE}/api/brokerage/orders`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, symbol, side, qty, type, timeInForce }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'Order failed' }));
    throw new Error(error.detail || 'Failed to place order');
  }
  return response.json();
}

/**
 * Place a fractional share order
 * @param {string} userId - User ID
 * @param {Object} params - {symbol, side, notional (dollar amount)}
 * @returns {Promise<Object>} Order confirmation
 */
export async function placeFractionalOrder(userId, { symbol, side, notional }) {
  const response = await fetch(`${API_BASE}/api/brokerage/orders/fractional`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, symbol, side, notional }),
  });

  if (!response.ok) throw new Error('Failed to place fractional order');
  return response.json();
}

/**
 * Get order history
 * @param {string} userId - User ID
 * @param {number} limit - Max orders to return
 * @returns {Promise<Array>} Order history
 */
export async function getOrderHistory(userId, limit = 50) {
  const response = await fetch(`${API_BASE}/api/brokerage/orders?userId=${userId}&limit=${limit}`);
  if (!response.ok) throw new Error('Failed to fetch order history');
  return response.json();
}

/**
 * Cancel an open order
 * @param {string} userId - User ID
 * @param {string} orderId - Order ID to cancel
 * @returns {Promise<Object>} Cancellation confirmation
 */
export async function cancelOrder(userId, orderId) {
  const response = await fetch(`${API_BASE}/api/brokerage/orders/${orderId}/cancel`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId }),
  });
  if (!response.ok) throw new Error('Failed to cancel order');
  return response.json();
}

/**
 * Get account history (equity curve)
 * @param {string} userId - User ID
 * @param {string} period - '1D' | '1W' | '1M' | '3M' | '1Y'
 * @returns {Promise<Array>} Equity history
 */
export async function getAccountHistory(userId, period = '1M') {
  const response = await fetch(`${API_BASE}/api/brokerage/history?userId=${userId}&period=${period}`);
  if (!response.ok) throw new Error('Failed to fetch account history');
  return response.json();
}

/**
 * Enable or disable dividend reinvestment (DRIP)
 * @param {string} userId - User ID
 * @param {boolean} enabled - Enable or disable DRIP
 * @returns {Promise<Object>} Update confirmation
 */
export async function setDRIP(userId, enabled) {
  const response = await fetch(`${API_BASE}/api/brokerage/drip`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, enabled }),
  });
  if (!response.ok) throw new Error('Failed to update DRIP setting');
  return response.json();
}

export default {
  linkBrokerageAccount,
  getPortfolio,
  getPositions,
  placeOrder,
  placeFractionalOrder,
  getOrderHistory,
  cancelOrder,
  getAccountHistory,
  setDRIP,
};
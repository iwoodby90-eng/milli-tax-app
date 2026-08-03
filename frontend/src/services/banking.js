/**
 * Banking Partner Integration Service
 * 
 * Integrates with SynapseFi / Unit.co for embedded banking:
 * - Checking/savings account creation
 * - ACH transfers, wire transfers
 * - Visa debit card issuance and management
 * - Transaction monitoring and balance checks
 */

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8000';

/**
 * Create a bank account (checking or savings)
 * @param {string} userId - User ID
 * @param {Object} params - {type, nickname}
 * @returns {Promise<Object>} Created account
 */
export async function createBankAccount(userId, { type = 'checking', nickname }) {
  const response = await fetch(`${API_BASE}/api/banking/accounts`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, type, nickname }),
  });

  if (!response.ok) throw new Error('Failed to create bank account');
  return response.json();
}

/**
 * Get all bank accounts for a user
 * @param {string} userId - User ID
 * @returns {Promise<Array>} Bank accounts
 */
export async function getBankAccounts(userId) {
  const response = await fetch(`${API_BASE}/api/banking/accounts?userId=${userId}`);
  if (!response.ok) throw new Error('Failed to fetch bank accounts');
  return response.json();
}

/**
 * Get account details (balance, routing, account number)
 * @param {string} userId - User ID
 * @param {string} accountId - Account ID
 * @returns {Promise<Object>} Account details
 */
export async function getAccountDetails(userId, accountId) {
  const response = await fetch(`${API_BASE}/api/banking/accounts/${accountId}?userId=${userId}`);
  if (!response.ok) throw new Error('Failed to fetch account details');
  return response.json();
}

/**
 * Initiate an ACH transfer
 * @param {string} userId - User ID
 * @param {Object} params - {fromAccountId, toAccountId, amount, note}
 * @returns {Promise<Object>} Transfer confirmation
 */
export async function initiateACHTransfer(userId, { fromAccountId, toAccountId, amount, note }) {
  const response = await fetch(`${API_BASE}/api/banking/transfers/ach`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, fromAccountId, toAccountId, amount, note }),
  });

  if (!response.ok) throw new Error('Failed to initiate ACH transfer');
  return response.json();
}

/**
 * Initiate a wire transfer
 * @param {string} userId - User ID
 * @param {Object} params - {fromAccountId, recipientBank, recipientAccount, recipientName, amount, routingNumber}
 * @returns {Promise<Object>} Wire transfer confirmation
 */
export async function initiateWireTransfer(userId, params) {
  const response = await fetch(`${API_BASE}/api/banking/transfers/wire`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, ...params }),
  });

  if (!response.ok) throw new Error('Failed to initiate wire transfer');
  return response.json();
}

/**
 * Request a Visa debit card
 * @param {string} userId - User ID
 * @param {string} accountId - Account to link the card to
 * @param {Object} shippingAddress - {name, line1, city, state, zip}
 * @returns {Promise<Object>} Card issuance confirmation
 */
export async function requestDebitCard(userId, accountId, shippingAddress) {
  const response = await fetch(`${API_BASE}/api/banking/cards`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, accountId, shippingAddress }),
  });

  if (!response.ok) throw new Error('Failed to request debit card');
  return response.json();
}

/**
 * Get card details (last 4, status, spending limits)
 * @param {string} userId - User ID
 * @returns {Promise<Array>} Cards
 */
export async function getCards(userId) {
  const response = await fetch(`${API_BASE}/api/banking/cards?userId=${userId}`);
  if (!response.ok) throw new Error('Failed to fetch cards');
  return response.json();
}

/**
 * Lock or unlock a debit card
 * @param {string} userId - User ID
 * @param {string} cardId - Card ID
 * @param {boolean} locked - Lock state
 * @returns {Promise<Object>} Update confirmation
 */
export async function setCardLock(userId, cardId, locked) {
  const response = await fetch(`${API_BASE}/api/banking/cards/${cardId}/lock`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, locked }),
  });
  if (!response.ok) throw new Error('Failed to update card lock');
  return response.json();
}

/**
 * Get transaction history for an account
 * @param {string} userId - User ID
 * @param {string} accountId - Account ID
 * @param {number} limit - Max transactions
 * @returns {Promise<Array>} Transactions
 */
export async function getTransactions(userId, accountId, limit = 50) {
  const response = await fetch(`${API_BASE}/api/banking/accounts/${accountId}/transactions?userId=${userId}&limit=${limit}`);
  if (!response.ok) throw new Error('Failed to fetch transactions');
  return response.json();
}

/**
 * Set spending limit on a card
 * @param {string} userId - User ID
 * @param {string} cardId - Card ID
 * @param {Object} limits - {daily, monthly}
 * @returns {Promise<Object>} Update confirmation
 */
export async function setSpendingLimit(userId, cardId, { daily, monthly }) {
  const response = await fetch(`${API_BASE}/api/banking/cards/${cardId}/limits`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, daily, monthly }),
  });
  if (!response.ok) throw new Error('Failed to set spending limit');
  return response.json();
}

export default {
  createBankAccount,
  getBankAccounts,
  getAccountDetails,
  initiateACHTransfer,
  initiateWireTransfer,
  requestDebitCard,
  getCards,
  setCardLock,
  getTransactions,
  setSpendingLimit,
};
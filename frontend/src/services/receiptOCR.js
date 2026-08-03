/**
 * Receipt OCR Service
 * 
 * Uses Google Cloud Vision API / AWS Textract to extract data from receipt images:
 * - Merchant name, date, total amount, line items
 * - Tax-deductible categorization
 * - Auto-categorize for Schedule C deductions
 */

const API_BASE = process.env.REACT_APP_API_URL || 'http://localhost:8000';

/**
 * Process a receipt image and extract structured data
 * @param {string} userId - User ID
 * @param {string} imageData - Base64-encoded image data
 * @param {string} mimeType - Image MIME type (image/jpeg, image/png)
 * @returns {Promise<Object>} Extracted receipt data
 */
export async function processReceipt(userId, imageData, mimeType = 'image/jpeg') {
  const response = await fetch(`${API_BASE}/api/ocr/receipt`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, imageData, mimeType }),
  });

  if (!response.ok) {
    const error = await response.json().catch(() => ({ detail: 'OCR processing failed' }));
    throw new Error(error.detail || 'Failed to process receipt');
  }

  return response.json();
}

/**
 * Batch process multiple receipts
 * @param {string} userId - User ID
 * @param {Array} receipts - Array of {imageData, mimeType}
 * @returns {Promise<Array>} Extracted receipt data for each image
 */
export async function batchProcessReceipts(userId, receipts) {
  const response = await fetch(`${API_BASE}/api/ocr/receipts/batch`, {
    method: 'POST',
    headers: { 'Content-Type': 'application/json' },
    body: JSON.stringify({ userId, receipts }),
  });

  if (!response.ok) throw new Error('Batch OCR processing failed');
  return response.json();
}

/**
 * Categorize a receipt for tax deduction purposes
 * @param {Object} receiptData - Extracted receipt data
 * @returns {Object} Categorized receipt with Schedule C category
 */
export function categorizeReceipt(receiptData) {
  const categoryMap = {
    'office supplies': 'Office Supplies',
    'software': 'Software & Subscriptions',
    'meals': 'Meals & Entertainment (50%)',
    'travel': 'Travel',
    'fuel': 'Vehicle Expenses',
    'parking': 'Vehicle Expenses',
    'phone': 'Phone & Internet',
    'internet': 'Phone & Internet',
    'advertising': 'Advertising & Marketing',
    'insurance': 'Insurance',
    'rent': 'Rent or Lease',
    'utilities': 'Utilities',
    'professional services': 'Legal & Professional Services',
    'education': 'Education & Training',
    'equipment': 'Equipment & Depreciation',
  };

  const merchantLower = (receiptData.merchant || '').toLowerCase();
  let category = 'Other';

  for (const [keyword, cat] of Object.entries(categoryMap)) {
    if (merchantLower.includes(keyword)) {
      category = cat;
      break;
    }
  }

  // Check line items for better categorization
  if (receiptData.items && receiptData.items.length > 0) {
    for (const item of receiptData.items) {
      const itemLower = (item.description || '').toLowerCase();
      for (const [keyword, cat] of Object.entries(categoryMap)) {
        if (itemLower.includes(keyword)) {
          category = cat;
          break;
        }
      }
    }
  }

  return {
    ...receiptData,
    scheduleC_category: category,
    deductible: category !== 'Other',
    deductiblePercentage: category.includes('50%') ? 50 : 100,
  };
}

/**
 * Get receipt history for a user
 * @param {string} userId - User ID
 * @param {string} category - Optional category filter
 * @returns {Promise<Array>} Receipt history
 */
export async function getReceiptHistory(userId, category = null) {
  const params = new URLSearchParams({ userId });
  if (category) params.append('category', category);

  const response = await fetch(`${API_BASE}/api/ocr/receipts?${params}`);
  if (!response.ok) throw new Error('Failed to fetch receipt history');
  return response.json();
}

/**
 * Delete a processed receipt
 * @param {string} receiptId - Receipt ID
 * @returns {Promise<Object>} Deletion confirmation
 */
export async function deleteReceipt(receiptId) {
  const response = await fetch(`${API_BASE}/api/ocr/receipts/${receiptId}`, {
    method: 'DELETE',
  });
  if (!response.ok) throw new Error('Failed to delete receipt');
  return response.json();
}

/**
 * Export receipts as CSV for tax filing
 * @param {string} userId - User ID
 * @param {string} taxYear - Tax year
 * @returns {Promise<string>} CSV data
 */
export async function exportReceiptsCSV(userId, taxYear) {
  const response = await fetch(`${API_BASE}/api/ocr/receipts/export?userId=${userId}&taxYear=${taxYear}`);
  if (!response.ok) throw new Error('Failed to export receipts');
  return response.text();
}

export default {
  processReceipt,
  batchProcessReceipts,
  categorizeReceipt,
  getReceiptHistory,
  deleteReceipt,
  exportReceiptsCSV,
};
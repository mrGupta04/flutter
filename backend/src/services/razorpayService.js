const crypto = require('crypto');

const PROVIDER = (process.env.RAZORPAY_PROVIDER || 'mock').toLowerCase();
const KEY_ID = process.env.RAZORPAY_KEY_ID || '';
const KEY_SECRET = process.env.RAZORPAY_KEY_SECRET || '';

function isMockMode() {
  return PROVIDER === 'mock';
}

function assertRazorpayConfigured() {
  if (isMockMode()) return;
  if (!KEY_ID || !KEY_SECRET) {
    throw new Error(
      'Razorpay is not configured. Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET, or use RAZORPAY_PROVIDER=mock for development.',
    );
  }
}

function getRazorpayClient() {
  assertRazorpayConfigured();
  if (isMockMode()) return null;
  // eslint-disable-next-line global-require
  const Razorpay = require('razorpay');
  return new Razorpay({ key_id: KEY_ID, key_secret: KEY_SECRET });
}

async function createOrder({ amountInPaise, receipt, notes = {} }) {
  if (isMockMode()) {
    return {
      id: `order_mock_${Date.now()}`,
      amount: amountInPaise,
      currency: 'INR',
      receipt,
      mock: true,
    };
  }

  const razorpay = getRazorpayClient();
  const order = await razorpay.orders.create({
    amount: amountInPaise,
    currency: 'INR',
    receipt,
    notes,
  });
  return order;
}

function verifyPaymentSignature({ orderId, paymentId, signature }) {
  if (isMockMode()) {
    return Boolean(orderId && paymentId);
  }

  const body = `${orderId}|${paymentId}`;
  const expected = crypto
    .createHmac('sha256', KEY_SECRET)
    .update(body)
    .digest('hex');
  return expected === signature;
}

function getProviderInfo() {
  return {
    provider: PROVIDER,
    configured: isMockMode() || Boolean(KEY_ID && KEY_SECRET),
    keyId: isMockMode() ? null : KEY_ID || null,
  };
}

/**
 * Refund a captured Razorpay payment (partial or full).
 * @param {{ paymentId: string, amountInPaise?: number, notes?: object }} opts
 * amountInPaise omitted = full refund
 */
async function createRefund({ paymentId, amountInPaise, notes = {} }) {
  if (!paymentId) {
    const err = new Error('Payment id is required for refund');
    err.statusCode = 400;
    throw err;
  }

  if (isMockMode()) {
    return {
      id: `rfnd_mock_${Date.now()}`,
      payment_id: paymentId,
      amount: amountInPaise ?? null,
      status: 'processed',
      mock: true,
    };
  }

  const razorpay = getRazorpayClient();
  const payload = { notes };
  if (amountInPaise != null && Number.isFinite(amountInPaise) && amountInPaise > 0) {
    payload.amount = Math.round(amountInPaise);
  }
  return razorpay.payments.refund(paymentId, payload);
}

module.exports = {
  createOrder,
  verifyPaymentSignature,
  createRefund,
  getProviderInfo,
  isMockMode,
  assertRazorpayConfigured,
};

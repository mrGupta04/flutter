const { v4: uuidv4 } = require('uuid');
const Coupon = require('./models/Coupon');

function toCoupon(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    code: d.code,
    description: d.description,
    discountType: d.discountType,
    discountValue: d.discountValue,
    maxDiscountInr: d.maxDiscountInr,
    minOrderInr: d.minOrderInr || 0,
    applicableTo: d.applicableTo || [],
    active: d.active !== false,
    usageCount: d.usageCount || 0,
    maxUses: d.maxUses,
    expiresAt: d.expiresAt,
    createdAt: d.createdAt,
  };
}

function computeDiscount(coupon, orderAmountInr) {
  const amount = Number(orderAmountInr) || 0;
  if (amount < (coupon.minOrderInr || 0)) {
    const err = new Error(
      `Minimum order amount is ₹${coupon.minOrderInr} for this coupon`,
    );
    err.statusCode = 400;
    throw err;
  }

  let discount = 0;
  if (coupon.discountType === 'percentage') {
    discount = Math.round((amount * coupon.discountValue) / 100);
    if (coupon.maxDiscountInr != null) {
      discount = Math.min(discount, coupon.maxDiscountInr);
    }
  } else {
    discount = Math.round(coupon.discountValue);
  }
  discount = Math.max(0, Math.min(discount, amount));
  return {
    discountAmount: discount,
    finalAmount: Math.max(0, amount - discount),
  };
}

async function validateCoupon({ code, orderAmountInr, applicableTo }) {
  const normalized = String(code || '')
    .trim()
    .toUpperCase();
  if (!normalized) {
    const err = new Error('Coupon code is required');
    err.statusCode = 400;
    throw err;
  }

  let coupon = await Coupon.findOne({ code: normalized });
  if (!coupon) {
    // Seed a few default promos in empty DBs so UX works out of the box.
    if (['CARE10', 'HEALTH50', 'FIRST100'].includes(normalized)) {
      await ensureDefaultCoupons();
      coupon = await Coupon.findOne({ code: normalized });
    }
  }

  if (!coupon || !coupon.active) {
    const err = new Error('Invalid or inactive coupon');
    err.statusCode = 400;
    throw err;
  }
  if (coupon.expiresAt && new Date(coupon.expiresAt) < new Date()) {
    const err = new Error('This coupon has expired');
    err.statusCode = 400;
    throw err;
  }
  if (coupon.maxUses != null && coupon.usageCount >= coupon.maxUses) {
    const err = new Error('This coupon has reached its usage limit');
    err.statusCode = 400;
    throw err;
  }
  if (
    applicableTo &&
    Array.isArray(coupon.applicableTo) &&
    coupon.applicableTo.length &&
    !coupon.applicableTo.includes(applicableTo)
  ) {
    const err = new Error('Coupon is not valid for this service');
    err.statusCode = 400;
    throw err;
  }

  const pricing = computeDiscount(toCoupon(coupon), orderAmountInr);
  return {
    coupon: toCoupon(coupon),
    ...pricing,
  };
}

async function incrementCouponUsage(code) {
  const normalized = String(code || '')
    .trim()
    .toUpperCase();
  if (!normalized) return;
  await Coupon.updateOne({ code: normalized }, { $inc: { usageCount: 1 } });
}

async function ensureDefaultCoupons() {
  const defaults = [
    {
      id: uuidv4(),
      code: 'CARE10',
      description: '10% off consultations',
      discountType: 'percentage',
      discountValue: 10,
      maxDiscountInr: 200,
      minOrderInr: 100,
      applicableTo: ['consultation'],
      active: true,
    },
    {
      id: uuidv4(),
      code: 'HEALTH50',
      description: '₹50 off lab & scan',
      discountType: 'flat',
      discountValue: 50,
      minOrderInr: 299,
      applicableTo: ['lab', 'scan'],
      active: true,
    },
    {
      id: uuidv4(),
      code: 'FIRST100',
      description: '₹100 off first booking',
      discountType: 'flat',
      discountValue: 100,
      minOrderInr: 199,
      applicableTo: ['consultation', 'lab', 'scan', 'blood'],
      active: true,
      maxUses: 10000,
    },
  ];

  for (const c of defaults) {
    const exists = await Coupon.findOne({ code: c.code });
    if (!exists) await Coupon.create(c);
  }
}

async function listCoupons() {
  await ensureDefaultCoupons();
  const docs = await Coupon.find().sort({ createdAt: -1 }).lean();
  return docs.map(toCoupon);
}

async function upsertCoupon(input) {
  const code = String(input.code || '')
    .trim()
    .toUpperCase();
  if (!code) {
    const err = new Error('Coupon code is required');
    err.statusCode = 400;
    throw err;
  }
  const existing = await Coupon.findOne({ code });
  const payload = {
    code,
    description: input.description,
    discountType: input.discountType || 'flat',
    discountValue: Number(input.discountValue) || 0,
    maxDiscountInr: input.maxDiscountInr != null ? Number(input.maxDiscountInr) : undefined,
    minOrderInr: Number(input.minOrderInr) || 0,
    applicableTo: Array.isArray(input.applicableTo)
      ? input.applicableTo
      : ['consultation', 'lab', 'scan', 'blood'],
    active: input.active !== false,
    maxUses: input.maxUses != null ? Number(input.maxUses) : undefined,
    expiresAt: input.expiresAt ? new Date(input.expiresAt) : undefined,
  };

  if (existing) {
    Object.assign(existing, payload);
    await existing.save();
    return toCoupon(existing);
  }

  const created = await Coupon.create({ id: uuidv4(), ...payload, usageCount: 0 });
  return toCoupon(created);
}

module.exports = {
  validateCoupon,
  incrementCouponUsage,
  listCoupons,
  upsertCoupon,
  ensureDefaultCoupons,
  toCoupon,
  computeDiscount,
};

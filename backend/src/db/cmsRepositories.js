const { v4: uuidv4 } = require('uuid');
const CmsBanner = require('./models/CmsBanner');

function toCmsBanner(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    title: d.title,
    subtitle: d.subtitle || null,
    imageUrl: d.imageUrl,
    linkUrl: d.linkUrl || null,
    sortOrder: d.sortOrder ?? 0,
    active: d.active !== false,
    placement: d.placement || 'home_hero',
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

async function ensureDefaultBanners() {
  const count = await CmsBanner.countDocuments();
  if (count > 0) return;

  const defaults = [
    {
      id: uuidv4(),
      title: 'Book trusted doctors instantly',
      subtitle: 'Online, home visit, or clinic consultations',
      imageUrl:
        'https://images.unsplash.com/photo-1666214280391-8ff5bd3c0bf0?w=1400&h=700&fit=crop',
      sortOrder: 0,
      active: true,
      placement: 'home_hero',
    },
    {
      id: uuidv4(),
      title: 'Care at your convenience',
      subtitle: 'Choose your slot and get care on your schedule',
      imageUrl:
        'https://images.unsplash.com/photo-1584432810601-6c7f27d2362b?w=1400&h=700&fit=crop',
      sortOrder: 1,
      active: true,
      placement: 'home_hero',
    },
    {
      id: uuidv4(),
      title: 'Verified providers, better outcomes',
      subtitle: 'Explore specialists by role, city, and service type',
      imageUrl:
        'https://images.unsplash.com/photo-1576091160550-2173dba999ef?w=1400&h=700&fit=crop',
      sortOrder: 2,
      active: true,
      placement: 'home_hero',
    },
  ];

  await CmsBanner.insertMany(defaults);
}

async function listActiveBanners(placement = 'home_hero') {
  await ensureDefaultBanners();
  const docs = await CmsBanner.find({
    active: true,
    placement: placement || 'home_hero',
  })
    .sort({ sortOrder: 1, createdAt: 1 })
    .lean();
  return docs.map(toCmsBanner);
}

async function listAllBanners(placement) {
  await ensureDefaultBanners();
  const query = {};
  if (placement) query.placement = placement;
  const docs = await CmsBanner.find(query)
    .sort({ sortOrder: 1, createdAt: -1 })
    .lean();
  return docs.map(toCmsBanner);
}

async function upsertBanner(input) {
  const title = String(input.title || '').trim();
  const imageUrl = String(input.imageUrl || '').trim();
  if (!title) {
    const err = new Error('Title is required');
    err.statusCode = 400;
    throw err;
  }
  if (!imageUrl) {
    const err = new Error('imageUrl is required');
    err.statusCode = 400;
    throw err;
  }

  const payload = {
    title,
    subtitle: input.subtitle != null ? String(input.subtitle).trim() : undefined,
    imageUrl,
    linkUrl: input.linkUrl != null ? String(input.linkUrl).trim() : undefined,
    sortOrder: input.sortOrder != null ? Number(input.sortOrder) : 0,
    active: input.active !== false,
    placement: input.placement || 'home_hero',
  };

  if (input.id) {
    const existing = await CmsBanner.findOne({ id: String(input.id) });
    if (existing) {
      Object.assign(existing, payload);
      await existing.save();
      return toCmsBanner(existing);
    }
  }

  const created = await CmsBanner.create({ id: uuidv4(), ...payload });
  return toCmsBanner(created);
}

async function deleteBanner(id) {
  const result = await CmsBanner.deleteOne({ id: String(id) });
  if (!result.deletedCount) {
    const err = new Error('Banner not found');
    err.statusCode = 404;
    throw err;
  }
  return true;
}

module.exports = {
  toCmsBanner,
  ensureDefaultBanners,
  listActiveBanners,
  listAllBanners,
  upsertBanner,
  deleteBanner,
};

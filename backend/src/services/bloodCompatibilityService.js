const { v4: uuidv4 } = require('uuid');
const BloodCompatibility = require('../db/models/BloodCompatibility');

const DEFAULT_RULES = [
  { recipientGroup: 'O-', compatibleDonorGroups: ['O-'] },
  { recipientGroup: 'O+', compatibleDonorGroups: ['O-', 'O+'] },
  { recipientGroup: 'A-', compatibleDonorGroups: ['O-', 'A-'] },
  { recipientGroup: 'A+', compatibleDonorGroups: ['O-', 'O+', 'A-', 'A+'] },
  { recipientGroup: 'B-', compatibleDonorGroups: ['O-', 'B-'] },
  { recipientGroup: 'B+', compatibleDonorGroups: ['O-', 'O+', 'B-', 'B+'] },
  { recipientGroup: 'AB-', compatibleDonorGroups: ['O-', 'A-', 'B-', 'AB-'] },
  {
    recipientGroup: 'AB+',
    compatibleDonorGroups: ['O-', 'O+', 'A-', 'A+', 'B-', 'B+', 'AB-', 'AB+'],
  },
];

const DEFAULT_COMPONENTS = [
  'whole_blood',
  'packed_rbc',
  'platelets',
  'plasma',
  'cryoprecipitate',
];

async function ensureDefaultCompatibility() {
  const count = await BloodCompatibility.countDocuments();
  if (count > 0) return listCompatibilityRules();

  await BloodCompatibility.insertMany(
    DEFAULT_RULES.map((rule) => ({
      id: uuidv4(),
      recipientGroup: rule.recipientGroup,
      compatibleDonorGroups: rule.compatibleDonorGroups,
      compatibleComponents: DEFAULT_COMPONENTS,
      notes:
        'Clinical crossmatching is still required. This mapping is for search and matching only.',
      active: true,
    })),
  );
  return listCompatibilityRules();
}

async function listCompatibilityRules() {
  await ensureDefaultCompatibility();
  const docs = await BloodCompatibility.find({ active: { $ne: false } }).sort({
    recipientGroup: 1,
  });
  return docs.map((d) => (d.toObject ? d.toObject() : d));
}

async function getCompatibleDonorGroups(recipientGroup) {
  if (!recipientGroup) return [];
  await ensureDefaultCompatibility();
  const rule = await BloodCompatibility.findOne({
    recipientGroup: String(recipientGroup).trim().toUpperCase(),
    active: { $ne: false },
  }).lean();
  return rule?.compatibleDonorGroups || [recipientGroup];
}

async function upsertCompatibilityRule(data, actorId) {
  const recipientGroup = String(data.recipientGroup || '')
    .trim()
    .toUpperCase();
  if (!recipientGroup) {
    const err = new Error('Invalid blood group');
    err.statusCode = 400;
    throw err;
  }

  const existing = await BloodCompatibility.findOne({ recipientGroup });
  const payload = {
    recipientGroup,
    compatibleDonorGroups: Array.isArray(data.compatibleDonorGroups)
      ? data.compatibleDonorGroups.map((g) => String(g).toUpperCase())
      : existing?.compatibleDonorGroups || [],
    compatibleComponents: data.compatibleComponents || existing?.compatibleComponents || DEFAULT_COMPONENTS,
    notes: data.notes ?? existing?.notes,
    active: data.active !== false,
    updatedBy: actorId,
  };

  if (existing) {
    await BloodCompatibility.updateOne({ id: existing.id }, { $set: payload });
    return BloodCompatibility.findOne({ id: existing.id }).lean();
  }

  return BloodCompatibility.create({ id: uuidv4(), ...payload });
}

function isValidBloodGroup(group) {
  return DEFAULT_RULES.some((r) => r.recipientGroup === String(group || '').toUpperCase());
}

module.exports = {
  ensureDefaultCompatibility,
  listCompatibilityRules,
  getCompatibleDonorGroups,
  upsertCompatibilityRule,
  isValidBloodGroup,
  DEFAULT_RULES,
};

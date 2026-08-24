const bcrypt = require('bcryptjs');
const crypto = require('crypto');
const { v4: uuidv4 } = require('uuid');

const Approver = require('./models/Approver');
const ApprovalRequest = require('./models/ApprovalRequest');
const AuditLog = require('./models/AuditLog');
const ProviderCategory = require('./models/ProviderCategory');
const ApprovalRule = require('./models/ApprovalRule');
const ApprovalNotification = require('./models/ApprovalNotification');
const ApprovalSavedFilter = require('./models/ApprovalSavedFilter');
const ApprovalSession = require('./models/ApprovalSession');
const Document = require('./models/Document');

const Doctor = require('./models/Doctor');
const Nurse = require('./models/Nurse');
const Ambulance = require('./models/Ambulance');
const BloodBank = require('./models/BloodBank');
const Lab = require('./models/Lab');
const ScanCenter = require('./models/ScanCenter');

const { toDoctor } = require('./mappers');
const { toNurse } = require('./nurseMappers');
const { toAmbulance } = require('./ambulanceMappers');
const { toBloodBank } = require('./bloodBankMappers');
const { toLab } = require('./labMappers');
const { toScanCenter } = require('./scanCenterMappers');

const {
  approveDoctor,
  rejectDoctor,
} = require('./repositories');
const {
  approveNurse,
  rejectNurse,
} = require('./nurseRepositories');
const {
  approveAmbulance,
  rejectAmbulance,
} = require('./ambulanceRepositories');
const {
  approveBloodBank,
  rejectBloodBank,
  requestBloodBankDocuments,
} = require('./bloodBankRepositories');
const {
  approveLab,
  rejectLab,
  requestLabDocuments,
} = require('./labRepositories');
const {
  approveScanCenter,
  rejectScanCenter,
  requestScanCenterDocuments,
} = require('./scanCenterRepositories');

const OPEN_REQUEST_STATUSES = ['pending', 'on_hold', 'needs_documents', 'escalated'];
const ASSIGNMENT_STRATEGIES = [
  'round_robin',
  'least_busy',
  'manual',
  'region_based',
  'category_based',
];
const REVIEW_PROVIDER_STATUSES = [
  'pending',
  'under_review',
  'verifier_approved',
  'verified',
  'rejected',
  'suspended',
];

const DEFAULT_PROVIDER_CATEGORIES = [
  { slug: 'doctor', name: 'Doctor', slaHours: 24, sortOrder: 10 },
  { slug: 'nurse', name: 'Nurse', slaHours: 18, sortOrder: 20 },
  { slug: 'hospital', name: 'Hospital', slaHours: 48, sortOrder: 30 },
  { slug: 'laboratory', name: 'Lab / Diagnostic Lab', slaHours: 12, sortOrder: 40 },
  { slug: 'scan_center', name: 'Scan / MRI Center', slaHours: 12, sortOrder: 50 },
  { slug: 'pharmacy', name: 'Pharmacy', slaHours: 12, sortOrder: 60 },
  { slug: 'ambulance', name: 'Ambulance', slaHours: 8, sortOrder: 70 },
  { slug: 'blood_bank', name: 'Blood Bank', slaHours: 12, sortOrder: 80 },
  { slug: 'home_care', name: 'Home Care', slaHours: 18, sortOrder: 90 },
  {
    slug: 'medical_equipment',
    name: 'Medical Equipment',
    slaHours: 24,
    sortOrder: 100,
  },
  {
    slug: 'physiotherapist',
    name: 'Physiotherapist',
    slaHours: 18,
    sortOrder: 110,
  },
  { slug: 'other', name: 'Other Categories', slaHours: 24, sortOrder: 120 },
];

/** Maps UI/legacy permission values onto canonical category slugs. */
const CATEGORY_ALIASES = {
  doctor: ['doctor', 'doctors'],
  nurse: ['nurse', 'nurses', 'nursing'],
  hospital: ['hospital', 'hospitals'],
  laboratory: [
    'laboratory',
    'lab',
    'labs',
    'diagnostic_lab',
    'diagnostic-lab',
    'pathology',
  ],
  scan_center: [
    'scan_center',
    'scan-center',
    'scan',
    'scans',
    'mri',
    'mri_center',
    'mri-center',
    'mri_scan',
    'mri-scan',
    'imaging',
    'radiology',
  ],
  pharmacy: ['pharmacy', 'pharmacies'],
  ambulance: ['ambulance', 'ambulances', 'ambulance_service', 'ambulance-service'],
  blood_bank: [
    'blood_bank',
    'blood-bank',
    'bloodbank',
    'blood',
    'blood_banks',
  ],
  home_care: ['home_care', 'home-care', 'homecare'],
  medical_equipment: ['medical_equipment', 'medical-equipment'],
  physiotherapist: ['physiotherapist', 'physio'],
  other: ['other'],
};

function expandPermissionKeys(permissions = []) {
  const expanded = new Set();
  for (const raw of permissions) {
    const key = String(raw || '')
      .trim()
      .toLowerCase()
      .replace(/[\s-]+/g, '_');
    if (!key) continue;
    expanded.add(key);
    for (const [canonical, aliases] of Object.entries(CATEGORY_ALIASES)) {
      const normalizedAliases = aliases.map((alias) =>
        String(alias).replace(/-/g, '_'),
      );
      if (
        canonical === key ||
        aliases.includes(raw) ||
        aliases.includes(key) ||
        normalizedAliases.includes(key)
      ) {
        expanded.add(canonical);
        for (const alias of aliases) {
          expanded.add(String(alias).replace(/-/g, '_'));
        }
      }
    }
  }
  return [...expanded];
}

function permissionKeysForRequest(request) {
  return expandPermissionKeys([
    request?.providerCategory,
    request?.providerType,
  ]);
}

function canonicalCategoryForProviderType(providerType) {
  const key = String(providerType || '')
    .trim()
    .toLowerCase()
    .replace(/-/g, '_');
  if (PROVIDER_DEFINITIONS[key]) return PROVIDER_DEFINITIONS[key].category;
  for (const [canonical, aliases] of Object.entries(CATEGORY_ALIASES)) {
    if (canonical === key || aliases.includes(key)) return canonical;
  }
  return key || 'other';
}

async function requestDoctorDocuments(id, note) {
  await Doctor.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'under_review',
        approvalNotes: note,
      },
    },
  );
}

async function requestNurseDocuments(id, note) {
  await Nurse.updateOne(
    { id },
    {
      $set: {
        verificationStatus: 'under_review',
        approvalNotes: note,
      },
    },
  );
}

const PROVIDER_DEFINITIONS = {
  doctor: {
    category: 'doctor',
    label: 'Doctor',
    model: Doctor,
    mapper: toDoctor,
    name: (p) => [p.firstName, p.lastName].filter(Boolean).join(' ').trim(),
    phone: (p) => p.mobileNumber,
    approve: approveDoctor,
    reject: rejectDoctor,
    requestDocuments: requestDoctorDocuments,
  },
  nurse: {
    category: 'nurse',
    label: 'Nurse',
    model: Nurse,
    mapper: toNurse,
    name: (p) => [p.firstName, p.lastName].filter(Boolean).join(' ').trim(),
    phone: (p) => p.mobileNumber,
    approve: approveNurse,
    reject: rejectNurse,
    requestDocuments: requestNurseDocuments,
  },
  ambulance: {
    category: 'ambulance',
    label: 'Ambulance',
    model: Ambulance,
    mapper: toAmbulance,
    name: (p) => p.serviceName || p.ownerName,
    phone: (p) => p.mobileNumber,
    approve: approveAmbulance,
    reject: rejectAmbulance,
  },
  blood_bank: {
    category: 'blood_bank',
    label: 'Blood Bank',
    model: BloodBank,
    mapper: toBloodBank,
    name: (p) => p.institutionName || p.ownerName || p.contactPerson,
    phone: (p) => p.mobileNumber,
    approve: approveBloodBank,
    reject: rejectBloodBank,
    requestDocuments: requestBloodBankDocuments,
  },
  laboratory: {
    category: 'laboratory',
    label: 'Laboratory',
    model: Lab,
    mapper: toLab,
    name: (p) => p.labName || p.ownerName,
    phone: (p) => p.mobileNumber,
    approve: approveLab,
    reject: rejectLab,
    requestDocuments: requestLabDocuments,
  },
  scan_center: {
    category: 'scan_center',
    label: 'Scan Center',
    model: ScanCenter,
    mapper: toScanCenter,
    name: (p) => p.centerName || p.ownerName,
    phone: (p) => p.mobileNumber,
    approve: approveScanCenter,
    reject: rejectScanCenter,
    requestDocuments: requestScanCenterDocuments,
  },
};

function escapeRegex(value) {
  return String(value || '').replace(/[.*+?^${}()|[\]\\]/g, '\\$&');
}

function normalizeArray(value) {
  if (!Array.isArray(value)) return [];
  return [...new Set(value.map((v) => String(v || '').trim()).filter(Boolean))];
}

function canonicalizePermissions(permissions = []) {
  const result = new Set();
  for (const raw of permissions) {
    const key = String(raw || '')
      .trim()
      .toLowerCase()
      .replace(/[\s-]+/g, '_');
    if (!key) continue;
    let matched = false;
    for (const [canonical, aliases] of Object.entries(CATEGORY_ALIASES)) {
      const normalizedAliases = aliases.map((alias) =>
        String(alias).replace(/-/g, '_'),
      );
      if (
        canonical === key ||
        aliases.includes(raw) ||
        aliases.includes(key) ||
        normalizedAliases.includes(key)
      ) {
        result.add(canonical);
        matched = true;
        break;
      }
    }
    if (
      !matched &&
      DEFAULT_PROVIDER_CATEGORIES.some((category) => category.slug === key)
    ) {
      result.add(key);
    }
  }
  return [...result];
}

function normalizeEmail(email) {
  return String(email || '').trim().toLowerCase();
}

function isValidEmail(email) {
  return /^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,}$/.test(email);
}

function assertApproverFields(data, { requireCore = false } = {}) {
  const firstName = data.firstName != null ? String(data.firstName).trim() : '';
  const lastName = data.lastName != null ? String(data.lastName).trim() : '';
  const employeeId = data.employeeId != null ? String(data.employeeId).trim() : '';
  const email = data.email != null ? normalizeEmail(data.email) : '';
  const phone = data.phone != null ? String(data.phone).replace(/\D/g, '') : '';
  const password = data.password != null ? String(data.password) : '';

  if (requireCore || data.firstName != null) {
    if (!firstName) throw badRequest('First name is required');
    if (firstName.length < 2 || !/^[a-zA-Z.\s\-']+$/.test(firstName)) {
      throw badRequest('Enter a valid first name');
    }
  }
  if (requireCore || data.lastName != null) {
    if (!lastName) throw badRequest('Last name is required');
    if (lastName.length < 2 || !/^[a-zA-Z.\s\-']+$/.test(lastName)) {
      throw badRequest('Enter a valid last name');
    }
  }
  if (requireCore || data.employeeId != null) {
    if (!/^[A-Za-z0-9\-_]{3,20}$/.test(employeeId)) {
      throw badRequest('Employee ID must be 3–20 letters or numbers');
    }
  }
  if (requireCore || data.email != null) {
    if (!isValidEmail(email)) throw badRequest('Enter a valid email address');
  }
  if (phone) {
    if (!/^[6-9]\d{9}$/.test(phone)) {
      throw badRequest('Phone must be a valid 10-digit mobile number');
    }
  }
  if (requireCore && password.length < 8) {
    throw badRequest('Password must be at least 8 characters');
  }
  if (!requireCore && password && password.length < 8) {
    throw badRequest('Password must be at least 8 characters');
  }
  if (data.profilePicture) {
    try {
      const url = new URL(String(data.profilePicture).trim());
      if (url.protocol !== 'http:' && url.protocol !== 'https:') {
        throw new Error('bad url');
      }
    } catch {
      throw badRequest('Enter a valid profile picture URL');
    }
  }
  const pincode = data.regions?.[0]?.pincode;
  if (pincode && !/^\d{6}$/.test(String(pincode).trim())) {
    throw badRequest('PIN code must be 6 digits');
  }
}

function hashRefreshToken(token) {
  return crypto.createHash('sha256').update(String(token)).digest('hex');
}

function newRefreshToken() {
  return crypto.randomBytes(48).toString('base64url');
}

function badRequest(message) {
  const err = new Error(message);
  err.statusCode = 400;
  return err;
}

function validatedHours(value, field, { min = 0, max = 720 } = {}) {
  const hours = Number(value);
  if (!Number.isFinite(hours) || hours < min || hours > max) {
    throw badRequest(`${field} must be between ${min} and ${max} hours`);
  }
  return hours;
}

function toDate(value) {
  if (!value) return null;
  const date = new Date(value);
  return Number.isNaN(date.getTime()) ? null : date;
}

function addHours(date, hours) {
  return new Date(date.getTime() + Number(hours || 0) * 60 * 60 * 1000);
}

function minutesBetween(start, end) {
  if (!start || !end) return null;
  return Math.max(0, Math.round((end.getTime() - start.getTime()) / 60000));
}

function startOfDay(date = new Date()) {
  const d = new Date(date);
  d.setHours(0, 0, 0, 0);
  return d;
}

function startOfWeek(date = new Date()) {
  const d = startOfDay(date);
  d.setDate(d.getDate() - d.getDay());
  return d;
}

function startOfMonth(date = new Date()) {
  const d = startOfDay(date);
  d.setDate(1);
  return d;
}

function actorFromRequest(req) {
  const auth = req?.auth || {};
  const role =
    auth.role === 'approver' || auth.type === 'approver'
      ? 'approver'
      : 'super_admin';
  const id =
    auth.approverId ||
    auth.adminId ||
    auth.id ||
    auth.email ||
    auth.sub ||
    (role === 'approver' ? 'approver' : 'super-admin');
  const name =
    auth.name ||
    auth.email ||
    (role === 'approver' ? 'Approver' : 'Super Admin');
  return { id, name, role };
}

function requestIp(req) {
  return (
    req?.headers?.['x-forwarded-for']?.split(',')[0]?.trim() ||
    req?.ip ||
    req?.socket?.remoteAddress ||
    ''
  );
}

function requestDevice(req) {
  return req?.headers?.['user-agent'] || '';
}

function isApproverActor(actor) {
  return actor?.role === 'approver';
}

function isAdminActor(actor) {
  return actor?.role === 'super_admin' || actor?.role === 'admin';
}

function statusFromProviderStatus(status) {
  if (status === 'verified') return 'approved';
  if (status === 'rejected') return 'rejected';
  if (status === 'suspended') return 'on_hold';
  return 'pending';
}

function providerSnapshot(providerType, provider) {
  const def = PROVIDER_DEFINITIONS[providerType];
  const snapshot = {
    name: def?.name(provider) || 'Provider',
    email: provider.email,
    phone: def?.phone(provider),
    country: provider.country || 'India',
    state: provider.state,
    district: provider.district,
    city: provider.city,
    pincode: provider.pincode,
    registrationDate: toDate(provider.createdAt) || new Date(),
    rawStatus: provider.verificationStatus,
  };
  if (providerType === 'doctor') {
    snapshot.offersOnlineConsult = Boolean(provider.offersOnlineConsult);
    snapshot.offersBookHome = Boolean(provider.offersBookHome);
    snapshot.offersVisitSite = Boolean(provider.offersVisitSite);
  }
  return snapshot;
}

function toApprover(doc, metrics = {}) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    firstName: d.firstName,
    lastName: d.lastName,
    name: [d.firstName, d.lastName].filter(Boolean).join(' ').trim(),
    employeeId: d.employeeId,
    email: d.email,
    phone: d.phone,
    department: d.department,
    designation: d.designation,
    profilePicture: d.profilePicture,
    status: d.status,
    role: d.role || 'approver',
    permissions: d.permissions || [],
    regions: d.regions || [],
    canReassign: Boolean(d.canReassign),
    twoFactorReady: Boolean(d.twoFactorReady),
    lastLoginAt: d.lastLoginAt,
    loginCount: d.loginCount || 0,
    workload: metrics.workload || 0,
    assigned: metrics.assigned || 0,
    approved: metrics.approved || 0,
    rejected: metrics.rejected || 0,
    pending: metrics.pending || 0,
    averageApprovalTimeMinutes: Math.round(metrics.averageApprovalTimeMinutes || 0),
    acceptanceRate: metrics.acceptanceRate || 0,
    rejectionRate: metrics.rejectionRate || 0,
    escalations: metrics.escalations || 0,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

function slaStateFor(request) {
  if (!request?.slaDueAt || !OPEN_REQUEST_STATUSES.includes(request.status)) {
    return { state: 'completed', remainingMinutes: 0 };
  }
  const remainingMinutes = Math.round(
    (new Date(request.slaDueAt).getTime() - Date.now()) / 60000,
  );
  if (remainingMinutes < 0) {
    return { state: 'overdue', remainingMinutes };
  }
  if (remainingMinutes <= 240) {
    return { state: 'near_deadline', remainingMinutes };
  }
  return { state: 'within_sla', remainingMinutes };
}

function toApprovalRequest(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  const sla = slaStateFor(d);
  return {
    id: d.id,
    providerId: d.providerId,
    providerType: d.providerType,
    providerCategory: d.providerCategory,
    provider: d.provider || {},
    providerName: d.provider?.name,
    priority: d.priority,
    status: d.status,
    currentAssigneeId: d.currentAssigneeId,
    currentAssigneeName: d.currentAssigneeName,
    assignedBy: d.assignedBy,
    assignedAt: d.assignedAt,
    assignmentStrategy: d.assignmentStrategy,
    currentApprovalLevel: d.currentApprovalLevel,
    approvalLevels: d.approvalLevels || [],
    slaHours: d.slaHours,
    slaDueAt: d.slaDueAt,
    remainingSlaMinutes: sla.remainingMinutes,
    slaState: sla.state,
    viewedAt: d.viewedAt,
    completedAt: d.completedAt,
    approvalDurationMinutes: d.approvalDurationMinutes,
    lastActionAt: d.lastActionAt,
    lastActionBy: d.lastActionBy,
    lastRemarks: d.lastRemarks,
    timeline: d.timeline || [],
    internalNotes: d.internalNotes || [],
    assignmentHistory: d.assignmentHistory || [],
    approvalHistory: d.approvalHistory || [],
    metadata: d.metadata || {},
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

async function writeAudit({
  req,
  actor,
  action,
  entityType,
  entityId,
  entityLabel,
  metadata = {},
}) {
  await AuditLog.create({
    id: uuidv4(),
    actorId: actor?.id,
    actorName: actor?.name,
    actorRole: actor?.role,
    action,
    entityType,
    entityId,
    entityLabel,
    ip: requestIp(req),
    device: requestDevice(req),
    metadata,
    createdAt: new Date(),
  });
}

async function createApprovalNotification({
  recipientId,
  recipientRole,
  title,
  body,
  type,
  data = {},
  channels = ['in_app'],
}) {
  if (!recipientId) return null;
  return ApprovalNotification.create({
    id: uuidv4(),
    recipientId,
    recipientRole,
    channels,
    title,
    body,
    type,
    data,
  });
}

async function ensureApprovalConfiguration() {
  await Promise.all(
    DEFAULT_PROVIDER_CATEGORIES.map((category) =>
      ProviderCategory.updateOne(
        { slug: category.slug },
        {
          $set: {
            name: category.name,
            description: `${category.name} approval workflow`,
            slaHours: category.slaHours,
            sortOrder: category.sortOrder,
            active: true,
          },
          $setOnInsert: {
            id: uuidv4(),
            slug: category.slug,
          },
        },
        { upsert: true },
      ),
    ),
  );

  await Promise.all(
    DEFAULT_PROVIDER_CATEGORIES.map((category) =>
      ApprovalRule.updateOne(
        { providerCategory: category.slug },
        {
          // Keep `active` only in $set — Mongo rejects the same path in $set + $setOnInsert.
          $setOnInsert: {
            id: uuidv4(),
            providerCategory: category.slug,
            assignmentStrategy: 'least_busy',
            slaHours: category.slaHours,
            escalationHours: 4,
            approvalLevels: [
              {
                id: 'level_1_approver',
                name: 'Primary Approver',
                role: 'approver',
                required: true,
                order: 1,
              },
              {
                id: 'level_2_admin',
                name: 'Admin Override',
                role: 'super_admin',
                required: false,
                order: 2,
              },
            ],
          },
          $set: {
            active: true,
          },
        },
        { upsert: true },
      ),
    ),
  );
}

async function getRuleForCategory(providerCategory) {
  await ensureApprovalConfiguration();
  return ApprovalRule.findOne({ providerCategory, active: true });
}

const SYNC_TTL_MS = 30 * 1000;
let _lastSyncAt = 0;
let _syncPromise = null;

async function syncProviderRequests({ force = false } = {}) {
  const now = Date.now();
  if (!force && now - _lastSyncAt < SYNC_TTL_MS) {
    return;
  }
  if (_syncPromise) {
    return _syncPromise;
  }

  _syncPromise = (async () => {
    await ensureApprovalConfiguration();

    const rules = await ApprovalRule.find({ active: true }).lean();
    const rulesByCategory = Object.fromEntries(
      rules.map((rule) => [rule.providerCategory, rule]),
    );

    for (const [providerType, def] of Object.entries(PROVIDER_DEFINITIONS)) {
      try {
        const docs = await def.model
          .find({ verificationStatus: { $in: REVIEW_PROVIDER_STATUSES } })
          .sort({ createdAt: -1 })
          .limit(500)
          .lean();

        if (!docs.length) continue;

        const providers = docs
          .map((raw) => def.mapper(raw))
          .filter((provider) => provider?.id);
        if (!providers.length) continue;

        const existingList = await ApprovalRequest.find({
          providerType,
          providerId: { $in: providers.map((provider) => provider.id) },
        })
          .select({
            providerId: 1,
            status: 1,
            approvalLevels: 1,
            timeline: 1,
          })
          .lean();
        const existingById = new Map(
          existingList.map((item) => [item.providerId, item]),
        );

        const rule = rulesByCategory[def.category];
        const ops = [];

        for (const provider of providers) {
          const existing = existingById.get(provider.id);
          const snapshot = providerSnapshot(providerType, provider);
          const mappedStatus = statusFromProviderStatus(
            provider.verificationStatus,
          );
          const registrationDate = snapshot.registrationDate || new Date();
          const slaHours = rule?.slaHours || 24;
          const approvalLevels = [...(rule?.approvalLevels || [])]
            .sort((a, b) => Number(a.order || 0) - Number(b.order || 0))
            .map((level) => ({
              id: uuidv4(),
              levelId: level.id,
              levelName: level.name,
              levelOrder: level.order,
              role: level.role,
              required: level.required !== false,
              status: level.required === false ? 'skipped' : 'pending',
            }));
          const firstRequiredLevel = approvalLevels.find(
            (level) => level.status === 'pending',
          );
          const existingClosed =
            existing && ['approved', 'rejected'].includes(existing.status);
          const status =
            mappedStatus === 'approved' || mappedStatus === 'rejected'
              ? mappedStatus
              : existingClosed
                ? existing.status
                : existing?.status || mappedStatus;

          const timeline =
            existing?.timeline?.length > 0
              ? existing.timeline
              : [
                  {
                    id: uuidv4(),
                    actor: {
                      id: provider.id,
                      name: snapshot.name,
                      role: 'provider',
                    },
                    action: 'provider_registered',
                    remarks: 'Provider registered in the platform.',
                    createdAt: registrationDate,
                    metadata: { providerType },
                  },
                  {
                    id: uuidv4(),
                    actor: { id: 'system', name: 'System', role: 'system' },
                    action: 'approval_request_created',
                    remarks: 'Approval workflow request created.',
                    createdAt: new Date(),
                    metadata: {
                      providerType,
                      providerCategory: def.category,
                    },
                  },
                ];

          // Never put the same path in both $set and $setOnInsert (Mongo conflict).
          const setOnInsert = {
            id: uuidv4(),
            priority: 'normal',
            providerType,
            providerId: provider.id,
            slaHours,
            slaDueAt: addHours(registrationDate, slaHours),
            timeline,
            approvalLevels,
            currentApprovalLevel: firstRequiredLevel?.levelOrder || 1,
          };
          const setFields = {
            provider: snapshot,
            status,
            providerCategory: def.category,
            metadata: {
              providerLabel: def.label,
              providerVerificationStatus: provider.verificationStatus,
            },
          };

          // Backfill levels only on existing docs that are missing them.
          if (
            existing &&
            !existing.approvalLevels?.length &&
            approvalLevels.length
          ) {
            setFields.approvalLevels = approvalLevels;
            setFields.currentApprovalLevel =
              firstRequiredLevel?.levelOrder || 1;
          }

          ops.push({
            updateOne: {
              filter: { providerType, providerId: provider.id },
              update: {
                $setOnInsert: setOnInsert,
                $set: setFields,
              },
              upsert: true,
            },
          });
        }

        if (ops.length) {
          try {
            await ApprovalRequest.bulkWrite(ops, { ordered: false });
          } catch (err) {
            // ordered:false still throws when some ops fail; keep syncing others.
            console.error(
              `Approval sync bulkWrite failed for ${providerType}:`,
              err?.message || err,
            );
          }
        }
      } catch (err) {
        console.error(
          `Approval sync failed for ${providerType}:`,
          err?.message || err,
        );
      }
    }

    await autoAssignUnassignedRequests();
    _lastSyncAt = Date.now();
  })().finally(() => {
    _syncPromise = null;
  });

  return _syncPromise;
}

/**
 * Assign open, unassigned requests to eligible approvers using each
 * category's assignment strategy (default: least_busy).
 */
async function autoAssignUnassignedRequests() {
  const unassigned = await ApprovalRequest.find({
    status: { $in: OPEN_REQUEST_STATUSES },
    $or: [
      { currentAssigneeId: null },
      { currentAssigneeId: { $exists: false } },
      { currentAssigneeId: '' },
    ],
  })
    .sort({ createdAt: 1 })
    .limit(500);

  if (!unassigned.length) return;

  const rules = await ApprovalRule.find({ active: true }).lean();
  const strategyByCategory = Object.fromEntries(
    rules.map((rule) => [
      rule.providerCategory,
      rule.assignmentStrategy || 'least_busy',
    ]),
  );

  const systemActor = { id: 'system', name: 'System', role: 'system' };

  for (const request of unassigned) {
    const strategy =
      strategyByCategory[request.providerCategory] || 'least_busy';
    const approver = await chooseApproverForRequest(request, strategy);
    if (!approver) continue;

    const toApproverName = `${approver.firstName} ${approver.lastName}`.trim();
    const eventId = uuidv4();
    const result = await ApprovalRequest.updateOne(
      {
        id: request.id,
        $or: [
          { currentAssigneeId: null },
          { currentAssigneeId: { $exists: false } },
          { currentAssigneeId: '' },
        ],
      },
      {
        $set: {
          currentAssigneeId: approver.id,
          currentAssigneeName: toApproverName,
          assignedBy: systemActor,
          assignedAt: new Date(),
          assignmentStrategy: strategy,
          lastActionAt: new Date(),
          lastActionBy: systemActor,
          lastRemarks: `Auto-assigned via ${strategy}`,
        },
        $push: {
          assignmentHistory: {
            id: eventId,
            fromApproverId: null,
            fromApproverName: null,
            toApproverId: approver.id,
            toApproverName,
            strategy,
            assignedBy: systemActor,
            remarks: `Auto-assigned via ${strategy}`,
            createdAt: new Date(),
          },
          timeline: {
            id: uuidv4(),
            actor: systemActor,
            action: 'request_assigned',
            remarks: `Auto-assigned to ${toApproverName}.`,
            createdAt: new Date(),
            metadata: { strategy, auto: true },
          },
        },
      },
    );

    if (result.modifiedCount > 0) {
      await createApprovalNotification({
        recipientId: approver.id,
        recipientRole: 'approver',
        title: 'New approval request',
        body: `${request.provider?.name || 'A provider'} was assigned to you for review.`,
        type: 'provider_assigned',
        data: {
          requestId: request.id,
          providerId: request.providerId,
          providerType: request.providerType,
        },
      });
    }
  }
}

async function getApproverMetrics(approverIds) {
  if (!approverIds.length) return {};
  const metrics = Object.fromEntries(
    approverIds.map((id) => [
      id,
      {
        workload: 0,
        assigned: 0,
        approved: 0,
        rejected: 0,
        pending: 0,
        averageApprovalTimeMinutes: 0,
        acceptanceRate: 0,
        rejectionRate: 0,
        escalations: 0,
      },
    ]),
  );

  const [pendingAgg, assignedAgg, historyAgg, escalationAgg] = await Promise.all([
    ApprovalRequest.aggregate([
      {
        $match: {
          currentAssigneeId: { $in: approverIds },
          status: { $in: OPEN_REQUEST_STATUSES },
        },
      },
      { $group: { _id: '$currentAssigneeId', count: { $sum: 1 } } },
    ]),
    ApprovalRequest.aggregate([
      { $unwind: '$assignmentHistory' },
      {
        $match: {
          'assignmentHistory.toApproverId': { $in: approverIds },
        },
      },
      { $group: { _id: '$assignmentHistory.toApproverId', count: { $sum: 1 } } },
    ]),
    ApprovalRequest.aggregate([
      { $unwind: '$approvalHistory' },
      {
        $match: {
          'approvalHistory.actor.id': { $in: approverIds },
          'approvalHistory.action': { $in: ['approve', 'reject'] },
        },
      },
      {
        $group: {
          _id: {
            id: '$approvalHistory.actor.id',
            action: '$approvalHistory.action',
          },
          count: { $sum: 1 },
          avgDuration: { $avg: '$approvalHistory.durationMinutes' },
        },
      },
    ]),
    ApprovalRequest.aggregate([
      { $unwind: '$approvalHistory' },
      {
        $match: {
          'approvalHistory.actor.id': { $in: approverIds },
          'approvalHistory.action': 'escalate',
        },
      },
      {
        $group: {
          _id: '$approvalHistory.actor.id',
          count: { $sum: 1 },
        },
      },
    ]),
  ]);

  for (const row of pendingAgg) {
    if (metrics[row._id]) {
      metrics[row._id].workload = row.count;
      metrics[row._id].pending = row.count;
    }
  }
  for (const row of assignedAgg) {
    if (metrics[row._id]) metrics[row._id].assigned = row.count;
  }
  for (const row of historyAgg) {
    const item = metrics[row._id.id];
    if (!item) continue;
    if (row._id.action === 'approve') item.approved = row.count;
    if (row._id.action === 'reject') item.rejected = row.count;
    if (row.avgDuration) {
      item.averageApprovalTimeMinutes = row.avgDuration;
    }
  }
  for (const row of escalationAgg) {
    if (metrics[row._id]) metrics[row._id].escalations = row.count;
  }

  for (const item of Object.values(metrics)) {
    const decisions = item.approved + item.rejected;
    if (decisions > 0) {
      item.acceptanceRate = Math.round((item.approved / decisions) * 100);
      item.rejectionRate = Math.round((item.rejected / decisions) * 100);
    }
  }

  return metrics;
}

async function listApprovers({ page = 1, pageSize = 50, status, search } = {}) {
  const filter = { deletedAt: null };
  if (status) filter.status = status;
  if (search?.trim()) {
    const regex = new RegExp(escapeRegex(search.trim()), 'i');
    filter.$or = [
      { firstName: regex },
      { lastName: regex },
      { employeeId: regex },
      { email: regex },
      { department: regex },
      { designation: regex },
    ];
  }
  const totalCount = await Approver.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const docs = await Approver.find(filter)
    .sort({ status: 1, firstName: 1, lastName: 1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize);
  const ids = docs.map((d) => d.id);
  const metrics = await getApproverMetrics(ids);
  return {
    approvers: docs.map((doc) => toApprover(doc, metrics[doc.id] || {})),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function createApprover(data, { req } = {}) {
  await ensureApprovalConfiguration();
  assertApproverFields(data || {}, { requireCore: true });
  const email = normalizeEmail(data.email);
  const existing = await Approver.findOne({
    $or: [{ email }, { employeeId: String(data.employeeId).trim() }],
  });
  if (existing) {
    const err = new Error('Approver email or employee ID already exists');
    err.statusCode = 409;
    throw err;
  }

  const doc = await Approver.create({
    id: uuidv4(),
    firstName: data.firstName.trim(),
    lastName: data.lastName.trim(),
    employeeId: String(data.employeeId).trim(),
    email,
    phone: data.phone ? String(data.phone).replace(/\D/g, '') : data.phone,
    passwordHash: bcrypt.hashSync(String(data.password), 10),
    department: data.department,
    designation: data.designation,
    profilePicture: data.profilePicture,
    status: data.status === 'inactive' ? 'inactive' : 'active',
    permissions: canonicalizePermissions(data.permissions),
    regions: Array.isArray(data.regions) ? data.regions : [],
    canReassign: Boolean(data.canReassign),
  });

  const actor = actorFromRequest(req);
  await writeAudit({
    req,
    actor,
    action: 'approver_created',
    entityType: 'approver',
    entityId: doc.id,
    entityLabel: `${doc.firstName} ${doc.lastName}`.trim(),
    metadata: { permissions: doc.permissions, regions: doc.regions },
  });

  // Immediately place matching open applications into this approver's queue.
  try {
    await syncProviderRequests();
    await autoAssignUnassignedRequests();
  } catch (err) {
    console.error('Failed to auto-assign after creating approver:', err);
  }

  return toApprover(doc);
}

async function updateApprover(id, data, { req } = {}) {
  const existing = await Approver.findOne({ id, deletedAt: null });
  if (!existing) {
    const err = new Error('Approver not found');
    err.statusCode = 404;
    throw err;
  }

  const beforePermissions = [...(existing.permissions || [])];
  assertApproverFields(data || {});
  const update = {};
  const fields = [
    'firstName',
    'lastName',
    'employeeId',
    'email',
    'phone',
    'department',
    'designation',
    'profilePicture',
  ];
  for (const field of fields) {
    if (data[field] != null) {
      update[field] = field === 'email' ? normalizeEmail(data[field]) : data[field];
    }
  }
  if (data.status === 'active' || data.status === 'inactive') update.status = data.status;
  if (Array.isArray(data.permissions)) {
    update.permissions = canonicalizePermissions(data.permissions);
  }
  if (Array.isArray(data.regions)) update.regions = data.regions;
  if (data.canReassign != null) update.canReassign = Boolean(data.canReassign);

  await Approver.updateOne({ id }, { $set: update });
  const updated = await Approver.findOne({ id });

  const actor = actorFromRequest(req);
  const action =
    update.permissions &&
    JSON.stringify(beforePermissions.sort()) !==
      JSON.stringify([...(updated.permissions || [])].sort())
      ? 'approver_permissions_changed'
      : 'approver_updated';
  await writeAudit({
    req,
    actor,
    action,
    entityType: 'approver',
    entityId: id,
    entityLabel: `${updated.firstName} ${updated.lastName}`.trim(),
    metadata: { changedFields: Object.keys(update), permissions: updated.permissions },
  });

  if (update.permissions || update.regions || update.status === 'active') {
    try {
      await syncProviderRequests();
      await autoAssignUnassignedRequests();
    } catch (err) {
      console.error('Failed to auto-assign after updating approver:', err);
    }
  }

  return toApprover(updated);
}

async function setApproverStatus(id, status, { req, reason } = {}) {
  if (!['active', 'inactive'].includes(status)) {
    const err = new Error('status must be active or inactive');
    err.statusCode = 400;
    throw err;
  }
  const existing = await Approver.findOne({ id, deletedAt: null });
  if (!existing) {
    const err = new Error('Approver not found');
    err.statusCode = 404;
    throw err;
  }
  await Approver.updateOne(
    { id },
    {
      $set: {
        status,
        deactivatedAt: status === 'inactive' ? new Date() : null,
      },
    },
  );
  if (status === 'inactive') {
    await ApprovalSession.updateMany(
      { userId: id, revokedAt: null },
      { $set: { revokedAt: new Date(), revokedReason: 'account_deactivated' } },
    );
  }
  const updated = await Approver.findOne({ id });
  const actor = actorFromRequest(req);
  await writeAudit({
    req,
    actor,
    action: status === 'active' ? 'approver_activated' : 'approver_deactivated',
    entityType: 'approver',
    entityId: id,
    entityLabel: `${updated.firstName} ${updated.lastName}`.trim(),
    metadata: { reason },
  });
  return toApprover(updated);
}

function generateTemporaryPassword() {
  return `Apr@${crypto.randomBytes(9).toString('base64url')}`;
}

async function resetApproverPassword(id, data = {}, { req } = {}) {
  const existing = await Approver.findOne({ id, deletedAt: null });
  if (!existing) {
    const err = new Error('Approver not found');
    err.statusCode = 404;
    throw err;
  }
  const temporaryPassword = data.password || generateTemporaryPassword();
  if (String(temporaryPassword).length < 8) {
    const err = new Error('Password must be at least 8 characters');
    err.statusCode = 400;
    throw err;
  }
  await Approver.updateOne(
    { id },
    { $set: { passwordHash: bcrypt.hashSync(String(temporaryPassword), 10) } },
  );
  await ApprovalSession.updateMany(
    { userId: id, revokedAt: null },
    { $set: { revokedAt: new Date(), revokedReason: 'password_reset' } },
  );
  const actor = actorFromRequest(req);
  await writeAudit({
    req,
    actor,
    action: 'approver_password_reset',
    entityType: 'approver',
    entityId: id,
    entityLabel: `${existing.firstName} ${existing.lastName}`.trim(),
  });
  return { approver: toApprover(existing), temporaryPassword };
}

async function deleteApprover(id, { req, reason } = {}) {
  const existing = await Approver.findOne({ id, deletedAt: null });
  if (!existing) {
    const err = new Error('Approver not found');
    err.statusCode = 404;
    throw err;
  }
  await Approver.updateOne(
    { id },
    {
      $set: {
        status: 'inactive',
        deletedAt: new Date(),
        deactivatedAt: new Date(),
      },
    },
  );
  await ApprovalSession.updateMany(
    { userId: id, revokedAt: null },
    { $set: { revokedAt: new Date(), revokedReason: 'account_deleted' } },
  );
  const actor = actorFromRequest(req);
  await writeAudit({
    req,
    actor,
    action: 'approver_deleted',
    entityType: 'approver',
    entityId: id,
    entityLabel: `${existing.firstName} ${existing.lastName}`.trim(),
    metadata: { reason },
  });
  return true;
}

async function loginApprover({ email, password }, { req } = {}) {
  const approver = await Approver.findOne({ email: normalizeEmail(email), deletedAt: null });
  if (!approver || approver.status !== 'active') {
    const err = new Error('Invalid credentials');
    err.statusCode = 401;
    throw err;
  }
  const valid = bcrypt.compareSync(String(password || ''), approver.passwordHash);
  if (!valid) {
    const err = new Error('Invalid credentials');
    err.statusCode = 401;
    throw err;
  }
  await Approver.updateOne(
    { id: approver.id },
    {
      $set: { lastLoginAt: new Date(), lastLoginIp: requestIp(req) },
      $inc: { loginCount: 1 },
    },
  );
  const actor = { id: approver.id, name: `${approver.firstName} ${approver.lastName}`, role: 'approver' };
  await writeAudit({
    req,
    actor,
    action: 'approver_login',
    entityType: 'approver',
    entityId: approver.id,
    entityLabel: actor.name,
  });
  return toApprover(approver);
}

async function createApproverSession(approver, { req } = {}) {
  const refreshToken = newRefreshToken();
  const expiresAt = new Date(Date.now() + 30 * 24 * 60 * 60 * 1000);
  const session = await ApprovalSession.create({
    id: uuidv4(),
    userId: approver.id,
    userRole: 'approver',
    refreshTokenHash: hashRefreshToken(refreshToken),
    ip: requestIp(req),
    device: requestDevice(req),
    userAgent: requestDevice(req),
    lastSeenAt: new Date(),
    expiresAt,
  });
  return { sessionId: session.id, refreshToken, expiresAt };
}

async function refreshApproverSession({ sessionId, refreshToken }, { req } = {}) {
  if (!sessionId || !refreshToken) {
    const err = new Error('sessionId and refreshToken are required');
    err.statusCode = 400;
    throw err;
  }
  const session = await ApprovalSession.findOne({
    id: sessionId,
    userRole: 'approver',
    revokedAt: null,
    expiresAt: { $gt: new Date() },
  });
  if (
    !session ||
    !crypto.timingSafeEqual(
      Buffer.from(session.refreshTokenHash),
      Buffer.from(hashRefreshToken(refreshToken)),
    )
  ) {
    const err = new Error('Invalid or expired refresh token');
    err.statusCode = 401;
    throw err;
  }
  const approver = await Approver.findOne({
    id: session.userId,
    status: 'active',
    deletedAt: null,
  });
  if (!approver) {
    const err = new Error('Approver account is inactive');
    err.statusCode = 401;
    throw err;
  }

  const rotatedRefreshToken = newRefreshToken();
  session.refreshTokenHash = hashRefreshToken(rotatedRefreshToken);
  session.lastSeenAt = new Date();
  session.ip = requestIp(req);
  session.device = requestDevice(req);
  await session.save();

  return {
    approver: toApprover(approver),
    sessionId: session.id,
    refreshToken: rotatedRefreshToken,
    expiresAt: session.expiresAt,
  };
}

async function revokeApproverSession(sessionId, { req } = {}) {
  const session = await ApprovalSession.findOne({
    id: sessionId,
    userRole: 'approver',
    revokedAt: null,
  });
  if (!session) return false;
  session.revokedAt = new Date();
  session.revokedReason = 'logout';
  await session.save();
  const approver = await Approver.findOne({ id: session.userId });
  await writeAudit({
    req,
    actor: {
      id: session.userId,
      name: approver
        ? `${approver.firstName} ${approver.lastName}`.trim()
        : 'Approver',
      role: 'approver',
    },
    action: 'approver_logout',
    entityType: 'approver',
    entityId: session.userId,
    entityLabel: approver
      ? `${approver.firstName} ${approver.lastName}`.trim()
      : session.userId,
  });
  return true;
}

function regionMatches(approver, request) {
  const regions = approver.regions || [];
  if (regions.length === 0) return true;
  const provider = request.provider || {};
  return regions.some((region) => {
    const entries = [
      ['country', provider.country],
      ['state', provider.state],
      ['district', provider.district],
      ['city', provider.city],
      ['pincode', provider.pincode],
    ];
    return entries.every(([key, value]) => {
      const expected = String(region[key] || '').trim().toLowerCase();
      if (!expected) return true;
      const actual = String(value || '').trim().toLowerCase();
      // Provider profile may be incomplete — don't exclude on missing fields.
      if (!actual) return true;
      return expected === actual;
    });
  });
}

function hasCategoryPermission(approver, request) {
  const permissions = expandPermissionKeys(approver.permissions || []);
  if (permissions.includes('other')) return true;
  const requestKeys = permissionKeysForRequest(request).filter(
    (key) => key !== 'other',
  );
  return requestKeys.some((key) => permissions.includes(key));
}

function isUnassignedRequest(request) {
  return !request?.currentAssigneeId;
}

async function buildApproverVisibilityFilter(actor) {
  if (!actor || !isApproverActor(actor)) return null;
  const approver = await Approver.findOne({
    id: actor.id,
    status: 'active',
    deletedAt: null,
  });
  const permissions = expandPermissionKeys(approver?.permissions || []);
  // Always show work assigned to this approver (any status).
  const clauses = [{ currentAssigneeId: actor.id }];

  if (!permissions.length) {
    return { $or: clauses };
  }

  // "other" = every open request; otherwise open requests in permitted categories.
  // This is what makes "Doctor" role put doctor applications in her queue.
  if (permissions.includes('other')) {
    clauses.push({ status: { $in: OPEN_REQUEST_STATUSES } });
  } else {
    const categoryKeys = permissions.filter((key) => key !== 'other');
    if (categoryKeys.length) {
      clauses.push({
        status: { $in: OPEN_REQUEST_STATUSES },
        $or: [
          { providerCategory: { $in: categoryKeys } },
          { providerType: { $in: categoryKeys } },
        ],
      });
    }
  }

  return { $or: clauses };
}

async function eligibleApproversForRequest(request) {
  const requestKeys = [
    ...permissionKeysForRequest(request),
    'other', // approvers with catch-all "other" permission
  ];
  const candidates = await Approver.find({
    status: 'active',
    deletedAt: null,
    permissions: { $in: requestKeys },
  }).sort({ firstName: 1, lastName: 1 });
  return candidates.filter(
    (approver) =>
      hasCategoryPermission(approver, request) &&
      regionMatches(approver, request),
  );
}

async function chooseApproverForRequest(request, strategy = 'least_busy') {
  const candidates = await eligibleApproversForRequest(request);
  if (!candidates.length) return null;

  if (strategy === 'round_robin') {
    const lastAssignments = await ApprovalRequest.aggregate([
      { $unwind: '$assignmentHistory' },
      {
        $match: {
          'assignmentHistory.toApproverId': { $in: candidates.map((c) => c.id) },
        },
      },
      {
        $group: {
          _id: '$assignmentHistory.toApproverId',
          lastAssignedAt: { $max: '$assignmentHistory.createdAt' },
        },
      },
    ]);
    const lastMap = new Map(lastAssignments.map((row) => [row._id, row.lastAssignedAt]));
    return [...candidates].sort((a, b) => {
      const aTime = lastMap.get(a.id)?.getTime?.() || 0;
      const bTime = lastMap.get(b.id)?.getTime?.() || 0;
      return aTime - bTime;
    })[0];
  }

  const workloads = await ApprovalRequest.aggregate([
    {
      $match: {
        currentAssigneeId: { $in: candidates.map((c) => c.id) },
        status: { $in: OPEN_REQUEST_STATUSES },
      },
    },
    { $group: { _id: '$currentAssigneeId', count: { $sum: 1 } } },
  ]);
  const workloadMap = new Map(workloads.map((row) => [row._id, row.count]));
  return [...candidates].sort((a, b) => {
    const diff = (workloadMap.get(a.id) || 0) - (workloadMap.get(b.id) || 0);
    if (diff !== 0) return diff;
    return String(a.firstName).localeCompare(String(b.firstName));
  })[0];
}

async function listEligibleApprovers(requestId, { req } = {}) {
  const request = await ApprovalRequest.findOne({ id: requestId });
  if (!request) {
    const err = new Error('Approval request not found');
    err.statusCode = 404;
    throw err;
  }
  const actor = actorFromRequest(req);
  if (isApproverActor(actor)) {
    await ensureRequestAccess(request, actor);
    const currentApprover = await Approver.findOne({
      id: actor.id,
      status: 'active',
      deletedAt: null,
    });
    if (!currentApprover?.canReassign) {
      const err = new Error('You do not have permission to reassign requests');
      err.statusCode = 403;
      throw err;
    }
  }
  const approvers = await eligibleApproversForRequest(request);
  return approvers.map((approver) => ({
    id: approver.id,
    name: `${approver.firstName} ${approver.lastName}`.trim(),
  }));
}

async function assignApprovalRequest(
  requestId,
  { approverId, strategy = 'manual', remarks },
  { req } = {},
) {
  const request = await ApprovalRequest.findOne({ id: requestId });
  if (!request) {
    const err = new Error('Approval request not found');
    err.statusCode = 404;
    throw err;
  }

  const actor = actorFromRequest(req);
  if (isApproverActor(actor)) {
    await ensureRequestAccess(request, actor);
    const approverActor = await Approver.findOne({ id: actor.id });
    if (!approverActor?.canReassign) {
      const err = new Error('You do not have permission to reassign requests');
      err.statusCode = 403;
      throw err;
    }
  }

  let approver = null;
  if (approverId) {
    approver = await Approver.findOne({ id: approverId, status: 'active', deletedAt: null });
  } else {
    approver = await chooseApproverForRequest(request, strategy);
  }

  if (!approver) {
    const err = new Error('No eligible active approver found for this request');
    err.statusCode = 400;
    throw err;
  }
  if (!hasCategoryPermission(approver, request) || !regionMatches(approver, request)) {
    const err = new Error('Approver is not eligible for this category or region');
    err.statusCode = 400;
    throw err;
  }

  const fromApproverId = request.currentAssigneeId;
  const fromApproverName = request.currentAssigneeName;
  if (fromApproverId && !String(remarks || '').trim()) {
    throw badRequest('remarks are required when reassigning a request');
  }
  const toApproverName = `${approver.firstName} ${approver.lastName}`.trim();
  const eventId = uuidv4();
  await ApprovalRequest.updateOne(
    { id: requestId },
    {
      $set: {
        currentAssigneeId: approver.id,
        currentAssigneeName: toApproverName,
        assignedBy: actor,
        assignedAt: new Date(),
        assignmentStrategy: strategy,
        lastActionAt: new Date(),
        lastActionBy: actor,
        lastRemarks: remarks || null,
      },
      $push: {
        assignmentHistory: {
          id: eventId,
          fromApproverId,
          fromApproverName,
          toApproverId: approver.id,
          toApproverName,
          strategy,
          assignedBy: actor,
          remarks,
          createdAt: new Date(),
        },
        timeline: {
          id: uuidv4(),
          actor,
          action: fromApproverId ? 'request_reassigned' : 'request_assigned',
          remarks: remarks || `Assigned to ${toApproverName}.`,
          ip: requestIp(req),
          device: requestDevice(req),
          createdAt: new Date(),
          metadata: {
            fromApproverId,
            fromApproverName,
            toApproverId: approver.id,
            toApproverName,
            strategy,
          },
        },
      },
    },
  );

  await writeAudit({
    req,
    actor,
    action: fromApproverId ? 'approval_request_reassigned' : 'approval_request_assigned',
    entityType: 'approval_request',
    entityId: requestId,
    entityLabel: request.provider?.name,
    metadata: {
      fromApproverId,
      fromApproverName,
      toApproverId: approver.id,
      toApproverName,
      strategy,
      remarks,
    },
  });

  await createApprovalNotification({
    recipientId: approver.id,
    recipientRole: 'approver',
    title: 'New provider assigned',
    body: `${request.provider?.name || 'Provider'} is ready for review.`,
    type: 'provider_assigned',
    data: { requestId, providerId: request.providerId, providerType: request.providerType },
  });

  return toApprovalRequest(await ApprovalRequest.findOne({ id: requestId }));
}

async function ensureRequestAccess(request, actor) {
  if (!isApproverActor(actor)) return;
  if (request.currentAssigneeId === actor.id) return;

  const approver = await Approver.findOne({
    id: actor.id,
    status: 'active',
    deletedAt: null,
  });
  const eligible =
    approver &&
    hasCategoryPermission(approver, request) &&
    regionMatches(approver, request);

  // Eligible approvers may open any open request in their category
  // (assigned or not) so doctor-role verifiers can review doctor apps.
  if (eligible && OPEN_REQUEST_STATUSES.includes(request.status)) {
    return;
  }

  const err = new Error(
    eligible
      ? 'This approval request is already completed'
      : 'This approval request is not in your assigned categories or region',
  );
  err.statusCode = 403;
  throw err;
}

async function claimRequestIfUnassigned(request, actor) {
  if (!isApproverActor(actor)) return request;
  if (request.currentAssigneeId === actor.id) return request;

  const approver = await Approver.findOne({
    id: actor.id,
    status: 'active',
    deletedAt: null,
  });
  if (
    !approver ||
    !hasCategoryPermission(approver, request) ||
    !regionMatches(approver, request)
  ) {
    const err = new Error(
      'You are not eligible to claim this request for your category or region',
    );
    err.statusCode = 403;
    throw err;
  }

  // Eligible category approver takes ownership when acting on an open request.
  if (!OPEN_REQUEST_STATUSES.includes(request.status)) {
    return request;
  }

  const fromApproverId = request.currentAssigneeId || null;
  const fromApproverName = request.currentAssigneeName || null;
  const toApproverName = `${approver.firstName} ${approver.lastName}`.trim();
  const eventId = uuidv4();
  const claimRemarks = fromApproverId
    ? 'Taken over for category verification'
    : 'Claimed from unassigned queue';

  await ApprovalRequest.updateOne(
    {
      id: request.id,
      status: { $in: OPEN_REQUEST_STATUSES },
      $or: [
        { currentAssigneeId: null },
        { currentAssigneeId: { $exists: false } },
        { currentAssigneeId: '' },
        { currentAssigneeId: fromApproverId },
      ],
    },
    {
      $set: {
        currentAssigneeId: approver.id,
        currentAssigneeName: toApproverName,
        assignedBy: actor,
        assignedAt: new Date(),
        assignmentStrategy: 'self_claim',
        lastActionAt: new Date(),
        lastActionBy: actor,
        lastRemarks: claimRemarks,
      },
      $push: {
        assignmentHistory: {
          id: eventId,
          fromApproverId,
          fromApproverName,
          toApproverId: approver.id,
          toApproverName,
          strategy: 'self_claim',
          assignedBy: actor,
          remarks: claimRemarks,
          createdAt: new Date(),
        },
        timeline: {
          id: uuidv4(),
          actor,
          action: 'request_assigned',
          remarks: `${claimRemarks} by ${toApproverName}.`,
          createdAt: new Date(),
          metadata: { strategy: 'self_claim' },
        },
      },
    },
  );
  const updated = await ApprovalRequest.findOne({ id: request.id });
  if (updated?.currentAssigneeId && updated.currentAssigneeId !== actor.id) {
    const err = new Error('This approval request was claimed by another approver');
    err.statusCode = 409;
    throw err;
  }
  return updated || request;
}

async function performProviderAction(request, action, remarks) {
  const def = PROVIDER_DEFINITIONS[request.providerType];
  if (!def) return null;
  if (action === 'approve') return def.approve(request.providerId, remarks);
  if (action === 'reject') return def.reject(request.providerId, remarks);
  if (action === 'request_documents' && def.requestDocuments) {
    return def.requestDocuments(request.providerId, remarks);
  }
  return null;
}

async function actionApprovalRequest(requestId, { action, remarks, reassignToApproverId }, { req } = {}) {
  let request = await ApprovalRequest.findOne({ id: requestId });
  if (!request) {
    const err = new Error('Approval request not found');
    err.statusCode = 404;
    throw err;
  }
  const actor = actorFromRequest(req);
  await ensureRequestAccess(request, actor);
  request = await claimRequestIfUnassigned(request, actor);
  if (isApproverActor(actor)) {
    const currentApprover = await Approver.findOne({
      id: actor.id,
      status: 'active',
      deletedAt: null,
    });
    if (
      !currentApprover ||
      !hasCategoryPermission(currentApprover, request) ||
      !regionMatches(currentApprover, request)
    ) {
      const err = new Error(
        'Your category or region permissions no longer allow this request',
      );
      err.statusCode = 403;
      throw err;
    }
    if (['approved', 'rejected'].includes(request.status)) {
      const err = new Error('This approval request is already complete');
      err.statusCode = 409;
      throw err;
    }
  }
  if (
    ['approved', 'rejected'].includes(request.status) &&
    !['approve', 'reject', 'add_note'].includes(action)
  ) {
    const err = new Error('Completed requests can only be overridden or annotated');
    err.statusCode = 409;
    throw err;
  }

  if (action === 'reassign') {
    return assignApprovalRequest(
      requestId,
      { approverId: reassignToApproverId, strategy: 'manual', remarks },
      { req },
    );
  }

  if (!String(remarks || '').trim() && action !== 'add_note') {
    const err = new Error('remarks are required');
    err.statusCode = 400;
    throw err;
  }

  const statusBefore = request.status;
  const now = new Date();
  let statusAfter = statusBefore;
  const update = {
    lastActionAt: now,
    lastActionBy: actor,
    lastRemarks: remarks || null,
  };
  const push = {
    timeline: {
      id: uuidv4(),
      actor,
      action,
      remarks,
      ip: requestIp(req),
      device: requestDevice(req),
      createdAt: now,
      metadata: {},
    },
  };

  if (action === 'add_note') {
    if (!String(remarks || '').trim()) {
      const err = new Error('note is required');
      err.statusCode = 400;
      throw err;
    }
    push.internalNotes = {
      id: uuidv4(),
      actor,
      note: remarks,
      createdAt: now,
    };
  } else if (action === 'approve') {
    const levels = (request.approvalLevels || []).map((level) =>
      level.toObject ? level.toObject() : { ...level },
    );
    const currentLevel =
      levels.find(
        (level) =>
          level.levelOrder === request.currentApprovalLevel &&
          level.status === 'pending',
      ) || levels.find((level) => level.status === 'pending');
    if (
      currentLevel &&
      isApproverActor(actor) &&
      currentLevel.role !== 'approver'
    ) {
      const err = new Error(
        `This request is awaiting the ${currentLevel.levelName || currentLevel.role} level`,
      );
      err.statusCode = 403;
      throw err;
    }
    if (currentLevel) {
      currentLevel.status = 'approved';
      currentLevel.decidedBy = actor;
      currentLevel.remarks = remarks;
      currentLevel.decidedAt = now;
      update.approvalLevels = levels;
    }
    update.firstDecisionAt = request.firstDecisionAt || now;

    // Super admin / admin KYC publish skips remaining unused levels and goes live.
    const isSuperAdminActor = !isApproverActor(actor);
    if (isSuperAdminActor) {
      for (const level of levels) {
        if (level.status === 'pending') {
          level.status = 'approved';
          level.decidedBy = actor;
          level.remarks = remarks || 'Approved by Super Admin';
          level.decidedAt = now;
        }
      }
      update.approvalLevels = levels;
    }

    const nextLevel = isSuperAdminActor
      ? null
      : levels
          .filter(
            (level) => level.status === 'pending' && level.required !== false,
          )
          .sort(
            (a, b) => Number(a.levelOrder || 0) - Number(b.levelOrder || 0),
          )[0];
    if (nextLevel) {
      statusAfter = nextLevel.role === 'approver' ? 'pending' : 'escalated';
      update.status = statusAfter;
      update.currentApprovalLevel = nextLevel.levelOrder;
      if (nextLevel.role !== 'approver') {
        update.currentAssigneeId = null;
        update.currentAssigneeName = null;
      }
    } else {
      await performProviderAction(request, 'approve', remarks);
      statusAfter = 'approved';
      update.status = statusAfter;
      update.completedAt = now;
      update.firstDecisionAt = request.firstDecisionAt || now;
      update.approvalDurationMinutes = minutesBetween(
        request.provider?.registrationDate || request.createdAt,
        now,
      );
    }
  } else if (action === 'reject') {
    const levels = (request.approvalLevels || []).map((level) =>
      level.toObject ? level.toObject() : { ...level },
    );
    const currentLevel =
      levels.find(
        (level) =>
          level.levelOrder === request.currentApprovalLevel &&
          level.status === 'pending',
      ) || levels.find((level) => level.status === 'pending');
    if (
      currentLevel &&
      isApproverActor(actor) &&
      currentLevel.role !== 'approver'
    ) {
      const err = new Error(
        `This request is awaiting the ${currentLevel.levelName || currentLevel.role} level`,
      );
      err.statusCode = 403;
      throw err;
    }
    if (currentLevel) {
      currentLevel.status = 'rejected';
      currentLevel.decidedBy = actor;
      currentLevel.remarks = remarks;
      currentLevel.decidedAt = now;
      update.approvalLevels = levels;
    }
    await performProviderAction(request, 'reject', remarks);
    statusAfter = 'rejected';
    update.status = statusAfter;
    update.completedAt = now;
    update.firstDecisionAt = request.firstDecisionAt || now;
    update.approvalDurationMinutes = minutesBetween(
      request.provider?.registrationDate || request.createdAt,
      now,
    );
  } else if (action === 'request_documents') {
    await performProviderAction(request, 'request_documents', remarks);
    statusAfter = 'needs_documents';
    update.status = statusAfter;
  } else if (action === 'on_hold') {
    statusAfter = 'on_hold';
    update.status = statusAfter;
  } else if (action === 'escalate') {
    statusAfter = 'escalated';
    update.status = statusAfter;
    await createApprovalNotification({
      recipientId: 'super-admin',
      recipientRole: 'super_admin',
      title: 'Approval escalation',
      body: `${request.provider?.name || 'Provider'} was escalated by ${actor.name}.`,
      type: 'approval_escalated',
      data: { requestId, providerId: request.providerId, providerType: request.providerType },
    });
  } else {
    const err = new Error('Unsupported approval action');
    err.statusCode = 400;
    throw err;
  }

  if (action !== 'add_note') {
    push.approvalHistory = {
      id: uuidv4(),
      actor,
      action,
      statusBefore,
      statusAfter,
      remarks,
      durationMinutes:
        update.approvalDurationMinutes ||
        minutesBetween(request.provider?.registrationDate || request.createdAt, now),
      createdAt: now,
    };
  }

  await ApprovalRequest.updateOne({ id: requestId }, { $set: update, $push: push });

  await writeAudit({
    req,
    actor,
    action: `approval_request_${action}`,
    entityType: 'approval_request',
    entityId: requestId,
    entityLabel: request.provider?.name,
    metadata: {
      statusBefore,
      statusAfter,
      providerId: request.providerId,
      providerType: request.providerType,
      remarks,
    },
  });

  return toApprovalRequest(await ApprovalRequest.findOne({ id: requestId }));
}

async function markApprovalRequestViewed(requestId, { req } = {}) {
  const request = await ApprovalRequest.findOne({ id: requestId });
  if (!request) {
    const err = new Error('Approval request not found');
    err.statusCode = 404;
    throw err;
  }
  const actor = actorFromRequest(req);
  await ensureRequestAccess(request, actor);
  const now = new Date();
  await ApprovalRequest.updateOne(
    { id: requestId },
    {
      $set: {
        viewedAt: request.viewedAt || now,
        lastActionAt: now,
        lastActionBy: actor,
      },
      $push: {
        timeline: {
          id: uuidv4(),
          actor,
          action: 'provider_viewed',
          remarks: 'Provider details viewed.',
          ip: requestIp(req),
          device: requestDevice(req),
          createdAt: now,
        },
      },
    },
  );
  await writeAudit({
    req,
    actor,
    action: 'provider_viewed',
    entityType: 'approval_request',
    entityId: requestId,
    entityLabel: request.provider?.name,
  });
  return toApprovalRequest(await ApprovalRequest.findOne({ id: requestId }));
}

async function listApprovalRequests({
  page = 1,
  pageSize = 50,
  status,
  providerType,
  category,
  approverId,
  city,
  state,
  priority,
  search,
  registrationFrom,
  registrationTo,
  sort = '-createdAt',
  actor,
} = {}) {
  await syncProviderRequests();
  // Ensure unassigned open requests get an eligible approver even when sync is cached.
  await autoAssignUnassignedRequests();
  const filter = {};
  if (status) filter.status = status;
  if (providerType) filter.providerType = providerType;
  if (category) filter.providerCategory = category;
  if (approverId) filter.currentAssigneeId = approverId;
  if (city) filter['provider.city'] = new RegExp(escapeRegex(city), 'i');
  if (state) filter['provider.state'] = new RegExp(escapeRegex(state), 'i');
  if (priority) filter.priority = priority;

  const andClauses = [];
  if (actor && isApproverActor(actor)) {
    const visibility = await buildApproverVisibilityFilter(actor);
    if (visibility) andClauses.push(visibility);
  }
  if (registrationFrom || registrationTo) {
    const registrationDate = {};
    const from = toDate(registrationFrom);
    const to = toDate(registrationTo);
    if (from) registrationDate.$gte = from;
    if (to) registrationDate.$lte = to;
    filter['provider.registrationDate'] = registrationDate;
  }
  if (search?.trim()) {
    const regex = new RegExp(escapeRegex(search.trim()), 'i');
    andClauses.push({
      $or: [
        { 'provider.name': regex },
        { 'provider.email': regex },
        { 'provider.phone': regex },
        { 'provider.city': regex },
        { 'provider.state': regex },
        { 'provider.pincode': regex },
        { providerId: regex },
      ],
    });
  }
  if (andClauses.length === 1) {
    Object.assign(filter, andClauses[0]);
  } else if (andClauses.length > 1) {
    filter.$and = andClauses;
  }

  const allowedSortFields = new Set([
    'createdAt',
    'updatedAt',
    'assignedAt',
    'completedAt',
    'slaDueAt',
    'priority',
    'status',
    'provider.registrationDate',
    'provider.name',
  ]);
  const requestedSortKey = sort.startsWith('-') ? sort.slice(1) : sort;
  const sortKey = allowedSortFields.has(requestedSortKey)
    ? requestedSortKey
    : 'createdAt';
  const sortSpec = { [sortKey]: sort.startsWith('-') ? -1 : 1 };

  const totalCount = await ApprovalRequest.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const docs = await ApprovalRequest.find(filter)
    .sort(sortSpec)
    .skip((page - 1) * pageSize)
    .limit(pageSize);
  return {
    requests: docs.map(toApprovalRequest),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function getApprovalRequestById(id, { req } = {}) {
  await syncProviderRequests();
  const request = await ApprovalRequest.findOne({ id });
  if (!request) {
    const err = new Error('Approval request not found');
    err.statusCode = 404;
    throw err;
  }
  const actor = actorFromRequest(req);
  await ensureRequestAccess(request, actor);
  const definition = PROVIDER_DEFINITIONS[request.providerType];
  let providerDetails = {};
  if (definition) {
    const provider = await definition.model.findOne({ id: request.providerId });
    if (provider) providerDetails = definition.mapper(provider) || {};
  }
  const documentOwnerField = {
    doctor: 'doctorId',
    nurse: 'nurseId',
    ambulance: 'ambulanceId',
  }[request.providerType];
  if (documentOwnerField) {
    const documents = await Document.find({
      [documentOwnerField]: request.providerId,
    })
      .sort({ uploadedAt: -1 })
      .lean();
    providerDetails.documents = documents.map((document) => ({
      id: document.id,
      documentType: document.documentType,
      fileUrl: document.fileUrl,
      fileName: document.fileName,
      fileSize: document.fileSize,
      mimeType: document.mimeType,
      status: document.status,
      rejectionReason: document.rejectionReason,
      verifiedAt: document.verifiedAt,
      verifiedBy: document.verifiedBy,
      uploadedAt: document.uploadedAt,
    }));
  } else if (Array.isArray(providerDetails.documents)) {
    // Lab / scan / blood bank keep embedded documents on the provider profile.
    providerDetails.documents = providerDetails.documents.map((document) => ({
      id: document.id,
      documentType: document.type || document.documentType,
      label: document.label,
      fileUrl: document.url || document.fileUrl,
      fileName: document.fileName || document.label,
      status: document.verificationStatus || document.status || 'pending',
      rejectionReason: document.rejectionReason,
      verifiedAt: document.verifiedAt,
      verifiedBy: document.verifiedBy,
      uploadedAt: document.uploadedAt || document.createdAt,
    }));
  }
  return {
    ...toApprovalRequest(request),
    providerDetails,
  };
}

async function actionApprovalRequestByProvider(
  providerType,
  providerId,
  { action, remarks },
  { req } = {},
) {
  if (!PROVIDER_DEFINITIONS[providerType]) {
    throw badRequest('Unsupported provider type');
  }
  await syncProviderRequests();
  const request = await ApprovalRequest.findOne({ providerType, providerId });
  if (!request) {
    const err = new Error('Approval request not found for provider');
    err.statusCode = 404;
    throw err;
  }
  return actionApprovalRequest(request.id, { action, remarks }, { req });
}

async function countByStatus(filter = {}) {
  const rows = await ApprovalRequest.aggregate([
    { $match: filter },
    { $group: { _id: '$status', count: { $sum: 1 } } },
  ]);
  const map = Object.fromEntries(rows.map((row) => [row._id, row.count]));
  return {
    total: Object.values(map).reduce((sum, value) => sum + value, 0),
    pending: map.pending || 0,
    approved: map.approved || 0,
    rejected: map.rejected || 0,
    onHold: map.on_hold || 0,
    needDocuments: map.needs_documents || 0,
    escalated: map.escalated || 0,
  };
}

async function chartByDate(match, dateField = 'createdAt', days = 14) {
  const since = new Date();
  since.setDate(since.getDate() - days + 1);
  since.setHours(0, 0, 0, 0);
  const rows = await ApprovalRequest.aggregate([
    { $match: { ...match, [dateField]: { $gte: since } } },
    {
      $group: {
        _id: {
          $dateToString: { format: '%Y-%m-%d', date: `$${dateField}` },
        },
        count: { $sum: 1 },
      },
    },
    { $sort: { _id: 1 } },
  ]);
  const map = new Map(rows.map((row) => [row._id, row.count]));
  return Array.from({ length: days }, (_, index) => {
    const date = new Date(since);
    date.setDate(since.getDate() + index);
    const key = date.toISOString().slice(0, 10);
    return { label: key.slice(5), date: key, value: map.get(key) || 0 };
  });
}

async function getApprovalDashboard(actor) {
  await syncProviderRequests();
  const now = new Date();
  const today = startOfDay(now);
  const week = startOfWeek(now);
  const month = startOfMonth(now);
  const requestFilter =
    (await buildApproverVisibilityFilter(actor)) || {};

  // If the queue is empty after a cached sync, force one rebuild from providers.
  const existingCount = await ApprovalRequest.countDocuments(requestFilter);
  if (existingCount === 0) {
    await syncProviderRequests({ force: true });
  }

  const [
    statusCounts,
    totalProviders,
    approversOnline,
    slaBreached,
    approvalsToday,
    rejectionsToday,
    weeklyApprovals,
    monthlyApprovals,
    durationAgg,
    providerTypeAgg,
    approvalTrend,
    providerGrowth,
  ] = await Promise.all([
    countByStatus(requestFilter),
    ApprovalRequest.countDocuments(requestFilter),
    isApproverActor(actor)
      ? Promise.resolve(0)
      : Approver.countDocuments({
          status: 'active',
          deletedAt: null,
          lastLoginAt: { $gte: new Date(Date.now() - 15 * 60 * 1000) },
        }),
    ApprovalRequest.countDocuments({
      ...requestFilter,
      status: { $in: OPEN_REQUEST_STATUSES },
      slaDueAt: { $lt: now },
    }),
    ApprovalRequest.countDocuments({
      ...requestFilter,
      status: 'approved',
      completedAt: { $gte: today },
    }),
    ApprovalRequest.countDocuments({
      ...requestFilter,
      status: 'rejected',
      completedAt: { $gte: today },
    }),
    ApprovalRequest.countDocuments({
      ...requestFilter,
      status: 'approved',
      completedAt: { $gte: week },
    }),
    ApprovalRequest.countDocuments({
      ...requestFilter,
      status: 'approved',
      completedAt: { $gte: month },
    }),
    ApprovalRequest.aggregate([
      {
        $match: {
          ...requestFilter,
          approvalDurationMinutes: { $gt: 0 },
        },
      },
      { $group: { _id: null, avg: { $avg: '$approvalDurationMinutes' } } },
    ]),
    ApprovalRequest.aggregate([
      { $match: requestFilter },
      { $group: { _id: '$providerCategory', count: { $sum: 1 } } },
      { $sort: { count: -1 } },
    ]),
    chartByDate({ ...requestFilter, status: 'approved' }, 'completedAt', 14),
    chartByDate(requestFilter, 'createdAt', 14),
  ]);

  const recent = await ApprovalRequest.find(requestFilter)
    .sort({ updatedAt: -1 })
    .limit(8);
  const approverData = isApproverActor(actor)
    ? { approvers: [] }
    : await listApprovers({ pageSize: 10 });

  return {
    stats: {
      totalProviders,
      pending: statusCounts.pending,
      approved: statusCounts.approved,
      rejected: statusCounts.rejected,
      onHold: statusCounts.onHold,
      needDocuments: statusCounts.needDocuments,
      escalated: statusCounts.escalated,
      approversOnline,
      averageApprovalTimeMinutes: Math.round(durationAgg[0]?.avg || 0),
      slaBreached,
      approvalsToday,
      rejectionsToday,
      weeklyApprovals,
      monthlyApprovals,
    },
    charts: {
      approvalTrend,
      providerGrowth,
      providerMix: providerTypeAgg.map((row) => ({
        label: row._id,
        value: row.count,
      })),
      statusMix: [
        { label: 'Pending', value: statusCounts.pending },
        { label: 'Approved', value: statusCounts.approved },
        { label: 'Rejected', value: statusCounts.rejected },
        { label: 'On hold', value: statusCounts.onHold },
        { label: 'Need docs', value: statusCounts.needDocuments },
        { label: 'Escalated', value: statusCounts.escalated },
      ],
    },
    recentRequests: recent.map(toApprovalRequest),
    approverPerformance: approverData.approvers,
  };
}

async function getApproverPerformance(id) {
  const approver = await Approver.findOne({ id, deletedAt: null });
  if (!approver) {
    const err = new Error('Approver not found');
    err.statusCode = 404;
    throw err;
  }
  const metrics = await getApproverMetrics([id]);
  const recentRequests = await ApprovalRequest.find({
    $or: [{ currentAssigneeId: id }, { 'approvalHistory.actor.id': id }],
  })
    .sort({ updatedAt: -1 })
    .limit(20);
  const monthly = await ApprovalRequest.aggregate([
    { $unwind: '$approvalHistory' },
    {
      $match: {
        'approvalHistory.actor.id': id,
        'approvalHistory.action': { $in: ['approve', 'reject', 'escalate'] },
      },
    },
    {
      $group: {
        _id: {
          month: {
            $dateToString: {
              format: '%Y-%m',
              date: '$approvalHistory.createdAt',
            },
          },
          action: '$approvalHistory.action',
        },
        count: { $sum: 1 },
      },
    },
    { $sort: { '_id.month': 1 } },
  ]);
  return {
    approver: toApprover(approver, metrics[id] || {}),
    recentActivity: recentRequests.map(toApprovalRequest),
    monthlyStatistics: monthly.map((row) => ({
      month: row._id.month,
      action: row._id.action,
      count: row.count,
    })),
  };
}

async function listAuditLogs({
  page = 1,
  pageSize = 50,
  action,
  actorRole,
  entityType,
  search,
  dateFrom,
  dateTo,
} = {}) {
  const filter = {};
  if (action) filter.action = action;
  if (actorRole) filter.actorRole = actorRole;
  if (entityType) filter.entityType = entityType;
  if (dateFrom || dateTo) {
    filter.createdAt = {};
    const from = toDate(dateFrom);
    const to = toDate(dateTo);
    if (from) filter.createdAt.$gte = from;
    if (to) filter.createdAt.$lte = to;
  }
  if (search?.trim()) {
    const regex = new RegExp(escapeRegex(search.trim()), 'i');
    filter.$or = [
      { actorName: regex },
      { action: regex },
      { entityLabel: regex },
      { entityId: regex },
    ];
  }
  const totalCount = await AuditLog.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const logs = await AuditLog.find(filter)
    .sort({ createdAt: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize);
  return {
    logs: logs.map((log) => {
      const d = log.toObject();
      return {
        id: d.id,
        actorId: d.actorId,
        actorName: d.actorName,
        actorRole: d.actorRole,
        action: d.action,
        entityType: d.entityType,
        entityId: d.entityId,
        entityLabel: d.entityLabel,
        ip: d.ip,
        device: d.device,
        metadata: d.metadata || {},
        createdAt: d.createdAt,
      };
    }),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function getApprovalConfig() {
  await ensureApprovalConfiguration();
  const [categories, rules] = await Promise.all([
    ProviderCategory.find().sort({ sortOrder: 1, name: 1 }),
    ApprovalRule.find().sort({ providerCategory: 1 }),
  ]);
  return {
    categories: categories.map((category) => {
      const d = category.toObject();
      return {
        id: d.id,
        slug: d.slug,
        name: d.name,
        description: d.description,
        active: d.active,
        slaHours: d.slaHours,
        sortOrder: d.sortOrder,
      };
    }),
    rules: rules.map((rule) => {
      const d = rule.toObject();
      return {
        id: d.id,
        providerCategory: d.providerCategory,
        assignmentStrategy: d.assignmentStrategy,
        slaHours: d.slaHours,
        approvalLevels: d.approvalLevels || [],
        escalationHours: d.escalationHours,
        active: d.active,
        aiBalancingReady: d.aiBalancingReady,
      };
    }),
    assignmentStrategies: ASSIGNMENT_STRATEGIES,
  };
}

async function updateApprovalConfig(data, { req } = {}) {
  const actor = actorFromRequest(req);
  if (Array.isArray(data.categories)) {
    for (const category of data.categories) {
      if (!category.slug || !category.name) continue;
      if (!/^[a-z0-9_]{2,64}$/.test(category.slug)) {
        throw badRequest('Category slug must use lowercase letters, numbers, or underscores');
      }
      const slaHours = validatedHours(category.slaHours ?? 24, 'SLA', {
        min: 1,
      });
      await ProviderCategory.updateOne(
        { slug: category.slug },
        {
          $set: {
            name: category.name,
            description: category.description,
            active: category.active !== false,
            slaHours,
            sortOrder: Number(category.sortOrder || 0),
          },
          $setOnInsert: { id: category.id || uuidv4(), slug: category.slug },
        },
        { upsert: true },
      );
    }
  }
  if (Array.isArray(data.rules)) {
    for (const rule of data.rules) {
      if (!rule.providerCategory) continue;
      const assignmentStrategy = rule.assignmentStrategy || 'least_busy';
      if (!ASSIGNMENT_STRATEGIES.includes(assignmentStrategy)) {
        throw badRequest('Unsupported assignment strategy');
      }
      const slaHours = validatedHours(rule.slaHours ?? 24, 'SLA', { min: 1 });
      const escalationHours = validatedHours(
        rule.escalationHours ?? 4,
        'Escalation',
      );
      const approvalLevels = Array.isArray(rule.approvalLevels)
        ? rule.approvalLevels
        : [];
      const orders = approvalLevels.map((level) => Number(level.order));
      if (
        approvalLevels.some(
          (level) =>
            !level.id ||
            !level.name ||
            !['approver', 'super_admin', 'admin'].includes(level.role) ||
            !Number.isInteger(Number(level.order)) ||
            Number(level.order) < 1,
        ) ||
        new Set(orders).size !== orders.length
      ) {
        throw badRequest('Approval levels require unique positive orders and valid roles');
      }
      await ApprovalRule.updateOne(
        { providerCategory: rule.providerCategory },
        {
          $set: {
            assignmentStrategy,
            slaHours,
            approvalLevels,
            escalationHours,
            active: rule.active !== false,
          },
          $setOnInsert: { id: rule.id || uuidv4() },
        },
        { upsert: true },
      );
    }
  }
  await writeAudit({
    req,
    actor,
    action: 'approval_configuration_changed',
    entityType: 'approval_config',
    entityId: 'global',
    entityLabel: 'Approval Configuration',
    metadata: {
      categoryCount: data.categories?.length || 0,
      ruleCount: data.rules?.length || 0,
    },
  });
  return getApprovalConfig();
}

function csvEscape(value) {
  const text = value == null ? '' : String(value);
  if (/[",\n\r]/.test(text)) {
    return `"${text.replace(/"/g, '""')}"`;
  }
  return text;
}

function toCsv(rows) {
  return rows.map((row) => row.map(csvEscape).join(',')).join('\n');
}

async function buildApprovalReport({ period = 'monthly', format } = {}) {
  await syncProviderRequests();
  const dashboard = await getApprovalDashboard();
  const approvers = await listApprovers({ pageSize: 100 });
  const audit = await listAuditLogs({ pageSize: 100 });
  const openRequests = await listApprovalRequests({
    pageSize: 200,
    status: undefined,
  });
  const rejectedReasons = audit.logs
    .filter((log) => log.action === 'approval_request_reject')
    .map((log) => ({
      provider: log.entityLabel,
      reason: log.metadata?.remarks,
      date: log.createdAt,
    }));
  const report = {
    generatedAt: new Date(),
    period,
    summary: dashboard.stats,
    slaCompliance: {
      breached: dashboard.stats.slaBreached,
      totalOpen:
        dashboard.stats.pending +
        dashboard.stats.onHold +
        dashboard.stats.needDocuments +
        dashboard.stats.escalated,
    },
    approvers: approvers.approvers,
    rejectedReasons,
    requests: openRequests.requests,
    exportFormats: ['csv', 'excel', 'pdf'],
  };

  if (format === 'csv' || format === 'excel') {
    const summaryRows = [
      ['Metric', 'Value'],
      ['Period', period],
      ['Generated At', report.generatedAt.toISOString()],
      ['Total Providers', dashboard.stats.totalProviders],
      ['Pending', dashboard.stats.pending],
      ['Approved', dashboard.stats.approved],
      ['Rejected', dashboard.stats.rejected],
      ['On Hold', dashboard.stats.onHold],
      ['Need Documents', dashboard.stats.needDocuments],
      ['Escalated', dashboard.stats.escalated],
      ['Past deadline', dashboard.stats.slaBreached],
      [
        'Average Approval Time (minutes)',
        dashboard.stats.averageApprovalTimeMinutes,
      ],
    ];
    const approverRows = [
      [
        'Approver',
        'Email',
        'Status',
        'Assigned',
        'Approved',
        'Rejected',
        'Pending',
        'Acceptance Rate',
        'Rejection Rate',
        'Escalations',
        'Avg Approval Minutes',
        'Last Login',
      ],
      ...approvers.approvers.map((item) => [
        item.name,
        item.email,
        item.status,
        item.assigned,
        item.approved,
        item.rejected,
        item.pending,
        item.acceptanceRate,
        item.rejectionRate,
        item.escalations,
        item.averageApprovalTimeMinutes,
        item.lastLoginAt || '',
      ]),
    ];
    const requestRows = [
      [
        'Provider',
        'Type',
        'Status',
        'Priority',
        'Assignee',
        'City',
        'State',
        'Registered',
        'SLA Due',
        'Last Remarks',
      ],
      ...openRequests.requests.map((item) => [
        item.provider?.name,
        item.providerCategory,
        item.status,
        item.priority,
        item.currentAssigneeName || 'Unassigned',
        item.provider?.city,
        item.provider?.state,
        item.provider?.registrationDate || '',
        item.slaDueAt || '',
        item.lastRemarks || '',
      ]),
    ];
    const rejectionRows = [
      ['Provider', 'Reason', 'Date'],
      ...rejectedReasons.map((item) => [
        item.provider,
        item.reason,
        item.date || '',
      ]),
    ];
    report.export = {
      format,
      contentType:
        format === 'excel'
          ? 'application/vnd.ms-excel'
          : 'text/csv; charset=utf-8',
      filename: `approval-report-${period}.${format === 'excel' ? 'csv' : 'csv'}`,
      csv: [
        '# Summary',
        toCsv(summaryRows),
        '',
        '# Approver Performance',
        toCsv(approverRows),
        '',
        '# Requests',
        toCsv(requestRows),
        '',
        '# Rejected Reasons',
        toCsv(rejectionRows),
      ].join('\n'),
    };
  }

  if (format === 'pdf') {
    report.export = {
      format: 'pdf',
      contentType: 'text/plain; charset=utf-8',
      filename: `approval-report-${period}.txt`,
      text: [
        `Approval Report (${period})`,
        `Generated: ${report.generatedAt.toISOString()}`,
        '',
        `Pending: ${dashboard.stats.pending}`,
        `Approved: ${dashboard.stats.approved}`,
        `Rejected: ${dashboard.stats.rejected}`,
        `On Hold: ${dashboard.stats.onHold}`,
        `Need Documents: ${dashboard.stats.needDocuments}`,
        `Escalated: ${dashboard.stats.escalated}`,
        `Past deadline: ${dashboard.stats.slaBreached}`,
        `Average Approval Time (min): ${dashboard.stats.averageApprovalTimeMinutes}`,
        '',
        'Approvers:',
        ...approvers.approvers.map(
          (item) =>
            `- ${item.name}: assigned=${item.assigned} approved=${item.approved} rejected=${item.rejected} pending=${item.pending}`,
        ),
      ].join('\n'),
    };
  }

  return report;
}

function toNotification(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    recipientId: d.recipientId,
    recipientRole: d.recipientRole,
    channels: d.channels || [],
    title: d.title,
    body: d.body,
    type: d.type,
    data: d.data || {},
    readAt: d.readAt || null,
    createdAt: d.createdAt,
  };
}

async function listApprovalNotifications(actor, { page = 1, pageSize = 50, unreadOnly = false } = {}) {
  const isAdmin = actor.role === 'super_admin' || actor.role === 'admin';
  const recipientFilter = isAdmin
    ? {
        $or: [
          { recipientId: actor.id },
          { recipientId: 'super-admin' },
          { recipientRole: { $in: ['super_admin', 'admin'] } },
        ],
      }
    : { recipientId: actor.id };
  const filter = unreadOnly
    ? { ...recipientFilter, readAt: null }
    : recipientFilter;
  const skip = (Math.max(1, page) - 1) * pageSize;
  const [items, total, unreadCount] = await Promise.all([
    ApprovalNotification.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(pageSize)
      .lean(),
    ApprovalNotification.countDocuments(filter),
    ApprovalNotification.countDocuments({ ...recipientFilter, readAt: null }),
  ]);
  return {
    notifications: items.map(toNotification),
    unreadCount,
    pagination: {
      page: Math.max(1, page),
      pageSize,
      total,
      totalPages: Math.max(1, Math.ceil(total / pageSize)),
    },
  };
}

async function markApprovalNotificationRead(notificationId, actor) {
  const notification = await ApprovalNotification.findOne({ id: notificationId });
  if (!notification) {
    const err = new Error('Notification not found');
    err.statusCode = 404;
    throw err;
  }
  const isAdmin = actor.role === 'super_admin' || actor.role === 'admin';
  const allowed =
    notification.recipientId === actor.id ||
    (isAdmin &&
      (notification.recipientId === 'super-admin' ||
        ['super_admin', 'admin'].includes(notification.recipientRole)));
  if (!allowed) {
    const err = new Error('Notification access denied');
    err.statusCode = 403;
    throw err;
  }
  if (!notification.readAt) {
    notification.readAt = new Date();
    await notification.save();
  }
  return toNotification(notification);
}

async function markAllApprovalNotificationsRead(actor) {
  const filter =
    actor.role === 'super_admin' || actor.role === 'admin'
      ? {
          readAt: null,
          $or: [
            { recipientId: actor.id },
            { recipientId: 'super-admin' },
            { recipientRole: { $in: ['super_admin', 'admin'] } },
          ],
        }
      : { recipientId: actor.id, readAt: null };
  const result = await ApprovalNotification.updateMany(filter, {
    $set: { readAt: new Date() },
  });
  return { updated: result.modifiedCount || 0 };
}

function toSavedFilter(doc) {
  if (!doc) return null;
  const d = doc.toObject ? doc.toObject() : doc;
  return {
    id: d.id,
    ownerId: d.ownerId,
    ownerRole: d.ownerRole,
    name: d.name,
    scope: d.scope,
    filters: d.filters || {},
    sort: d.sort,
    columns: d.columns || [],
    isDefault: d.isDefault === true,
    createdAt: d.createdAt,
    updatedAt: d.updatedAt,
  };
}

async function listSavedFilters(actor, { scope } = {}) {
  const filter = { ownerId: actor.id };
  if (scope) filter.scope = scope;
  const items = await ApprovalSavedFilter.find(filter).sort({ updatedAt: -1 }).lean();
  return items.map(toSavedFilter);
}

async function createSavedFilter(payload, { req } = {}) {
  const actor = actorFromRequest(req);
  const name = String(payload.name || '').trim();
  if (!name) throw badRequest('Filter name is required');
  const scope = payload.scope || 'requests';
  if (!['requests', 'audit_logs', 'approvers', 'reports'].includes(scope)) {
    throw badRequest('Invalid filter scope');
  }
  if (payload.isDefault) {
    await ApprovalSavedFilter.updateMany(
      { ownerId: actor.id, scope },
      { $set: { isDefault: false } },
    );
  }
  const created = await ApprovalSavedFilter.create({
    id: uuidv4(),
    ownerId: actor.id,
    ownerRole: actor.role,
    name,
    scope,
    filters: payload.filters || {},
    sort: payload.sort || '-updatedAt',
    columns: Array.isArray(payload.columns) ? payload.columns : [],
    isDefault: payload.isDefault === true,
  });
  await writeAudit({
    req,
    actor,
    action: 'approval_saved_filter_created',
    entityType: 'approval_saved_filter',
    entityId: created.id,
    entityLabel: created.name,
  });
  return toSavedFilter(created);
}

async function deleteSavedFilter(filterId, { req } = {}) {
  const actor = actorFromRequest(req);
  const existing = await ApprovalSavedFilter.findOne({
    id: filterId,
    ownerId: actor.id,
  });
  if (!existing) {
    const err = new Error('Saved filter not found');
    err.statusCode = 404;
    throw err;
  }
  await ApprovalSavedFilter.deleteOne({ id: filterId });
  await writeAudit({
    req,
    actor,
    action: 'approval_saved_filter_deleted',
    entityType: 'approval_saved_filter',
    entityId: filterId,
    entityLabel: existing.name,
  });
  return { deleted: true };
}

async function processSlaEscalationsAndReminders() {
  const now = new Date();
  const rules = await ApprovalRule.find({ active: true }).lean();
  const escalationByCategory = new Map(
    rules.map((rule) => [rule.providerCategory, Number(rule.escalationHours || 4)]),
  );

  const openRequests = await ApprovalRequest.find({
    status: { $in: ['pending', 'on_hold', 'needs_documents'] },
    slaDueAt: { $ne: null },
  }).limit(200);

  let escalated = 0;
  let reminded = 0;

  for (const request of openRequests) {
    const due = request.slaDueAt ? new Date(request.slaDueAt) : null;
    if (!due || Number.isNaN(due.getTime())) continue;

    const metadata = {
      ...(request.metadata && typeof request.metadata === 'object'
        ? request.metadata
        : {}),
    };
    const escalationHours =
      escalationByCategory.get(request.providerCategory) ?? 4;
    const nearDeadlineAt = new Date(
      due.getTime() - Math.max(0, escalationHours) * 60 * 60 * 1000,
    );

    if (due.getTime() <= now.getTime()) {
      if (metadata.slaAutoEscalatedAt) continue;
      metadata.slaAutoEscalatedAt = now.toISOString();
      metadata.slaBreachedAt = now.toISOString();
      await ApprovalRequest.updateOne(
        { id: request.id },
        {
          $set: {
            status: 'escalated',
            lastActionAt: now,
            lastRemarks: 'Auto-escalated due to SLA breach',
            metadata,
            lastActionBy: {
              id: 'system',
              name: 'SLA Monitor',
              role: 'super_admin',
            },
          },
          $push: {
            timeline: {
              id: uuidv4(),
              actor: { id: 'system', name: 'SLA Monitor', role: 'super_admin' },
              action: 'sla_auto_escalated',
              remarks: 'Request auto-escalated after SLA breach.',
              createdAt: now,
              metadata: { slaDueAt: due },
            },
            approvalHistory: {
              id: uuidv4(),
              actor: { id: 'system', name: 'SLA Monitor', role: 'super_admin' },
              action: 'escalate',
              statusBefore: request.status,
              statusAfter: 'escalated',
              remarks: 'Auto-escalated due to SLA breach',
              createdAt: now,
            },
          },
        },
      );
      await AuditLog.create({
        id: uuidv4(),
        actorId: 'system',
        actorName: 'SLA Monitor',
        actorRole: 'super_admin',
        action: 'approval_request_sla_auto_escalated',
        entityType: 'approval_request',
        entityId: request.id,
        entityLabel: request.provider?.name,
        metadata: {
          providerId: request.providerId,
          providerType: request.providerType,
          slaDueAt: due,
        },
        createdAt: now,
      });
      await createApprovalNotification({
        recipientId: 'super-admin',
        recipientRole: 'super_admin',
        title: 'SLA breach',
        body: `${request.provider?.name || 'Provider'} breached SLA and was escalated.`,
        type: 'sla_breach',
        data: {
          requestId: request.id,
          providerId: request.providerId,
          providerType: request.providerType,
        },
      });
      if (request.currentAssigneeId) {
        await createApprovalNotification({
          recipientId: request.currentAssigneeId,
          recipientRole: 'approver',
          title: 'Past deadline',
          body: `${request.provider?.name || 'Provider'} is overdue and escalated to admin.`,
          type: 'sla_breach',
          data: {
            requestId: request.id,
            providerId: request.providerId,
            providerType: request.providerType,
          },
        });
      }
      escalated += 1;
      continue;
    }

    if (
      nearDeadlineAt.getTime() <= now.getTime() &&
      !metadata.slaReminderSentAt
    ) {
      metadata.slaReminderSentAt = now.toISOString();
      await ApprovalRequest.updateOne(
        { id: request.id },
        { $set: { metadata } },
      );
      if (request.currentAssigneeId) {
        await createApprovalNotification({
          recipientId: request.currentAssigneeId,
          recipientRole: 'approver',
          title: 'SLA expiring',
          body: `${request.provider?.name || 'Provider'} is nearing the SLA deadline.`,
          type: 'sla_expiring',
          data: {
            requestId: request.id,
            providerId: request.providerId,
            providerType: request.providerType,
            slaDueAt: due,
          },
        });
      }
      await createApprovalNotification({
        recipientId: 'super-admin',
        recipientRole: 'super_admin',
        title: 'SLA nearing deadline',
        body: `${request.provider?.name || 'Provider'} is approaching SLA expiry.`,
        type: 'sla_expiring',
        data: {
          requestId: request.id,
          providerId: request.providerId,
          providerType: request.providerType,
          slaDueAt: due,
        },
      });
      reminded += 1;
    }
  }

  return { escalated, reminded };
}

module.exports = {
  actorFromRequest,
  ensureApprovalConfiguration,
  syncProviderRequests,
  listApprovers,
  createApprover,
  updateApprover,
  setApproverStatus,
  resetApproverPassword,
  deleteApprover,
  loginApprover,
  createApproverSession,
  refreshApproverSession,
  revokeApproverSession,
  listApprovalRequests,
  listEligibleApprovers,
  getApprovalRequestById,
  actionApprovalRequestByProvider,
  assignApprovalRequest,
  actionApprovalRequest,
  markApprovalRequestViewed,
  getApprovalDashboard,
  getApproverPerformance,
  listAuditLogs,
  getApprovalConfig,
  updateApprovalConfig,
  buildApprovalReport,
  listApprovalNotifications,
  markApprovalNotificationRead,
  markAllApprovalNotificationsRead,
  listSavedFilters,
  createSavedFilter,
  deleteSavedFilter,
  processSlaEscalationsAndReminders,
  createApprovalNotification,
};

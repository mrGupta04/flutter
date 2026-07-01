const express = require('express');
const { v4: uuidv4 } = require('uuid');

const {
  findBloodBankById,
  findBloodBankByEmail,
  ensureBloodBankStub,
  updateBloodBankProfilePicture,
  updateBloodBankLogo,
  addBloodBankGalleryImage,
  addBloodBankDocument,
  upsertBloodBank,
  listBloodBanks,
  submitBloodBankForReview,
  getBloodBankDashboardStats,
  DEFAULT_BLOOD_COMPONENTS,
} = require('../db/bloodBankRepositories');

const {
  listInventoryByBloodBank,
  upsertInventoryEntry,
  addBloodUnits,
  removeExpiredUnits,
  initializeBloodBankInventory,
} = require('../db/bloodInventoryRepositories');

const {
  findOrderById,
  listOrdersByBloodBank,
  listOrdersByPatient,
  createBloodOrder,
  createPaymentOrderForBloodOrder,
  confirmBloodOrderAfterPayment,
  updateOrderStatus,
} = require('../db/bloodOrderRepositories');
const { isMockMode } = require('../services/razorpayService');

const { listReviewsByBloodBank, createBloodReview } = require('../db/bloodReviewRepositories');

const {
  createEmergencyRequest,
  listEmergencyRequestsForBloodBank,
  acceptEmergencyRequest,
  findEmergencyRequestById,
} = require('../db/emergencyBloodRequestRepositories');
const {
  notifyEmergencyRequestCreated,
  notifyEmergencyRequestAccepted,
} = require('../services/bloodBankNotificationService');

const {
  listStaffByBloodBank,
  upsertStaff,
  removeStaff,
} = require('../db/bloodBankStaffRepositories');

const { sendSuccess, sendError } = require('../utils/response');
const { signToken, authOptional } = require('../middleware/auth');
const { upload, filePublicUrl } = require('../middleware/multerUpload');
const { loginProvider } = require('../utils/providerAuth');
const { toBloodBank } = require('../db/bloodBankMappers');
const { normalizeMobile, validateMobile } = require('../utils/mobile');

const router = express.Router();

// ——— Public discovery ———

router.get('/verified', async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(50, parseInt(req.query.pageSize || '20', 10));
    const { bloodBanks, pagination } = await listBloodBanks({
      status: 'verified',
      page,
      pageSize,
      search: req.query.q || req.query.search || '',
      city: req.query.city || '',
      pincode: req.query.pincode || '',
      area: req.query.area || '',
      available24x7: req.query.available24x7 || '',
      bloodGroup: req.query.bloodGroup || '',
      hasApheresis: req.query.hasApheresis || '',
      emergencySupply: req.query.emergencySupply || '',
      homeDelivery: req.query.homeDelivery || '',
      openNow: req.query.openNow || '',
      componentType: req.query.componentType || '',
      hasDiscount: req.query.hasDiscount || '',
      minRating: req.query.minRating || '',
      maxPrice: req.query.maxPrice || '',
      latitude: req.query.latitude || '',
      longitude: req.query.longitude || '',
      maxDistanceKm: req.query.maxDistanceKm || '',
    });

    const enriched = await Promise.all(
      bloodBanks.map(async (bank) => {
        const inventory = await listInventoryByBloodBank(bank.id);
        return { ...bank, inventory };
      }),
    );

    return sendSuccess(res, { data: enriched, pagination });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to list blood banks', 500);
  }
});

router.get('/catalog', (_req, res) => {
  return sendSuccess(res, {
    data: {
      bloodGroups: ['A+', 'A-', 'B+', 'B-', 'AB+', 'AB-', 'O+', 'O-', 'Bombay', 'Rare'],
      components: DEFAULT_BLOOD_COMPONENTS,
      facilities: [
        'Blood Storage',
        'Blood Component Separation',
        'Platelet Availability',
        'Plasma Availability',
        'Packed RBC',
        'Cryoprecipitate',
        'Rare Blood Groups',
        'Home Delivery',
        'Blood Donation Camp',
        'Voluntary Blood Donation Registration',
        'Emergency Blood Supply',
        'Walk-in Collection',
        'Online Booking',
      ],
    },
  });
});

// ——— Auth ———

router.post('/login', async (req, res) => {
  try {
    const { email, password } = req.body || {};
    const result = await loginProvider({
      email,
      password,
      findByEmail: (e) => findBloodBankByEmail(e),
      toPublic: (doc) => toBloodBank(doc),
      buildTokenPayload: (profile) => ({
        bloodBankId: profile.id,
        mobileNumber: profile.mobileNumber,
        type: 'bloodbank',
      }),
    });

    if (!result.ok) {
      return sendError(res, result.error, result.status);
    }

    const token = signToken(result.tokenPayload, '30d');
    return sendSuccess(res, {
      message: 'Login successful',
      data: result.profile,
      token,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Login failed', 500);
  }
});

// ——— Profile ———

router.get('/profile', authOptional, async (req, res) => {
  try {
    const bloodBankId = req.query.bloodBankId || req.auth?.bloodBankId;
    if (!bloodBankId) {
      return sendError(res, 'bloodBankId is required', 400);
    }

    const bloodBank = await findBloodBankById(bloodBankId);
    if (!bloodBank) {
      return sendError(res, 'Blood bank not found', 404);
    }

    const inventory = await listInventoryByBloodBank(bloodBankId);
    const staff = await listStaffByBloodBank(bloodBankId);

    return sendSuccess(res, { data: { ...bloodBank, inventory, staff } });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch profile', 500);
  }
});

router.put('/profile', authOptional, async (req, res) => {
  try {
    const body = req.body || {};
    if (!body.id) {
      return sendError(res, 'Blood bank id is required');
    }

    const existing = await findBloodBankById(body.id);
    if (!existing) {
      return sendError(res, 'Blood bank not found', 404);
    }

    const bloodBank = await upsertBloodBank({
      ...body,
      id: body.id,
      bloodGroupsAvailable: Array.isArray(body.bloodGroupsAvailable)
        ? body.bloodGroupsAvailable
        : body.bloodGroupsAvailable
          ? String(body.bloodGroupsAvailable).split(',').map((s) => s.trim()).filter(Boolean)
          : existing.bloodGroupsAvailable,
    });

    return sendSuccess(res, { message: 'Profile updated successfully', data: bloodBank });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to update profile', 500);
  }
});

// ——— Uploads ———

router.post('/upload-profile', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return sendError(res, 'File is required');
    const bloodBankId = req.body.bloodBankId;
    if (!bloodBankId) return sendError(res, 'bloodBankId is required');

    await ensureBloodBankStub(bloodBankId, req.body.mobileNumber);
    const fileUrl = await filePublicUrl(req, req.file);
    await updateBloodBankProfilePicture(bloodBankId, fileUrl);

    return sendSuccess(res, { message: 'Profile picture uploaded', data: { profilePicture: fileUrl } });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Upload failed', 500);
  }
});

router.post('/upload-logo', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return sendError(res, 'File is required');
    const bloodBankId = req.body.bloodBankId;
    if (!bloodBankId) return sendError(res, 'bloodBankId is required');

    await ensureBloodBankStub(bloodBankId, req.body.mobileNumber);
    const fileUrl = await filePublicUrl(req, req.file);
    await updateBloodBankLogo(bloodBankId, fileUrl);

    return sendSuccess(res, { message: 'Logo uploaded', data: { logoUrl: fileUrl } });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Upload failed', 500);
  }
});

router.post('/upload-gallery', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return sendError(res, 'File is required');
    const bloodBankId = req.body.bloodBankId;
    if (!bloodBankId) return sendError(res, 'bloodBankId is required');

    const fileUrl = await filePublicUrl(req, req.file);
    const bank = await addBloodBankGalleryImage(bloodBankId, fileUrl);

    return sendSuccess(res, { message: 'Gallery image uploaded', data: bank });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Upload failed', 500);
  }
});

router.post('/upload-document', upload.single('file'), async (req, res) => {
  try {
    if (!req.file) return sendError(res, 'File is required');
    const bloodBankId = req.body.bloodBankId;
    if (!bloodBankId) return sendError(res, 'bloodBankId is required');

    const fileUrl = await filePublicUrl(req, req.file);
    const document = {
      id: uuidv4(),
      type: req.body.type || 'license',
      label: req.body.label || 'Document',
      url: fileUrl,
      verificationStatus: 'pending',
    };
    const bank = await addBloodBankDocument(bloodBankId, document);

    return sendSuccess(res, { message: 'Document uploaded', data: bank });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Upload failed', 500);
  }
});

// ——— Registration ———

router.post('/register', async (req, res) => {
  try {
    const body = req.body || {};
    const bloodBankId = body.id || uuidv4();

    const mobileCheck = validateMobile(body.mobileNumber, { countryCode: body.countryCode });
    if (!mobileCheck.valid) return sendError(res, mobileCheck.error, 400);
    const mobile = mobileCheck.mobile;

    if (body.emergencyContact) {
      const emergencyCheck = validateMobile(body.emergencyContact, {
        countryCode: body.emergencyCountryCode || body.countryCode,
      });
      if (!emergencyCheck.valid) {
        return sendError(res, `Emergency contact: ${emergencyCheck.error}`, 400);
      }
    }

    if (body.email) {
      const emailTaken = await findBloodBankByEmail(body.email.trim().toLowerCase(), bloodBankId);
      if (emailTaken) return sendError(res, 'Email already registered', 409);
    }

    const bloodGroupsAvailable = Array.isArray(body.bloodGroupsAvailable)
      ? body.bloodGroupsAvailable
      : String(body.bloodGroupsAvailable || '')
          .split(',')
          .map((s) => s.trim())
          .filter(Boolean);

    const defaultComponents = DEFAULT_BLOOD_COMPONENTS.map((c) => ({
      ...c,
      priceInr: 0,
      availabilityStatus: 'available',
      enabled: true,
    }));

    const bloodBank = await submitBloodBankForReview(
      (
        await upsertBloodBank({
          id: bloodBankId,
          institutionName: body.institutionName?.trim(),
          ownerName: body.ownerName?.trim() || body.contactPerson?.trim(),
          licenseNumber: body.licenseNumber?.trim(),
          governmentRegistrationNumber: body.governmentRegistrationNumber?.trim(),
          gstNumber: body.gstNumber?.trim(),
          contactPerson: body.contactPerson?.trim() || body.ownerName?.trim(),
          email: body.email?.trim().toLowerCase(),
          mobileNumber: mobile || body.mobileNumber,
          countryCode: mobileCheck.countryCode,
          profilePicture: body.profilePicture?.trim(),
          logoUrl: body.logoUrl?.trim(),
          description: body.description?.trim(),
          emergencyContact: normalizeMobile(body.emergencyContact) || body.emergencyContact,
          whatsappNumber: body.whatsappNumber,
          landlineNumber: body.landlineNumber,
          emailSupport: body.emailSupport?.trim(),
          address: body.address?.trim(),
          city: body.city?.trim(),
          state: body.state?.trim(),
          pincode: body.pincode?.trim(),
          latitude: body.latitude != null ? Number(body.latitude) : undefined,
          longitude: body.longitude != null ? Number(body.longitude) : undefined,
          openingTime: body.openingTime,
          closingTime: body.closingTime,
          workingDays: body.workingDays,
          bloodGroupsAvailable,
          facilities: body.facilities || [],
          hasApheresis: Boolean(body.hasApheresis),
          hasComponentSeparation: Boolean(body.hasComponentSeparation),
          available24x7: Boolean(body.available24x7),
          emergencyBloodSupply: Boolean(body.emergencyBloodSupply),
          homeDeliveryAvailable: Boolean(body.homeDeliveryAvailable),
          hospitalDeliveryAvailable: Boolean(body.hospitalDeliveryAvailable),
          cashPaymentEnabled: body.cashPaymentEnabled !== false,
          bloodComponents: body.bloodComponents?.length
            ? body.bloodComponents
            : defaultComponents,
          offers: body.offers || [],
          password: body.password,
        })
      ).id,
    );

    await initializeBloodBankInventory(bloodBankId);

    const token = signToken(
      { bloodBankId: bloodBank.id, mobileNumber: bloodBank.mobileNumber, type: 'bloodbank' },
      '30d',
    );

    return res.status(200).json({
      success: true,
      message: 'Application submitted for admin review',
      statusCode: 200,
      data: bloodBank,
      token,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Registration failed', 500);
  }
});

// ——— Dashboard ———

router.get('/dashboard', authOptional, async (req, res) => {
  try {
    const bloodBankId = req.query.bloodBankId || req.auth?.bloodBankId;
    if (!bloodBankId) return sendError(res, 'bloodBankId is required', 400);

    const stats = await getBloodBankDashboardStats(bloodBankId);
    const inventory = await listInventoryByBloodBank(bloodBankId);
    const bank = await findBloodBankById(bloodBankId);

    return sendSuccess(res, {
      data: { ...stats, inventory, bloodBank: bank },
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load dashboard', 500);
  }
});

// ——— Inventory ———

router.get('/inventory', authOptional, async (req, res) => {
  try {
    const bloodBankId = req.query.bloodBankId || req.auth?.bloodBankId;
    if (!bloodBankId) return sendError(res, 'bloodBankId is required', 400);

    const inventory = await listInventoryByBloodBank(bloodBankId);
    return sendSuccess(res, { data: inventory });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch inventory', 500);
  }
});

router.put('/inventory', authOptional, async (req, res) => {
  try {
    const body = req.body || {};
    if (!body.bloodBankId || !body.bloodGroup) {
      return sendError(res, 'bloodBankId and bloodGroup are required', 400);
    }

    const entry = await upsertInventoryEntry(body);
    return sendSuccess(res, { message: 'Inventory updated', data: entry });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to update inventory', 500);
  }
});

router.post('/inventory/add-units', authOptional, async (req, res) => {
  try {
    const { bloodBankId, bloodGroup, units, expiryDate } = req.body || {};
    if (!bloodBankId || !bloodGroup || !units) {
      return sendError(res, 'bloodBankId, bloodGroup, and units are required', 400);
    }

    const entry = await addBloodUnits(
      bloodBankId,
      bloodGroup,
      Number(units),
      expiryDate ? new Date(expiryDate) : null,
    );
    return sendSuccess(res, { message: 'Units added', data: entry });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to add units', 500);
  }
});

router.post('/inventory/remove-expired', authOptional, async (req, res) => {
  try {
    const bloodBankId = req.body?.bloodBankId || req.auth?.bloodBankId;
    if (!bloodBankId) return sendError(res, 'bloodBankId is required', 400);

    const result = await removeExpiredUnits(bloodBankId);
    return sendSuccess(res, { message: 'Expired units removed', data: result });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to remove expired units', 500);
  }
});

// ——— Orders ———

router.get('/bookings', authOptional, async (req, res) => {
  try {
    const bloodBankId = req.query.bloodBankId || req.auth?.bloodBankId;
    const patientId = req.query.patientId || req.auth?.patientId;
    const status = req.query.status;
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(50, parseInt(req.query.pageSize || '20', 10));

    if (bloodBankId) {
      const { orders, pagination } = await listOrdersByBloodBank(bloodBankId, {
        status,
        page,
        pageSize,
      });
      return sendSuccess(res, { data: orders, pagination });
    }

    if (patientId) {
      const { orders, pagination } = await listOrdersByPatient(patientId, { page, pageSize });
      return sendSuccess(res, { data: orders, pagination });
    }

    return sendError(res, 'bloodBankId or patientId is required', 400);
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch bookings', 500);
  }
});

router.get('/bookings/:orderId', authOptional, async (req, res) => {
  try {
    const order = await findOrderById(req.params.orderId);
    if (!order) return sendError(res, 'Order not found', 404);
    return sendSuccess(res, { data: order });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch order', 500);
  }
});

router.post('/bookings', authOptional, async (req, res) => {
  try {
    const body = req.body || {};
    if (!body.bloodBankId || !body.bloodGroup || !body.componentType || !body.units) {
      return sendError(res, 'bloodBankId, bloodGroup, componentType, and units are required', 400);
    }

    const order = await createBloodOrder({
      ...body,
      patientId: body.patientId || req.auth?.patientId,
    });

    return sendSuccess(res, { message: 'Order placed successfully', data: order });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to place order', status);
  }
});

router.post('/payments/create-order', authOptional, async (req, res) => {
  try {
    const { orderId } = req.body || {};
    if (!orderId) return sendError(res, 'orderId is required', 400);

    const result = await createPaymentOrderForBloodOrder(orderId);

    return sendSuccess(res, {
      statusCode: 201,
      data: {
        orderId: result.order.id,
        bloodBankName: result.bloodBankName,
        orderRazorpayId: result.razorpayOrder.id,
        amount: result.amountInPaise,
        amountInRupees: result.order.totalAmount,
        currency: 'INR',
        keyId: result.keyId,
        paymentExpiresAt: result.order.paymentExpiresAt,
        mock: result.mock,
        prefill: result.prefill,
      },
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Could not create payment order', status);
  }
});

router.post('/payments/verify', authOptional, async (req, res) => {
  try {
    const {
      orderId,
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature,
    } = req.body || {};

    if (!orderId) return sendError(res, 'orderId is required', 400);

    if (!isMockMode()) {
      if (!razorpayOrderId || !razorpayPaymentId || !razorpaySignature) {
        return sendError(res, 'Payment details are required', 400);
      }
    } else if (!razorpayOrderId || !razorpayPaymentId) {
      return sendError(res, 'Payment details are required', 400);
    }

    const order = await confirmBloodOrderAfterPayment({
      orderId,
      razorpayOrderId,
      razorpayPaymentId,
      razorpaySignature,
    });

    return res.status(200).json({
      success: true,
      message: 'Payment successful. Blood order confirmed.',
      statusCode: 200,
      data: order,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Payment verification failed', status);
  }
});

router.post('/bookings/:orderId/status', authOptional, async (req, res) => {
  try {
    const { status, rejectionReason, estimatedDeliveryTime } = req.body || {};
    if (!status) return sendError(res, 'status is required', 400);

    const order = await updateOrderStatus(req.params.orderId, status, {
      rejectionReason,
      estimatedDeliveryTime: estimatedDeliveryTime
        ? new Date(estimatedDeliveryTime)
        : undefined,
    });

    if (!order) return sendError(res, 'Order not found', 404);
    return sendSuccess(res, { message: 'Order status updated', data: order });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to update order', 500);
  }
});

// ——— Reviews ———

router.get('/reviews', async (req, res) => {
  try {
    const bloodBankId = req.query.bloodBankId;
    if (!bloodBankId) return sendError(res, 'bloodBankId is required', 400);

    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(50, parseInt(req.query.pageSize || '20', 10));
    const { reviews, pagination } = await listReviewsByBloodBank(bloodBankId, { page, pageSize });

    return sendSuccess(res, { data: reviews, pagination });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch reviews', 500);
  }
});

router.post('/reviews', authOptional, async (req, res) => {
  try {
    const body = req.body || {};
    if (!body.bloodBankId || !body.rating) {
      return sendError(res, 'bloodBankId and rating are required', 400);
    }

    const review = await createBloodReview({
      ...body,
      patientId: body.patientId || req.auth?.patientId,
    });

    return sendSuccess(res, { message: 'Review submitted', data: review });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to submit review', 500);
  }
});

// ——— Emergency requests ———

router.post('/emergency', authOptional, async (req, res) => {
  try {
    const body = req.body || {};
    if (!body.bloodGroup || !body.units) {
      return sendError(res, 'bloodGroup and units are required', 400);
    }

    const request = await createEmergencyRequest({
      ...body,
      patientId: body.patientId || req.auth?.patientId,
    });

    const { bloodBanks } = await listBloodBanks({
      status: 'verified',
      pageSize: 20,
      bloodGroup: body.bloodGroup,
      city: body.city,
      emergencySupply: true,
    });

    notifyEmergencyRequestCreated(request, bloodBanks).catch((err) =>
      console.error('[emergency] notify failed:', err.message),
    );

    return sendSuccess(res, { message: 'Emergency request created', data: request });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to create emergency request', 500);
  }
});

router.get('/emergency', authOptional, async (req, res) => {
  try {
    const bloodBankId = req.query.bloodBankId || req.auth?.bloodBankId;
    if (!bloodBankId) return sendError(res, 'bloodBankId is required', 400);

    const requests = await listEmergencyRequestsForBloodBank(bloodBankId, {
      status: req.query.status || 'open',
    });

    return sendSuccess(res, { data: requests });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch emergency requests', 500);
  }
});

router.post('/emergency/:requestId/accept', authOptional, async (req, res) => {
  try {
    const bloodBankId = req.body?.bloodBankId || req.auth?.bloodBankId;
    if (!bloodBankId) return sendError(res, 'bloodBankId is required', 400);

    const request = await acceptEmergencyRequest(req.params.requestId, bloodBankId);

    const bank = await findBloodBankById(bloodBankId);
    notifyEmergencyRequestAccepted(request, bank).catch((err) =>
      console.error('[emergency] accept notify failed:', err.message),
    );

    return sendSuccess(res, { message: 'Emergency request accepted', data: request });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to accept request', status);
  }
});

router.get('/emergency/:requestId', authOptional, async (req, res) => {
  try {
    const request = await findEmergencyRequestById(req.params.requestId);
    if (!request) return sendError(res, 'Request not found', 404);
    return sendSuccess(res, { data: request });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch request', 500);
  }
});

// ——— Staff ———

router.get('/staff', authOptional, async (req, res) => {
  try {
    const bloodBankId = req.query.bloodBankId || req.auth?.bloodBankId;
    if (!bloodBankId) return sendError(res, 'bloodBankId is required', 400);

    const staff = await listStaffByBloodBank(bloodBankId);
    return sendSuccess(res, { data: staff });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch staff', 500);
  }
});

router.post('/staff', authOptional, async (req, res) => {
  try {
    const body = req.body || {};
    if (!body.bloodBankId || !body.name) {
      return sendError(res, 'bloodBankId and name are required', 400);
    }

    const member = await upsertStaff(body);
    return sendSuccess(res, { message: 'Staff saved', data: member });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to save staff', 500);
  }
});

router.delete('/staff/:staffId', authOptional, async (req, res) => {
  try {
    const member = await removeStaff(req.params.staffId);
    return sendSuccess(res, { message: 'Staff removed', data: member });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to remove staff', 500);
  }
});

module.exports = router;

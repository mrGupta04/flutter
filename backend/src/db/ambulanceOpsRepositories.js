const Ambulance = require('./models/Ambulance');
const AmbulanceBooking = require('./models/AmbulanceBooking');
const AmbulanceReview = require('./models/AmbulanceReview');
const { toAmbulance, toAmbulanceBooking, toAmbulancePublic } = require('./ambulanceMappers');
const { ACTIVE_TRIP_STATUSES } = require('./ambulanceConstants');
const { writeAmbulanceAudit } = require('./ambulanceAuditRepositories');
const { locationFreshness } = require('../services/ambulanceLocationService');

async function getProviderDashboard(ambulanceId) {
  const provider = await Ambulance.findOne({ id: ambulanceId }).lean();
  if (!provider) {
    const err = new Error('Ambulance provider not found');
    err.statusCode = 404;
    throw err;
  }

  const startOfDay = new Date();
  startOfDay.setHours(0, 0, 0, 0);

  const [
    availableAmbulances,
    activeTrips,
    emergencyRequests,
    scheduledTrips,
    driversOnline,
    completedToday,
    earningsAgg,
  ] = await Promise.all([
    Promise.resolve(
      (provider.vehicles || []).filter((item) => item.status === 'AVAILABLE').length,
    ),
    AmbulanceBooking.countDocuments({
      ambulanceId,
      status: { $in: ACTIVE_TRIP_STATUSES },
    }),
    AmbulanceBooking.countDocuments({
      ambulanceId,
      bookingKind: 'emergency',
      status: { $in: ['requested', 'searching_ambulance'] },
    }),
    AmbulanceBooking.countDocuments({
      ambulanceId,
      bookingKind: 'scheduled',
      status: { $in: ['requested', 'accepted', 'ambulance_assigned', 'driver_accepted'] },
    }),
    Promise.resolve(
      (provider.drivers || []).filter((item) => item.isOnline || item.status === 'AVAILABLE')
        .length,
    ),
    AmbulanceBooking.countDocuments({
      ambulanceId,
      status: { $in: ['trip_completed', 'completed'] },
      completedAt: { $gte: startOfDay },
    }),
    AmbulanceBooking.aggregate([
      {
        $match: {
          ambulanceId,
          paymentStatus: { $in: ['paid', 'cash'] },
          completedAt: { $gte: startOfDay },
        },
      },
      { $group: { _id: null, total: { $sum: '$fare.total' } } },
    ]),
  ]);

  return {
    provider: toAmbulance(provider),
    stats: {
      availableAmbulances,
      activeTrips,
      emergencyRequests,
      scheduledTrips,
      driversOnline,
      completedToday,
      earningsToday: earningsAgg[0]?.total || 0,
      totalAmbulances: (provider.vehicles || []).length,
      totalDrivers: (provider.drivers || []).length,
    },
  };
}

async function getProviderAnalytics(ambulanceId) {
  const bookings = await AmbulanceBooking.find({ ambulanceId }).lean();
  const completed = bookings.filter((item) =>
    ['trip_completed', 'completed'].includes(item.status),
  );
  const cancelled = bookings.filter((item) => item.status === 'cancelled');
  const emergency = bookings.filter((item) => item.isEmergency !== false);
  const durations = completed
    .map((item) => Number(item.tripDurationMinutes))
    .filter((value) => Number.isFinite(value));
  const revenue = completed.reduce((sum, item) => sum + Number(item.fare?.total || 0), 0);

  return {
    totalTrips: bookings.length,
    emergencyTrips: emergency.length,
    scheduledTrips: bookings.length - emergency.length,
    completedTrips: completed.length,
    cancellationRate: bookings.length
      ? Math.round((cancelled.length / bookings.length) * 1000) / 10
      : 0,
    averageTripDuration: durations.length
      ? Math.round(durations.reduce((a, b) => a + b, 0) / durations.length)
      : 0,
    revenue,
    ambulanceUtilization: completed.length,
  };
}

async function getAdminAmbulanceOverview() {
  const [providers, bookings, reviews] = await Promise.all([
    Ambulance.find({}).lean(),
    AmbulanceBooking.find({}).lean(),
    AmbulanceReview.countDocuments(),
  ]);
  const verified = providers.filter(
    (item) => item.verificationStatus === 'verified' || item.isApproved,
  );
  const vehicles = providers.flatMap((item) => item.vehicles || []);
  const drivers = providers.flatMap((item) => item.drivers || []);
  const completed = bookings.filter((item) =>
    ['trip_completed', 'completed'].includes(item.status),
  );
  return {
    totalProviders: providers.length,
    verifiedProviders: verified.length,
    totalAmbulances: vehicles.length,
    availableAmbulances: vehicles.filter((item) => item.status === 'AVAILABLE').length,
    activeTrips: bookings.filter((item) => ACTIVE_TRIP_STATUSES.includes(item.status)).length,
    emergencyRequests: bookings.filter(
      (item) =>
        item.bookingKind === 'emergency' &&
        ['requested', 'searching_ambulance'].includes(item.status),
    ).length,
    completedTrips: completed.length,
    cancelledTrips: bookings.filter((item) => item.status === 'cancelled').length,
    driversOnline: drivers.filter((item) => item.isOnline || item.status === 'AVAILABLE').length,
    revenue: completed.reduce((sum, item) => sum + Number(item.fare?.total || 0), 0),
    reviews,
  };
}

async function getAdminAnalytics() {
  const bookings = await AmbulanceBooking.find({}).lean();
  const byHour = Array.from({ length: 24 }, (_, hour) => ({ hour, count: 0 }));
  bookings.forEach((item) => {
    const hour = new Date(item.createdAt).getHours();
    byHour[hour].count += 1;
  });
  const completed = bookings.filter((item) =>
    ['trip_completed', 'completed'].includes(item.status),
  );
  return {
    demandByHour: byHour,
    emergencyRequests: bookings.filter((item) => item.isEmergency !== false).length,
    completionRate: bookings.length
      ? Math.round((completed.length / bookings.length) * 1000) / 10
      : 0,
    cancellationRate: bookings.length
      ? Math.round(
          (bookings.filter((item) => item.status === 'cancelled').length / bookings.length) *
            1000,
        ) / 10
      : 0,
    revenue: completed.reduce((sum, item) => sum + Number(item.fare?.total || 0), 0),
  };
}

async function getLiveOperations() {
  const providers = await Ambulance.find({
    $or: [{ verificationStatus: 'verified' }, { isApproved: true }],
  }).lean();
  const trips = await AmbulanceBooking.find({
    status: { $in: ACTIVE_TRIP_STATUSES },
  }).lean();

  const ambulances = [];
  providers.forEach((provider) => {
    (provider.vehicles || []).forEach((vehicle) => {
      const freshness = locationFreshness(vehicle.lastLocationAt);
      ambulances.push({
        ambulanceId: provider.id,
        providerName: provider.serviceName,
        vehicleId: vehicle.id,
        registration: vehicle.registrationNumber,
        type: vehicle.vehicleType,
        status: vehicle.status,
        driverId: vehicle.assignedDriverId,
        currentBookingId: vehicle.currentBookingId,
        latitude: vehicle.currentLatitude ?? provider.latitude,
        longitude: vehicle.currentLongitude ?? provider.longitude,
        lastLocationAt: vehicle.lastLocationAt,
        location: freshness,
      });
    });
  });

  return {
    ambulances,
    trips: trips.map((trip) => ({
      ...toAmbulanceBooking(trip),
      location: locationFreshness(trip.liveLocationUpdatedAt),
    })),
  };
}

async function listPublicProviders({ page = 1, pageSize = 20, city, vehicleType } = {}) {
  const filter = {
    $or: [{ verificationStatus: 'verified' }, { isApproved: true }],
    isDisabled: { $ne: true },
    isSuspended: { $ne: true },
  };
  if (city) filter.city = new RegExp(city, 'i');
  if (vehicleType) filter.vehicleTypes = new RegExp(vehicleType, 'i');
  const totalCount = await Ambulance.countDocuments(filter);
  const docs = await Ambulance.find(filter)
    .sort({ ratingAverage: -1, createdAt: -1 })
    .skip((page - 1) * pageSize)
    .limit(pageSize)
    .lean();
  return {
    providers: docs.map(toAmbulancePublic),
    pagination: {
      currentPage: page,
      totalPages: Math.max(1, Math.ceil(totalCount / pageSize)),
      pageSize,
      totalCount,
    },
  };
}

async function getPublicProvider(id) {
  const doc = await Ambulance.findOne({ id }).lean();
  if (!doc || (doc.verificationStatus !== 'verified' && !doc.isApproved)) {
    const err = new Error('Ambulance provider not found');
    err.statusCode = 404;
    throw err;
  }
  const reviews = await AmbulanceReview.find({ ambulanceId: id })
    .sort({ createdAt: -1 })
    .limit(20)
    .lean();
  return { provider: toAmbulancePublic(doc), reviews };
}

async function setProviderAccess(id, { suspended, disabled }, actor) {
  const update = {};
  if (suspended != null) {
    update.isSuspended = Boolean(suspended);
    if (suspended) update.verificationStatus = 'suspended';
  }
  if (disabled != null) update.isDisabled = Boolean(disabled);
  await Ambulance.updateOne({ id }, { $set: update });
  await writeAmbulanceAudit({
    actorId: actor?.actorId || 'admin',
    actorRole: actor?.actorRole || 'admin',
    action: suspended ? 'provider_suspended' : disabled ? 'provider_disabled' : 'provider_enabled',
    entityType: 'AmbulanceProvider',
    entityId: id,
    ambulanceId: id,
    newValue: update,
  });
  return Ambulance.findOne({ id }).lean();
}

module.exports = {
  getProviderDashboard,
  getProviderAnalytics,
  getAdminAmbulanceOverview,
  getAdminAnalytics,
  getLiveOperations,
  listPublicProviders,
  getPublicProvider,
  setProviderAccess,
};

require('dotenv').config();
const path = require('path');
const express = require('express');
const cors = require('cors');
const { connectDB } = require('./db/connect');
const { seed } = require('./db/seed');
const doctorRoutes = require('./routes/doctorRoutes');
const nurseRoutes = require('./routes/nurseRoutes');
const adminAuthRoutes = require('./routes/adminAuthRoutes');
const adminRoutes = require('./routes/adminRoutes');
const ambulanceRoutes = require('./routes/ambulanceRoutes');
const bloodBankRoutes = require('./routes/bloodBankRoutes');
const labRoutes = require('./routes/labRoutes');
const scanRoutes = require('./routes/scanRoutes');
const patientRoutes = require('./routes/patientRoutes');
const patientFeatureRoutes = require('./routes/patientFeatureRoutes');
const paymentRoutes = require('./routes/paymentRoutes');
const consultationRoutes = require('./routes/consultationRoutes');
const cmsRoutes = require('./routes/cmsRoutes');
const { getProviderInfo: getRazorpayInfo } = require('./services/razorpayService');
const { getProviderInfo: getVideoProviderInfo } = require('./services/videoConsultService');
const { sendSuccess, sendError } = require('./utils/response');
const {
  verifySmtpConnection,
  getProviderInfo,
  resolveProviderName,
} = require('./services/emailProviders');
const {
  startPrescriptionAutoSendScheduler,
} = require('./services/prescriptionAutoSendService');
const {
  startVisitReminderScheduler,
} = require('./services/visitReminderService');
const PORT = parseInt(process.env.PORT || '3000', 10);
const NODE_ENV = process.env.NODE_ENV || 'development';
const app = express();


app.set('trust proxy', 1);

const corsOrigin = process.env.CORS_ORIGIN || '*';
app.use(
  cors({
    origin: corsOrigin === '*' ? true : corsOrigin.split(','),
    credentials: true,
  }),
);

app.use(express.json({ limit: '2mb' }));
app.use(express.urlencoded({ extended: true }));

const uploadsPath = path.join(__dirname, '../uploads');
const uploadRoutes = require('./routes/uploadRoutes');
app.use('/uploads', uploadRoutes);

app.get('/health', async (_req, res) => {
  try {
    const { mongoose } = require('./db/connect');
    const dbState = mongoose.connection.readyState;
    sendSuccess(res, {
      data: {
        status: 'ok',
        service: '1mg-doctors-api',
        environment: NODE_ENV,
        database: dbState === 1 ? 'mongodb_connected' : 'mongodb_disconnected',
        email: getProviderInfo(),
        payments: getRazorpayInfo(),
        videoConsult: getVideoProviderInfo(),
      },
    });
  } catch {
    sendSuccess(res, {
      data: { status: 'ok', service: '1mg-doctors-api', environment: NODE_ENV },
    });
  }
});

app.use('/api/v1/admin', adminAuthRoutes);
app.use('/api/v1/admin', adminRoutes);
app.use('/api/v1/doctor', doctorRoutes);
app.use('/api/v1/nurse', nurseRoutes);
app.use('/api/v1/ambulance', ambulanceRoutes);
app.use('/api/v1/blood-bank', bloodBankRoutes);
app.use('/api/v1/lab', labRoutes);
app.use('/api/v1/scan', scanRoutes);
app.use('/api/v1/patient', patientRoutes);
app.use('/api/v1/patient', patientFeatureRoutes);
app.use('/api/v1/payments', paymentRoutes);
app.use('/api/v1/consultations', consultationRoutes);
app.use('/api/v1/cms', cmsRoutes);
app.use((req, res) => {
  sendError(res, `Route not found: ${req.method} ${req.path}`, 404);
});

app.use((err, _req, res, _next) => {
  console.error(err);
  if (err.code === 'LIMIT_FILE_SIZE') {
    return sendError(res, 'File size exceeds 10 MB limit', 413);
  }
  sendError(res, err.message || 'Internal server error', 500);
});

async function start() {
  if (!process.env.JWT_SECRET || process.env.JWT_SECRET.length < 32) {
    console.warn(
      'WARNING: Set JWT_SECRET to a random string of at least 32 characters.',
    );
  }

  await connectDB();

  const paymentInfo = getRazorpayInfo();
  if (paymentInfo.provider === 'mock') {
    console.warn(
      'Booking payments running in mock mode (RAZORPAY_PROVIDER=mock). ' +
        'Set RAZORPAY_KEY_ID and RAZORPAY_KEY_SECRET when ready for real payments.',
    );
  } else {
    console.log('Booking payments Razorpay configured');
  }

  const videoInfo = getVideoProviderInfo();
  if (videoInfo.provider === 'mock') {
    console.warn(
      'Online consult video running in mock mode (VIDEO_PROVIDER=mock). ' +
        'Set VIDEO_PROVIDER=jitsi for real video via Jitsi Meet.',
    );
  } else {
    console.log(`Online consult video provider: ${videoInfo.provider}`);
  }

  if (process.env.SEED_DATABASE === 'true') {
    await seed();
    console.log('Database seeded with sample data (SEED_DATABASE=true)');
  }

  await new Promise((resolve) => {
    app.listen(PORT, '0.0.0.0', () => {
      console.log(`1mg Doctors API [${NODE_ENV}] http://0.0.0.0:${PORT}`);
      console.log(`  Health: http://localhost:${PORT}/health`);
      console.log(`  API:    http://localhost:${PORT}/api/v1`);
      resolve();
    });
  });

  void verifySmtpAtStartup();
  startPrescriptionAutoSendScheduler();
  startVisitReminderScheduler();
}

async function verifySmtpAtStartup() {
  if (resolveProviderName() === 'mock') {
    console.warn('Email verification running in mock mode (EMAIL_PROVIDER=mock)');
    return;
  }

  try {
    await verifySmtpConnection();
    console.log('Email verification connection verified');
  } catch (err) {
    console.warn(
      `WARNING: Email verification failed: ${err.message}. ` +
        'The API is running; OTP delivery will be attempted when doctors request a code.',
    );
  }
}

start().catch((err) => {
  console.error('Failed to start server:', err.message);
  process.exit(1);
});

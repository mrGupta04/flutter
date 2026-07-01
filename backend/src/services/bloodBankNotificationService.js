const { sendSms } = require('./smsService');
const { sendWhatsApp } = require('./whatsappService');
const { sendPushNotification } = require('./pushNotificationService');
const { getProvider, resolveProviderName } = require('./emailProviders');
const { findBloodBankById } = require('../db/bloodBankRepositories');

const APP_NAME = process.env.APP_NAME || 'MedConnect';

const STATUS_MESSAGES = {
  pending: {
    patient: 'Your blood order has been placed and is awaiting confirmation.',
    bloodBank: 'New blood order received — please review and accept.',
  },
  accepted: {
    patient: 'Your blood order has been accepted by the blood bank.',
    bloodBank: 'You accepted a blood order.',
  },
  rejected: {
    patient: 'Your blood order was declined by the blood bank.',
    bloodBank: 'You declined a blood order.',
  },
  blood_ready: {
    patient: 'Your blood order is ready for pickup or delivery.',
    bloodBank: 'Blood units marked ready for patient order.',
  },
  out_for_delivery: {
    patient: 'Your blood order is out for delivery.',
    bloodBank: 'Blood order dispatched for delivery.',
  },
  delivered: {
    patient: 'Your blood order has been delivered successfully.',
    bloodBank: 'Blood order marked as delivered.',
  },
};

function formatOrderSummary(order, bloodBank) {
  const bankName = bloodBank?.institutionName || 'Blood bank';
  return `${order.bloodGroup} ${order.componentType} × ${order.units} units @ ${bankName}`;
}

function buildEmailHtml({ recipientName, title, body, orderId, summary }) {
  return `
    <div style="font-family:Arial,sans-serif;line-height:1.6;color:#1f2937;max-width:560px;">
      <h2 style="margin:0 0 12px;color:#B71C1C;">${title}</h2>
      <p style="margin:0 0 16px;">Hello ${recipientName},</p>
      <p style="margin:0 0 16px;">${body}</p>
      <table style="width:100%;border-collapse:collapse;margin:0 0 20px;">
        <tr><td style="padding:8px 0;color:#6b7280;">Order</td><td style="padding:8px 0;font-weight:600;">${summary}</td></tr>
        <tr><td style="padding:8px 0;color:#6b7280;">Order ID</td><td style="padding:8px 0;font-family:monospace;">${orderId}</td></tr>
      </table>
      <p style="margin:0;font-size:13px;color:#9ca3af;">— ${APP_NAME} Blood Bank</p>
    </div>
  `;
}

async function sendEmail({ to, subject, text, html }) {
  if (!to || !/^[^\s@]+@[^\s@]+\.[^\s@]+$/.test(to)) {
    return { sent: false, reason: 'invalid_email' };
  }

  const providerName = resolveProviderName();
  if (providerName === 'mock') {
    console.log(`[blood-email] To ${to}: ${subject}`);
    console.log(text);
    return { sent: true, provider: 'mock' };
  }

  try {
    const provider = getProvider();
    await provider.sendTransactionalEmail({ to, subject, text, html });
    return { sent: true, provider: providerName };
  } catch (err) {
    console.error('[blood-email] Failed:', err.message);
    return { sent: false, error: err.message };
  }
}

async function notifyPatientChannels({ order, bloodBank, event, message }) {
  const summary = formatOrderSummary(order, bloodBank);
  const subject = `${APP_NAME} — Blood order ${event.replace(/_/g, ' ')}`;
  const text = `${message}\n\n${summary}\nOrder ID: ${order.id}`;

  const results = {};

  const patientMobile = String(order.patientMobile || '').replace(/\D/g, '').slice(-10);
  if (patientMobile.length === 10) {
    results.sms = await sendSms(patientMobile, `${APP_NAME}: ${message} Order ${order.id}`);
    const whatsappNumber = bloodBank?.whatsappNumber || patientMobile;
    results.whatsapp = await sendWhatsApp(
      whatsappNumber === patientMobile ? patientMobile : patientMobile,
      `${APP_NAME}: ${message} ${summary}`,
    );
  }

  if (order.patientEmail) {
    results.email = await sendEmail({
      to: order.patientEmail,
      subject,
      text,
      html: buildEmailHtml({
        recipientName: order.patientName || 'Patient',
        title: subject,
        body: message,
        orderId: order.id,
        summary,
      }),
    });
  }

  if (order.patientId) {
    results.push = await sendPushNotification({
      userId: order.patientId,
      title: subject,
      body: message,
      data: { orderId: order.id, event, type: 'blood_order' },
    });
  }

  return results;
}

async function notifyBloodBankChannels({ order, bloodBank, event, message }) {
  const summary = formatOrderSummary(order, bloodBank);
  const subject = `${APP_NAME} — ${message}`;
  const text = `${message}\n\n${summary}\nOrder ID: ${order.id}`;

  const results = {};

  const bankMobile = String(bloodBank?.mobileNumber || '').replace(/\D/g, '').slice(-10);
  if (bankMobile.length === 10) {
    results.sms = await sendSms(bankMobile, `${APP_NAME}: ${message} Order ${order.id}`);
  }

  const whatsapp = String(bloodBank?.whatsappNumber || bankMobile).replace(/\D/g, '').slice(-10);
  if (whatsapp.length === 10) {
    results.whatsapp = await sendWhatsApp(whatsapp, `${APP_NAME}: ${message} ${summary}`);
  }

  const email = bloodBank?.emailSupport || bloodBank?.email;
  if (email) {
    results.email = await sendEmail({
      to: email,
      subject,
      text,
      html: buildEmailHtml({
        recipientName: bloodBank.institutionName || 'Blood bank',
        title: subject,
        body: message,
        orderId: order.id,
        summary,
      }),
    });
  }

  results.push = await sendPushNotification({
    userId: bloodBank?.id,
    title: subject,
    body: message,
    data: { orderId: order.id, event, type: 'blood_order', bloodBankId: bloodBank?.id },
  });

  return results;
}

async function notifyBloodOrderStatusChange(order, status) {
  const bloodBank = await findBloodBankById(order.bloodBankId);
  const event = status;
  const messages = STATUS_MESSAGES[status];
  if (!messages) return { skipped: true };

  const [patient, bank] = await Promise.all([
    notifyPatientChannels({
      order,
      bloodBank,
      event,
      message: messages.patient,
    }),
    notifyBloodBankChannels({
      order,
      bloodBank,
      event,
      message: messages.bloodBank,
    }),
  ]);

  return { patient, bloodBank: bank, event };
}

async function notifyBloodOrderPlaced(order) {
  return notifyBloodOrderStatusChange(order, 'pending');
}

async function notifyEmergencyRequestCreated(request, nearbyBloodBanks = []) {
  const summary = `Emergency: ${request.bloodGroup} × ${request.units} units needed ${request.requiredWithin || 'urgently'}`;
  const text = `${summary}\nPatient: ${request.patientName || 'N/A'}\nHospital: ${request.hospitalName || 'N/A'}\nContact: ${request.contactNumber || 'N/A'}`;

  const results = { bloodBanks: [] };

  const contact = String(request.contactNumber || '').replace(/\D/g, '').slice(-10);
  if (contact.length === 10) {
    results.patientSms = await sendSms(
      contact,
      `${APP_NAME}: Emergency blood request submitted. Nearby banks notified.`,
    );
  }

  for (const bank of nearbyBloodBanks.slice(0, 10)) {
    const bankResult = { bloodBankId: bank.id };
    const mobile = String(bank.mobileNumber || '').replace(/\D/g, '').slice(-10);
    if (mobile.length === 10) {
      bankResult.sms = await sendSms(mobile, `${APP_NAME}: ${text}`);
    }
    const wa = String(bank.whatsappNumber || mobile).replace(/\D/g, '').slice(-10);
    if (wa.length === 10) {
      bankResult.whatsapp = await sendWhatsApp(wa, `${APP_NAME}: ${text}`);
    }
    if (bank.email) {
      bankResult.email = await sendEmail({
        to: bank.email,
        subject: `${APP_NAME} — Emergency blood request`,
        text,
        html: buildEmailHtml({
          recipientName: bank.institutionName || 'Blood bank',
          title: 'Emergency blood request',
          body: text,
          orderId: request.id,
          summary,
        }),
      });
    }
    bankResult.push = await sendPushNotification({
      userId: bank.id,
      title: `${APP_NAME} — Emergency blood request`,
      body: summary,
      data: { requestId: request.id, type: 'emergency_blood' },
    });
    results.bloodBanks.push(bankResult);
  }

  return results;
}

async function notifyEmergencyRequestAccepted(request, bloodBank) {
  const contact = String(request.contactNumber || '').replace(/\D/g, '').slice(-10);
  const bankName = bloodBank?.institutionName || 'A blood bank';
  const message = `${bankName} accepted your emergency blood request for ${request.bloodGroup}.`;

  const results = {};
  if (contact.length === 10) {
    results.sms = await sendSms(contact, `${APP_NAME}: ${message}`);
    results.whatsapp = await sendWhatsApp(contact, `${APP_NAME}: ${message}`);
  }
  if (request.patientId) {
    results.push = await sendPushNotification({
      userId: request.patientId,
      title: `${APP_NAME} — Emergency request accepted`,
      body: message,
      data: { requestId: request.id, bloodBankId: bloodBank?.id },
    });
  }
  return results;
}

module.exports = {
  notifyBloodOrderPlaced,
  notifyBloodOrderStatusChange,
  notifyEmergencyRequestCreated,
  notifyEmergencyRequestAccepted,
};

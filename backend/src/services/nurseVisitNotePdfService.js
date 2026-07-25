const fs = require('fs');
const path = require('path');
const PDFDocument = require('pdfkit');
const { v4: uuidv4 } = require('uuid');

const uploadsDir = path.join(__dirname, '../../uploads');

function ensureUploadsDir() {
  if (!fs.existsSync(uploadsDir)) {
    fs.mkdirSync(uploadsDir, { recursive: true });
  }
}

function formatDate(value) {
  if (!value) return '—';
  const date = value instanceof Date ? value : new Date(value);
  if (Number.isNaN(date.getTime())) return '—';
  return date.toLocaleString('en-IN', {
    day: '2-digit',
    month: 'short',
    year: 'numeric',
    hour: '2-digit',
    minute: '2-digit',
  });
}

function writeSectionTitle(doc, title) {
  doc.moveDown(0.4);
  doc.fontSize(12).fillColor('#208376').text(title, { underline: true });
  doc.moveDown(0.2);
  doc.fillColor('#111827');
}

function formatFollowUp(value) {
  const map = {
    continue_medication: 'Continue Medication',
    consult_doctor: 'Consult Doctor',
    emergency_visit: 'Emergency Visit Recommended',
    follow_up_home_visit: 'Follow-up Home Visit',
    hospital_admission: 'Hospital Admission Suggested',
  };
  return map[value] || value || '—';
}

function generateNurseVisitNotePdf({
  note,
  nurseName,
  nurseQualification,
  bookingId,
  slotStart,
  patientMobile,
  patientAddress,
}) {
  ensureUploadsDir();

  const fileName = `nursing-report-${note.id || uuidv4()}.pdf`;
  const filePath = path.join(uploadsDir, fileName);
  const appName = process.env.APP_NAME || '1mg Care';

  return new Promise((resolve, reject) => {
    const doc = new PDFDocument({ margin: 48, size: 'A4' });
    const stream = fs.createWriteStream(filePath);

    stream.on('finish', () => {
      resolve({
        fileName,
        filePath,
        publicPath: `/uploads/${fileName}`,
      });
    });
    stream.on('error', reject);
    doc.on('error', reject);
    doc.pipe(stream);

    doc.fontSize(20).fillColor('#208376').text(appName, { align: 'center' });
    doc.fontSize(16).fillColor('#111827').text('Nursing Visit Report', {
      align: 'center',
    });
    doc.moveDown(0.3);
    doc
      .fontSize(10)
      .fillColor('#6b7280')
      .text(`Generated on ${formatDate(note.pdfGeneratedAt || new Date())}`, {
        align: 'center',
      });
    doc.moveDown(0.8);

    writeSectionTitle(doc, 'Visit information');
    doc.fontSize(11);
    doc.text(`Appointment ID: ${bookingId || '—'}`);
    doc.text(`Patient: ${note.patientName || '—'}`);
    if (patientMobile) doc.text(`Mobile: ${patientMobile}`);
    if (patientAddress) doc.text(`Address: ${patientAddress}`);
    doc.text(`Nurse: ${nurseName || '—'}`);
    if (nurseQualification) doc.text(`Qualification: ${nurseQualification}`);
    if (slotStart) doc.text(`Scheduled: ${formatDate(slotStart)}`);
    if (note.visitStartedAt) {
      doc.text(`Visit started: ${formatDate(note.visitStartedAt)}`);
    }
    if (note.visitEndedAt) {
      doc.text(`Visit ended: ${formatDate(note.visitEndedAt)}`);
    }
    if (note.visitDurationMinutes != null) {
      doc.text(`Duration: ${note.visitDurationMinutes} minutes`);
    }

    const v = note.vitalsData || {};
    const hasVitals = Object.values(v).some((x) => x != null && x !== '');
    if (hasVitals) {
      writeSectionTitle(doc, 'Patient vitals');
      doc.fontSize(11);
      if (v.bloodPressureSystolic != null && v.bloodPressureDiastolic != null) {
        doc.text(`Blood Pressure: ${v.bloodPressureSystolic}/${v.bloodPressureDiastolic} mmHg`);
      }
      if (v.pulseRate != null) doc.text(`Pulse Rate: ${v.pulseRate} bpm`);
      if (v.oxygenSaturation != null) doc.text(`SpO₂: ${v.oxygenSaturation}%`);
      if (v.bodyTemperature != null) doc.text(`Temperature: ${v.bodyTemperature} °F`);
      if (v.bloodSugar != null) {
        doc.text(
          `Blood Sugar: ${v.bloodSugar} mg/dL${v.bloodSugarType ? ` (${v.bloodSugarType})` : ''}`,
        );
      }
      if (v.respiratoryRate != null) {
        doc.text(`Respiratory Rate: ${v.respiratoryRate} /min`);
      }
      if (v.heightCm != null) doc.text(`Height: ${v.heightCm} cm`);
      if (v.weightKg != null) doc.text(`Weight: ${v.weightKg} kg`);
      if (v.bmi != null) doc.text(`BMI: ${v.bmi}`);
    }

    const ga = note.generalAssessment || {};
    const hasAssessment = Object.values(ga).some((x) => x != null && x !== '');
    if (hasAssessment) {
      writeSectionTitle(doc, 'General assessment');
      doc.fontSize(11);
      if (ga.patientCondition) doc.text(`Condition: ${ga.patientCondition}`);
      if (ga.painLevel != null) doc.text(`Pain level: ${ga.painLevel}/10`);
      if (ga.mentalStatus) doc.text(`Mental status: ${ga.mentalStatus}`);
      if (ga.mobilityStatus) doc.text(`Mobility: ${ga.mobilityStatus}`);
      if (ga.hydrationStatus) doc.text(`Hydration: ${ga.hydrationStatus}`);
    }

    if (note.symptoms?.length) {
      writeSectionTitle(doc, 'Symptoms');
      doc.fontSize(11).text(note.symptoms.join(', '));
      if (note.symptomsOther) {
        doc.fontSize(10).fillColor('#374151').text(`Other: ${note.symptomsOther}`);
        doc.fillColor('#111827');
      }
    }

    if (note.proceduresPerformed?.length) {
      writeSectionTitle(doc, 'Nursing procedures performed');
      doc.fontSize(11).text(note.proceduresPerformed.join(', '));
      if (note.proceduresOther) {
        doc.fontSize(10).fillColor('#374151').text(`Other: ${note.proceduresOther}`);
        doc.fillColor('#111827');
      }
    }

    const meds = note.medicinesAdministered || [];
    if (meds.length) {
      writeSectionTitle(doc, 'Medicines administered');
      meds.forEach((med, index) => {
        doc.fontSize(11).text(`${index + 1}. ${med.name}`);
        const parts = [
          med.dosage ? `Dosage: ${med.dosage}` : null,
          med.quantity ? `Qty: ${med.quantity}` : null,
          med.route ? `Route: ${med.route}` : null,
          med.timeGiven ? `Time: ${med.timeGiven}` : null,
        ].filter(Boolean);
        if (parts.length) {
          doc.fontSize(10).fillColor('#374151').text(parts.join(' | '));
          doc.fillColor('#111827');
        }
        doc.moveDown(0.15);
      });
    }

    const notesText = note.nurseNotes || note.careSummary;
    if (notesText) {
      writeSectionTitle(doc, 'Nurse notes');
      doc.fontSize(11).text(notesText);
    }

    if (note.followUpRecommendation) {
      writeSectionTitle(doc, 'Follow-up recommendation');
      doc.fontSize(11).text(formatFollowUp(note.followUpRecommendation));
    }

    doc.moveDown(1.5);
    doc.fontSize(10).fillColor('#6b7280');
    doc.text('Nurse digital signature', { continued: false });
    doc.moveDown(2);
    doc.text('_______________________________');
    doc.text(nurseName || 'Assigned Nurse');
    doc.moveDown(1);
    if (note.verificationCode) {
      doc.text(`Verification ID: ${note.verificationCode}`);
      doc.text('Scan or share this ID with support to verify report authenticity.');
    }

    doc.end();
  });
}

module.exports = {
  generateNurseVisitNotePdf,
};

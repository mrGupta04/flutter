const express = require('express');
const {
  findDoctorById,
  findDocumentsByDoctorId,
  listDoctors,
  approveDoctor,
  rejectDoctor,
} = require('../db/repositories');
const {
  findNurseById,
  findDocumentsByNurseId,
  listNurses,
  approveNurse,
  rejectNurse,
} = require('../db/nurseRepositories');
const {
  findAmbulanceById,
  findDocumentsByAmbulanceId,
  listAmbulances,
  approveAmbulance,
  rejectAmbulance,
} = require('../db/ambulanceRepositories');
const {
  findDocumentById,
  verifyDocument,
  rejectDocument,
  ensureDoctorDocumentsFromProfile,
  ensureNurseDocumentsFromProfile,
  ensureAmbulanceDocumentsFromProfile,
} = require('../db/documentVerification');
const {
  findBloodBankById,
  listBloodBanks,
  approveBloodBank,
  rejectBloodBank,
  suspendBloodBank,
  requestBloodBankDocuments,
  verifyBloodBankDocument,
  rejectBloodBankDocument,
  getBloodBankDashboardStats,
} = require('../db/bloodBankRepositories');
const { listAllOrders } = require('../db/bloodOrderRepositories');
const { listAllEmergencyRequests } = require('../db/emergencyBloodRequestRepositories');
const { listInventoryByBloodBank } = require('../db/bloodInventoryRepositories');
const {
  findLabById,
  listLabs,
  approveLab,
  rejectLab,
  suspendLab,
  requestLabDocuments,
  verifyLabDocument,
  rejectLabDocument,
} = require('../db/labRepositories');
const {
  findScanCenterById,
  listScanCenters,
  approveScanCenter,
  rejectScanCenter,
  suspendScanCenter,
  requestScanCenterDocuments,
  verifyScanCenterDocument,
  rejectScanCenterDocument,
} = require('../db/scanCenterRepositories');
const { sendSuccess, sendError } = require('../utils/response');
const { adminRequired } = require('../middleware/auth');

const router = express.Router();

// ——— Doctor applications (admin only) ———

router.get('/doctors', adminRequired, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(100, parseInt(req.query.pageSize || '20', 10));
    const status = req.query.status;

    const { doctors, pagination } = await listDoctors({ status, page, pageSize });

    return sendSuccess(res, {
      data: doctors,
      pagination,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to list doctors', 500);
  }
});

router.get('/doctors/:id', adminRequired, async (req, res) => {
  try {
    const doctor = await findDoctorById(req.params.id);
    if (!doctor) {
      return sendError(res, 'Doctor not found', 404);
    }
    return sendSuccess(res, { data: doctor });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch doctor', 500);
  }
});

router.get('/doctors/:id/documents', adminRequired, async (req, res) => {
  try {
    const doctor = await findDoctorById(req.params.id);
    if (!doctor) {
      return sendError(res, 'Doctor not found', 404);
    }
    const documents = await ensureDoctorDocumentsFromProfile(doctor);
    return sendSuccess(res, { data: documents });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch documents', 500);
  }
});

router.post(
  '/doctors/:doctorId/documents/:documentId/verify',
  adminRequired,
  async (req, res) => {
    try {
      const { doctorId, documentId } = req.params;
      const document = await findDocumentById(documentId);
      if (!document || document.doctorId !== doctorId) {
        return sendError(res, 'Document not found', 404);
      }

      const verified = await verifyDocument(documentId, req.auth?.adminId);
      return sendSuccess(res, {
        message: 'Document verified',
        data: verified,
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to verify document', status);
    }
  },
);

router.post(
  '/doctors/:doctorId/documents/:documentId/reject',
  adminRequired,
  async (req, res) => {
    try {
      const { doctorId, documentId } = req.params;
      const { rejectionReason } = req.body;
      if (!rejectionReason?.trim()) {
        return sendError(res, 'rejectionReason is required');
      }

      const document = await findDocumentById(documentId);
      if (!document || document.doctorId !== doctorId) {
        return sendError(res, 'Document not found', 404);
      }

      const rejected = await rejectDocument(
        documentId,
        rejectionReason.trim(),
        req.auth?.adminId,
      );
      return sendSuccess(res, {
        message: 'Document rejected',
        data: rejected,
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to reject document', status);
    }
  },
);

// Admin approval: pending / under_review → verified (live on user app)
router.post('/doctors/:id/approve', adminRequired, async (req, res) => {
  try {
    const { approvalNotes } = req.body;
    const existing = await findDoctorById(req.params.id);
    if (!existing) {
      return sendError(res, 'Doctor not found', 404);
    }

    const doctor = await approveDoctor(req.params.id, approvalNotes);

    return sendSuccess(res, {
      message: 'Doctor approved successfully',
      data: doctor,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to approve doctor', status);
  }
});

router.post('/doctors/:id/reject', adminRequired, async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    if (!rejectionReason?.trim()) {
      return sendError(res, 'rejectionReason is required');
    }

    const existing = await findDoctorById(req.params.id);
    if (!existing) {
      return sendError(res, 'Doctor not found', 404);
    }

    const allowed = ['pending', 'under_review', 'verifier_approved'];
    if (!allowed.includes(existing.verificationStatus)) {
      return sendError(
        res,
        `Cannot reject doctor with status "${existing.verificationStatus}"`,
        400,
      );
    }

    const doctor = await rejectDoctor(req.params.id, rejectionReason.trim());

    return sendSuccess(res, {
      message: 'Doctor rejected successfully',
      data: doctor,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to reject doctor', 500);
  }
});

// ——— Nurse applications (admin only) ———

router.get('/nurses', adminRequired, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(100, parseInt(req.query.pageSize || '20', 10));
    const status = req.query.status;

    const { nurses, pagination } = await listNurses({ status, page, pageSize });

    return sendSuccess(res, {
      data: nurses,
      pagination,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to list nurses', 500);
  }
});

router.get('/nurses/:id', adminRequired, async (req, res) => {
  try {
    const nurse = await findNurseById(req.params.id);
    if (!nurse) {
      return sendError(res, 'Nurse not found', 404);
    }
    return sendSuccess(res, { data: nurse });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch nurse', 500);
  }
});

router.get('/nurses/:id/documents', adminRequired, async (req, res) => {
  try {
    const nurse = await findNurseById(req.params.id);
    if (!nurse) {
      return sendError(res, 'Nurse not found', 404);
    }
    const documents = await ensureNurseDocumentsFromProfile(nurse);
    return sendSuccess(res, { data: documents });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch documents', 500);
  }
});

router.post(
  '/nurses/:nurseId/documents/:documentId/verify',
  adminRequired,
  async (req, res) => {
    try {
      const { nurseId, documentId } = req.params;
      const document = await findDocumentById(documentId);
      if (!document || document.nurseId !== nurseId) {
        return sendError(res, 'Document not found', 404);
      }

      const verified = await verifyDocument(documentId, req.auth?.adminId);
      return sendSuccess(res, {
        message: 'Document verified',
        data: verified,
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to verify document', status);
    }
  },
);

router.post(
  '/nurses/:nurseId/documents/:documentId/reject',
  adminRequired,
  async (req, res) => {
    try {
      const { nurseId, documentId } = req.params;
      const { rejectionReason } = req.body;
      if (!rejectionReason?.trim()) {
        return sendError(res, 'rejectionReason is required');
      }

      const document = await findDocumentById(documentId);
      if (!document || document.nurseId !== nurseId) {
        return sendError(res, 'Document not found', 404);
      }

      const rejected = await rejectDocument(
        documentId,
        rejectionReason.trim(),
        req.auth?.adminId,
      );
      return sendSuccess(res, {
        message: 'Document rejected',
        data: rejected,
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to reject document', status);
    }
  },
);

router.post('/nurses/:id/approve', adminRequired, async (req, res) => {
  try {
    const { approvalNotes } = req.body;
    const existing = await findNurseById(req.params.id);
    if (!existing) {
      return sendError(res, 'Nurse not found', 404);
    }

    const nurse = await approveNurse(req.params.id, approvalNotes);

    return sendSuccess(res, {
      message: 'Nurse approved successfully',
      data: nurse,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to approve nurse', status);
  }
});

router.post('/nurses/:id/reject', adminRequired, async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    if (!rejectionReason?.trim()) {
      return sendError(res, 'rejectionReason is required');
    }

    const existing = await findNurseById(req.params.id);
    if (!existing) {
      return sendError(res, 'Nurse not found', 404);
    }

    const allowed = ['pending', 'under_review', 'verifier_approved'];
    if (!allowed.includes(existing.verificationStatus)) {
      return sendError(
        res,
        `Cannot reject nurse with status "${existing.verificationStatus}"`,
        400,
      );
    }

    const nurse = await rejectNurse(req.params.id, rejectionReason.trim());

    return sendSuccess(res, {
      message: 'Nurse rejected successfully',
      data: nurse,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to reject nurse', 500);
  }
});

// ——— Ambulance applications (admin only) ———

router.get('/ambulances', adminRequired, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(100, parseInt(req.query.pageSize || '20', 10));
    const status = req.query.status;

    const { ambulances, pagination } = await listAmbulances({ status, page, pageSize });

    return sendSuccess(res, { data: ambulances, pagination });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to list ambulances', 500);
  }
});

router.get('/ambulances/:id', adminRequired, async (req, res) => {
  try {
    const ambulance = await findAmbulanceById(req.params.id);
    if (!ambulance) {
      return sendError(res, 'Ambulance service not found', 404);
    }
    return sendSuccess(res, { data: ambulance });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch ambulance', 500);
  }
});

router.get('/ambulances/:id/documents', adminRequired, async (req, res) => {
  try {
    const ambulance = await findAmbulanceById(req.params.id);
    if (!ambulance) {
      return sendError(res, 'Ambulance service not found', 404);
    }
    const documents = await ensureAmbulanceDocumentsFromProfile(ambulance);
    return sendSuccess(res, { data: documents });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch documents', 500);
  }
});

router.post(
  '/ambulances/:ambulanceId/documents/:documentId/verify',
  adminRequired,
  async (req, res) => {
    try {
      const { ambulanceId, documentId } = req.params;
      const document = await findDocumentById(documentId);
      if (!document || document.ambulanceId !== ambulanceId) {
        return sendError(res, 'Document not found', 404);
      }

      const verified = await verifyDocument(documentId, req.auth?.adminId);
      return sendSuccess(res, {
        message: 'Document verified',
        data: verified,
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to verify document', status);
    }
  },
);

router.post(
  '/ambulances/:ambulanceId/documents/:documentId/reject',
  adminRequired,
  async (req, res) => {
    try {
      const { ambulanceId, documentId } = req.params;
      const { rejectionReason } = req.body;
      if (!rejectionReason?.trim()) {
        return sendError(res, 'rejectionReason is required');
      }

      const document = await findDocumentById(documentId);
      if (!document || document.ambulanceId !== ambulanceId) {
        return sendError(res, 'Document not found', 404);
      }

      const rejected = await rejectDocument(
        documentId,
        rejectionReason.trim(),
        req.auth?.adminId,
      );
      return sendSuccess(res, {
        message: 'Document rejected',
        data: rejected,
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to reject document', status);
    }
  },
);

router.post('/ambulances/:id/approve', adminRequired, async (req, res) => {
  try {
    const { approvalNotes } = req.body;
    const existing = await findAmbulanceById(req.params.id);
    if (!existing) {
      return sendError(res, 'Ambulance service not found', 404);
    }

    const ambulance = await approveAmbulance(req.params.id, approvalNotes);

    return sendSuccess(res, {
      message: 'Ambulance approved successfully',
      data: ambulance,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to approve ambulance', status);
  }
});

router.post('/ambulances/:id/reject', adminRequired, async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    if (!rejectionReason?.trim()) {
      return sendError(res, 'rejectionReason is required');
    }

    const existing = await findAmbulanceById(req.params.id);
    if (!existing) {
      return sendError(res, 'Ambulance service not found', 404);
    }

    const allowed = ['pending', 'under_review', 'verifier_approved'];
    if (!allowed.includes(existing.verificationStatus)) {
      return sendError(
        res,
        `Cannot reject ambulance with status "${existing.verificationStatus}"`,
        400,
      );
    }

    const ambulance = await rejectAmbulance(req.params.id, rejectionReason.trim());

    return sendSuccess(res, {
      message: 'Ambulance rejected successfully',
      data: ambulance,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to reject ambulance', 500);
  }
});

// ——— Blood bank applications (admin only) ———

router.get('/blood-banks', adminRequired, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(100, parseInt(req.query.pageSize || '20', 10));
    const status = req.query.status;

    const { bloodBanks, pagination } = await listBloodBanks({ status, page, pageSize });

    return sendSuccess(res, { data: bloodBanks, pagination });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to list blood banks', 500);
  }
});

router.get('/blood-banks/:id', adminRequired, async (req, res) => {
  try {
    const bloodBank = await findBloodBankById(req.params.id);
    if (!bloodBank) {
      return sendError(res, 'Blood bank not found', 404);
    }
    return sendSuccess(res, { data: bloodBank });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch blood bank', 500);
  }
});

router.post('/blood-banks/:id/approve', adminRequired, async (req, res) => {
  try {
    const { approvalNotes } = req.body;
    const existing = await findBloodBankById(req.params.id);
    if (!existing) {
      return sendError(res, 'Blood bank not found', 404);
    }

    const bloodBank = await approveBloodBank(req.params.id, approvalNotes);

    return sendSuccess(res, {
      message: 'Blood bank approved successfully',
      data: bloodBank,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to approve blood bank', status);
  }
});

router.post('/blood-banks/:id/reject', adminRequired, async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    if (!rejectionReason?.trim()) {
      return sendError(res, 'rejectionReason is required');
    }

    const existing = await findBloodBankById(req.params.id);
    if (!existing) {
      return sendError(res, 'Blood bank not found', 404);
    }

    const allowed = ['pending', 'under_review', 'verifier_approved'];
    if (!allowed.includes(existing.verificationStatus)) {
      return sendError(
        res,
        `Cannot reject blood bank with status "${existing.verificationStatus}"`,
        400,
      );
    }

    const bloodBank = await rejectBloodBank(req.params.id, rejectionReason.trim());

    return sendSuccess(res, {
      message: 'Blood bank rejected successfully',
      data: bloodBank,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to reject blood bank', 500);
  }
});

router.post('/blood-banks/:id/suspend', adminRequired, async (req, res) => {
  try {
    const existing = await findBloodBankById(req.params.id);
    if (!existing) {
      return sendError(res, 'Blood bank not found', 404);
    }

    const bloodBank = await suspendBloodBank(req.params.id, req.body?.reason);
    return sendSuccess(res, { message: 'Blood bank suspended', data: bloodBank });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to suspend blood bank', 500);
  }
});

router.post('/blood-banks/:id/request-documents', adminRequired, async (req, res) => {
  try {
    const { note } = req.body;
    if (!note?.trim()) {
      return sendError(res, 'note is required');
    }

    const existing = await findBloodBankById(req.params.id);
    if (!existing) {
      return sendError(res, 'Blood bank not found', 404);
    }

    const bloodBank = await requestBloodBankDocuments(req.params.id, note.trim());
    return sendSuccess(res, { message: 'Document request sent', data: bloodBank });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to request documents', 500);
  }
});

router.post(
  '/blood-banks/:bloodBankId/documents/:documentId/verify',
  adminRequired,
  async (req, res) => {
    try {
      const { bloodBankId, documentId } = req.params;
      const bloodBank = await findBloodBankById(bloodBankId);
      if (!bloodBank) {
        return sendError(res, 'Blood bank not found', 404);
      }

      const document = await verifyBloodBankDocument(bloodBankId, documentId);
      const updated = await findBloodBankById(bloodBankId);
      return sendSuccess(res, {
        message: 'Document verified',
        data: { document, bloodBank: updated },
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to verify document', status);
    }
  },
);

router.post(
  '/blood-banks/:bloodBankId/documents/:documentId/reject',
  adminRequired,
  async (req, res) => {
    try {
      const { bloodBankId, documentId } = req.params;
      const { rejectionReason } = req.body;
      if (!rejectionReason?.trim()) {
        return sendError(res, 'rejectionReason is required');
      }

      const bloodBank = await findBloodBankById(bloodBankId);
      if (!bloodBank) {
        return sendError(res, 'Blood bank not found', 404);
      }

      const document = await rejectBloodBankDocument(
        bloodBankId,
        documentId,
        rejectionReason.trim(),
      );
      const updated = await findBloodBankById(bloodBankId);
      return sendSuccess(res, {
        message: 'Document rejected',
        data: { document, bloodBank: updated },
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to reject document', status);
    }
  },
);

router.get('/blood-banks/:id/stats', adminRequired, async (req, res) => {
  try {
    const stats = await getBloodBankDashboardStats(req.params.id);
    const inventory = await listInventoryByBloodBank(req.params.id);
    return sendSuccess(res, { data: { ...stats, inventory } });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch stats', 500);
  }
});

router.get('/blood-orders', adminRequired, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(100, parseInt(req.query.pageSize || '20', 10));
    const status = req.query.status;

    const { orders, pagination } = await listAllOrders({ status, page, pageSize });
    return sendSuccess(res, { data: orders, pagination });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to list orders', 500);
  }
});

router.get('/emergency-blood-requests', adminRequired, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(100, parseInt(req.query.pageSize || '20', 10));
    const status = req.query.status;

    const { requests, pagination } = await listAllEmergencyRequests({
      status,
      page,
      pageSize,
    });
    return sendSuccess(res, { data: requests, pagination });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to list emergency requests', 500);
  }
});

// ——— Diagnostic lab applications (admin only) ———

router.get('/labs', adminRequired, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(100, parseInt(req.query.pageSize || '20', 10));
    const status = req.query.status;

    const { labs, pagination } = await listLabs({ status, page, pageSize });

    return sendSuccess(res, { data: labs, pagination });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to list labs', 500);
  }
});

router.get('/labs/:id', adminRequired, async (req, res) => {
  try {
    const lab = await findLabById(req.params.id);
    if (!lab) {
      return sendError(res, 'Lab not found', 404);
    }
    return sendSuccess(res, { data: lab });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch lab', 500);
  }
});

router.post('/labs/:id/approve', adminRequired, async (req, res) => {
  try {
    const { approvalNotes } = req.body;
    const existing = await findLabById(req.params.id);
    if (!existing) {
      return sendError(res, 'Lab not found', 404);
    }

    const lab = await approveLab(req.params.id, approvalNotes);

    return sendSuccess(res, {
      message: 'Lab approved successfully',
      data: lab,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to approve lab', status);
  }
});

router.post('/labs/:id/reject', adminRequired, async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    if (!rejectionReason?.trim()) {
      return sendError(res, 'rejectionReason is required');
    }

    const existing = await findLabById(req.params.id);
    if (!existing) {
      return sendError(res, 'Lab not found', 404);
    }

    const allowed = ['pending', 'under_review', 'verifier_approved'];
    if (!allowed.includes(existing.verificationStatus)) {
      return sendError(
        res,
        `Cannot reject lab with status "${existing.verificationStatus}"`,
        400,
      );
    }

    const lab = await rejectLab(req.params.id, rejectionReason.trim());

    return sendSuccess(res, {
      message: 'Lab rejected successfully',
      data: lab,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to reject lab', 500);
  }
});

router.post('/labs/:id/suspend', adminRequired, async (req, res) => {
  try {
    const { reason } = req.body;
    const existing = await findLabById(req.params.id);
    if (!existing) {
      return sendError(res, 'Lab not found', 404);
    }

    const lab = await suspendLab(req.params.id, reason?.trim());

    return sendSuccess(res, {
      message: 'Lab suspended successfully',
      data: lab,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to suspend lab', 500);
  }
});

router.post('/labs/:id/request-documents', adminRequired, async (req, res) => {
  try {
    const { note } = req.body;
    if (!note?.trim()) {
      return sendError(res, 'note is required');
    }

    const existing = await findLabById(req.params.id);
    if (!existing) {
      return sendError(res, 'Lab not found', 404);
    }

    const lab = await requestLabDocuments(req.params.id, note.trim());

    return sendSuccess(res, {
      message: 'Document request sent to lab',
      data: lab,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to request documents', 500);
  }
});

router.post(
  '/labs/:labId/documents/:documentId/verify',
  adminRequired,
  async (req, res) => {
    try {
      const { labId, documentId } = req.params;
      const lab = await findLabById(labId);
      if (!lab) {
        return sendError(res, 'Lab not found', 404);
      }

      const document = await verifyLabDocument(labId, documentId);
      const updated = await findLabById(labId);
      return sendSuccess(res, {
        message: 'Document verified',
        data: { document, lab: updated },
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to verify document', status);
    }
  },
);

router.post(
  '/labs/:labId/documents/:documentId/reject',
  adminRequired,
  async (req, res) => {
    try {
      const { labId, documentId } = req.params;
      const { rejectionReason } = req.body;
      if (!rejectionReason?.trim()) {
        return sendError(res, 'rejectionReason is required');
      }

      const lab = await findLabById(labId);
      if (!lab) {
        return sendError(res, 'Lab not found', 404);
      }

      const document = await rejectLabDocument(
        labId,
        documentId,
        rejectionReason.trim(),
      );
      const updated = await findLabById(labId);
      return sendSuccess(res, {
        message: 'Document rejected',
        data: { document, lab: updated },
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to reject document', status);
    }
  },
);

// ——— Scan center applications (admin only) ———

router.get('/scan-centers', adminRequired, async (req, res) => {
  try {
    const page = Math.max(1, parseInt(req.query.page || '1', 10));
    const pageSize = Math.min(100, parseInt(req.query.pageSize || '20', 10));
    const status = req.query.status;

    const { scanCenters, pagination } = await listScanCenters({
      status,
      page,
      pageSize,
    });

    return sendSuccess(res, { data: scanCenters, pagination });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to list scan centers', 500);
  }
});

router.get('/scan-centers/:id', adminRequired, async (req, res) => {
  try {
    const center = await findScanCenterById(req.params.id);
    if (!center) {
      return sendError(res, 'Scan center not found', 404);
    }
    return sendSuccess(res, { data: center });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to fetch scan center', 500);
  }
});

router.post('/scan-centers/:id/approve', adminRequired, async (req, res) => {
  try {
    const { approvalNotes } = req.body;
    const existing = await findScanCenterById(req.params.id);
    if (!existing) {
      return sendError(res, 'Scan center not found', 404);
    }

    const center = await approveScanCenter(req.params.id, approvalNotes);

    return sendSuccess(res, {
      message: 'Scan center approved successfully',
      data: center,
    });
  } catch (err) {
    console.error(err);
    const status = err.statusCode || 500;
    return sendError(res, err.message || 'Failed to approve scan center', status);
  }
});

router.post('/scan-centers/:id/reject', adminRequired, async (req, res) => {
  try {
    const { rejectionReason } = req.body;
    if (!rejectionReason?.trim()) {
      return sendError(res, 'rejectionReason is required');
    }

    const existing = await findScanCenterById(req.params.id);
    if (!existing) {
      return sendError(res, 'Scan center not found', 404);
    }

    const allowed = ['pending', 'under_review', 'verifier_approved'];
    if (!allowed.includes(existing.verificationStatus)) {
      return sendError(
        res,
        `Cannot reject scan center with status "${existing.verificationStatus}"`,
        400,
      );
    }

    const center = await rejectScanCenter(req.params.id, rejectionReason.trim());

    return sendSuccess(res, {
      message: 'Scan center rejected successfully',
      data: center,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to reject scan center', 500);
  }
});

router.post('/scan-centers/:id/suspend', adminRequired, async (req, res) => {
  try {
    const { reason } = req.body;
    const existing = await findScanCenterById(req.params.id);
    if (!existing) {
      return sendError(res, 'Scan center not found', 404);
    }

    const center = await suspendScanCenter(req.params.id, reason?.trim());

    return sendSuccess(res, {
      message: 'Scan center suspended successfully',
      data: center,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to suspend scan center', 500);
  }
});

router.post('/scan-centers/:id/request-documents', adminRequired, async (req, res) => {
  try {
    const { note } = req.body;
    if (!note?.trim()) {
      return sendError(res, 'note is required');
    }

    const existing = await findScanCenterById(req.params.id);
    if (!existing) {
      return sendError(res, 'Scan center not found', 404);
    }

    const center = await requestScanCenterDocuments(req.params.id, note.trim());

    return sendSuccess(res, {
      message: 'Document request sent to scan center',
      data: center,
    });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to request documents', 500);
  }
});

router.post(
  '/scan-centers/:scanCenterId/documents/:documentId/verify',
  adminRequired,
  async (req, res) => {
    try {
      const { scanCenterId, documentId } = req.params;
      const center = await findScanCenterById(scanCenterId);
      if (!center) {
        return sendError(res, 'Scan center not found', 404);
      }

      const document = await verifyScanCenterDocument(scanCenterId, documentId);
      const updated = await findScanCenterById(scanCenterId);
      return sendSuccess(res, {
        message: 'Document verified',
        data: { document, scanCenter: updated },
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to verify document', status);
    }
  },
);

router.post(
  '/scan-centers/:scanCenterId/documents/:documentId/reject',
  adminRequired,
  async (req, res) => {
    try {
      const { scanCenterId, documentId } = req.params;
      const { rejectionReason } = req.body;
      if (!rejectionReason?.trim()) {
        return sendError(res, 'rejectionReason is required');
      }

      const center = await findScanCenterById(scanCenterId);
      if (!center) {
        return sendError(res, 'Scan center not found', 404);
      }

      const document = await rejectScanCenterDocument(
        scanCenterId,
        documentId,
        rejectionReason.trim(),
      );
      const updated = await findScanCenterById(scanCenterId);
      return sendSuccess(res, {
        message: 'Document rejected',
        data: { document, scanCenter: updated },
      });
    } catch (err) {
      console.error(err);
      const status = err.statusCode || 500;
      return sendError(res, err.message || 'Failed to reject document', status);
    }
  },
);

module.exports = router;

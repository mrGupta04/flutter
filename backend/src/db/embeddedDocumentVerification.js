function assertEmbeddedDocumentsVerified(documents, label = 'document') {
  const list = Array.isArray(documents) ? documents : [];
  const withUrl = list.filter((d) => d?.url);
  if (withUrl.length === 0) {
    const err = new Error(`No ${label}s uploaded yet`);
    err.statusCode = 400;
    throw err;
  }

  const pending = withUrl.filter((d) => d.verificationStatus !== 'verified');
  if (pending.length > 0) {
    const names = pending
      .map((d) => d.label || d.type)
      .filter(Boolean)
      .join(', ');
    const err = new Error(
      `All documents must be verified before approval. Pending: ${names}`,
    );
    err.statusCode = 400;
    throw err;
  }
}

async function verifyEmbeddedDocument(Model, entityId, documentId) {
  const entity = await Model.findOne({ id: entityId });
  if (!entity) {
    const err = new Error('Provider not found');
    err.statusCode = 404;
    throw err;
  }

  const docs = [...(entity.documents || [])];
  const idx = docs.findIndex((d) => d.id === documentId);
  if (idx < 0) {
    const err = new Error('Document not found');
    err.statusCode = 404;
    throw err;
  }

  docs[idx] = {
    ...docs[idx],
    verificationStatus: 'verified',
    rejectionReason: null,
  };

  await Model.updateOne({ id: entityId }, { $set: { documents: docs } });
  return docs[idx];
}

async function rejectEmbeddedDocument(
  Model,
  entityId,
  documentId,
  rejectionReason,
) {
  const entity = await Model.findOne({ id: entityId });
  if (!entity) {
    const err = new Error('Provider not found');
    err.statusCode = 404;
    throw err;
  }

  const docs = [...(entity.documents || [])];
  const idx = docs.findIndex((d) => d.id === documentId);
  if (idx < 0) {
    const err = new Error('Document not found');
    err.statusCode = 404;
    throw err;
  }

  docs[idx] = {
    ...docs[idx],
    verificationStatus: 'rejected',
    rejectionReason: rejectionReason.trim(),
  };

  await Model.updateOne({ id: entityId }, { $set: { documents: docs } });
  return docs[idx];
}

module.exports = {
  assertEmbeddedDocumentsVerified,
  verifyEmbeddedDocument,
  rejectEmbeddedDocument,
};

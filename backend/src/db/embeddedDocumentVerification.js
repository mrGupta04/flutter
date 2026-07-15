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

function documentPlain(doc) {
  if (!doc) return null;
  return typeof doc.toObject === 'function' ? doc.toObject() : { ...doc };
}

async function findEmbeddedDocument(Model, entityId, documentId) {
  const entity = await Model.findOne({ id: entityId });
  if (!entity) {
    const err = new Error('Provider not found');
    err.statusCode = 404;
    throw err;
  }

  const doc = (entity.documents || []).find((d) => d.id === documentId);
  if (!doc) {
    const err = new Error('Document not found');
    err.statusCode = 404;
    throw err;
  }

  return { entity, doc };
}

async function verifyEmbeddedDocument(Model, entityId, documentId) {
  await findEmbeddedDocument(Model, entityId, documentId);

  // Use positional $set — spreading Mongoose subdocs drops schema fields.
  const result = await Model.updateOne(
    { id: entityId, 'documents.id': documentId },
    {
      $set: {
        'documents.$.verificationStatus': 'verified',
        'documents.$.rejectionReason': null,
      },
    },
  );

  if (result.matchedCount === 0) {
    const err = new Error('Document not found');
    err.statusCode = 404;
    throw err;
  }

  const { doc } = await findEmbeddedDocument(Model, entityId, documentId);
  return documentPlain(doc);
}

async function rejectEmbeddedDocument(
  Model,
  entityId,
  documentId,
  rejectionReason,
) {
  await findEmbeddedDocument(Model, entityId, documentId);

  const result = await Model.updateOne(
    { id: entityId, 'documents.id': documentId },
    {
      $set: {
        'documents.$.verificationStatus': 'rejected',
        'documents.$.rejectionReason': String(rejectionReason || '').trim(),
      },
    },
  );

  if (result.matchedCount === 0) {
    const err = new Error('Document not found');
    err.statusCode = 404;
    throw err;
  }

  const { doc } = await findEmbeddedDocument(Model, entityId, documentId);
  return documentPlain(doc);
}

module.exports = {
  assertEmbeddedDocumentsVerified,
  verifyEmbeddedDocument,
  rejectEmbeddedDocument,
};

const multer = require('multer');
const { saveUpload } = require('../services/gridfsUploads');

const upload = multer({
  storage: multer.memoryStorage(),
  limits: { fileSize: 10 * 1024 * 1024 },
});

function getPublicBaseUrl(req) {
  const configured = process.env.PUBLIC_BASE_URL;
  if (configured && String(configured).trim()) {
    return String(configured).trim().replace(/\/$/, '');
  }
  return `${req.protocol}://${req.get('host')}`;
}

async function filePublicUrl(req, file) {
  const filename = await saveUpload(file);
  return `${getPublicBaseUrl(req)}/uploads/${filename}`;
}

module.exports = { upload, filePublicUrl, getPublicBaseUrl };

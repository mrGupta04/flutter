const fs = require('fs');
const path = require('path');
const { v4: uuidv4 } = require('uuid');
const { GridFSBucket } = require('mongodb');
const { mongoose } = require('../db/connect');

const uploadsDir = path.join(__dirname, '../../uploads');
if (!fs.existsSync(uploadsDir)) {
  fs.mkdirSync(uploadsDir, { recursive: true });
}

function getBucket() {
  if (mongoose.connection.readyState !== 1 || !mongoose.connection.db) {
    return null;
  }
  return new GridFSBucket(mongoose.connection.db, { bucketName: 'uploads' });
}

function buildFilename(file) {
  const ext = path.extname(file?.originalname || '') || '';
  return `${uuidv4()}${ext}`;
}

async function saveUpload(file) {
  if (!file?.buffer?.length) {
    throw new Error('Upload file buffer is empty');
  }

  const filename = buildFilename(file);
  const bucket = getBucket();

  if (bucket) {
    await new Promise((resolve, reject) => {
      const stream = bucket.openUploadStream(filename, {
        contentType: file.mimetype || 'application/octet-stream',
      });
      stream.on('finish', resolve);
      stream.on('error', reject);
      stream.end(file.buffer);
    });
  }

  fs.writeFileSync(path.join(uploadsDir, filename), file.buffer);
  return filename;
}

function openDownloadStream(filename) {
  const bucket = getBucket();
  if (!bucket) return null;
  return bucket.openDownloadStreamByName(filename);
}

function diskFilePath(filename) {
  return path.join(uploadsDir, path.basename(filename));
}

function fileExistsOnDisk(filename) {
  return fs.existsSync(diskFilePath(filename));
}

module.exports = {
  uploadsDir,
  saveUpload,
  openDownloadStream,
  diskFilePath,
  fileExistsOnDisk,
};

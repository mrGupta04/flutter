const express = require('express');
const path = require('path');
const {
  openDownloadStream,
  diskFilePath,
  fileExistsOnDisk,
} = require('../services/gridfsUploads');

const router = express.Router();

router.get('/:filename', (req, res) => {
  const filename = path.basename(req.params.filename || '');
  if (!filename) {
    return res.status(404).send('Not found');
  }

  if (fileExistsOnDisk(filename)) {
    return res.sendFile(diskFilePath(filename));
  }

  const stream = openDownloadStream(filename);
  if (!stream) {
    return res.status(404).send('Not found');
  }

  stream.on('error', () => {
    if (!res.headersSent) {
      res.status(404).send('Not found');
    }
  });
  stream.pipe(res);
});

module.exports = router;

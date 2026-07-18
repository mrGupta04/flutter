const express = require('express');
const { sendSuccess, sendError } = require('../utils/response');
const { listActiveBanners } = require('../db/cmsRepositories');

const router = express.Router();

// GET /cms/banners?placement=home_hero — public
router.get('/banners', async (req, res) => {
  try {
    const placement = req.query.placement || 'home_hero';
    const banners = await listActiveBanners(placement);
    return sendSuccess(res, { data: banners });
  } catch (err) {
    console.error(err);
    return sendError(res, err.message || 'Failed to load banners', 500);
  }
});

module.exports = router;

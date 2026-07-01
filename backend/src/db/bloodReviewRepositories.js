const { v4: uuidv4 } = require('uuid');
const BloodReview = require('./models/BloodReview');
const BloodBank = require('./models/BloodBank');
const { toBloodReview } = require('./bloodBankModuleMappers');

async function listReviewsByBloodBank(bloodBankId, { page = 1, pageSize = 20 } = {}) {
  const filter = { bloodBankId };
  const totalCount = await BloodReview.countDocuments(filter);
  const totalPages = Math.max(1, Math.ceil(totalCount / pageSize));
  const skip = (page - 1) * pageSize;

  const docs = await BloodReview.find(filter)
    .sort({ createdAt: -1 })
    .skip(skip)
    .limit(pageSize);

  return {
    reviews: docs.map(toBloodReview),
    pagination: {
      currentPage: page,
      totalPages,
      pageSize,
      totalCount,
      hasNextPage: page < totalPages,
    },
  };
}

async function createBloodReview(data) {
  const review = await BloodReview.create({
    id: data.id || uuidv4(),
    bloodBankId: data.bloodBankId,
    patientId: data.patientId,
    patientName: data.patientName,
    rating: data.rating,
    comment: data.comment,
    orderId: data.orderId,
  });

  const stats = await BloodReview.aggregate([
    { $match: { bloodBankId: data.bloodBankId } },
    {
      $group: {
        _id: '$bloodBankId',
        avgRating: { $avg: '$rating' },
        count: { $sum: 1 },
      },
    },
  ]);

  if (stats.length) {
    await BloodBank.updateOne(
      { id: data.bloodBankId },
      {
        $set: {
          averageRating: Math.round(stats[0].avgRating * 10) / 10,
          reviewCount: stats[0].count,
        },
      },
    );
  }

  return toBloodReview(review);
}

module.exports = {
  listReviewsByBloodBank,
  createBloodReview,
};

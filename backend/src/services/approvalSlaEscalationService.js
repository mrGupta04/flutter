const {
  processSlaEscalationsAndReminders,
} = require('../db/approvalWorkflowRepositories');

const POLL_MS = Number(process.env.APPROVAL_SLA_POLL_MS || 60_000);

let timer = null;

async function tick() {
  try {
    const result = await processSlaEscalationsAndReminders();
    if (result.escalated > 0 || result.reminded > 0) {
      console.log(
        `[ApprovalSLA] escalated=${result.escalated} reminded=${result.reminded}`,
      );
    }
  } catch (err) {
    console.error('[ApprovalSLA] tick failed:', err.message);
  }
}

function startApprovalSlaEscalationScheduler() {
  if (timer) return;
  console.log(`[ApprovalSLA] scheduler started (poll ${POLL_MS}ms)`);
  timer = setInterval(() => {
    void tick();
  }, POLL_MS);
  void tick();
}

module.exports = {
  startApprovalSlaEscalationScheduler,
  processSlaEscalationsAndReminders,
};

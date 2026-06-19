function sendSuccess(
  res,
  { data = null, message = null, statusCode = 200, token = null } = {},
) {
  const body = {
    success: true,
    message,
    data,
    statusCode,
  };
  if (token != null && token !== '') {
    body.token = token;
  }
  return res.status(statusCode).json(body);
}

function sendError(res, message, statusCode = 400) {
  return res.status(statusCode).json({
    success: false,
    error: message,
    statusCode,
  });
}

module.exports = { sendSuccess, sendError };

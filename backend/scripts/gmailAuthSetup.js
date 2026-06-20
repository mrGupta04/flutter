/**
 * One-time helper to obtain a Gmail API refresh token.
 *
 * Prerequisites:
 * 1. Google Cloud project with Gmail API enabled
 * 2. OAuth 2.0 Desktop client (Client ID + Client Secret)
 * 3. Add http://localhost:3333/oauth2callback as an authorized redirect URI
 *
 * Usage:
 *   GMAIL_CLIENT_ID=... GMAIL_CLIENT_SECRET=... node scripts/gmailAuthSetup.js
 */
const http = require('http');
const { URL } = require('url');

const CLIENT_ID = process.env.GMAIL_CLIENT_ID || '';
const CLIENT_SECRET = process.env.GMAIL_CLIENT_SECRET || '';
const REDIRECT_URI = 'http://localhost:3333/oauth2callback';
const PORT = 3333;
const SCOPES = ['https://www.googleapis.com/auth/gmail.send'];

if (!CLIENT_ID || !CLIENT_SECRET) {
  console.error('Set GMAIL_CLIENT_ID and GMAIL_CLIENT_SECRET before running this script.');
  process.exit(1);
}

const authUrl = new URL('https://accounts.google.com/o/oauth2/v2/auth');
authUrl.searchParams.set('client_id', CLIENT_ID);
authUrl.searchParams.set('redirect_uri', REDIRECT_URI);
authUrl.searchParams.set('response_type', 'code');
authUrl.searchParams.set('scope', SCOPES.join(' '));
authUrl.searchParams.set('access_type', 'offline');
authUrl.searchParams.set('prompt', 'consent');

const server = http.createServer(async (req, res) => {
  const requestUrl = new URL(req.url, `http://localhost:${PORT}`);

  if (requestUrl.pathname !== '/oauth2callback') {
    res.writeHead(404);
    res.end('Not found');
    return;
  }

  const code = requestUrl.searchParams.get('code');
  const error = requestUrl.searchParams.get('error');

  if (error) {
    res.writeHead(400);
    res.end(`OAuth error: ${error}`);
    server.close();
    process.exit(1);
    return;
  }

  if (!code) {
    res.writeHead(400);
    res.end('Missing authorization code');
    return;
  }

  try {
    const tokenResponse = await fetch('https://oauth2.googleapis.com/token', {
      method: 'POST',
      headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
      body: new URLSearchParams({
        code,
        client_id: CLIENT_ID,
        client_secret: CLIENT_SECRET,
        redirect_uri: REDIRECT_URI,
        grant_type: 'authorization_code',
      }),
    });

    const tokens = await tokenResponse.json();
    if (!tokenResponse.ok) {
      throw new Error(tokens.error_description || tokens.error || 'Token exchange failed');
    }

    res.writeHead(200, { 'Content-Type': 'text/html; charset=utf-8' });
    res.end('<h1>Gmail authorization successful</h1><p>You can close this tab.</p>');

    console.log('\nGmail API tokens received.\n');
    console.log('Add these to Render / .env:\n');
    console.log(`EMAIL_PROVIDER=gmail-api`);
    console.log(`GMAIL_CLIENT_ID=${CLIENT_ID}`);
    console.log(`GMAIL_CLIENT_SECRET=${CLIENT_SECRET}`);
    console.log(`GMAIL_REFRESH_TOKEN=${tokens.refresh_token || '(missing — re-run with prompt=consent)'}`);
    console.log(`GMAIL_USER=your@gmail.com`);
    console.log('\nIf refresh_token is missing, revoke app access at https://myaccount.google.com/permissions and run again.\n');
  } catch (err) {
    res.writeHead(500);
    res.end(`Failed: ${err.message}`);
    console.error(err.message);
  } finally {
    server.close();
    process.exit(0);
  }
});

server.listen(PORT, () => {
  console.log('Gmail OAuth setup\n');
  console.log('1. Open this URL in your browser and sign in with your Gmail account:\n');
  console.log(authUrl.toString());
  console.log(`\n2. Waiting for callback on ${REDIRECT_URI} ...\n`);
});

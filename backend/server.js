import express from 'express';

const app = express();
const port = 3000;
const keycloakInternalUrl = process.env.KEYCLOAK_INTERNAL_URL || 'http://keycloak:8080';
const keycloakRealm = process.env.KEYCLOAK_REALM || 'poc';
const keycloakAdminUsername = process.env.KEYCLOAK_ADMIN_USERNAME || 'admin';
const keycloakAdminPassword = process.env.KEYCLOAK_ADMIN_PASSWORD || 'admin';

function decodeJwtWithoutVerification(token) {
  if (!token) return null;
  const parts = token.split('.');
  if (parts.length < 2) return null;
  try {
    const json = Buffer.from(parts[1], 'base64url').toString('utf8');
    return JSON.parse(json);
  } catch {
    return null;
  }
}

function bearerClaims(req) {
  const authorization = req.get('authorization') || '';
  const token = authorization.startsWith('Bearer ')
    ? authorization.slice('Bearer '.length)
    : null;
  return { token, claims: decodeJwtWithoutVerification(token) };
}

async function getAdminToken() {
  const body = new URLSearchParams({
    client_id: 'admin-cli',
    username: keycloakAdminUsername,
    password: keycloakAdminPassword,
    grant_type: 'password'
  });
  const response = await fetch(`${keycloakInternalUrl}/realms/master/protocol/openid-connect/token`, {
    method: 'POST',
    headers: { 'content-type': 'application/x-www-form-urlencoded' },
    body
  });
  if (!response.ok) throw new Error(`Keycloak admin token failed: ${response.status}`);
  return (await response.json()).access_token;
}

async function requireEmailVerificationForUser(username) {
  const adminToken = await getAdminToken();
  const headers = { authorization: `Bearer ${adminToken}` };
  const usersResponse = await fetch(
    `${keycloakInternalUrl}/admin/realms/${encodeURIComponent(keycloakRealm)}/users?username=${encodeURIComponent(username)}&exact=true`,
    { headers }
  );
  if (!usersResponse.ok) throw new Error(`Keycloak user lookup failed: ${usersResponse.status}`);
  const users = await usersResponse.json();
  if (users.length !== 1) throw new Error(`Expected exactly one Keycloak user for ${username}`);

  const user = users[0];
  if (user.email) throw new Error('This PoC action is only for users without an email');

  const actions = new Set(user.requiredActions || []);
  actions.add('UPDATE_PROFILE');
  actions.add('VERIFY_EMAIL');

  const updateResponse = await fetch(
    `${keycloakInternalUrl}/admin/realms/${encodeURIComponent(keycloakRealm)}/users/${encodeURIComponent(user.id)}`,
    {
      method: 'PUT',
      headers: { ...headers, 'content-type': 'application/json' },
      body: JSON.stringify({ ...user, emailVerified: false, requiredActions: [...actions] })
    }
  );
  if (!updateResponse.ok) throw new Error(`Keycloak user update failed: ${updateResponse.status}`);

  const logoutResponse = await fetch(
    `${keycloakInternalUrl}/admin/realms/${encodeURIComponent(keycloakRealm)}/users/${encodeURIComponent(user.id)}/logout`,
    { method: 'POST', headers }
  );
  if (!logoutResponse.ok) throw new Error(`Keycloak user logout failed: ${logoutResponse.status}`);

  return { username, requiredActions: [...actions] };
}

app.get(['/me', '/api/me'], (req, res) => {
  const { token, claims } = bearerClaims(req);
  const loginProvider = claims?.login_provider ?? 'local';
  const mfaMethod = claims?.mfa_method ?? null;

  res.json({
    authenticatedByProxy: true,
    tokenPresent: Boolean(token),
    tokenValidationPerformedByApp: false,
    email: claims?.email ?? null,
    emailVerified: claims?.email_verified ?? null,
    emailVerifiedAt: claims?.email_verified_at ?? null,
    externalIdpLinked: claims?.external_idp_linked ?? false,
    externalIdpLinkedAt: claims?.external_idp_linked_at ?? null,
    loginProvider,
    mfaMethod,
    preferredUsername: claims?.preferred_username ?? null,
    subject: claims?.sub ?? null,
    claims,
    note: 'PoC only: backend decodes JWT payload without validating signature, issuer, audience, expiry or nonce.'
  });
});

app.post('/api/poc/require-email-verification', async (req, res) => {
  const { claims } = bearerClaims(req);
  const username = claims?.preferred_username;
  if (!username) return res.status(400).json({ error: 'preferred_username claim is required' });
  if (claims?.email) return res.status(409).json({ error: 'This PoC action is only available when the current user has no email' });

  try {
    const result = await requireEmailVerificationForUser(username);
    res.json({
      ok: true,
      ...result,
      next: 'Sign out from oauth2-proxy, then sign in again to run the Keycloak required actions.'
    });
  } catch (error) {
    console.error(error);
    res.status(502).json({ error: 'Could not configure Keycloak required actions' });
  }
});

app.get(['/health', '/api/health'], (_req, res) => res.json({ ok: true }));

app.listen(port, '0.0.0.0', () => {
  console.log(`backend listening on ${port}`);
});

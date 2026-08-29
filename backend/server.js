import express from 'express';

const app = express();
const port = 3000;

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

app.get('/me', (req, res) => {
  const authorization = req.get('authorization') || '';
  const token = authorization.startsWith('Bearer ')
    ? authorization.slice('Bearer '.length)
    : null;

  const claims = decodeJwtWithoutVerification(token);
  const loginProvider = claims?.login_provider ?? 'local';
  const mfaMethod = claims?.mfa_method ?? null;

  res.json({
    authenticatedByProxy: true,
    tokenPresent: Boolean(token),
    tokenValidationPerformedByApp: false,
    email: claims?.email ?? req.get('x-forwarded-email') ?? null,
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

app.get('/health', (_req, res) => res.json({ ok: true }));

app.listen(port, '0.0.0.0', () => {
  console.log(`backend listening on ${port}`);
});

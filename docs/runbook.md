# Local Runbook

## Start

```powershell
docker compose up --build -d
```

Check containers:

```powershell
docker compose ps
```

Open:
- App: `http://localhost:8000`
- Keycloak Admin: `http://localhost:18080/admin`
- Mailpit: `http://localhost:18025`

Credentials:
- Keycloak admin: `admin` / `admin`
- Demo user: `demo` / `demo1234`
- Demo email: `demo@example.com`

## Phase 1 test

```powershell
./scripts/phase1.ps1
```

Expected:
1. Open the app.
2. Login as demo.
3. Login succeeds although email is initially unverified.
4. UI shows `NOT VERIFIED`.
5. Click `Verify email with Keycloak`.
6. Open Mailpit and follow the verification email.
7. Return to app / refresh session and confirm `email_verified=true`.

## Reset demo user to unverified

For repeated Phase 1/2 tests, use Keycloak Admin Console:
1. Realm `poc` -> Users -> `demo`.
2. Set Email verified = Off.
3. Save.
4. Sign out / run the phase script again to invalidate sessions.

## Phase 2 test

```powershell
./scripts/phase2.ps1
```

Expected with unverified demo user:
1. Open app.
2. Login with username/password.
3. Keycloak requires both Email OTP and email verification before login can complete.
4. Depending on Keycloak's authentication/required-action lifecycle, the OTP challenge may appear before the Verify Email required action.
5. OTP and verification emails appear in Mailpit.
6. Complete both challenges.
7. Only then can oauth2-proxy establish the authenticated application session.
8. UI shows `VERIFIED`.

Expected with already verified demo user:
1. Login with username/password.
2. No Verify Email action is required.
3. Email OTP is required.
4. Successful OTP completes login.

## Switch back to Phase 1

```powershell
./scripts/phase1.ps1
```

Next login should no longer require Email OTP.

## Logs

```powershell
docker compose logs -f keycloak
docker compose logs -f oauth2-proxy
docker compose logs -f kong
docker compose logs -f backend
```

## Stop

```powershell
docker compose down
```

Delete database state and re-import realm:

```powershell
docker compose down -v
docker compose up --build -d
```

## Troubleshooting

### Browser is redirected to `keycloak:8080`
Browser-facing auth endpoints must use `localhost:18080`. Container-to-container token/JWKS endpoints use `keycloak:8080`.

### oauth2-proxy rejects unverified email in Phase 1
Confirm `insecureAllowUnverifiedEmail: true` in `oauth2-proxy/alpha.yaml`.

### Email does not arrive
Check Mailpit and Keycloak SMTP configuration. Keycloak must connect to host `mailpit`, port `1025`.

### Email OTP execution is missing
Confirm the provider JAR loaded successfully and the authenticator provider id is `email-authenticator` for the pinned extension version.

### Phase change appears to have no effect
Existing Keycloak or oauth2-proxy sessions may still be active. The phase scripts perform Keycloak realm logout, but browser oauth2-proxy cookies may also need Sign out if a stale session remains.

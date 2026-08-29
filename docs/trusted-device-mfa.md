# MFA Trust — Device or Account Mode

## Goal

Phase 2 supports a configurable MFA trust period. The default period is 30 days and trust is created automatically after a successful Email OTP; there is no checkbox on the OTP page.

Two modes are supported:

- `trustedDeviceEnabled=true`: trust is per browser/device. Each new browser must complete Email OTP once, then that browser can skip MFA until its trust expires.
- `trustedDeviceEnabled=false`: trust is account-wide. After Email OTP succeeds on any device, all devices for that user can skip MFA until the account trust expires.

The duration is configured independently with `trustDays` (default `30`).

## Flow

```text
Phase 2 authentication
        ↓
Email verified / required actions
        ↓
MFA Trust Condition
        ↓
trustedDeviceEnabled?
   ├─ true
   │    ↓
   │  browser/device token valid?
   │    ├─ yes → skip MFA → Application
   │    └─ no  → MFA Selector → Email OTP
   │                            ↓
   │                      trust this browser
   │                      for trustDays
   │                            ↓
   │                       Application
   │
   └─ false
        ↓
      account trust valid?
        ├─ yes → skip MFA on any device → Application
        └─ no  → MFA Selector → Email OTP
                                ↓
                          trust user account
                          for trustDays
                                ↓
                           Application
```

The same policy is used after an External IdP only when that IdP has `require_mfa_after_broker=true`.

## Device mode storage

When `trustedDeviceEnabled=true`, the browser receives an HttpOnly cookie named `POC_MFA_TRUST`. Its value is a cryptographically random opaque 32-byte token. The raw token is never persisted in Keycloak.

The user has a multi-valued server-side attribute:

```text
poc_mfa_trusted_device
```

Each value contains:

```text
SHA256(token)|expires_at_epoch_seconds|created_at_epoch_seconds
```

Expired records are pruned when trust is evaluated. This PoC retains at most 10 active trusted-browser records per user.

Cookie properties are `HttpOnly`, `SameSite=Lax`, realm-scoped path `/realms/<realm>`, Max-Age based on `trustDays`, and `Secure` automatically when Keycloak is accessed through HTTPS. Local HTTP intentionally omits `Secure` for testing.

## Account mode storage

When `trustedDeviceEnabled=false`, no browser token is required. A server-side user attribute stores the account trust expiry:

```text
poc_mfa_trusted_until=<expires_at_epoch_seconds>
```

A successful Email OTP refreshes this timestamp to `now + trustDays`. Any device authenticating as the same user can skip the Keycloak MFA subflow while this timestamp is still valid.

This mode therefore deliberately trades per-device control for account-wide convenience.

## Authentication flow providers

Custom providers:

```text
poc-trusted-device-condition
poc-trusted-device-recorder
```

Both providers are configurable with the trust mode. The recorder also receives the trust duration.

Local Phase 2 flow:

```text
poc-phase2-browser-v3
  forms
    ...copied browser executions...
    poc-phase2-trusted-mfa                 CONDITIONAL
      PoC Trusted Device Condition         CONDITIONAL
      PoC MFA Method Selector              REQUIRED
      Email OTP                            REQUIRED
      PoC Trusted Device Recorder          REQUIRED
```

Post-broker flow:

```text
poc-external-idp-post-login-phase2-v2
  poc-post-broker-trusted-mfa              CONDITIONAL
    PoC Trusted Device Condition            CONDITIONAL
    PoC MFA Method Selector                 REQUIRED
    Email OTP                               REQUIRED
    PoC Trusted Device Recorder             REQUIRED
```

Configuration example:

```powershell
# Per-device/browser trust for 30 days
.\scripts\configure-auth-flows.ps1 -TrustedDeviceEnabled $true -TrustDays 30

# Account-wide trust across all devices for 30 days
.\scripts\configure-auth-flows.ps1 -TrustedDeviceEnabled $false -TrustDays 30
```

## Session claim

After actual Email OTP:

```text
mfa_method=email
```

When device-mode trust skips OTP:

```text
mfa_method=trusted_device
```

When account-mode trust skips OTP:

```text
mfa_method=trusted_account
```

## Revocation

Admin/testing revocation uses:

```powershell
.\scripts\clear-mfa-trust.ps1 -Username demo
```

The revocation implementation must clear both `poc_mfa_trusted_device` and `poc_mfa_trusted_until`. Password and email changes also revoke both trust modes.

Normal logout does not revoke MFA trust; MFA trust lifetime is independent from the SSO session lifetime.

## Security boundary

Device mode is safer when different browsers/devices should be independently challenged or revoked. Account mode intentionally means that one successful OTP grants the configured trust window to every device that can subsequently authenticate to the same account.

This PoC stores trust state as Keycloak user attributes. A production implementation needing device-management UI, richer audit history, selective device revocation, or large device counts should use dedicated persistent storage.

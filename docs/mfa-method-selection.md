# MFA method selection

Phase 2 now has a dedicated Keycloak MFA method-selection step.

Current enabled method:

- Email OTP

Visible placeholders are also shown for Authenticator App and Passkey/WebAuthn, but they are disabled in this PoC. This intentionally separates method selection from the Email OTP challenge so additional MFA authenticators can be added later without redesigning the login UX.

The custom authenticator is `poc-mfa-method-selector`. It stores the selected method in the authentication/user-session note `mfa_method`. The `poc-app` client maps that note to the `mfa_method` token claim.

Current Phase 2 local flow:

```text
Username + Password
  -> Trusted Browser valid?
      -> yes: skip MFA
      -> no: Choose verification method
             -> Email OTP
             -> trust browser for 30 days
  -> success
```

Current Phase 2 external IdP flow when `require_mfa_after_broker=true`:

```text
External IdP
  -> broker account resolution/linking
  -> Trusted Browser valid?
      -> yes: skip Keycloak MFA
      -> no: Choose verification method
             -> Email OTP
             -> trust browser for 30 days
  -> success
```

The trusted-browser decision occurs before the MFA selector, so a trusted browser does not see the selector or OTP page. Trust is created automatically after successful Email OTP; there is no checkbox.

The built-in Keycloak `browser` flow is not modified.

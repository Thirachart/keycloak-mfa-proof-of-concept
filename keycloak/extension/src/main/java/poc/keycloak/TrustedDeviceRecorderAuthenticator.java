package poc.keycloak;

import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.Authenticator;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;

public final class TrustedDeviceRecorderAuthenticator implements Authenticator {
    @Override
    public void authenticate(AuthenticationFlowContext context) {
        int trustDays = TrustedDeviceSupport.DEFAULT_TRUST_DAYS;
        boolean trustedDeviceEnabled = true;
        if (context.getAuthenticatorConfig() != null) {
            String configuredDays = context.getAuthenticatorConfig().getConfig().get("trustDays");
            if (configuredDays != null) {
                try {
                    trustDays = Integer.parseInt(configuredDays);
                } catch (NumberFormatException ignored) {
                    trustDays = TrustedDeviceSupport.DEFAULT_TRUST_DAYS;
                }
            }
            String configuredMode = context.getAuthenticatorConfig().getConfig().get("trustedDeviceEnabled");
            if (configuredMode != null) {
                trustedDeviceEnabled = Boolean.parseBoolean(configuredMode);
            }
        }

        String method = context.getAuthenticationSession().getAuthNote(MfaMethodSelectorAuthenticator.METHOD_NOTE);
        if (MfaMethodSelectorAuthenticator.EMAIL_METHOD.equals(method)) {
            TrustedDeviceSupport.issueTrust(context, trustDays, trustedDeviceEnabled);
        }
        context.success();
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        context.success();
    }

    @Override
    public boolean requiresUser() {
        return true;
    }

    @Override
    public boolean configuredFor(KeycloakSession session, RealmModel realm, UserModel user) {
        return true;
    }

    @Override
    public void setRequiredActions(KeycloakSession session, RealmModel realm, UserModel user) {
        // No enrollment is needed.
    }

    @Override
    public void close() {
    }
}

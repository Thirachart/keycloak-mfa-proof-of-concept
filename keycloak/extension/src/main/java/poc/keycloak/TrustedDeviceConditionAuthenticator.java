package poc.keycloak;

import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.authenticators.conditional.ConditionalAuthenticator;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;

public final class TrustedDeviceConditionAuthenticator implements ConditionalAuthenticator {
    @Override
    public boolean matchCondition(AuthenticationFlowContext context) {
        boolean trustedDeviceEnabled = true;
        if (context.getAuthenticatorConfig() != null) {
            String configured = context.getAuthenticatorConfig().getConfig().get("trustedDeviceEnabled");
            if (configured != null) {
                trustedDeviceEnabled = Boolean.parseBoolean(configured);
            }
        }

        boolean trusted = TrustedDeviceSupport.hasValidTrust(context, trustedDeviceEnabled);
        if (trusted) {
            String method = TrustedDeviceSupport.trustedMethod(trustedDeviceEnabled);
            context.getAuthenticationSession().setAuthNote(MfaMethodSelectorAuthenticator.METHOD_NOTE, method);
            context.getAuthenticationSession().setUserSessionNote(MfaMethodSelectorAuthenticator.METHOD_NOTE, method);
        }
        return !trusted;
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        // Conditional authenticators do not handle form actions.
    }

    @Override
    public boolean requiresUser() {
        return true;
    }

    @Override
    public void setRequiredActions(KeycloakSession session, RealmModel realm, UserModel user) {
        // No required action.
    }

    @Override
    public void close() {
    }
}

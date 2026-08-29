package poc.keycloak;

import jakarta.ws.rs.core.MultivaluedMap;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.authentication.Authenticator;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;

public final class MfaMethodSelectorAuthenticator implements Authenticator {
    public static final String METHOD_NOTE = "mfa_method";
    public static final String EMAIL_METHOD = "email";

    @Override
    public void authenticate(AuthenticationFlowContext context) {
        context.challenge(context.form().createForm("mfa-method-selector.ftl"));
    }

    @Override
    public void action(AuthenticationFlowContext context) {
        MultivaluedMap<String, String> formData = context.getHttpRequest().getDecodedFormParameters();
        String method = formData.getFirst("mfa_method");
        if (!EMAIL_METHOD.equals(method)) {
            context.challenge(context.form()
                    .setError("Please select Email OTP.")
                    .createForm("mfa-method-selector.ftl"));
            return;
        }

        context.getAuthenticationSession().setAuthNote(METHOD_NOTE, EMAIL_METHOD);
        context.getAuthenticationSession().setUserSessionNote(METHOD_NOTE, EMAIL_METHOD);
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
        // No enrollment is needed for Email OTP.
    }

    @Override
    public void close() {
    }
}

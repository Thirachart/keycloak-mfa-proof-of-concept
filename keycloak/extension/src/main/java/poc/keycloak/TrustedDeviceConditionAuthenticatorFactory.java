package poc.keycloak;

import java.util.List;
import org.keycloak.Config;
import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.AuthenticatorFactory;
import org.keycloak.models.AuthenticationExecutionModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.provider.ProviderConfigProperty;

public final class TrustedDeviceConditionAuthenticatorFactory implements AuthenticatorFactory {
    public static final String ID = "poc-trusted-device-condition";
    private static final Authenticator SINGLETON = new TrustedDeviceConditionAuthenticator();
    private static final AuthenticationExecutionModel.Requirement[] REQUIREMENTS = {
            AuthenticationExecutionModel.Requirement.CONDITIONAL,
            AuthenticationExecutionModel.Requirement.DISABLED
    };

    @Override
    public String getId() {
        return ID;
    }

    @Override
    public String getDisplayType() {
        return "PoC Trusted Device Condition";
    }

    @Override
    public String getReferenceCategory() {
        return "trusted-device-condition";
    }

    @Override
    public boolean isConfigurable() {
        return true;
    }

    @Override
    public AuthenticationExecutionModel.Requirement[] getRequirementChoices() {
        return REQUIREMENTS;
    }

    @Override
    public boolean isUserSetupAllowed() {
        return false;
    }

    @Override
    public String getHelpText() {
        return "Runs the MFA subflow only when the configured MFA trust is not valid. Trusted-device mode checks this browser; account mode trusts all devices for the user.";
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        ProviderConfigProperty trustedDeviceEnabled = new ProviderConfigProperty();
        trustedDeviceEnabled.setName("trustedDeviceEnabled");
        trustedDeviceEnabled.setLabel("Trusted device enabled");
        trustedDeviceEnabled.setType(ProviderConfigProperty.BOOLEAN_TYPE);
        trustedDeviceEnabled.setDefaultValue(Boolean.TRUE.toString());
        trustedDeviceEnabled.setHelpText("When true, MFA trust is per browser/device. When false, the user account is trusted across all devices for the configured trust period.");
        return List.of(trustedDeviceEnabled);
    }

    @Override
    public Authenticator create(KeycloakSession session) {
        return SINGLETON;
    }

    @Override
    public void init(Config.Scope config) {
    }

    @Override
    public void postInit(KeycloakSessionFactory factory) {
    }

    @Override
    public void close() {
    }
}

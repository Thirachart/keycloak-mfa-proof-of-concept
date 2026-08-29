package poc.keycloak;

import java.util.List;
import org.keycloak.Config;
import org.keycloak.authentication.Authenticator;
import org.keycloak.authentication.AuthenticatorFactory;
import org.keycloak.models.AuthenticationExecutionModel;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.KeycloakSessionFactory;
import org.keycloak.provider.ProviderConfigProperty;

public final class TrustedDeviceRecorderAuthenticatorFactory implements AuthenticatorFactory {
    public static final String ID = "poc-trusted-device-recorder";
    private static final Authenticator SINGLETON = new TrustedDeviceRecorderAuthenticator();
    private static final AuthenticationExecutionModel.Requirement[] REQUIREMENTS = {
            AuthenticationExecutionModel.Requirement.REQUIRED,
            AuthenticationExecutionModel.Requirement.DISABLED
    };

    @Override
    public String getId() {
        return ID;
    }

    @Override
    public String getDisplayType() {
        return "PoC Trusted Device Recorder";
    }

    @Override
    public String getReferenceCategory() {
        return "trusted-device-recorder";
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
        return "Creates a server-side trusted-device record and browser cookie after successful MFA.";
    }

    @Override
    public List<ProviderConfigProperty> getConfigProperties() {
        ProviderConfigProperty trustDays = new ProviderConfigProperty();
        trustDays.setName("trustDays");
        trustDays.setLabel("Trust period (days)");
        trustDays.setType(ProviderConfigProperty.STRING_TYPE);
        trustDays.setDefaultValue(Integer.toString(TrustedDeviceSupport.DEFAULT_TRUST_DAYS));
        trustDays.setHelpText("Number of days MFA can be skipped after a successful Email OTP.");

        ProviderConfigProperty trustedDeviceEnabled = new ProviderConfigProperty();
        trustedDeviceEnabled.setName("trustedDeviceEnabled");
        trustedDeviceEnabled.setLabel("Trusted device enabled");
        trustedDeviceEnabled.setType(ProviderConfigProperty.BOOLEAN_TYPE);
        trustedDeviceEnabled.setDefaultValue(Boolean.TRUE.toString());
        trustedDeviceEnabled.setHelpText("When true, create a per-browser trusted-device record. When false, create an account-level trust valid for all devices.");
        return List.of(trustDays, trustedDeviceEnabled);
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

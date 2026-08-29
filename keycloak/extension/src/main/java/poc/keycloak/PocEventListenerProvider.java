package poc.keycloak;

import java.time.Instant;

import org.keycloak.events.Event;
import org.keycloak.events.EventListenerProvider;
import org.keycloak.events.EventType;
import org.keycloak.events.admin.AdminEvent;
import org.keycloak.models.KeycloakSession;
import org.keycloak.models.RealmModel;
import org.keycloak.models.UserModel;

final class PocEventListenerProvider implements EventListenerProvider {
    static final String EMAIL_VERIFIED_AT = "email_verified_at";
    static final String EXTERNAL_IDP_LINKED_AT = "external_idp_linked_at";
    static final String EXTERNAL_IDP_ALIAS = "lab-idp";

    private final KeycloakSession session;

    PocEventListenerProvider(KeycloakSession session) {
        this.session = session;
    }

    @Override
    public void onEvent(Event event) {
        if (event == null || event.getRealmId() == null || event.getUserId() == null) {
            return;
        }

        RealmModel realm = session.realms().getRealm(event.getRealmId());
        if (realm == null) {
            return;
        }

        UserModel user = session.users().getUserById(realm, event.getUserId());
        if (user == null) {
            return;
        }

        EventType type = event.getType();
        if (type == EventType.VERIFY_EMAIL && user.isEmailVerified()) {
            setTimestampIfMissing(user, EMAIL_VERIFIED_AT);
            return;
        }

        if (type == EventType.UPDATE_EMAIL) {
            user.removeAttribute(EMAIL_VERIFIED_AT);
            TrustedDeviceSupport.clearAll(user);
            return;
        }

        if (type == EventType.UPDATE_PASSWORD) {
            TrustedDeviceSupport.clearAll(user);
            return;
        }

        if (type == EventType.FEDERATED_IDENTITY_LINK
                || type == EventType.IDENTITY_PROVIDER_LINK_ACCOUNT
                || type == EventType.IDENTITY_PROVIDER_FIRST_LOGIN
                || type == EventType.FEDERATED_IDENTITY_OVERRIDE_LINK) {
            if (hasExternalIdpLink(realm, user)) {
                setTimestampIfMissing(user, EXTERNAL_IDP_LINKED_AT);
            }
            return;
        }

        if (type == EventType.REMOVE_FEDERATED_IDENTITY && !hasExternalIdpLink(realm, user)) {
            user.removeAttribute(EXTERNAL_IDP_LINKED_AT);
        }
    }

    private boolean hasExternalIdpLink(RealmModel realm, UserModel user) {
        return session.users().getFederatedIdentity(realm, user, EXTERNAL_IDP_ALIAS) != null;
    }

    private static void setTimestampIfMissing(UserModel user, String attributeName) {
        if (user.getFirstAttribute(attributeName) == null) {
            user.setSingleAttribute(attributeName, Instant.now().toString());
        }
    }

    @Override
    public void onEvent(AdminEvent event, boolean includeRepresentation) {
    }

    @Override
    public void close() {
    }
}

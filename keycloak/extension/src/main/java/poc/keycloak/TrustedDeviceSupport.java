package poc.keycloak;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.security.NoSuchAlgorithmException;
import java.security.SecureRandom;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.Comparator;
import java.util.List;
import org.keycloak.authentication.AuthenticationFlowContext;
import org.keycloak.models.UserModel;

final class TrustedDeviceSupport {
    static final String COOKIE_NAME = "POC_MFA_TRUST";
    static final String USER_ATTRIBUTE = "poc_mfa_trusted_device";
    static final String ACCOUNT_TRUST_UNTIL_ATTRIBUTE = "poc_mfa_trusted_until";
    static final String TRUSTED_METHOD = "trusted_device";
    static final String TRUSTED_ACCOUNT_METHOD = "trusted_account";
    static final int DEFAULT_TRUST_DAYS = 30;
    private static final int MAX_TRUSTED_DEVICES = 10;
    private static final SecureRandom RANDOM = new SecureRandom();

    private TrustedDeviceSupport() {
    }

    static boolean hasValidTrust(AuthenticationFlowContext context, boolean trustedDeviceEnabled) {
        if (context.getUser() == null) {
            return false;
        }
        return trustedDeviceEnabled ? hasValidDeviceTrust(context) : hasValidAccountTrust(context.getUser());
    }

    static String trustedMethod(boolean trustedDeviceEnabled) {
        return trustedDeviceEnabled ? TRUSTED_METHOD : TRUSTED_ACCOUNT_METHOD;
    }

    static void issueTrust(AuthenticationFlowContext context, int trustDays, boolean trustedDeviceEnabled) {
        if (context.getUser() == null) {
            return;
        }

        int effectiveDays = trustDays > 0 ? trustDays : DEFAULT_TRUST_DAYS;
        long now = Instant.now().getEpochSecond();
        long expiresAt = now + (effectiveDays * 24L * 60L * 60L);
        if (!trustedDeviceEnabled) {
            context.getUser().setSingleAttribute(ACCOUNT_TRUST_UNTIL_ATTRIBUTE, Long.toString(expiresAt));
            return;
        }

        String token = newToken();
        String tokenHash = sha256(token);
        List<Record> records = readActiveRecords(context.getUser(), now);
        records.sort(Comparator.comparingLong(Record::expiresAt).reversed());
        if (records.size() >= MAX_TRUSTED_DEVICES) {
            records = new ArrayList<>(records.subList(0, MAX_TRUSTED_DEVICES - 1));
        }
        records.add(new Record(tokenHash, expiresAt, now));
        persistRecords(context.getUser(), records);

        int maxAgeSeconds = Math.toIntExact(Math.min(Integer.MAX_VALUE, effectiveDays * 24L * 60L * 60L));
        String realmPath = "/realms/" + context.getRealm().getName();
        boolean secure = "https".equalsIgnoreCase(context.getUriInfo().getRequestUri().getScheme());
        StringBuilder cookie = new StringBuilder()
                .append(COOKIE_NAME).append('=').append(token)
                .append("; Path=").append(realmPath)
                .append("; Max-Age=").append(maxAgeSeconds)
                .append("; HttpOnly; SameSite=Lax");
        if (secure) {
            cookie.append("; Secure");
        }
        context.getSession().getContext().getHttpResponse().addHeader("Set-Cookie", cookie.toString());
    }

    static void clearAll(UserModel user) {
        if (user != null) {
            user.removeAttribute(USER_ATTRIBUTE);
            user.removeAttribute(ACCOUNT_TRUST_UNTIL_ATTRIBUTE);
        }
    }

    private static boolean hasValidDeviceTrust(AuthenticationFlowContext context) {
        String token = readCookie(context);
        if (token == null || token.isBlank()) {
            return false;
        }
        long now = Instant.now().getEpochSecond();
        String expectedHash = sha256(token);
        List<Record> active = readActiveRecords(context.getUser(), now);
        persistRecords(context.getUser(), active);
        return active.stream().anyMatch(record -> constantTimeEquals(record.tokenHash(), expectedHash));
    }

    private static boolean hasValidAccountTrust(UserModel user) {
        String raw = user.getFirstAttribute(ACCOUNT_TRUST_UNTIL_ATTRIBUTE);
        if (raw == null || raw.isBlank()) {
            return false;
        }
        try {
            long expiresAt = Long.parseLong(raw);
            if (expiresAt > Instant.now().getEpochSecond()) {
                return true;
            }
        } catch (NumberFormatException ignored) {
        }
        user.removeAttribute(ACCOUNT_TRUST_UNTIL_ATTRIBUTE);
        return false;
    }

    private static String readCookie(AuthenticationFlowContext context) {
        var cookie = context.getHttpRequest().getHttpHeaders().getCookies().get(COOKIE_NAME);
        return cookie == null ? null : cookie.getValue();
    }

    private static List<Record> readActiveRecords(UserModel user, long now) {
        List<Record> records = new ArrayList<>();
        user.getAttributeStream(USER_ATTRIBUTE).forEach(raw -> {
            Record parsed = Record.parse(raw);
            if (parsed != null && parsed.expiresAt() > now) {
                records.add(parsed);
            }
        });
        return records;
    }

    private static void persistRecords(UserModel user, List<Record> records) {
        List<String> encoded = records.stream().map(Record::encode).toList();
        if (encoded.isEmpty()) {
            user.removeAttribute(USER_ATTRIBUTE);
        } else {
            user.setAttribute(USER_ATTRIBUTE, encoded);
        }
    }

    private static String newToken() {
        byte[] bytes = new byte[32];
        RANDOM.nextBytes(bytes);
        return Base64.getUrlEncoder().withoutPadding().encodeToString(bytes);
    }

    private static String sha256(String value) {
        try {
            MessageDigest digest = MessageDigest.getInstance("SHA-256");
            return toHex(digest.digest(value.getBytes(StandardCharsets.UTF_8)));
        } catch (NoSuchAlgorithmException e) {
            throw new IllegalStateException("SHA-256 is not available", e);
        }
    }

    private static boolean constantTimeEquals(String left, String right) {
        return MessageDigest.isEqual(left.getBytes(StandardCharsets.US_ASCII), right.getBytes(StandardCharsets.US_ASCII));
    }

    private static String toHex(byte[] bytes) {
        StringBuilder result = new StringBuilder(bytes.length * 2);
        for (byte value : bytes) {
            result.append(String.format("%02x", value));
        }
        return result.toString();
    }

    private record Record(String tokenHash, long expiresAt, long createdAt) {
        static Record parse(String raw) {
            if (raw == null) {
                return null;
            }
            String[] parts = raw.split("\\|", -1);
            if (parts.length != 3) {
                return null;
            }
            try {
                return new Record(parts[0], Long.parseLong(parts[1]), Long.parseLong(parts[2]));
            } catch (NumberFormatException ignored) {
                return null;
            }
        }

        String encode() {
            return tokenHash + "|" + expiresAt + "|" + createdAt;
        }
    }
}

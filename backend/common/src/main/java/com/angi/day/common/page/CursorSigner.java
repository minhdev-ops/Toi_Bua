package com.angi.day.common.page;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;

import javax.crypto.Mac;
import javax.crypto.spec.SecretKeySpec;
import java.nio.charset.StandardCharsets;
import java.util.Base64;
import java.util.Map;

@Component
public class CursorSigner {
    private final ObjectMapper mapper = new ObjectMapper();
    private final String secret;

    public CursorSigner(@Value("${app.cursor-secret:change-me-cursor-secret}") String secret) {
        this.secret = secret;
    }

    public String encode(Map<String, Object> claims) {
        try {
            String body = Base64.getUrlEncoder().withoutPadding()
                .encodeToString(mapper.writeValueAsBytes(claims));
            return body + "." + sign(body);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    @SuppressWarnings("unchecked")
    public Map<String, Object> decode(String cursor) {
        if (cursor == null || cursor.isBlank()) return Map.of();
        int dot = cursor.lastIndexOf('.');
        if (dot < 0) throw new IllegalArgumentException("bad cursor");
        String body = cursor.substring(0, dot);
        String sig = cursor.substring(dot + 1);
        if (!safeEqual(sig, sign(body))) throw new IllegalArgumentException("bad cursor signature");
        try {
            byte[] json = Base64.getUrlDecoder().decode(body);
            return mapper.readValue(json, Map.class);
        } catch (Exception e) {
            throw new IllegalArgumentException("bad cursor", e);
        }
    }

    private String sign(String body) {
        try {
            Mac mac = Mac.getInstance("HmacSHA256");
            mac.init(new SecretKeySpec(secret.getBytes(StandardCharsets.UTF_8), "HmacSHA256"));
            byte[] h = mac.doFinal(body.getBytes(StandardCharsets.UTF_8));
            return Base64.getUrlEncoder().withoutPadding().encodeToString(h);
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    private boolean safeEqual(String a, String b) {
        if (a == null || b == null) return false;
        byte[] ab = a.getBytes(StandardCharsets.UTF_8);
        byte[] bb = b.getBytes(StandardCharsets.UTF_8);
        if (ab.length != bb.length) return false;
        int r = 0;
        for (int i = 0; i < ab.length; i++) r |= ab[i] ^ bb[i];
        return r == 0;
    }
}

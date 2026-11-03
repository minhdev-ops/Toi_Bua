package com.angi.day.common.security;

import io.jsonwebtoken.Claims;
import io.jsonwebtoken.JwtException;
import io.jsonwebtoken.Jwts;
import java.security.KeyPair;
import java.security.KeyPairGenerator;
import java.security.PublicKey;
import java.security.interfaces.RSAPublicKey;
import java.util.Base64;
import java.util.Date;
import java.util.Map;

public final class JwtUtils {
    private JwtUtils() {}

    public static KeyPair generateRsa(int keysize) {
        try {
            KeyPairGenerator gen = KeyPairGenerator.getInstance("RSA");
            gen.initialize(keysize);
            return gen.generateKeyPair();
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    public static String issueAccessToken(KeyPair kp, String subject, long ttlMillis, Map<String, Object> claims) {
        long now = System.currentTimeMillis();
        var b = Jwts.builder().subject(subject).issuedAt(new Date(now))
            .expiration(new Date(now + ttlMillis));
        if (claims != null) b.addClaims(claims);
        return b.signWith(kp.getPrivate()).compact();
    }

    public static String issueRefreshToken(KeyPair kp, String subject, long ttlMillis) {
        long now = System.currentTimeMillis();
        return Jwts.builder().subject(subject).issuedAt(new Date(now))
            .expiration(new Date(now + ttlMillis)).signWith(kp.getPrivate()).compact();
    }

    public static Claims parse(PublicKey pub, String token) throws JwtException {
        return Jwts.parser().verifyWith(pub).build().parseSignedClaims(token).getPayload();
    }

    public static String jwkJson(RSAPublicKey pub, String kid, String alg) {
        String n = Base64.getUrlEncoder().withoutPadding().encodeToString(pub.getModulus().toByteArray());
        String e = Base64.getUrlEncoder().withoutPadding().encodeToString(pub.getPublicExponent().toByteArray());
        return "{\"keys\":[{\"kty\":\"RSA\",\"use\":\"sig\",\"alg\":\"" + alg
            + "\",\"kid\":\"" + kid + "\",\"n\":\"" + n + "\",\"e\":\"" + e + "\"}]}";
    }
}

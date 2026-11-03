package com.angi.day.identity.security;

import com.angi.day.common.security.JwtUtils;
import org.springframework.stereotype.Component;

import java.security.KeyPair;
import java.security.interfaces.RSAPublicKey;

@Component
public class JwtKeyProvider {
    private final KeyPair keyPair;
    private final String kid = "angi-rsa-1";
    private final String alg = "RS256";
    private final String jwkJson;

    public JwtKeyProvider() {
        this.keyPair = JwtUtils.generateRsa(2048);
        this.jwkJson = JwtUtils.jwkJson((RSAPublicKey) keyPair.getPublic(), kid, alg);
    }

    public KeyPair getKeyPair() { return keyPair; }
    public java.security.PublicKey getPublicKey() { return keyPair.getPublic(); }
    public String jwkJson() { return jwkJson; }
    public String kid() { return kid; }
}

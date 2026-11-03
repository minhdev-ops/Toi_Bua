package com.angi.day.gateway.security;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.math.BigInteger;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.RSAPublicKeySpec;
import java.util.Base64;

@Component
public class JwksProvider {
    private final WebClient webClient;
    private final String jwksUrl;
    private volatile PublicKey cached;

    public JwksProvider(WebClient.Builder builder) {
        this.webClient = builder.build();
        this.jwksUrl = "http://identity:8081/.well-known/jwks.json";
    }

    public Mono<PublicKey> publicKey() {
        if (cached != null) return Mono.just(cached);
        return fetch();
    }

    private Mono<PublicKey> fetch() {
        return webClient.get().uri(jwksUrl).retrieve().bodyToMono(String.class)
            .map(this::parse).doOnNext(k -> cached = k);
    }

    private PublicKey parse(String json) {
        try {
            JsonNode root = new ObjectMapper().readTree(json);
            JsonNode key = root.get("keys").get(0);
            BigInteger modulus = new BigInteger(1, Base64.getUrlDecoder().decode(key.get("n").asText()));
            BigInteger exponent = new BigInteger(1, Base64.getUrlDecoder().decode(key.get("e").asText()));
            return KeyFactory.getInstance("RSA").generatePublic(new RSAPublicKeySpec(modulus, exponent));
        } catch (Exception ex) {
            throw new IllegalStateException(ex);
        }
    }
}

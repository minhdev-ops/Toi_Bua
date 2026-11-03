package com.angi.day.gateway.security;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.beans.factory.annotation.Value;
import org.springframework.stereotype.Component;
import org.springframework.web.reactive.function.client.WebClient;
import reactor.core.publisher.Mono;

import java.math.BigInteger;
import java.security.KeyFactory;
import java.security.PublicKey;
import java.security.spec.RSAPublicKeySpec;
import java.time.Duration;
import java.util.Base64;

@Component
public class JwksProvider {

    private final WebClient webClient;
    private final ObjectMapper mapper;
    private final String jwksUrl;
    private volatile PublicKey cached;

    public JwksProvider(WebClient.Builder builder,
                        ObjectMapper mapper,
                        @Value("${services.identity-url:http://identity:8081}") String identityUrl) {
        this.webClient = builder.build();
        this.mapper = mapper;
        // Trước đây hard-code http://identity:8081 ⇒ không chạy được ngoài compose.
        this.jwksUrl = identityUrl + "/.well-known/jwks.json";
    }

    public Mono<PublicKey> publicKey() {
        PublicKey key = cached;
        if (key != null) return Mono.just(key);
        return fetch();
    }

    private Mono<PublicKey> fetch() {
        return webClient.get().uri(jwksUrl).retrieve().bodyToMono(String.class)
            .timeout(Duration.ofSeconds(3))
            .map(this::parse)
            .doOnNext(k -> cached = k);
    }

    private PublicKey parse(String json) {
        try {
            JsonNode root = mapper.readTree(json);
            JsonNode key = root.get("keys").get(0);
            BigInteger modulus = new BigInteger(1, Base64.getUrlDecoder().decode(key.get("n").asText()));
            BigInteger exponent = new BigInteger(1, Base64.getUrlDecoder().decode(key.get("e").asText()));
            return KeyFactory.getInstance("RSA").generatePublic(new RSAPublicKeySpec(modulus, exponent));
        } catch (Exception ex) {
            throw new IllegalStateException("Không đọc được JWKS từ " + jwksUrl, ex);
        }
    }
}

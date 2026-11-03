package com.angi.day.common.security;

import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.math.BigInteger;
import java.security.KeyPair;
import java.security.interfaces.RSAPublicKey;
import java.util.Base64;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;

class JwtUtilsTest {

    private final KeyPair keyPair = JwtUtils.generateRsa(2048);

    @Test
    void jwk_modulus_đúng_256_byte_theo_RFC_7518() throws Exception {
        RSAPublicKey pub = (RSAPublicKey) keyPair.getPublic();
        String json = JwtUtils.jwkJson(pub, "k1", "RS256");

        JsonNode key = new ObjectMapper().readTree(json).get("keys").get(0);
        byte[] n = Base64.getUrlDecoder().decode(key.get("n").asText());
        byte[] e = Base64.getUrlDecoder().decode(key.get("e").asText());

        // BigInteger.toByteArray() thêm 0x00 khi bit cao bật ⇒ 257 byte, sai chuẩn.
        assertThat(n).hasSize(256);
        assertThat(e).hasSize(3);
        assertThat(new BigInteger(1, n)).isEqualTo(pub.getModulus());
        assertThat(new BigInteger(1, e)).isEqualTo(pub.getPublicExponent());
    }

    @Test
    void token_ký_và_giải_mã_được_bằng_khoá_công_khai_trong_jwk() throws Exception {
        String token = JwtUtils.issueAccessToken(keyPair, "usr_42", 60_000, Map.of("kind", "guest"));
        var claims = JwtUtils.parse(keyPair.getPublic(), token);
        assertThat(claims.getSubject()).isEqualTo("usr_42");
        assertThat(claims.get("kind")).isEqualTo("guest");
    }
}

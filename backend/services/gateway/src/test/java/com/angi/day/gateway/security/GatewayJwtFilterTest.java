package com.angi.day.gateway.security;

import com.angi.day.common.config.JacksonConfig;
import com.angi.day.common.headers.Headers;
import com.angi.day.common.security.JwtUtils;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.http.HttpStatus;
import org.springframework.mock.http.server.reactive.MockServerHttpRequest;
import org.springframework.mock.web.server.MockServerWebExchange;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.security.KeyPair;
import java.util.Map;

import static org.assertj.core.api.Assertions.assertThat;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;

class GatewayJwtFilterTest {

    private final KeyPair keyPair = JwtUtils.generateRsa(2048);
    private final ObjectMapper mapper = JacksonConfig.mapper();

    private GatewayJwtFilter filter() {
        JwksProvider jwks = mock(JwksProvider.class);
        when(jwks.publicKey()).thenReturn(Mono.just(keyPair.getPublic()));
        return new GatewayJwtFilter(jwks, mapper);
    }

    private GatewayFilterChain chain() {
        GatewayFilterChain chain = mock(GatewayFilterChain.class);
        when(chain.filter(any())).thenReturn(Mono.empty());
        return chain;
    }

    @Test
    void token_hợp_lệ_không_bị_đặt_401() {
        String token = JwtUtils.issueAccessToken(keyPair, "usr_1", 60_000, Map.of());
        MockServerWebExchange ex = MockServerWebExchange.from(
            MockServerHttpRequest.get("/v1/spins/history")
                .header(Headers.AUTHORIZATION, "Bearer " + token).build());

        filter().filter(ex, chain()).block();

        // Trước khi sửa: switchIfEmpty(unauthorized(...)) gọi tham số ngay lúc lắp
        // ghép ⇒ setStatusCode(401) chạy trên MỌI request, kể cả request hợp lệ.
        assertThat(ex.getResponse().getStatusCode()).isNotEqualTo(HttpStatus.UNAUTHORIZED);
    }

    @Test
    void token_sai_trả_401_với_envelope_snake_case() {
        MockServerWebExchange ex = MockServerWebExchange.from(
            MockServerHttpRequest.get("/v1/spins/history")
                .header(Headers.AUTHORIZATION, "Bearer not-a-jwt").build());

        filter().filter(ex, chain()).block();

        assertThat(ex.getResponse().getStatusCode()).isEqualTo(HttpStatus.UNAUTHORIZED);
        String body = ex.getResponse().getBodyAsString().block();
        assertThat(body).contains("\"request_id\"").contains("\"doc_url\"").doesNotContain("requestId");
    }

    @Test
    void đường_công_khai_không_cần_token() {
        MockServerWebExchange ex = MockServerWebExchange.from(MockServerHttpRequest.get("/v1/config").build());
        filter().filter(ex, chain()).block();
        assertThat(ex.getResponse().getStatusCode()).isNull();
    }

    @Test
    void jwks_công_khai_để_client_tải_khoá() {
        MockServerWebExchange ex = MockServerWebExchange.from(
            MockServerHttpRequest.get("/.well-known/jwks.json").build());
        filter().filter(ex, chain()).block();
        assertThat(ex.getResponse().getStatusCode()).isNull();
    }
}

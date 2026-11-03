package com.angi.day.gateway.security;

import com.angi.day.common.error.ApiErrorCode;
import com.angi.day.common.error.ErrorDetail;
import com.angi.day.common.error.ErrorEnvelope;
import com.angi.day.common.headers.Headers;
import com.angi.day.common.id.RequestIds;
import com.angi.day.common.security.JwtUtils;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.cloud.gateway.filter.GatewayFilterChain;
import org.springframework.cloud.gateway.filter.GlobalFilter;
import org.springframework.core.Ordered;
import org.springframework.http.HttpStatus;
import org.springframework.http.MediaType;
import org.springframework.stereotype.Component;
import org.springframework.web.server.ServerWebExchange;
import reactor.core.publisher.Mono;

import java.security.PublicKey;
import java.util.List;
import java.util.Optional;
import java.util.Set;

@Component
public class GatewayJwtFilter implements GlobalFilter, Ordered {

    private final JwksProvider jwks;
    private final ObjectMapper mapper;

    private static final Set<String> PUBLIC = Set.of(
        "/v1/auth/guest", "/v1/auth/oauth", "/v1/config", "/v1/dishes/taxonomy",
        "/v1/dishes/bundle", "/v1/places/urgent", "/v1/healthz", "/.well-known/jwks.json");

    public GatewayJwtFilter(JwksProvider jwks, ObjectMapper mapper) {
        this.jwks = jwks;
        this.mapper = mapper;
    }

    @Override
    public Mono<Void> filter(ServerWebExchange exchange, GatewayFilterChain chain) {
        String rid = exchange.getRequest().getHeaders().getFirst(Headers.X_REQUEST_ID);
        if (rid == null || rid.isBlank()) rid = RequestIds.newId();
        exchange.getResponse().getHeaders().set(Headers.X_REQUEST_ID, rid);

        String path = exchange.getRequest().getURI().getPath();
        if (isPublic(path)) {
            return chain.filter(withRid(exchange, rid));
        }
        String auth = exchange.getRequest().getHeaders().getFirst(Headers.AUTHORIZATION);
        if (auth == null || !auth.startsWith("Bearer ")) {
            return unauthorized(exchange, rid);
        }
        final String ridF = rid;
        final String token = auth.substring(7);
        // KHÔNG dùng switchIfEmpty ở đây. chain.filter(...) trả Mono<Void> — Mono
        // rỗng theo định nghĩa (không emit value) — nên switchIfEmpty bắn cả khi
        // xác thực THÀNH CÔNG và ghi đè 401 lên mọi response. Bọc khoá công khai
        // vào Optional để pipeline luôn có giá trị, rồi mới quyết định.
        return jwks.publicKey()
            .map(Optional::<PublicKey>of)
            // Identity chết ⇒ JWKS không tải được: coi như chưa xác thực, không phải 500.
            .onErrorReturn(Optional.empty())
            .defaultIfEmpty(Optional.empty())
            .flatMap(maybeKey -> {
                if (maybeKey.isEmpty()) return unauthorized(exchange, ridF);
                try {
                    var claims = JwtUtils.parse(maybeKey.get(), token);
                    return chain.filter(withUser(withRid(exchange, ridF), claims.getSubject()));
                } catch (Exception e) {
                    return unauthorized(exchange, ridF);
                }
            });
    }

    private boolean isPublic(String path) {
        if (path.startsWith("/v1/places/")) return true;
        return PUBLIC.contains(path);
    }

    private ServerWebExchange withRid(ServerWebExchange ex, String rid) {
        return ex.mutate().request(ex.getRequest().mutate().header(Headers.X_REQUEST_ID, rid).build()).build();
    }

    private ServerWebExchange withUser(ServerWebExchange ex, String userId) {
        return ex.mutate().request(ex.getRequest().mutate().header(Headers.X_USER_ID, userId).build()).build();
    }

    private Mono<Void> unauthorized(ServerWebExchange ex, String rid) {
        byte[] body;
        try {
            // Dùng ObjectMapper của context (snake_case) — new ObjectMapper() sẽ
            // in "requestId"/"docUrl", sai contract docs/02 §2.3.
            body = mapper.writeValueAsBytes(new ErrorEnvelope(new ErrorDetail(
                ApiErrorCode.UNAUTHENTICATED.name(), "Unauthenticated", List.of(), rid, true,
                "https://api.angi.example/docs/errors#UNAUTHENTICATED")));
        } catch (Exception e) {
            body = new byte[0];
        }
        var resp = ex.getResponse();
        resp.setStatusCode(HttpStatus.UNAUTHORIZED);
        resp.getHeaders().set(Headers.X_REQUEST_ID, rid);
        resp.getHeaders().setContentType(MediaType.APPLICATION_JSON);
        return resp.writeWith(Mono.just(resp.bufferFactory().wrap(body)));
    }

    @Override
    public int getOrder() {
        return -1;
    }
}

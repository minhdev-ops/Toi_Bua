package com.angi.day.gateway;

import com.angi.day.common.headers.Headers;
import org.springframework.boot.SpringApplication;
import org.springframework.boot.autoconfigure.SpringBootApplication;
import org.springframework.cloud.gateway.filter.ratelimit.KeyResolver;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.ComponentScan;
import reactor.core.publisher.Mono;

@ComponentScan({"com.angi.day.common", "com.angi.day.gateway"})
@SpringBootApplication
public class GatewayApplication {
    public static void main(String[] args) {
        SpringApplication.run(GatewayApplication.class, args);
    }

    @Bean
    public KeyResolver rateLimitKeyResolver() {
        return exchange -> {
            String dev = exchange.getRequest().getHeaders().getFirst(Headers.X_DEVICE_ID);
            if (dev != null && !dev.isBlank()) return Mono.just(dev);
            var addr = exchange.getRequest().getRemoteAddress();
            return Mono.just(addr != null ? addr.getAddress().getHostAddress() : "anon");
        };
    }
}

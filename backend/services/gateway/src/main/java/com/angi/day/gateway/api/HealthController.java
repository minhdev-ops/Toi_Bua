package com.angi.day.gateway.api;

import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

import java.util.Map;

@RestController
public class HealthController {
    @GetMapping("/v1/healthz")
    public Map<String, String> health() {
        return Map.of("status", "ok");
    }
}

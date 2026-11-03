package com.angi.day.identity.api;

import com.angi.day.identity.security.JwtKeyProvider;
import org.springframework.web.bind.annotation.GetMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
public class JwksController {
    private final JwtKeyProvider keys;

    public JwksController(JwtKeyProvider keys) {
        this.keys = keys;
    }

    @GetMapping("/.well-known/jwks.json")
    public String jwks() {
        return keys.jwkJson();
    }
}

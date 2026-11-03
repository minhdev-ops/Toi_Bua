package com.angi.day.identity.api;

import com.angi.day.identity.application.AuthService;
import com.angi.day.identity.application.AuthService.GuestResult;
import com.angi.day.identity.security.JwtKeyProvider;
import jakarta.validation.Valid;
import jakarta.validation.constraints.NotBlank;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/auth")
public class AuthController {
    private final AuthService authService;
    private final JwtKeyProvider keys;

    public AuthController(AuthService authService, JwtKeyProvider keys) {
        this.authService = authService;
        this.keys = keys;
    }

    @PostMapping("/guest")
    public GuestResult guest(@Valid @RequestBody GuestRequest req) {
        return authService.guest(req.installId(), req.platform());
    }

    @PostMapping("/refresh")
    public GuestResult refresh(@Valid @RequestBody RefreshRequest req) {
        return authService.refresh(req.refreshToken());
    }

    @PostMapping("/logout")
    public void logout(@Valid @RequestBody RefreshRequest req) {
        authService.logout(req.refreshToken());
    }

    public record GuestRequest(@NotBlank String installId, @NotBlank String platform) {}
    public record RefreshRequest(@NotBlank String refreshToken) {}
}

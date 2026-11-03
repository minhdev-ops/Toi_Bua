package com.angi.day.identity.application;

import com.angi.day.common.error.ApiErrorCode;
import com.angi.day.common.error.ApiException;
import com.angi.day.common.id.Ulid;
import com.angi.day.common.security.JwtUtils;
import com.angi.day.identity.domain.AppUser;
import com.angi.day.identity.domain.RefreshToken;
import com.angi.day.identity.infrastructure.AppUserRepository;
import com.angi.day.identity.infrastructure.RefreshTokenRepository;
import com.angi.day.identity.security.JwtKeyProvider;
import io.jsonwebtoken.JwtException;
import org.springframework.stereotype.Service;
import org.springframework.transaction.annotation.Transactional;

import java.security.KeyPair;
import java.time.Duration;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;

@Service
public class AuthService {
    private final AppUserRepository users;
    private final RefreshTokenRepository refreshTokens;
    private final JwtKeyProvider keys;
    private final long accessTtl = Duration.ofMinutes(15).toMillis();
    private final long refreshTtl = Duration.ofDays(30).toMillis();

    public AuthService(AppUserRepository users, RefreshTokenRepository refreshTokens, JwtKeyProvider keys) {
        this.users = users;
        this.refreshTokens = refreshTokens;
        this.keys = keys;
    }

    @Transactional
    public GuestResult guest(String installId, String platform) {
        String userId = Ulid.generate("usr_");
        AppUser u = new AppUser();
        u.setId(userId);
        u.setGuest(true);
        u.setInstallId(installId);
        u.setPlatform(platform);
        u.setLocale("vi");
        u.setOnboarded(false);
        u.setCreatedAt(Instant.now());
        u.setUpdatedAt(Instant.now());
        users.save(u);
        return issue(userId);
    }

    @Transactional
    public GuestResult refresh(String refreshToken) {
        String userId;
        try {
            userId = JwtUtils.parse(keys.getPublicKey(), refreshToken).getSubject();
        } catch (JwtException e) {
            throw new ApiException(ApiErrorCode.TOKEN_EXPIRED, "invalid or expired refresh token");
        }
        refreshTokens.findByTokenHash(hash(refreshToken)).ifPresent(rt -> {
            rt.setRevoked(true);
            refreshTokens.save(rt);
        });
        return issue(userId);
    }

    @Transactional
    public void logout(String refreshToken) {
        refreshTokens.findByTokenHash(hash(refreshToken)).ifPresent(rt -> {
            rt.setRevoked(true);
            refreshTokens.save(rt);
        });
    }

    private GuestResult issue(String userId) {
        KeyPair kp = keys.getKeyPair();
        String access = JwtUtils.issueAccessToken(kp, userId, accessTtl, null);
        String refresh = JwtUtils.issueRefreshToken(kp, userId, refreshTtl);
        RefreshToken rt = new RefreshToken();
        rt.setId(Ulid.generate("rft_"));
        rt.setTokenHash(hash(refresh));
        rt.setUserId(userId);
        rt.setExpiresAt(Instant.now().plusMillis(refreshTtl));
        rt.setRevoked(false);
        rt.setCreatedAt(Instant.now());
        refreshTokens.save(rt);
        AppUser u = users.findById(userId).orElse(null);
        boolean onboarded = u != null && u.isOnboarded();
        String kind = (u != null && u.isGuest()) ? "guest" : "user";
        UserDto user = new UserDto(userId, kind, null, onboarded);
        return new GuestResult(user, access, (int) Duration.ofMillis(accessTtl).getSeconds(),
            refresh, (int) Duration.ofMillis(refreshTtl).getSeconds(),
            List.of("location"), "2026.10");
    }

    private String hash(String t) {
        try {
            var md = java.security.MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(t.getBytes(java.nio.charset.StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }

    public record UserDto(String id, String kind, String displayName, boolean onboardingCompleted) {}
    public record GuestResult(UserDto user, String accessToken, int accessExpiresIn,
                              String refreshToken, int refreshExpiresIn,
                              List<String> consentsRequired, String policyVersion) {}
}

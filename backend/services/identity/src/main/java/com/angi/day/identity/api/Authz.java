package com.angi.day.identity.api;

import com.angi.day.common.error.ApiErrorCode;
import com.angi.day.common.error.ApiException;
import com.angi.day.common.security.JwtUtils;
import com.angi.day.identity.security.JwtKeyProvider;
import io.jsonwebtoken.JwtException;
import jakarta.servlet.http.HttpServletRequest;

public final class Authz {
    private Authz() {}

    public static String userId(HttpServletRequest req, JwtKeyProvider keys) {
        String h = req.getHeader("Authorization");
        if (h == null || !h.startsWith("Bearer ")) {
            throw new ApiException(ApiErrorCode.UNAUTHENTICATED, "missing bearer token");
        }
        try {
            return JwtUtils.parse(keys.getPublicKey(), h.substring(7)).getSubject();
        } catch (JwtException e) {
            throw new ApiException(ApiErrorCode.TOKEN_EXPIRED, "invalid or expired token");
        }
    }
}

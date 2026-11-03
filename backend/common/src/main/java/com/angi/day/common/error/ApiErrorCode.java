package com.angi.day.common.error;

public enum ApiErrorCode {
    VALIDATION_FAILED(400, false),
    UNAUTHENTICATED(401, true),
    TOKEN_EXPIRED(401, true),
    FORBIDDEN(403, false),
    CONSENT_REQUIRED(403, false),
    NOT_FOUND(404, false),
    CONFLICT(409, true),
    IDEMPOTENCY_REPLAY(409, true),
    ROOM_VERSION_STALE(409, true),
    ROOM_EXPIRED(410, false),
    DIET_FILTER_EMPTY(422, false),
    PROVIDER_UNAVAILABLE(424, true),
    RATE_LIMITED(429, true),
    DEGRADED_NO_RESULT(503, true);

    private final int http;
    private final boolean retryable;

    ApiErrorCode(int http, boolean retryable) {
        this.http = http;
        this.retryable = retryable;
    }

    public int http() { return http; }
    public boolean retryable() { return retryable; }
}

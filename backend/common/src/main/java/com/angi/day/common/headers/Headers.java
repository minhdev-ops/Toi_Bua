package com.angi.day.common.headers;

public final class Headers {
    private Headers() {}
    public static final String AUTHORIZATION = "Authorization";
    public static final String X_REQUEST_ID = "X-Request-Id";
    public static final String X_DEVICE_ID = "X-Device-Id";
    public static final String X_PLATFORM = "X-Platform";
    public static final String X_APP_VERSION = "X-App-Version";
    public static final String X_LOCALE = "X-Locale";
    public static final String X_IDEMPOTENCY_KEY = "X-Idempotency-Key";
    public static final String X_USER_ID = "X-User-Id";
    public static final String X_GEO_PRECISION = "X-Geo-Precision";
    public static final String X_DATA_QUALITY = "X-Data-Quality";
    public static final String X_RATE_LIMIT_LIMIT = "X-RateLimit-Limit";
    public static final String X_RATE_LIMIT_REMAINING = "X-RateLimit-Remaining";
    public static final String X_RATE_LIMIT_RESET = "X-RateLimit-Reset";
    public static final String X_MIN_APP_VERSION = "X-Min-App-Version";

    public static final String DQ_FRESH = "fresh";
    public static final String DQ_CACHED = "cached";
    public static final String DQ_STALE = "stale";
    public static final String DQ_PROVIDER_DEGRADED = "provider_degraded";
    public static final String DQ_OFFLINE_BUNDLE = "offline_bundle";
}

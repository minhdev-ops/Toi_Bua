package com.angi.day.common.error;

import java.util.List;

public class ApiException extends RuntimeException {
    private final ApiErrorCode code;
    private final List<ErrorDetailItem> details;

    public ApiException(ApiErrorCode code, String message) {
        this(code, message, List.of());
    }

    public ApiException(ApiErrorCode code, String message, List<ErrorDetailItem> details) {
        super(message);
        this.code = code;
        this.details = details == null ? List.of() : details;
    }

    public ApiErrorCode code() { return code; }
    public List<ErrorDetailItem> details() { return details; }
    public int httpStatus() { return code.http(); }
    public boolean retryable() { return code.retryable(); }
}

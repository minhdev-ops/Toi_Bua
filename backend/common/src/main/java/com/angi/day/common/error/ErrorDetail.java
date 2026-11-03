package com.angi.day.common.error;

import java.util.List;

public record ErrorDetail(String code, String message, List<ErrorDetailItem> details, String requestId, boolean retryable, String docUrl) {}

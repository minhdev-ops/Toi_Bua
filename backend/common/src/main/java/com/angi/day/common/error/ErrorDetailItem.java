package com.angi.day.common.error;

public record ErrorDetailItem(String field, String rule, Object allowed, Object received, String messageKey) {
    public static ErrorDetailItem of(String field, String rule, Object allowed, Object received, String messageKey) {
        return new ErrorDetailItem(field, rule, allowed, received, messageKey);
    }
}

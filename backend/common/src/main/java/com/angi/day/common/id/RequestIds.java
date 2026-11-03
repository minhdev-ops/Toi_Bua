package com.angi.day.common.id;

public final class RequestIds {
    private RequestIds() {}
    public static String newId() {
        return Ulid.generate();
    }
}

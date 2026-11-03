package com.angi.day.common.money;

public record Money(long vnd) {
    public Money {
        if (vnd < 0) throw new IllegalArgumentException("vnd must be >= 0");
    }
    public static Money of(long vnd) { return new Money(vnd); }
}

package com.angi.day.common.geo;

public record GeoPoint(double lat, double lng) {
    public GeoPoint {
        if (lat < -90 || lat > 90 || lng < -180 || lng > 180) {
            throw new IllegalArgumentException("invalid geo point");
        }
    }
}

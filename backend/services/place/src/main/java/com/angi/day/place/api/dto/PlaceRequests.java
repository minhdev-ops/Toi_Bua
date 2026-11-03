package com.angi.day.place.api.dto;

import java.util.List;
import java.util.Map;

public final class PlaceRequests {

    public record NearbyQuery(
        String geo, String userLocationId, String address,
        Integer radiusM, List<String> dishIds,
        Boolean openNow, Long budgetVnd, String travelMode,
        String sort, String view, Integer limit, String cursor) {}

    public record MatchesRequest(
        String dishId, List<String> dishIds, String spinId,
        String geo, String userLocationId, String address,
        Integer radiusM, Integer limit, Filters filters,
        String travelMode, List<String> excludePlaceIds,
        Boolean includeClosed, Boolean personalization) {}

    public record Filters(String meal, String price, String region, String temp,
                          String mood, Integer partySize, Long budgetVnd) {}

    public record ReportRequest(
        String kind, String detail, Map<String, Object> suggestedValue,
        GeoInput observationGeo, String observationAt, List<String> uploadIds) {}

    public record GeoInput(double lat, double lng) {}

    public record GeocodeRequest(String address) {}

    public record UserLocationRequest(String label, GeoInput geo, String address) {}

    public record GeoResponse(double lat, double lng, String label, String source) {}
}

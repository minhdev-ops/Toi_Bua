package com.angi.day.place.api.dto;

import com.angi.day.common.page.PageMeta;
import com.fasterxml.jackson.annotation.JsonProperty;

import java.util.List;
import java.util.Map;

public final class PlaceDtos {

    public record Geo(double lat, double lng) {}
    public record PriceRange(Long min, Long max) {}
    public record OpenStatus(@JsonProperty("is_open") boolean isOpen, Integer closesInMin, boolean closingSoon, double oScore, String tz) {}
    public record Source(String provider, String verifiedAt, Double dataConfidence) {}
    public record DishHighlight(String dishId, String name, double confidence, Long priceVnd) {}
    public record ScoreComponent(String key, String messageKey, double value, double weight) {}
    public record ScoreBreakdown(double scoreTotal, String topComponent, List<ScoreComponent> components) {}
    public record Why(String headline, List<String> bullets, String key, Map<String, String> params) {}

    public record PlaceView(
        String id, String name, String address,
        Geo geo, String travelMode, int distanceM, int walkMinutes,
        int priceLevel, @JsonProperty("price_range_vnd") PriceRange priceRange, long avgPriceVnd,
        double ratingRaw, double ratingBayesian, int reviewCount,
        OpenStatus openStatus, List<String> cuisineTags, List<DishHighlight> dishHighlights,
        List<String> badges, Source source, ScoreBreakdown scoreBreakdown, Why why) {}

    public record Anchor(Geo geo, String label) {}
    public record Context(Anchor anchor, int radiusM, List<String> requestedDishIds, String now) {}
    public record Meta(String dataQuality, String generatedAt, int cacheAgeS,
                       List<String> providersUsed, Map<String, String> experimentArms, Integer latencyMs) {}

    public record NearbyResponse(List<PlaceView> items, PageMeta page, Context context,
                                 Object clusters, Object relaxation, Meta meta) {}

    public record DishRef(String id, String name, List<String> categoryPath) {}
    public record RelaxStep(String dimension, Object from, Object to, int expectedExtra, String whyKey) {}
    public record Relaxation(boolean applied, List<RelaxStep> stepsAvailable) {}
    public record SubstituteDish(String id, String name, double similarity, String reasonKey) {}
    public record ContextUsed(String localTime, String dow, String weather, boolean monthEnd,
                              Map<String, Double> weightOverrides) {}

    public record MatchesResponse(DishRef dish, List<PlaceView> items, Relaxation relaxation,
                                  List<SubstituteDish> substituteDishes, ContextUsed contextUsed, Meta meta) {}

    public record FallbackDish(String id, String name, String reasonKey) {}
    public record Decision(@JsonProperty("radius_m_used") int radiusMUsed, boolean expanded,
                           int candidatesConsidered, String oneTapAction,
                           FallbackDish fallbackDish, String notifyKey) {}
    public record Alternative(String id, String name, int distanceM, String whyKey, Map<String, String> whyParams) {}
    public record UrgentResponse(PlaceView place, Decision decision, List<Alternative> alternatives,
                                 OpenStatus openStatus, Meta meta) {}

    public record HoursByDow(int dow, String opensAt, String closesAt, @JsonProperty("is_closed") boolean isClosed) {}
    public record MenuDish(String dishId, String name, long priceVnd, double confidence, boolean popular) {}
    public record Menu(List<MenuDish> dishes, String source, String updatedAt) {}
    public record Image(String url, String credit, String source, @JsonProperty("is_user_submitted") boolean isUserSubmitted) {}
    public record VerdictSplit(int good, int ok, int bad) {}
    public record ReviewsSummary(double avg, int count, VerdictSplit verdictSplit) {}
    public record Reviews(ReviewsSummary summary, List<Object> items) {}
    public record Contact(String phoneE164, String bookingUrl, String deliveryUrl) {}
    public record ReportSummary(int count30d, int pending, String lastKind, boolean canReport, int cooldownS) {}
    public record SimilarPlace(String id, String name, int distanceM) {}

    public record PlaceDetailResponse(
        String id, String name, String address,
        Geo geo, String travelMode, int distanceM, int walkMinutes,
        int priceLevel, @JsonProperty("price_range_vnd") PriceRange priceRange, long avgPriceVnd,
        double ratingRaw, double ratingBayesian, int reviewCount,
        OpenStatus openStatus, List<String> cuisineTags, List<DishHighlight> dishHighlights,
        List<String> badges, Source source, ScoreBreakdown scoreBreakdown, Why why,
        List<HoursByDow> hoursByDow, Menu menu, List<Image> images, Reviews reviews,
        Contact contact, ReportSummary reportSummary, List<SimilarPlace> similarPlaces) {}

    public record ReportResponse(String reportId, String status, boolean queuedForReview,
                                 boolean credited, boolean affectsRankingAfterReview,
                                 int cooldownS, String duplicateOf) {}
}

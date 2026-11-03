package com.angi.day.journal.api.dto;

public final class VisitDto {

    public record VisitRequest(
        String placeId, String dishId, String spinId,
        String status, String source, Long spendVnd,
        String note, Integer privateRating, java.util.List<String> uploadIds,
        String occurredAt, String deviceUpdatedAt, String deviceVersion) {}

    public record VisitResponse(
        String id, String status, String occurredAt,
        boolean askReview, String reviewPromptKey, Long budgetDeltaVnd) {}

    public record RecordResult(boolean replayed, VisitResponse response) {}
}

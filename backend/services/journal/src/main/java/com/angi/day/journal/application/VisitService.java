package com.angi.day.journal.application;

import com.angi.day.common.error.ApiException;
import com.angi.day.common.error.ApiErrorCode;
import com.angi.day.common.id.Ulid;
import com.angi.day.journal.api.dto.VisitDto.RecordResult;
import com.angi.day.journal.api.dto.VisitDto.VisitRequest;
import com.angi.day.journal.api.dto.VisitDto.VisitResponse;
import com.angi.day.journal.domain.Visit;
import com.angi.day.journal.infrastructure.VisitRepository;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.temporal.ChronoUnit;
import java.util.Set;

@Service
public class VisitService {

    private static final Set<String> STATUSES = Set.of("chosen", "arrived", "completed");
    private static final Set<String> SOURCES = Set.of("manual", "checkin", "nav_open");

    private final VisitRepository repo;
    private final PlaceClient placeClient;

    public VisitService(VisitRepository repo, PlaceClient placeClient) {
        this.repo = repo;
        this.placeClient = placeClient;
    }

    public RecordResult record(VisitRequest req, String idempotencyKey, String userId) {
        if (idempotencyKey == null || idempotencyKey.isBlank()) {
            throw new ApiException(ApiErrorCode.VALIDATION_FAILED, "X-Idempotency-Key header is required");
        }
        if (req.placeId() == null || !req.placeId().startsWith("plc_")) {
            throw new ApiException(ApiErrorCode.VALIDATION_FAILED, "place_id is required and must start with plc_");
        }
        if (req.status() == null || !STATUSES.contains(req.status())) {
            throw new ApiException(ApiErrorCode.VALIDATION_FAILED, "status must be chosen|arrived|completed");
        }
        if (req.source() != null && !SOURCES.contains(req.source())) {
            throw new ApiException(ApiErrorCode.VALIDATION_FAILED, "source must be manual|checkin|nav_open");
        }

        var existing = repo.findByIdempotencyKey(idempotencyKey);
        if (existing.isPresent()) {
            Visit v = existing.get();
            return new RecordResult(true, toResponse(v));
        }

        placeClient.assertExists(req.placeId());

        Instant occurred = req.occurredAt() != null ? Instant.parse(req.occurredAt()) : Instant.now();
        Instant now = Instant.now();
        if (occurred.isAfter(now) || occurred.isBefore(now.minus(7, ChronoUnit.DAYS))) {
            throw new ApiException(ApiErrorCode.VALIDATION_FAILED, "occurred_at must be within the last 7 days and not in the future");
        }

        Visit v = new Visit();
        v.setId(Ulid.generate("vst_"));
        v.setPlaceId(req.placeId());
        v.setDishId(req.dishId());
        v.setSpinId(req.spinId());
        v.setStatus(req.status());
        v.setSource(req.source() != null ? req.source() : "manual");
        v.setSpendVnd(req.spendVnd());
        v.setNote(req.note());
        v.setPrivateRating(req.privateRating());
        v.setOccurredAt(occurred);
        v.setDeviceUpdatedAt(req.deviceUpdatedAt() != null ? Instant.parse(req.deviceUpdatedAt()) : null);
        v.setDeviceVersion(req.deviceVersion());
        v.setUserId(userId);
        v.setIdempotencyKey(idempotencyKey);
        v.setCreatedAt(now);
        repo.save(v);
        return new RecordResult(false, toResponse(v));
    }

    private VisitResponse toResponse(Visit v) {
        return new VisitResponse(v.getId(), v.getStatus(),
            v.getOccurredAt().toString(), true, "prompt.rate_after_visit",
            v.getSpendVnd() != null ? v.getSpendVnd() : 0L);
    }
}

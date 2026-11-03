package com.angi.day.journal.api;

import com.angi.day.common.error.ApiErrorCode;
import com.angi.day.common.error.ApiException;
import com.angi.day.journal.api.dto.VisitDto.RecordResult;
import com.angi.day.journal.api.dto.VisitDto.VisitRequest;
import com.angi.day.journal.api.dto.VisitDto.VisitResponse;
import com.angi.day.journal.application.VisitService;
import com.angi.day.common.headers.Headers;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.annotation.PostMapping;
import org.springframework.web.bind.annotation.RequestBody;
import org.springframework.web.bind.annotation.RequestMapping;
import org.springframework.web.bind.annotation.RestController;

@RestController
@RequestMapping("/v1/journal")
public class VisitController {

    private final VisitService service;

    public VisitController(VisitService service) {
        this.service = service;
    }

    @PostMapping("/visits")
    public ResponseEntity<VisitResponse> create(@RequestBody VisitRequest body, HttpServletRequest req) {
        String idem = req.getHeader(Headers.X_IDEMPOTENCY_KEY);
        if (idem == null || idem.isBlank()) {
            throw new ApiException(ApiErrorCode.VALIDATION_FAILED, "X-Idempotency-Key header is required");
        }
        RecordResult result = service.record(body, idem, req.getHeader(Headers.X_USER_ID));
        if (result.replayed()) {
            return ResponseEntity.status(409).body(result.response());
        }
        return ResponseEntity.status(201).body(result.response());
    }
}

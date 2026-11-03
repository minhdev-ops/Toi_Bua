package com.angi.day.identity.api;

import com.angi.day.common.error.ApiErrorCode;
import com.angi.day.common.error.ApiException;
import com.angi.day.common.error.ErrorDetail;
import com.angi.day.common.error.ErrorDetailItem;
import com.angi.day.common.error.ErrorEnvelope;
import com.angi.day.common.headers.Headers;
import jakarta.servlet.http.HttpServletRequest;
import org.springframework.http.ResponseEntity;
import org.springframework.web.bind.MethodArgumentNotValidException;
import org.springframework.web.bind.annotation.ExceptionHandler;
import org.springframework.web.bind.annotation.RestControllerAdvice;

import java.util.List;
import java.util.stream.Collectors;

@RestControllerAdvice
public class GlobalExceptionHandler {

    @ExceptionHandler(ApiException.class)
    public ResponseEntity<ErrorEnvelope> handleApi(ApiException ex, HttpServletRequest req) {
        ErrorDetail detail = new ErrorDetail(ex.code().name(), ex.getMessage(), ex.details(), reqId(req), ex.retryable(), docUrl(ex.code()));
        return ResponseEntity.status(ex.httpStatus()).header(Headers.X_REQUEST_ID, reqId(req)).body(new ErrorEnvelope(detail));
    }

    @ExceptionHandler(MethodArgumentNotValidException.class)
    public ResponseEntity<ErrorEnvelope> handleValidation(MethodArgumentNotValidException ex, HttpServletRequest req) {
        List<ErrorDetailItem> items = ex.getBindingResult().getFieldErrors().stream()
            .map(fe -> new ErrorDetailItem(fe.getField(), "valid", null, fe.getRejectedValue(), fe.getDefaultMessage()))
            .collect(Collectors.toList());
        ErrorDetail detail = new ErrorDetail(ApiErrorCode.VALIDATION_FAILED.name(), "Validation failed", items, reqId(req), false, docUrl(ApiErrorCode.VALIDATION_FAILED));
        return ResponseEntity.status(400).header(Headers.X_REQUEST_ID, reqId(req)).body(new ErrorEnvelope(detail));
    }

    @ExceptionHandler(Exception.class)
    public ResponseEntity<ErrorEnvelope> handleOther(Exception ex, HttpServletRequest req) {
        ErrorDetail detail = new ErrorDetail(ApiErrorCode.DEGRADED_NO_RESULT.name(), "Unexpected error", List.of(), reqId(req), true, docUrl(ApiErrorCode.DEGRADED_NO_RESULT));
        return ResponseEntity.status(500).header(Headers.X_REQUEST_ID, reqId(req)).body(new ErrorEnvelope(detail));
    }

    private String reqId(HttpServletRequest req) {
        String id = req.getHeader(Headers.X_REQUEST_ID);
        return id != null ? id : "server";
    }

    private String docUrl(ApiErrorCode code) {
        return "https://api.angi.example/docs/errors#" + code.name();
    }
}

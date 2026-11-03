package com.angi.day.common.contract;

import com.angi.day.common.config.JacksonConfig;
import com.angi.day.common.error.ApiErrorCode;
import com.angi.day.common.error.ErrorDetail;
import com.angi.day.common.error.ErrorDetailItem;
import com.angi.day.common.error.ErrorEnvelope;
import com.angi.day.common.geo.GeoPoint;
import com.angi.day.common.money.Money;
import com.angi.day.common.page.CursorPage;
import com.angi.day.common.page.PageMeta;
import com.fasterxml.jackson.databind.JsonNode;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.junit.jupiter.api.Test;

import java.util.List;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertFalse;
import static org.junit.jupiter.api.Assertions.assertTrue;

/**
 * Guards the wire contract from docs/02: snake_case keys, dropped nulls,
 * and the single error envelope shape. Uses the same mapper the services use.
 */
class WireContractTest {

    private final ObjectMapper m = JacksonConfig.mapper();

    private JsonNode json(Object o) throws Exception {
        return m.readTree(m.writeValueAsString(o));
    }

    @Test
    void pagination_is_snake_case_and_drops_absent_cursor() throws Exception {
        JsonNode n = json(new CursorPage<>(List.of("a"), new PageMeta(null, false, 1L)));
        assertTrue(n.has("items"));
        JsonNode page = n.get("page");
        assertTrue(page.has("has_more"), "has_more expected");
        assertTrue(page.has("total_estimate"), "total_estimate expected");
        assertFalse(page.has("next_cursor"), "null next_cursor must be dropped");
        assertFalse(page.has("hasMore"), "camelCase must not leak");
    }

    @Test
    void error_envelope_matches_contract() throws Exception {
        ErrorDetailItem item = new ErrorDetailItem("dish_id", "conflict", null, List.of("x"), "err.diet.empty");
        ErrorDetail d = new ErrorDetail("DIET_FILTER_EMPTY", "No dish", List.of(item), "req_1", false, "https://x#DIET");
        JsonNode n = json(new ErrorEnvelope(d)).get("error");
        assertEquals("DIET_FILTER_EMPTY", n.get("code").asText());
        assertEquals("req_1", n.get("request_id").asText());
        assertTrue(n.has("retryable"));
        assertTrue(n.has("doc_url"));
        JsonNode it = n.get("details").get(0);
        assertTrue(it.has("message_key"));
        assertTrue(it.has("field"));
        assertFalse(it.has("messageKey"), "camelCase must not leak");
    }

    @Test
    void value_objects_serialize_expected_keys() throws Exception {
        assertTrue(json(new Money(42000L)).has("vnd"));
        JsonNode g = json(new GeoPoint(10.7, 106.7));
        assertTrue(g.has("lat"));
        assertTrue(g.has("lng"));
    }

    @Test
    void error_codes_map_to_http_and_retryable() {
        assertEquals(400, ApiErrorCode.VALIDATION_FAILED.http());
        assertEquals(401, ApiErrorCode.UNAUTHENTICATED.http());
        assertEquals(404, ApiErrorCode.NOT_FOUND.http());
        assertEquals(422, ApiErrorCode.DIET_FILTER_EMPTY.http());
        assertTrue(ApiErrorCode.PROVIDER_UNAVAILABLE.retryable());
        assertFalse(ApiErrorCode.NOT_FOUND.retryable());
        assertFalse(ApiErrorCode.DIET_FILTER_EMPTY.retryable());
    }
}

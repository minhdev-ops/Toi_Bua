package com.angi.day.roulette.api;

import com.angi.day.common.config.JacksonConfig;
import com.angi.day.common.error.ApiErrorCode;
import com.angi.day.common.error.ApiException;
import com.angi.day.common.error.ErrorDetailItem;
import com.angi.day.roulette.application.RouletteService;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.springframework.http.converter.json.MappingJackson2HttpMessageConverter;
import org.springframework.test.web.servlet.MockMvc;
import org.springframework.test.web.servlet.setup.MockMvcBuilders;

import java.util.List;
import java.util.Map;

import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.when;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.get;
import static org.springframework.test.web.servlet.request.MockMvcRequestBuilders.post;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.header;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Contract tests at the HTTP boundary: response keys must be snake_case and every
 * error must use the single envelope with request_id / retryable / doc_url.
 */
class RouletteContractTest {

    private RouletteService svc;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        svc = mock(RouletteService.class);
        mvc = MockMvcBuilders.standaloneSetup(new RouletteController(svc))
            .setControllerAdvice(new GlobalExceptionHandler())
            .setMessageConverters(new MappingJackson2HttpMessageConverter(JacksonConfig.mapper()))
            .build();
    }

    private RouletteService.DishDto dish() {
        return new RouletteService.DishDto("dsh_01", "Phở bò", "Beef pho", "cat_noodle",
            List.of("món nước"), "north", "hot", List.of("lunch"), List.of(), 2, null, false);
    }

    private RouletteService.SpinResult spinResult() {
        return new RouletteService.SpinResult(
            "spn_1", "2026-11-01T03:20:00Z", dish(),
            new RouletteService.ProofDto("c2VlZA==", "abc123", "weighted-csprng-v1", "pool123",
                "/v1/spins/spn_1/verify"),
            new RouletteService.PoolDto(6, 6, 6, new RouletteService.PoolRemovedDto(0, 0, 0, 0, 0)),
            new RouletteService.AntiRepeatDto(3, 3.0, List.of(), 0.0),
            Map.of(),
            new RouletteService.AnimationDto("wheel", 2600, false, true, true, 4,
                List.of("dsh_01", "dsh_02"), 0),
            new RouletteService.NextActionDto("fetch_places", "POST", "/v1/matches",
                Map.<String, Object>of("dish_id", "dsh_01", "radius_m", 1500, "limit", 3)),
            new RouletteService.SpinMetaDto("fresh", false, Map.of()));
    }

    @Test
    void bundle_is_snake_case() throws Exception {
        when(svc.bundle(any())).thenReturn(
            new RouletteService.BundleResponse("20261101", List.of(dish())));

        mvc.perform(get("/v1/dishes/bundle"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.version").value("20261101"))
            .andExpect(jsonPath("$.dishes[0].id").value("dsh_01"))
            .andExpect(jsonPath("$.dishes[0].category_id").value("cat_noodle"))
            .andExpect(jsonPath("$.dishes[0].price_level").value(2))
            .andExpect(jsonPath("$.dishes[0].is_excluded").value(false));
    }

    @Test
    void spin_returns_full_contract_shape() throws Exception {
        when(svc.spin(eq("usr_1"), any())).thenReturn(spinResult());

        mvc.perform(post("/v1/spins")
                .header("X-User-Id", "usr_1")
                .contentType("application/json").content("{}"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.spin_id").value("spn_1"))
            .andExpect(jsonPath("$.created_at").value("2026-11-01T03:20:00Z"))
            .andExpect(jsonPath("$.dish.id").value("dsh_01"))
            .andExpect(jsonPath("$.proof.sha256_result").value("abc123"))
            .andExpect(jsonPath("$.proof.verify_url").value("/v1/spins/spn_1/verify"))
            .andExpect(jsonPath("$.pool.size_final").value(6))
            .andExpect(jsonPath("$.pool.removed.diet_hard").value(0))
            .andExpect(jsonPath("$.anti_repeat.days_window").value(3))
            .andExpect(jsonPath("$.animation.style").value("wheel"))
            .andExpect(jsonPath("$.animation.duration_ms").value(2600))
            .andExpect(jsonPath("$.animation.wheel_items[0]").value("dsh_01"))
            .andExpect(jsonPath("$.animation.result_index").value(0))
            .andExpect(jsonPath("$.next.path").value("/v1/matches"))
            .andExpect(jsonPath("$.next.suggested_body.dish_id").value("dsh_01"))
            .andExpect(jsonPath("$.meta.data_quality").value("fresh"));
    }

    @Test
    void missing_user_is_401_envelope_with_request_id() throws Exception {
        mvc.perform(post("/v1/spins")
                .header("X-Request-Id", "req-abc")
                .contentType("application/json").content("{}"))
            .andExpect(status().isUnauthorized())
            .andExpect(header().string("X-Request-Id", "req-abc"))
            .andExpect(jsonPath("$.error.code").value("UNAUTHENTICATED"))
            .andExpect(jsonPath("$.error.request_id").value("req-abc"))
            .andExpect(jsonPath("$.error.retryable").value(true))
            .andExpect(jsonPath("$.error.doc_url").exists());
    }

    @Test
    void diet_empty_is_422_with_message_key() throws Exception {
        when(svc.spin(eq("usr_1"), any())).thenThrow(new ApiException(
            ApiErrorCode.DIET_FILTER_EMPTY, "No dish",
            List.of(new ErrorDetailItem("exclude_dish_ids", "conflict", null,
                List.of("dsh_01"), "err.diet.empty"))));

        mvc.perform(post("/v1/spins")
                .header("X-User-Id", "usr_1")
                .contentType("application/json").content("{}"))
            .andExpect(status().isUnprocessableEntity())
            .andExpect(jsonPath("$.error.code").value("DIET_FILTER_EMPTY"))
            .andExpect(jsonPath("$.error.details[0].message_key").value("err.diet.empty"));
    }

    @Test
    void missing_spin_is_404_envelope() throws Exception {
        when(svc.get("nope")).thenThrow(new ApiException(ApiErrorCode.NOT_FOUND, "spin not found"));

        mvc.perform(get("/v1/spins/nope"))
            .andExpect(status().isNotFound())
            .andExpect(jsonPath("$.error.code").value("NOT_FOUND"));
    }
}

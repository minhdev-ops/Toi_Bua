package com.angi.day.place.api;

import com.angi.day.common.config.JacksonConfig;
import com.angi.day.common.page.PageMeta;
import com.angi.day.place.api.dto.PlaceDtos.*;
import com.angi.day.place.application.PlaceService;
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
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.jsonPath;
import static org.springframework.test.web.servlet.result.MockMvcResultMatchers.status;

/**
 * Locks the place wire contract (docs/02 §4): snake_case, top-level place fields on
 * detail, urgent decision fields, and the report acknowledgement.
 */
class PlaceContractTest {

    private PlaceService svc;
    private MockMvc mvc;

    @BeforeEach
    void setUp() {
        svc = mock(PlaceService.class);
        mvc = MockMvcBuilders.standaloneSetup(new PlaceController(svc))
            .setControllerAdvice(new GlobalExceptionHandler())
            .setMessageConverters(new MappingJackson2HttpMessageConverter(JacksonConfig.mapper()))
            .build();
    }

    private OpenStatus openStatus() {
        return new OpenStatus(true, 47, false, 1.0, "Asia/Ho_Chi_Minh");
    }

    private PlaceView view() {
        return new PlaceView("plc_1", "Bún bò", "12 Lê Lợi",
            new Geo(10.7, 106.7), "walk", 420, 6, 2,
            new PriceRange(35000L, 55000L), 42000L, 4.41, 4.28, 182,
            openStatus(), List.of("Món nước"),
            List.of(new DishHighlight("dsh_01", "Bún bò Huế", 0.93, 45000L)),
            List.of("top_rated"),
            new Source("osm", "2026-08-14T00:00:00Z", 0.81),
            new ScoreBreakdown(68.85, "Q", List.of(new ScoreComponent("Q", "err.score.q", 0.9, 0.35))),
            new Why("4,3★ · 420 m", List.of("bullet"), "why.headline", Map.of("rating", "4.3")));
    }

    @Test
    void detail_is_flattened_top_level_snake_case() throws Exception {
        PlaceView v = view();
        PlaceDetailResponse detail = new PlaceDetailResponse(
            v.id(), v.name(), v.address(), v.geo(), v.travelMode(), v.distanceM(), v.walkMinutes(),
            v.priceLevel(), v.priceRange(), v.avgPriceVnd(), v.ratingRaw(), v.ratingBayesian(),
            v.reviewCount(), v.openStatus(), v.cuisineTags(), v.dishHighlights(), v.badges(),
            v.source(), v.scoreBreakdown(), v.why(),
            List.of(new HoursByDow(1, "06:30", "21:00", false)),
            new Menu(List.of(new MenuDish("dsh_01", "Bún bò Huế", 45000L, 0.93, true)),
                "community", "2026-08-14T00:00:00Z"),
            List.of(),
            new Reviews(new ReviewsSummary(4.41, 182, new VerdictSplit(141, 28, 13)), List.of()),
            new Contact(null, null, null),
            new ReportSummary(2, 1, "wrong_hours", true, 0),
            List.of(new SimilarPlace("plc_2", "Khác", 640)));
        when(svc.detail(eq("plc_1"), any())).thenReturn(detail);

        mvc.perform(get("/v1/places/plc_1"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.id").value("plc_1"))
            .andExpect(jsonPath("$.score_breakdown.score_total").value(68.85))
            .andExpect(jsonPath("$.price_range_vnd.min").value(35000))
            .andExpect(jsonPath("$.open_status.is_open").value(true))
            .andExpect(jsonPath("$.hours_by_dow[0].is_closed").value(false))
            .andExpect(jsonPath("$.menu.dishes[0].dish_id").value("dsh_01"))
            .andExpect(jsonPath("$.report_summary.can_report").value(true));
    }

    @Test
    void urgent_decision_has_documented_fields() throws Exception {
        UrgentResponse urgent = new UrgentResponse(view(),
            new Decision(2500, true, 22, "navigate",
                new FallbackDish("dsh_01", "Bún bò Huế", "urgent.nearby_match"), null),
            List.of(), openStatus(),
            new Meta("fresh", "2026-11-01T03:20:00Z", 0, List.of("db"), Map.of(), 640));
        when(svc.urgent(any(), any(), any(), any(), any(), any(), any(), any())).thenReturn(urgent);
        mvc.perform(get("/v1/places/urgent"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.place.id").value("plc_1"))
            .andExpect(jsonPath("$.decision.radius_m_used").value(2500))
            .andExpect(jsonPath("$.decision.expanded").value(true))
            .andExpect(jsonPath("$.decision.candidates_considered").value(22))
            .andExpect(jsonPath("$.decision.one_tap_action").value("navigate"))
            .andExpect(jsonPath("$.open_status.is_open").value(true))
            .andExpect(jsonPath("$.meta.latency_ms").value(640));
    }

    @Test
    void nearby_has_items_page_and_context() throws Exception {
        NearbyResponse nearby = new NearbyResponse(List.of(view()),
            new PageMeta("c1", true, 37L),
            new Context(new Anchor(new Geo(10.779, 106.702), "anchor"), 1500,
                List.of("dsh_01"), "2026-11-01T03:20:00Z"),
            null, null,
            new Meta("fresh", "2026-11-01T03:20:00Z", 0, List.of("db"), Map.of(), null));
        when(svc.nearby(any(), any())).thenReturn(nearby);

        mvc.perform(get("/v1/places/nearby").param("geo", "10.779,106.702").param("radius_m", "1500"))
            .andExpect(status().isOk())
            .andExpect(jsonPath("$.items[0].id").value("plc_1"))
            .andExpect(jsonPath("$.page.has_more").value(true))
            .andExpect(jsonPath("$.context.radius_m").value(1500))
            .andExpect(jsonPath("$.context.anchor.geo.lat").value(10.779));
    }

    @Test
    void report_ack_matches_contract() throws Exception {
        when(svc.report(eq("plc_1"), any(), any(), any(), any()))
            .thenReturn(new ReportResponse("rpt_1", "open", true, false, true, 300, null));

        String body = """
            {"kind":"wrong_hours"}
            """;
        mvc.perform(post("/v1/places/plc_1/reports")
                .header("X-Idempotency-Key", "idem-1")
                .contentType("application/json")
                .content(body))
            .andExpect(status().isCreated())
            .andExpect(jsonPath("$.report_id").value("rpt_1"))
            .andExpect(jsonPath("$.queued_for_review").value(true))
            .andExpect(jsonPath("$.affects_ranking_after_review").value(true));
    }
}

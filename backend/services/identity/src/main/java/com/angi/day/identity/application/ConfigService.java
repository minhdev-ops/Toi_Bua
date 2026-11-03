package com.angi.day.identity.application;

import org.springframework.stereotype.Service;

import java.util.List;
import java.util.Map;

/**
 * Remote config (docs/02 §5.1). This is the single source of business constants
 * for the app: weights, radii, timeouts, flags. Values are served from memory in P1
 * and move to DB/admin in P2.
 */
@Service
public class ConfigService {

    public Map<String, Object> config() {
        return Map.ofEntries(
            Map.entry("config_version", "2026.11.01.3"),
            Map.entry("policy_version", "2026.10"),
            Map.entry("min_app_version", Map.of("ios", "1.2.0", "android", "1.2.0")),
            Map.entry("force_upgrade", false),
            Map.entry("flags", Map.of(
                "roulette_v2", "on",
                "group_rooms", "off",
                "journal", "off",
                "reviews", "off",
                "weather_context", "off",
                "merchant_portal", "off")),
            Map.entry("ranking_weights", Map.of(
                "Q", 0.35, "D", 0.25, "P", 0.15, "O", 0.15, "U", 0.10, "version", "2026.10")),
            Map.entry("spin", Map.of(
                "anti_repeat_days_default", 3,
                "tau_days", 3.0,
                "min_pool", 3,
                "rate_limit_per_min", 60)),
            Map.entry("place", Map.of(
                "radius_default_m", 1500,
                "radius_max_m", 5000,
                "closing_soon_min", 30,
                "open_min_left_to_score_1", 45,
                "urgent_radius_steps", List.of(1500, 2500, 4000))),
            Map.entry("animation_styles", List.of("wheel", "chest", "draw")),
            Map.entry("locale_supported", List.of("vi", "en")),
            Map.entry("dish_bundle_version", 20261101),
            Map.entry("feature_gates", Map.of(
                "requires_consent_location", List.of("places_nearby", "urgent"),
                "requires_account", List.of("lists", "sync", "share_card"))),
            Map.entry("experiments", Map.of("ranking_weights_v2", "control"))
        );
    }
}

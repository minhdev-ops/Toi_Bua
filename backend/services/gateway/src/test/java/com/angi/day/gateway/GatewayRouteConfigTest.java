package com.angi.day.gateway;

import org.junit.jupiter.api.Test;
import org.springframework.beans.factory.config.YamlPropertiesFactoryBean;
import org.springframework.core.io.ClassPathResource;

import java.util.Comparator;
import java.util.List;
import java.util.Map;
import java.util.Properties;

import static org.assertj.core.api.Assertions.assertThat;

/**
 * Chặn tái phát lỗi định tuyến: Spring AND mọi predicate trong CÙNG một route
 * (RouteDefinitionRouteLocator dùng Predicate.and). Hai dòng "- Path=..." vì thế
 * tạo ra điều kiện không bao giờ đúng và route chết im lặng — 404 cho mọi request.
 */
class GatewayRouteConfigTest {

    private static final Map<String, List<String>> EXPECTED = Map.of(
        "identity", List.of("/v1/auth/**", "/v1/me/**", "/v1/config", "/.well-known/jwks.json"),
        "roulette", List.of("/v1/dishes/**", "/v1/spins/**", "/v1/exclusions"),
        "place", List.of("/v1/places/**", "/v1/geocode", "/v1/user-locations/**", "/v1/matches"),
        "ranking", List.of("/v1/rank/**"),
        "journal", List.of("/v1/journal/**")
    );

    private Properties routesYaml() {
        YamlPropertiesFactoryBean yaml = new YamlPropertiesFactoryBean();
        yaml.setResources(new ClassPathResource("application.yml"));
        Properties props = yaml.getObject();
        assertThat(props).isNotNull();
        return props;
    }

    @Test
    void mỗi_route_chỉ_có_đúng_một_predicate_Path() {
        Properties props = routesYaml();
        EXPECTED.keySet().forEach(routeId -> assertThat(predicatesOf(props, routeId))
            .as("route %s: nhiều predicate bị AND lại nên route sẽ không bao giờ khớp", routeId)
            .hasSize(1));
    }

    @Test
    void predicate_Path_giữ_đủ_pattern_của_từng_route() {
        Properties props = routesYaml();
        EXPECTED.forEach((routeId, patterns) -> {
            String predicate = predicatesOf(props, routeId).get(0);
            assertThat(predicate).startsWith("Path=");
            assertThat(predicate.substring("Path=".length()).split(","))
                .as("route %s", routeId)
                .containsExactlyInAnyOrderElementsOf(patterns);
        });
    }

    private static List<String> predicatesOf(Properties props, String routeId) {
        String prefix = "spring.cloud.gateway.routes[" + indexOf(props, routeId) + "].predicates";
        return props.stringPropertyNames().stream()
            .filter(n -> n.startsWith(prefix + "["))
            .sorted(Comparator.comparingInt(GatewayRouteConfigTest::listIndex))
            .map(props::getProperty)
            .toList();
    }

    private static int listIndex(String name) {
        int open = name.lastIndexOf('[');
        return Integer.parseInt(name.substring(open + 1, name.length() - 1));
    }

    private static int indexOf(Properties props, String routeId) {
        for (String name : props.stringPropertyNames()) {
            if (name.endsWith(".id") && routeId.equals(props.getProperty(name))) {
                String prefix = name.substring(0, name.length() - ".id".length());
                return Integer.parseInt(prefix.substring(prefix.lastIndexOf('[') + 1, prefix.length() - 1));
            }
        }
        throw new AssertionError("Không tìm thấy route " + routeId);
    }
}

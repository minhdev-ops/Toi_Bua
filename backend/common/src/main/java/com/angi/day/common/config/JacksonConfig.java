package com.angi.day.common.config;

import com.fasterxml.jackson.annotation.JsonInclude;
import com.fasterxml.jackson.databind.ObjectMapper;
import com.fasterxml.jackson.databind.PropertyNamingStrategies;
import com.fasterxml.jackson.databind.SerializationFeature;
import com.fasterxml.jackson.datatype.jsr310.JavaTimeModule;
import org.springframework.boot.autoconfigure.jackson.Jackson2ObjectMapperBuilderCustomizer;
import org.springframework.context.annotation.Bean;
import org.springframework.context.annotation.Configuration;
import org.springframework.http.converter.json.Jackson2ObjectMapperBuilder;

/**
 * Enforces the API wire contract (docs/02): snake_case keys, drop absent keys,
 * RFC3339 timestamps (no epoch numbers). Shared by every service via component scan,
 * and reused by tests through mapper() so tests exercise the real wire format.
 */
@Configuration
public class JacksonConfig {

    @Bean
    public Jackson2ObjectMapperBuilderCustomizer angiJacksonCustomizer() {
        return JacksonConfig::configure;
    }

    public static void configure(Jackson2ObjectMapperBuilder builder) {
        builder.propertyNamingStrategy(PropertyNamingStrategies.SNAKE_CASE);
        builder.serializationInclusion(JsonInclude.Include.NON_NULL);
        builder.featuresToDisable(SerializationFeature.WRITE_DATES_AS_TIMESTAMPS);
    }

    public static ObjectMapper mapper() {
        Jackson2ObjectMapperBuilder b = new Jackson2ObjectMapperBuilder();
        configure(b);
        b.modules(new JavaTimeModule());
        return b.build();
    }
}

package com.angi.day.common.redis;

import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;
import java.util.Optional;

@Component
public class RedisCache {
    private final StringRedisTemplate redis;
    private final ObjectMapper mapper;

    public RedisCache(StringRedisTemplate redis, ObjectMapper mapper) {
        this.redis = redis;
        this.mapper = mapper;
    }

    public <T> Optional<T> get(String key, Class<T> type) {
        String v = redis.opsForValue().get(key);
        if (v == null) return Optional.empty();
        try {
            return Optional.of(mapper.readValue(v, type));
        } catch (Exception e) {
            return Optional.empty();
        }
    }

    public void set(String key, Object value, Duration ttl) {
        try {
            redis.opsForValue().set(key, mapper.writeValueAsString(value), ttl);
        } catch (Exception ignored) {
        }
    }

    public void evict(String key) {
        redis.delete(key);
    }
}

package com.angi.day.common.redis;

import org.springframework.data.redis.core.StringRedisTemplate;
import org.springframework.stereotype.Component;

import java.time.Duration;

@Component
public class DistributedLock {
    private final StringRedisTemplate redis;

    public DistributedLock(StringRedisTemplate redis) {
        this.redis = redis;
    }

    public boolean tryLock(String key, Duration ttl) {
        Boolean ok = redis.opsForValue().setIfAbsent(key, "1", ttl);
        return Boolean.TRUE.equals(ok);
    }

    public void unlock(String key) {
        redis.delete(key);
    }
}

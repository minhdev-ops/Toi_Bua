package com.angi.day.roulette.application;

import com.angi.day.common.error.ApiErrorCode;
import com.angi.day.common.error.ApiException;
import com.angi.day.common.page.CursorSigner;
import com.angi.day.common.redis.RedisCache;
import com.angi.day.roulette.domain.Spin;
import com.angi.day.roulette.infrastructure.SpinRepository;
import org.junit.jupiter.api.BeforeEach;
import org.junit.jupiter.api.Test;
import org.mockito.ArgumentCaptor;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Instant;
import java.util.HexFormat;
import java.util.List;
import java.util.Optional;

import static org.junit.jupiter.api.Assertions.assertEquals;
import static org.junit.jupiter.api.Assertions.assertNotNull;
import static org.junit.jupiter.api.Assertions.assertThrows;
import static org.junit.jupiter.api.Assertions.assertTrue;
import static org.mockito.ArgumentMatchers.any;
import static org.mockito.ArgumentMatchers.anyString;
import static org.mockito.ArgumentMatchers.eq;
import static org.mockito.Mockito.mock;
import static org.mockito.Mockito.never;
import static org.mockito.Mockito.verify;
import static org.mockito.Mockito.when;

class RouletteServiceTest {

    private SpinRepository spins;
    private RedisCache redis;
    private RouletteService svc;

    @BeforeEach
    void setUp() {
        spins = mock(SpinRepository.class);
        redis = mock(RedisCache.class);
        svc = new RouletteService(spins, redis, new CursorSigner("test-secret"));
    }

    @Test
    void weighted_sampler_is_deterministic_for_same_seed() {
        List<RouletteService.DishDto> pool = svc.bundle(null).dishes();
        RouletteService.DishDto a = RouletteService.WeightedSampler.pick(pool, "seed-123");
        RouletteService.DishDto b = RouletteService.WeightedSampler.pick(pool, "seed-123");
        assertEquals(a.id(), b.id());
        assertTrue(pool.contains(a));
    }

    @Test
    void spin_stores_seed_and_sha256_proof_and_animation_is_consistent() {
        when(redis.get(anyString(), eq(RouletteService.ExclusionSet.class)))
            .thenReturn(Optional.<RouletteService.ExclusionSet>empty());
        when(spins.save(any(Spin.class))).thenAnswer(inv -> inv.getArgument(0));

        RouletteService.SpinResult r = svc.spin("usr_1", new RouletteService.SpinRequest(null));

        assertNotNull(r.dish());
        assertTrue(r.spinId().startsWith("spn_"));
        assertEquals(6, r.pool().sizeFinal());
        assertNotNull(r.proof());

        ArgumentCaptor<Spin> cap = ArgumentCaptor.forClass(Spin.class);
        verify(spins).save(cap.capture());
        Spin saved = cap.getValue();
        assertEquals(r.spinId(), saved.getId());
        assertEquals("usr_1", saved.getUserId());
        assertEquals(r.dish().id(), saved.getDishId());
        assertNotNull(saved.getSeed());
        assertEquals(sha256(saved.getSeed() + saved.getDishId()), saved.getSha256());
        assertEquals(saved.getSha256(), r.proof().sha256Result());

        // server-guaranteed invariant (docs/02 §3.3): wheel_items[result_index] == dish.id
        var anim = r.animation();
        assertEquals(r.dish().id(), anim.wheelItems().get(anim.resultIndex()));
        assertEquals(anim.resultIndex(), anim.targetPosition() % anim.wheelItems().size());
        assertEquals("/v1/matches", r.next().path());
        assertEquals("fresh", r.meta().dataQuality());
    }

    @Test
    void spin_throws_diet_filter_empty_when_pool_exhausted() {
        List<String> all = svc.bundle(null).dishes().stream().map(RouletteService.DishDto::id).toList();
        when(redis.get(anyString(), eq(RouletteService.ExclusionSet.class)))
            .thenReturn(Optional.of(new RouletteService.ExclusionSet(all)));

        ApiException ex = assertThrows(ApiException.class,
            () -> svc.spin("usr_1", new RouletteService.SpinRequest(null)));

        assertEquals(ApiErrorCode.DIET_FILTER_EMPTY, ex.code());
        assertEquals(422, ex.httpStatus());
        verify(spins, never()).save(any());
    }

    @Test
    void verify_rejects_mismatched_proof() {
        Spin s = new Spin();
        s.setId("spn_1");
        s.setUserId("usr_1");
        s.setDishId("dsh_01");
        s.setSeed("seed");
        s.setSha256("deadbeef");
        s.setCreatedAt(Instant.now());
        when(spins.findById("spn_1")).thenReturn(Optional.of(s));

        ApiException ex = assertThrows(ApiException.class, () -> svc.verify("spn_1", "wrong"));
        assertEquals(ApiErrorCode.CONFLICT, ex.code());
        assertEquals("dsh_01", svc.verify("spn_1", "deadbeef").dishId());
    }

    @Test
    void get_missing_spin_is_not_found() {
        when(spins.findById("nope")).thenReturn(Optional.empty());
        ApiException ex = assertThrows(ApiException.class, () -> svc.get("nope"));
        assertEquals(ApiErrorCode.NOT_FOUND, ex.code());
    }

    private String sha256(String s) {
        try {
            var md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(s.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) {
            throw new IllegalStateException(e);
        }
    }
}

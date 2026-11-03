package com.angi.day.roulette.application;

import com.angi.day.common.error.ApiErrorCode;
import com.angi.day.common.error.ApiException;
import com.angi.day.common.error.ErrorDetailItem;
import com.angi.day.common.id.Ulid;
import com.angi.day.common.page.CursorPage;
import com.angi.day.common.page.CursorSigner;
import com.angi.day.common.page.PageMeta;
import com.angi.day.common.redis.RedisCache;
import com.angi.day.roulette.domain.Spin;
import com.angi.day.roulette.infrastructure.SpinRepository;
import com.fasterxml.jackson.annotation.JsonProperty;
import org.springframework.data.domain.Page;
import org.springframework.data.domain.PageRequest;
import org.springframework.stereotype.Service;

import java.nio.charset.StandardCharsets;
import java.security.MessageDigest;
import java.time.Duration;
import java.time.Instant;
import java.util.ArrayList;
import java.util.Base64;
import java.util.HexFormat;
import java.util.LinkedHashMap;
import java.util.List;
import java.util.Map;
import java.util.stream.Collectors;

@Service
public class RouletteService {

    private final SpinRepository spins;
    private final RedisCache redis;
    private final CursorSigner cursorSigner;

    public RouletteService(SpinRepository spins, RedisCache redis, CursorSigner cursorSigner) {
        this.spins = spins;
        this.redis = redis;
        this.cursorSigner = cursorSigner;
    }

    // ---- static seed (Phase 1; replace by catalog service / DB later) ----
    public record DishDto(String id, String name, String nameEn, String categoryId, List<String> categoryPath, String region, String temp, List<String> meal, List<TagDto> tags, int priceLevel, String imageUrl, @JsonProperty("is_excluded") boolean isExcluded) {}
    public record TagDto(String id, String kind, String label) {}
    public record CategoryDto(String id, String name, String parentId) {}
    public record TaxonomyResponse(List<CategoryDto> categories, List<TagDto> tags) {}
    public record BundleResponse(String version, List<DishDto> dishes) {}

    /** Input docs/02 §3.3. Unknown fields (filters/locked/diet/...) are ignored in P1. */
    public record SpinRequest(List<String> excludeDishIds) {}

    // ---- response DTOs matching docs/02 §3.3 exactly ----
    public record AnimationDto(String style, int durationMs, boolean reduceMotion, boolean sound,
                               boolean haptics, int targetPosition, List<String> wheelItems, int resultIndex) {}
    public record ProofDto(String seedB64, String sha256Result, String algorithm, String poolHash, String verifyUrl) {}
    public record PoolRemovedDto(int dietHard, int excluded, int locked, int filters, int antiRepeat) {}
    public record PoolDto(int sizeInitial, int sizeAfterHardFilters, int sizeFinal, PoolRemovedDto removed) {}
    public record AntiRepeatItemDto(String dishId, double factor, int daysSince) {}
    public record AntiRepeatDto(int daysWindow, double tauDays, List<AntiRepeatItemDto> applied, double maxPenalty) {}
    public record NextActionDto(String action, String method, String path, Map<String, Object> suggestedBody) {}
    public record SpinMetaDto(String dataQuality, boolean personalizationUsed, Map<String, String> experimentArms) {}
    public record SpinResult(String spinId, String createdAt, DishDto dish, ProofDto proof, PoolDto pool,
                             AntiRepeatDto antiRepeat, Map<String, Object> appliedFilters,
                             AnimationDto animation, NextActionDto next, SpinMetaDto meta) {}

    public record SpinView(String id, String dishId, String seed, String createdAt) {}
    public record ExclusionSet(List<String> ids) {}

    private static final List<DishDto> DISHES = List.of(
        new DishDto("dsh_01", "Phở bò", "Beef pho", "cat_noodle", List.of("món nước", "phở"), "north", "hot", List.of("breakfast", "lunch", "dinner"), List.of(new TagDto("tag_beef", "cuisine", "bò")), 2, null, false),
        new DishDto("dsh_02", "Bún bò Huế", "Hue beef noodle", "cat_noodle", List.of("món nước", "bún"), "central", "hot", List.of("lunch", "dinner"), List.of(new TagDto("tag_spicy", "attribute", "cay")), 2, null, false),
        new DishDto("dsh_03", "Cơm tấm", "Broken rice", "cat_rice", List.of("cơm"), "south", "hot", List.of("lunch", "dinner"), List.of(new TagDto("tag_pork", "cuisine", "heo")), 2, null, false),
        new DishDto("dsh_04", "Bánh mì", "Banh mi", "cat_bread", List.of("bánh mì"), "south", "any", List.of("breakfast", "lunch", "late_night"), List.of(new TagDto("tag_pork", "cuisine", "heo")), 1, null, false),
        new DishDto("dsh_05", "Gỏi cuốn", "Spring rolls", "cat_snack", List.of("cuốn"), "south", "cold", List.of("lunch", "dinner"), List.of(new TagDto("tag_veg", "diet", "chay")), 1, null, false),
        new DishDto("dsh_06", "Chè", "Sweet soup", "cat_dessert", List.of("tráng miệng"), "south", "cold", List.of("any"), List.of(), 1, null, false)
    );

    public TaxonomyResponse taxonomy() {
        List<CategoryDto> cats = List.of(
            new CategoryDto("cat_noodle", "Món nước", null),
            new CategoryDto("cat_rice", "Cơm", null),
            new CategoryDto("cat_bread", "Bánh mì", null),
            new CategoryDto("cat_snack", "Cuốn", null),
            new CategoryDto("cat_dessert", "Tráng miệng", null));
        List<TagDto> tags = List.of(
            new TagDto("tag_beef", "cuisine", "bò"),
            new TagDto("tag_pork", "cuisine", "heo"),
            new TagDto("tag_spicy", "attribute", "cay"),
            new TagDto("tag_veg", "diet", "chay"));
        return new TaxonomyResponse(cats, tags);
    }

    public BundleResponse bundle(String sinceVersion) {
        return new BundleResponse("20261101", DISHES);
    }

    public SpinResult spin(String userId, SpinRequest req) {
        List<String> excl = exclusions(userId);
        List<String> reqExcl = req != null && req.excludeDishIds() != null ? req.excludeDishIds() : List.of();

        List<DishDto> pool = new ArrayList<>();
        int removedExcluded = 0;
        for (DishDto d : DISHES) {
            if (excl.contains(d.id()) || reqExcl.contains(d.id())) {
                removedExcluded++;
                continue;
            }
            pool.add(d);
        }
        if (pool.isEmpty()) {
            throw new ApiException(ApiErrorCode.DIET_FILTER_EMPTY, "No dish left after exclusions",
                List.of(new ErrorDetailItem("exclude_dish_ids", "conflict", null, reqExcl, "err.diet.empty")));
        }

        String seed = Long.toUnsignedString(new java.security.SecureRandom().nextLong(), 36);
        DishDto chosen = WeightedSampler.pick(pool, seed);
        String hash = sha256(seed + chosen.id());
        String poolHash = sha256(pool.stream().map(DishDto::id).sorted().collect(Collectors.joining(",")));
        String spinId = Ulid.generate("spn_");
        Instant now = Instant.now();

        Spin s = new Spin();
        s.setId(spinId);
        s.setUserId(userId);
        s.setDishId(chosen.id());
        s.setSeed(seed);
        s.setSha256(hash);
        s.setCreatedAt(now);
        spins.save(s);

        List<String> wheelItems = pool.stream().map(DishDto::id).collect(Collectors.toList());
        int resultIndex = wheelItems.indexOf(chosen.id());
        int targetPosition = resultIndex + wheelItems.size() * 4;

        ProofDto proof = new ProofDto(
            Base64.getEncoder().encodeToString(seed.getBytes(StandardCharsets.UTF_8)),
            hash, "weighted-csprng-v1", poolHash, "/v1/spins/" + spinId + "/verify");
        PoolDto poolDto = new PoolDto(DISHES.size(), pool.size(), pool.size(),
            new PoolRemovedDto(0, removedExcluded, 0, 0, 0));
        AntiRepeatDto antiRepeat = new AntiRepeatDto(3, 3.0, List.of(), 0.0);
        AnimationDto animation = new AnimationDto("wheel", 2600, false, true, true,
            targetPosition, wheelItems, resultIndex);
        Map<String, Object> suggested = new LinkedHashMap<>();
        suggested.put("dish_id", chosen.id());
        suggested.put("radius_m", 1500);
        suggested.put("limit", 3);
        NextActionDto next = new NextActionDto("fetch_places", "POST", "/v1/matches", suggested);
        SpinMetaDto meta = new SpinMetaDto("fresh", false, Map.of());

        return new SpinResult(spinId, now.toString(), chosen, proof, poolDto, antiRepeat,
            Map.of(), animation, next, meta);
    }

    public SpinView get(String id) {
        Spin s = spins.findById(id).orElseThrow(() -> new ApiException(ApiErrorCode.NOT_FOUND, "spin not found"));
        return toView(s);
    }

    public SpinView verify(String id, String sha256) {
        Spin s = spins.findById(id).orElseThrow(() -> new ApiException(ApiErrorCode.NOT_FOUND, "spin not found"));
        if (!s.getSha256().equals(sha256)) {
            throw new ApiException(ApiErrorCode.CONFLICT, "spin proof mismatch");
        }
        return toView(s);
    }

    public CursorPage<SpinView> list(String userId, String cursor, int limit) {
        int offset = 0;
        if (cursor != null && !cursor.isBlank()) {
            Map<String, Object> m = cursorSigner.decode(cursor);
            offset = ((Number) m.getOrDefault("o", 0)).intValue();
        }
        Page<Spin> page = spins.findByUserIdOrderByCreatedAtDesc(userId, PageRequest.of(offset / limit, limit));
        List<SpinView> items = new ArrayList<>();
        for (Spin s : page.getContent()) items.add(toView(s));
        boolean hasMore = offset + limit < page.getTotalElements();
        String next = hasMore ? cursorSigner.encode(Map.of("o", offset + limit)) : null;
        return new CursorPage<>(items, new PageMeta(next, hasMore, page.getTotalElements()));
    }

    public List<String> exclusions(String userId) {
        return redis.get(key(userId), ExclusionSet.class).map(ExclusionSet::ids).orElse(List.of());
    }

    public void setExclusions(String userId, List<String> ids) {
        redis.set(key(userId), new ExclusionSet(ids), Duration.ofDays(30));
    }

    private String key(String u) { return "excl:" + u; }

    private SpinView toView(Spin s) {
        return new SpinView(s.getId(), s.getDishId(), s.getSeed(), s.getCreatedAt().toString());
    }

    private String sha256(String s) {
        try {
            var md = MessageDigest.getInstance("SHA-256");
            return HexFormat.of().formatHex(md.digest(s.getBytes(StandardCharsets.UTF_8)));
        } catch (Exception e) { throw new IllegalStateException(e); }
    }

    public static class WeightedSampler {
        public static DishDto pick(List<DishDto> pool, String seedStr) {
            long s = 0;
            for (byte x : seedStr.getBytes(StandardCharsets.UTF_8)) s = s * 31 + x;
            java.util.Random r = new java.util.Random(s);
            return pool.get(r.nextInt(pool.size()));
        }
    }
}

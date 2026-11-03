package com.angi.day.place.application;

import com.angi.day.common.error.ApiException;
import com.angi.day.common.error.ApiErrorCode;
import com.angi.day.common.id.Ulid;
import com.angi.day.common.page.CursorSigner;
import com.angi.day.common.page.PageMeta;
import com.angi.day.place.api.dto.PlaceDtos.*;
import com.angi.day.place.api.dto.PlaceRequests.*;
import com.angi.day.place.domain.Place;
import com.angi.day.place.domain.Report;
import com.angi.day.place.domain.UserLocation;
import com.angi.day.place.infrastructure.PlaceRepository;
import com.angi.day.place.infrastructure.ReportRepository;
import com.angi.day.place.infrastructure.UserLocationRepository;
import com.fasterxml.jackson.core.type.TypeReference;
import com.fasterxml.jackson.databind.ObjectMapper;
import org.springframework.stereotype.Service;

import java.time.Instant;
import java.time.ZoneId;
import java.time.format.DateTimeFormatter;
import java.util.*;
import java.util.stream.Collectors;

@Service
public class PlaceService {

    private static final double EARTH_R = 6371000.0;
    private static final double WALK_SPEED = 80.0;
    private static final double BIKE_SPEED = 250.0;
    private static final double CAR_SPEED = 600.0;
    private static final List<Integer> URGENT_STEPS = List.of(1500, 2500, 4000);
    private static final Set<String> REPORT_KINDS = Set.of(
        "closed", "wrong_hours", "wrong_price", "wrong_location", "wrong_name", "duplicate", "other");

    private final PlaceRepository placeRepo;
    private final ReportRepository reportRepo;
    private final UserLocationRepository ulRepo;
    private final RankingClient ranking;
    private final CursorSigner cursor;
    private final ObjectMapper mapper;

    public PlaceService(PlaceRepository placeRepo, ReportRepository reportRepo,
                        UserLocationRepository ulRepo, RankingClient ranking,
                        CursorSigner cursor, ObjectMapper mapper) {
        this.placeRepo = placeRepo;
        this.reportRepo = reportRepo;
        this.ulRepo = ulRepo;
        this.ranking = ranking;
        this.cursor = cursor;
        this.mapper = mapper;
    }

    private static final Map<String, String[]> DISH_NAMES = Map.of(
        "dsh_01", new String[]{"Bún bò Huế", "Món nước|Bún|Bún bò"},
        "dsh_02", new String[]{"Cơm tấm sườn", "Cơm|Cơm tấm"},
        "dsh_03", new String[]{"Phở bò tái", "Món nước|Phở"},
        "dsh_04", new String[]{"Bánh mì thịt nướng", "Bánh mì|Fast food"},
        "dsh_05", new String[]{"Cơm chay thập cẩm", "Chay|Nhà hàng"},
        "dsh_06", new String[]{"Hủ tiếu Nam Vang", "Món nước|Hủ tiếu"}
    );

    // ---------- nearby ----------
    public NearbyResponse nearby(NearbyQuery q, String userId) {
        double[] anchor = resolveAnchor(q.geo(), q.userLocationId(), q.address());
        int radius = clamp(q.radiusM(), 200, 5000, 1500);
        boolean openNow = q.openNow() == null || q.openNow();
        List<String> wantDishes = q.dishIds();

        List<Scored> scored = candidates(anchor, radius, openNow, wantDishes, null, false)
            .stream().map(s -> new Scored(s, buildView(s, anchor[0], anchor[1],
                travelMode(q.travelMode()), q.budgetVnd(), firstDish(wantDishes), 0.0)))
            .collect(Collectors.toList());

        sortScored(scored, q.sort());
        int total = scored.size();

        int limit = clamp(q.limit(), 1, 50, 20);
        int offset = decodeOffset(q.cursor());
        List<PlaceView> page = scored.stream().skip(offset).limit(limit).map(Scored::view).collect(Collectors.toList());
        boolean hasMore = offset + limit < total;
        String nextCursor = hasMore ? cursor.encode(Map.of("o", offset + limit)) : null;

        Context ctx = new Context(new Anchor(new Geo(anchor[0], anchor[1]), "anchor"),
            radius, wantDishes, nowUtc());
        Meta meta = new Meta("fresh", nowUtc(), 0, List.of("db"), Map.of(), null);
        return new NearbyResponse(page, new PageMeta(nextCursor, hasMore, (long) total), ctx, null, null, meta);
    }

    // ---------- matches ----------
    public MatchesResponse matches(MatchesRequest req, String userId) {
        String dishId = req.dishId() != null ? req.dishId()
            : (req.dishIds() != null && !req.dishIds().isEmpty() ? req.dishIds().get(0) : null);
        if (dishId == null) throw new ApiException(ApiErrorCode.VALIDATION_FAILED, "dish_id or dish_ids is required");

        double[] anchor = resolveAnchor(req.geo(), req.userLocationId(), req.address());
        int radius = clamp(req.radiusM(), 200, 5000, 1500);
        int limit = clamp(req.limit(), 1, 10, 3);
        Long budget = req.filters() != null ? req.filters().budgetVnd() : null;
        boolean includeClosed = req.includeClosed() != null && req.includeClosed();
        List<String> exclude = req.excludePlaceIds() != null ? req.excludePlaceIds() : List.of();

        List<Place> cands = candidates(anchor, radius, !includeClosed, List.of(dishId), exclude, includeClosed);
        List<Scored> scored = cands.stream().map(p -> new Scored(p, buildView(p, anchor[0], anchor[1],
            travelMode(req.travelMode()), budget, dishId, 0.0))).collect(Collectors.toList());
        sortScored(scored, "score");
        List<PlaceView> items = scored.stream().limit(limit).map(Scored::view).collect(Collectors.toList());

        Relaxation relaxation;
        if (items.isEmpty()) {
            relaxation = new Relaxation(false, List.of(
                new RelaxStep("radius_m", radius, Math.min(5000, radius + 1000), 12, "relax.radius"),
                new RelaxStep("price_level_max", 2, 3, 4, "relax.price")));
        } else {
            relaxation = new Relaxation(false, List.of());
        }

        DishRef dishRef = buildDishRef(dishId);
        ContextUsed ctxUsed = new ContextUsed(localTime(), dow(), "auto", false, Map.of());
        Meta meta = new Meta("fresh", nowUtc(), 0, List.of("db"), Map.of(), null);
        return new MatchesResponse(dishRef, items, relaxation, List.of(), ctxUsed, meta);
    }

    // ---------- urgent ----------
    public UrgentResponse urgent(String geo, String userLocationId, String address,
                                 Integer radiusM, String travelMode, Long budgetVnd,
                                 String dishId, String userId) {
        double[] anchor = (geo != null || userLocationId != null || address != null)
            ? resolveAnchor(geo, userLocationId, address) : new double[]{10.7760, 106.7000};
        String tm = travelMode(travelMode);

        for (int r : URGENT_STEPS) {
            List<Place> open = placeRepo.findByActiveTrue().stream()
                .filter(p -> distance(anchor[0], anchor[1], p.getLat(), p.getLng()) <= r)
                .filter(p -> Boolean.TRUE.equals(p.getOpenNow()))
                .filter(p -> p.getClosesInMin() == null || p.getClosesInMin() >= 45)
                .collect(Collectors.toList());
            if (!open.isEmpty()) {
                Place best = open.stream().max(Comparator.comparingDouble(p ->
                    scoreOnly(p, anchor, tm, budgetVnd, dishId, 0.0))).orElse(open.get(0));
                PlaceView view = buildView(best, anchor[0], anchor[1], tm, budgetVnd, dishId, 0.0);
                FallbackDish fallback = new FallbackDish(
                    dishId != null ? dishId : best.getId(), best.getName(), "urgent.nearby_match");
                return new UrgentResponse(view,
                    new Decision(r, false, open.size(), "navigate", fallback, null),
                    List.of(), view.openStatus(),
                    new Meta("fresh", nowUtc(), 0, List.of("db"), Map.of(), 640));
            }
        }
        // none open within 4km -> alternatives = soon-to-open (highest rated not open)
        List<Alternative> alts = placeRepo.findByActiveTrue().stream()
            .filter(p -> !Boolean.TRUE.equals(p.getOpenNow()))
            .sorted(Comparator.comparingDouble(Place::getRatingRaw).reversed())
            .limit(3)
            .map(p -> new Alternative(p.getId(), p.getName(),
                (int) Math.round(distance(anchor[0], anchor[1], p.getLat(), p.getLng())),
                "alt.open_later", Map.of()))
            .collect(Collectors.toList());
        return new UrgentResponse(null,
            new Decision(4000, true, 0, "navigate", null, "urgent.none_open"),
            alts, null,
            new Meta("fresh", nowUtc(), 0, List.of("db"), Map.of(), 640));
    }

    // ---------- detail ----------
    public PlaceDetailResponse detail(String id, String sections) {
        Place p = placeRepo.findById(id).orElse(null);
        if (p == null || !Boolean.TRUE.equals(p.getActive())) {
            throw new ApiException(ApiErrorCode.NOT_FOUND, "place not found");
        }
        PlaceView view = buildView(p, p.getLat(), p.getLng(), "walk", null, null, 0.0);
        List<HoursByDow> hours = new ArrayList<>();
        for (int d = 1; d <= 7; d++) hours.add(new HoursByDow(d, "06:30", "21:00", false));
        List<MenuDish> dishes = parseDishHighlights(p).stream()
            .map(h -> new MenuDish(h.dishId(), h.name(), h.priceVnd() == null ? 0 : h.priceVnd(),
                h.confidence(), false)).collect(Collectors.toList());
        Menu menu = new Menu(dishes, "community", "2026-08-14T00:00:00Z");
        Reviews reviews = new Reviews(new ReviewsSummary(p.getRatingRaw(), p.getReviewCount(),
            new VerdictSplit((int) (p.getReviewCount() * 0.7), (int) (p.getReviewCount() * 0.2),
                p.getReviewCount() - (int) (p.getReviewCount() * 0.9))), List.of());
        Contact contact = new Contact(null, null, null);
        ReportSummary rs = new ReportSummary(p.getReportCount30d(), 0, "none", true, 0);
        List<SimilarPlace> sims = placeRepo.findByActiveTrue().stream()
            .filter(x -> !x.getId().equals(id))
            .sorted(Comparator.comparingDouble(x -> distance(p.getLat(), p.getLng(), x.getLat(), x.getLng())))
            .limit(3)
            .map(x -> new SimilarPlace(x.getId(), x.getName(),
                (int) Math.round(distance(p.getLat(), p.getLng(), x.getLat(), x.getLng()))))
            .collect(Collectors.toList());
        return new PlaceDetailResponse(
            view.id(), view.name(), view.address(), view.geo(), view.travelMode(),
            view.distanceM(), view.walkMinutes(), view.priceLevel(), view.priceRange(),
            view.avgPriceVnd(), view.ratingRaw(), view.ratingBayesian(), view.reviewCount(),
            view.openStatus(), view.cuisineTags(), view.dishHighlights(), view.badges(),
            view.source(), view.scoreBreakdown(), view.why(),
            hours, menu, List.of(), reviews, contact, rs, sims);
    }

    // ---------- report ----------
    public ReportResponse report(String placeId, ReportRequest req, String idempotencyKey,
                                 String userId, String deviceId) {
        if (placeRepo.findById(placeId).isEmpty()) {
            throw new ApiException(ApiErrorCode.NOT_FOUND, "place not found");
        }
        if (req.kind() == null || !REPORT_KINDS.contains(req.kind())) {
            throw new ApiException(ApiErrorCode.VALIDATION_FAILED, "invalid report kind");
        }
        String day = nowUtc().substring(0, 10);
        String dedup = placeId + "|" + req.kind() + "|" + (userId != null ? userId : deviceId) + "|" + day;
        Optional<Report> existing = reportRepo.findActiveByDedupKey(dedup);
        if (existing.isPresent()) {
            return new ReportResponse(existing.get().getId(), existing.get().getStatus(), false,
                false, false, 300, existing.get().getId());
        }
        Report r = new Report();
        r.setId(Ulid.generate("rpt_"));
        r.setPlaceId(placeId);
        r.setKind(req.kind());
        r.setDetail(req.detail());
        r.setSuggestedValueJson(toJson(req.suggestedValue()));
        r.setObservationGeo(req.observationGeo() != null ? req.observationGeo().lat() + "," + req.observationGeo().lng() : null);
        r.setObservationAt(req.observationAt() != null ? Instant.parse(req.observationAt()) : Instant.now());
        r.setUploadIdsJson(toJson(req.uploadIds()));
        r.setUserId(userId);
        r.setDeviceId(deviceId);
        r.setStatus("open");
        r.setDedupKey(dedup);
        r.setCreatedAt(Instant.now());
        reportRepo.save(r);
        return new ReportResponse(r.getId(), "open", true, false, true, 300, null);
    }

    // ---------- geocode stub ----------
    public GeoResponse geocode(String address) {
        return new GeoResponse(10.7760, 106.7000, address, "stub");
    }

    // ---------- user locations ----------
    public List<UserLocation> listUserLocations(String userId) {
        return ulRepo.findByUserId(userId);
    }

    public UserLocation createUserLocation(UserLocationRequest req, String userId) {
        UserLocation ul = new UserLocation();
        ul.setId(Ulid.generate("ulc_"));
        ul.setUserId(userId);
        ul.setLabel(req.label());
        ul.setLat(req.geo() != null ? req.geo().lat() : null);
        ul.setLng(req.geo() != null ? req.geo().lng() : null);
        ul.setAddress(req.address());
        return ulRepo.save(ul);
    }

    public void deleteUserLocation(String id, String userId) {
        ulRepo.findById(id).ifPresent(ul -> {
            if (userId == null || userId.equals(ul.getUserId())) ulRepo.delete(ul);
        });
    }

    // ---------- internals ----------
    private List<Place> candidates(double[] anchor, int radius, boolean openOnly,
                                   List<String> wantDishes, List<String> exclude, boolean includeClosed) {
        return placeRepo.findByActiveTrue().stream()
            .filter(p -> distance(anchor[0], anchor[1], p.getLat(), p.getLng()) <= radius)
            .filter(p -> exclude == null || !exclude.contains(p.getId()))
            .filter(p -> !openOnly || Boolean.TRUE.equals(p.getOpenNow()) || includeClosed)
            .filter(p -> wantDishes == null || wantDishes.isEmpty() || servesDish(p, wantDishes))
            .collect(Collectors.toList());
    }

    private boolean servesDish(Place p, List<String> want) {
        return parseDishHighlights(p).stream().anyMatch(h -> want.contains(h.dishId()));
    }

    private double scoreOnly(Place p, double[] anchor, String tm, Long budget, String dishId, double u) {
        RankingClient.ScoreResult r = ranking.score(toCandidate(p, anchor, tm, budget, dishId, u));
        return r.scoreTotal();
    }

    private PlaceView buildView(Place p, double aLat, double aLng, String tm, Long budget,
                                String dishId, double u) {
        int dist = (int) Math.round(distance(aLat, aLng, p.getLat(), p.getLng()));
        double speed = switch (tm) {
            case "bike" -> BIKE_SPEED; case "car" -> CAR_SPEED; default -> WALK_SPEED;
        };
        int minutes = (int) Math.round(dist / speed);
        double bayes = ((p.getReviewCount() * p.getRatingRaw() + 20 * 4.0) / (p.getReviewCount() + 20));
        RankingClient.ScoreResult sr = ranking.score(toCandidate(p, new double[]{aLat, aLng}, tm, budget, dishId, u));
        List<ScoreComponent> comps = sr.components().stream()
            .map(c -> new ScoreComponent(c.key(), c.messageKey(), c.value(), c.weight()))
            .collect(Collectors.toList());
        String top = comps.stream().max(Comparator.comparingDouble(c -> c.value() * c.weight())).map(ScoreComponent::key).orElse("Q");

        List<String> cuisines = splitCsv(p.getCuisineTags());
        List<String> badges = splitCsv(p.getBadges());
        List<DishHighlight> dh = parseDishHighlights(p).stream()
            .map(h -> new DishHighlight(h.dishId(), h.name(), h.confidence(), h.priceVnd()))
            .collect(Collectors.toList());
        Source src = new Source(p.getSourceProvider(), p.getSourceVerifiedAt(), p.getDataConfidence());
        OpenStatus os = new OpenStatus(Boolean.TRUE.equals(p.getOpenNow()),
            p.getClosesInMin(), Boolean.TRUE.equals(p.getClosingSoon()),
            Boolean.TRUE.equals(p.getOpenNow()) ? 1.0 : 0.0, p.getTz());
        ScoreBreakdown sb = new ScoreBreakdown(sr.scoreTotal(), top, comps);
        Why why = buildWhy(p, dist, minutes, bayes);
        return new PlaceView(p.getId(), p.getName(), p.getAddress(),
            new Geo(p.getLat(), p.getLng()), tm, dist, minutes,
            p.getPriceLevel(), new PriceRange(p.getPriceMinVnd(), p.getPriceMaxVnd()),
            p.getAvgPriceVnd(), p.getRatingRaw(), bayes, p.getReviewCount(),
            os, cuisines, dh, badges, src, sb, why);
    }

    private Why buildWhy(Place p, int dist, int minutes, double bayes) {
        List<String> bullets = new ArrayList<>();
        bullets.add(String.format("%.1f★ từ %d đánh giá", p.getRatingRaw(), p.getReviewCount()));
        bullets.add("Cách bạn " + minutes + " phút đi bộ");
        if (Boolean.TRUE.equals(p.getOpenNow())) bullets.add("Đang mở cửa");
        Map<String, String> params = new LinkedHashMap<>();
        params.put("rating", String.format("%.1f", p.getRatingRaw()));
        params.put("count", String.valueOf(p.getReviewCount()));
        params.put("distance", String.valueOf(dist));
        return new Why(String.format("%.1f★ từ %d đánh giá · cách %d m · đang mở", p.getRatingRaw(), p.getReviewCount(), dist),
            bullets, "why.headline", params);
    }

    private RankingClient.CandidateScore toCandidate(Place p, double[] anchor, String tm, Long budget,
                                                     String dishId, double u) {
        double ratio = p.getReviewCount() > 0 ? (double) p.getReportCount30d() / p.getReviewCount() : 0.0;
        return new RankingClient.CandidateScore(p.getId(), dishId, p.getRatingRaw(), p.getReviewCount(),
            distance(anchor[0], anchor[1], p.getLat(), p.getLng()), tm,
            p.getAvgPriceVnd() == null ? 0 : p.getAvgPriceVnd(), budget,
            Boolean.TRUE.equals(p.getOpenNow()), Boolean.TRUE.equals(p.getStaleVerified()),
            Math.min(1.0, ratio), Boolean.TRUE.equals(p.getSuspectFake()), u);
    }

    private double[] resolveAnchor(String geo, String userLocationId, String address) {
        if (geo != null && !geo.isBlank()) {
            String[] parts = geo.split(",");
            if (parts.length == 2) {
                return new double[]{Double.parseDouble(parts[0].trim()), Double.parseDouble(parts[1].trim())};
            }
        }
        if (userLocationId != null) {
            return ulRepo.findById(userLocationId).map(ul -> new double[]{
                ul.getLat() != null ? ul.getLat() : 10.7760,
                ul.getLng() != null ? ul.getLng() : 106.7000}).orElse(new double[]{10.7760, 106.7000});
        }
        if (address != null && !address.isBlank()) {
            GeoResponse g = geocode(address);
            return new double[]{g.lat(), g.lng()};
        }
        throw new ApiException(ApiErrorCode.VALIDATION_FAILED, "one of geo, user_location_id, address is required");
    }

    private static double distance(double lat1, double lng1, Double lat2, Double lng2) {
        if (lat2 == null || lng2 == null) return Double.MAX_VALUE;
        double dLat = Math.toRadians(lat2 - lat1);
        double dLng = Math.toRadians(lng2 - lng1);
        double a = Math.sin(dLat / 2) * Math.sin(dLat / 2)
            + Math.cos(Math.toRadians(lat1)) * Math.cos(Math.toRadians(lat2))
            * Math.sin(dLng / 2) * Math.sin(dLng / 2);
        return EARTH_R * 2 * Math.atan2(Math.sqrt(a), Math.sqrt(1 - a));
    }

    private void sortScored(List<Scored> list, String sort) {
        Comparator<Scored> c = switch (sort == null ? "score" : sort) {
            case "distance" -> Comparator.comparingInt((Scored s) -> s.view().distanceM());
            case "rating" -> Comparator.comparingDouble((Scored s) -> s.view().ratingRaw()).reversed();
            case "price_asc" -> Comparator.comparingLong((Scored s) -> s.view().avgPriceVnd());
            default -> Comparator.comparingDouble((Scored s) -> s.view().scoreBreakdown().scoreTotal()).reversed();
        };
        list.sort(c);
    }

    private String travelMode(String tm) {
        if (tm == null) return "walk";
        return switch (tm) {
            case "bike", "car" -> tm; default -> "walk";
        };
    }

    private String firstDish(List<String> dishes) {
        return dishes != null && !dishes.isEmpty() ? dishes.get(0) : null;
    }

    private DishRef buildDishRef(String dishId) {
        String[] meta = DISH_NAMES.getOrDefault(dishId, new String[]{null, ""});
        List<String> path = meta[1] != null ? Arrays.asList(meta[1].split("\\|")) : List.of();
        return new DishRef(dishId, meta[0], path);
    }

    private int decodeOffset(String cursor) {
        if (cursor == null || cursor.isBlank()) return 0;
        try {
            Map<String, Object> m = cursor == null ? Map.of() : this.cursor.decode(cursor);
            Object o = m.get("o");
            return o instanceof Number ? ((Number) o).intValue() : 0;
        } catch (Exception e) {
            return 0;
        }
    }

    private List<DishHighlightInput> parseDishHighlights(Place p) {
        if (p.getDishHighlightsJson() == null || p.getDishHighlightsJson().isBlank()) return List.of();
        try {
            return mapper.readValue(p.getDishHighlightsJson(), new TypeReference<List<DishHighlightInput>>() {});
        } catch (Exception e) {
            return List.of();
        }
    }

    private List<String> splitCsv(String s) {
        if (s == null || s.isBlank()) return List.of();
        return Arrays.stream(s.split("\\|")).map(String::trim).filter(x -> !x.isEmpty()).collect(Collectors.toList());
    }

    private String toJson(Object o) {
        try { return o == null ? null : mapper.writeValueAsString(o); }
        catch (Exception e) { return null; }
    }

    private int clamp(Integer v, int min, int max, int def) {
        if (v == null) return def;
        return Math.max(min, Math.min(max, v));
    }

    private String nowUtc() {
        return Instant.now().atZone(ZoneId.of("UTC")).format(DateTimeFormatter.ISO_INSTANT);
    }

    private String localTime() {
        return Instant.now().atZone(ZoneId.of("Asia/Ho_Chi_Minh")).format(DateTimeFormatter.ofPattern("HH:mm"));
    }

    private String dow() {
        return Instant.now().atZone(ZoneId.of("Asia/Ho_Chi_Minh")).getDayOfWeek().name().toLowerCase();
    }

    private record Scored(Place place, PlaceView view) {}

    private record DishHighlightInput(String dishId, String name, double confidence, Long priceVnd) {}
}

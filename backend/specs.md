# Specs — Backend P1 ĂnGìĐây

Mỗi section = 1 bounded context (service). Chi tiết DTO input/output tham chiếu docs/02 (P1) và docs/03 (P2/P3). Mọi endpoint phải pass contract test so với docs.

## 1. Gateway (edge)
Trách nhiệm: TLS, verify JWT RS256 (hoặc Guest token), rate limit (Redis sliding window), prefix /v1, propagate + echo X-Request-Id, forced-upgrade (X-Min-App-Version), route đến services.
Endpoint riêng: GET /v1/healthz.
Public (không cần auth): POST /v1/auth/guest, POST /v1/auth/oauth, GET /v1/config, GET /v1/dishes/taxonomy, GET /v1/dishes/bundle, GET /v1/places/urgent, GET /v1/places/{id}.
Rate limit: 60 req/phút/client -> 429 + Retry-After + X-RateLimit-*.
Acceptance: thiếu token tại route bảo vệ -> 401 UNAUTHENTICATED; token hết hạn -> 401 TOKEN_EXPIRED; X-Request-Id luôn echo.

## 2. Identity (FR-AUTH + config)
Endpoints (docs/02 muc 2):
- POST /v1/auth/guest (FR-AUTH-01): body {install_id, platform} -> 201 {access_token(15m), refresh_token(30d, rotate), user_id:"usr_guest..."}.
- POST /v1/auth/oauth (FR-AUTH-02/03): {provider:google|apple, id_token, guest_upgrade?} -> 200 giữ nguyên user_id cũ (FR-AUTH-03).
- POST /v1/auth/refresh + /logout (muc 2.4): refresh luân chuyển, hash lưu, reuse -> thu hồi toàn bộ session.
- GET /v1/me (muc 2.5): hồ sơ, mọi tính năng đọc từ đây.
- PUT /v1/me, /me/preferences, /me/diet, /me/settings (muc 2.6).
- PUT /v1/me/onboarding (muc 2.7): tối đa 3 màn, bỏ qua được.
- POST /v1/me/consents (muc 2.8).
- (P2) GET /v1/me/export, DELETE /v1/me.
- GET /v1/config (muc 5.1): remote config + feature flags + tài nguyên động. Trả cả trọng số ranking, lambda, tau, m (FR-PER-02).
Redis: session/refresh hash, revocation set. JWT RS256 keypair (public cho gateway verify).
Acceptance: guest -> user_id usr_guest...; refresh reuse detect; /me trả schema docs/02 muc 2.5.

## 3. Roulette (FR-ROU)
Endpoints (docs/02 muc 3):
- GET /v1/dishes/taxonomy (muc 3.1): cây món + tag; app lưu local.
- GET /v1/dishes/bundle?since_version= (muc 3.2): quay offline (FR-ROU-10); trả version + dish list.
- POST /v1/spins (muc 3.3) ⭐: body {filters, diet(hard), geo|user_location_id, excluded_dish_ids?, bias?} -> 201 {dish, seed, animation, pool_size}. p95 < 300ms (NFR-02). Kết quả chốt TRƯỚC animation: lưu (seed, sha256) (FR-ROU-07). Thuật toán WeightedSampler + CsprngPort; w = base·pref·exp(-Δdays/τ), τ=3d (docs/01 muc 7). Trả về dish_id + suggested_body (app hiển thị, không tự tính).
- GET /v1/spins/{id}, GET /v1/spins?cursor&limit&from, POST /v1/spins/{id}/verify (muc 3.4).
- POST /v1/spins/{id}/dismiss (muc 3.5) [P2].
- Exclusions (muc 3.6): PUT/GET danh sách loại.
Redis: dish pool cache, recent spins (anti-repeat) key spin:recent:{user_id}.
Acceptance: diet loại sạch pool -> 422 DIET_FILTER_EMPTY + details[]; seed+sha256 lưu để verify; response khớp docs/02 muc 3.3.

## 4. Place (FR-PLC)
Endpoints (docs/02 muc 4):
- POST /v1/geocode (muc 4.1): address -> geo (Phase 1 mock; sau gọi MapDistancePort/Nominatim).
- GET/POST/PUT/DELETE /v1/user-locations (muc 4.2): lưu nhà/công ty/ghim.
- GET /v1/places/nearby (muc 4.3) ⭐: query geo, radius_m, cursor, limit, filters -> {items, page}. NFR-01.
- POST /v1/matches (muc 4.4) ⭐: {dish_id, geo, radius_m, bias, limit=3} -> top3 + score_breakdown + why + relaxation (khi 0 kết quả). Gọi ranking.
- GET /v1/places/urgent (muc 4.5): UC-03 < 2s; 1 kết quả, open_now, walk_minutes.
- GET /v1/places/{id} (muc 4.6): detail (FR-PLC-05).
- POST /v1/places/{id}/reports (muc 4.7): báo sai (FR-PLC-07).
Redis L1: geo:{geohash6}:{dish}:{filter_hash} TTL 10m; osm:{geohash5}/ggl:{geohash6}:{type} TTL 24h (provider cache).
Acceptance: 0 quán -> 200 + relaxation + substitute_dishes[]; provider chết -> X-Data-Quality: provider_degraded + kết quả Postgres; response khớp docs/02 muc 4.

## 5. Ranking (FR-REC)
Không REST công khai nhiều; là service nội bộ được roulette/place/group gọi (docs/01 muc 3, muc 6.1).
Logic (docs/01 muc 7):
- BayesianQuality: Q = ((v·R + m·C)/(v+m))/R_max, m=20.
- PlaceScorer: Score = 100·(0.35·Q + 0.25·D + 0.15·P + 0.15·O + 0.10·U) − Penalty. D = exp(-d_m/λ) (λ_walk=600, λ_bike=2500, λ_car=6000). P theo budget. O theo giờ mở. U = 0.5·favourite+0.3·similarity+0.2·exploration. Penalty = 8·stale +10·report_ratio +15·suspect_fake.
- RelaxationLadder: 0 kết quả -> nới radius -> price -> meal -> category + why.
- ContextResolver (WeatherPort): mưa -> +comfort, cuối tháng -> +P.
Trả score_breakdown.components[]: mỗi {key, message_key, value, weight}. Hằng số từ config.
Redis: cache score theo place+dish+context.

## 6. Journal (FR-JRN P1-lite)
- POST /v1/journal/visits (docs/02 muc 6.1): {place_id, status:"arrived", source:"nav_open"} -> 201. Dùng cho anti-repeat và cá nhân hoá (U).
(P2/P3: bản đầy đủ + sync ở docs/03).

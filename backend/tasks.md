# Tasks - Phase 1 (MVP) - Thuc te (Maven multi-module)

> Kien truc da pivot: Maven reactor (khong phai Gradle) + microservice (khong phai modular monolith).
> Da duyet 3 deviations trong plan.md + constitution.md. Build da verify: mvn compile/package xanh, 1 unit test ranking xanh.

## T0 Scaffold
- [x] pom.xml parent (Java 21, Boot 3.3.5, Spring Cloud 2023.0.3, jjwt 0.12.6)
- [x] common module: ErrorEnvelope/ErrorCode, CursorPage + CursorSigner (HMAC), Money, GeoPoint, Headers, Ulid + RequestIds, JwtUtils, RedisCache + DistributedLock
- [x] 6 service POMs (identity, gateway, roulette, ranking, place, journal) + Lombok provided
- [x] docker-compose.yml (postgres-postgis + redis cluster 6 node + redis-cluster-init + 6 services), Dockerfile (multi-stage, build-arg SERVICE), redis.conf

## T1 Gateway
- [x] Spring Cloud Gateway: routes /v1/* toi cac service, JWT RS256 verify qua JWKS identity, sinh/X-Request-Id, rate limit Redis, healthz /v1/healthz

## T2 Identity
- [x] POST /v1/auth/guest, /refresh, /logout; GET+PUT /v1/me, /preferences, /diet, /onboarding, /consents; GET /v1/config
- [x] JWT RS256 keypair, refresh token hash + revoke; JWKS /.well-known/jwks.json

## T3 Roulette
- [x] GET /v1/dishes/taxonomy, /dishes/bundle
- [x] POST /v1/spins (WeightedSampler + SecureRandom seed, luu seed+sha256, exclusions Redis, 422 DIET_FILTER_EMPTY)
- [x] GET /v1/spins/{id}, /v1/spins list (cursor), /verify; GET/PUT /v1/exclusions
- [x] Unit + contract tests (RouletteServiceTest: sampler/proof/diet-empty/verify; RouletteContractTest: snake_case + error envelope)

## T4 Ranking
- [x] POST /v1/rank/score: Bayesian quality, distance decay, penalty; tra score_breakdown.components[]
- [x] Unit tests (formula) - RankingServiceTest xanh

## T5 Place
- [x] GET /v1/places/nearby (cursor, sort, filter), POST /v1/matches (goi ranking, relaxation, 0-result path), GET /v1/places/urgent, GET /v1/places/{id}, POST /v1/places/{id}/reports (idempotency/dedup)
- [x] GET /v1/geocode (stub), user-locations CRUD
- [x] Seed data (8 quan HCMC); X-Data-Quality header; JSON non-null (drop absent keys)

## T6 Journal
- [x] POST /v1/journal/visits (idempotency replay 409, FUTURE_DATE 400, PLACE_NOT_FOUND 404, verify place qua REST)

## T7 Verify
- [x] mvn -pl ... -am compile + package -DskipTests xanh
- [x] mvn test toan reactor xanh: 23 tests (WireContractTest 4, UlidTest 2, RankingServiceTest 3, RouletteServiceTest 5, RouletteContractTest 5, PlaceContractTest 4)
- [x] Contract test (wire + HTTP): snake_case, drop absent keys, error envelope (request_id/retryable/doc_url/message_key), pagination keys
- [x] JacksonConfig dung chung (SNAKE_CASE + NON_NULL) cho moi service; RestTemplate noi bo dung cung ObjectMapper
- [x] Fix bug Ulid.generate() (StringIndexOutOfBounds) - test phat hien
- [x] Doi chieu frontend<->backend va sua wire shape: spin §3.3 (proof/pool/next/meta), place detail top-level, urgent decision (radius_m_used/candidates_considered/one_tap_action/fallback_dish), config §5.1, guest auth (user object + access_expires_in)
- [x] Gateway route /v1/exclusions; nearby bind query param snake_case (geo/user_location_id/address/radius_m/open_now/travel_mode)
- [ ] docker compose up --build chay end-to-end (can may co Docker + JDK) - chua chay trong sandbox
- [ ] Contract test cho identity/journal - moi co common + roulette + place
- [ ] ArchUnit (layering R01 / bounded context R02) - chua co
- [ ] flutter analyze app_flutter - da xanh tu session truoc

## Deferred (P2/P3)
- Group WSS, community, admin, notification, providers (Google/OSM), RabbitMQ + Outbox, object storage, SSE/GraphQL (cam R14).

# Plan — Backend Microservice ĂnGìĐây

## Giai đoạn (phasing)
Phase 1 (MVP, lần này): scaffold + 6 services (gateway, identity, roulette, place, ranking, journal) chạy được với PostgreSQL+PostGIS (store chính) + Redis Cluster (L1 cache/state), implement flow UC-01 (quay -> matches -> detail) + urgent + guest auth + journal.
Phase 2: Postgres+PostGIS (geo ST_DWithin), RabbitMQ+Outbox, providers (OSM/Google), group WSS, admin, community, notification, object storage.
Phase 3: partner gateway, AI features, scale.

## Cây thư mục
(theo constitution muc 3)

## Redis Cluster
- 6 node (3 master + 3 replica) qua docker-compose.redis-cluster.yml.
- Lettuce với ClusterClientOptions + timeout + cluster pipelining.
- Dùng cho: L1 cache (geohash results, provider), rate limit (sliding window), distributed lock (SET NX), room state+stream (P2), session/refresh (identity).
- Mọi truy cập Redis phải có TTL; không block thread; fallback khi Redis chết -> 503/provider_degraded (docs/01 muc 4.8, NFR-06).

## Build & test
- Gradle multi-project: parent settings.gradle.kts include các service + libs.
- libs.versions.toml pin Java 21, Boot 3.3, Lettuce, Spring Cloud Gateway, Testcontainers (Redis, Postgres P2).
- Test: contract test mỗi endpoint so với docs/02,03; ArchUnit cho layering (NFR-12); Testcontainers Redis cho cache/rate-limit; unit cho WeightedSampler, BayesianQuality, PlaceScorer.
- CI: GitHub Actions build + test (NFR-12).

## Điều chỉnh so với docs/01 (đã duyệt)
1. Modular monolith -> microservice (yêu cầu của bạn).
2. Postgres+PostGIS dùng từ Phase 1 làm store chính (bạn duyệt giữ nguyên, không dời Phase 2).
3. Gradle -> Maven (toolchain máy có sẵn Maven; Gradle không cài, dễ đổi sau).

# Constitution — Backend ĂnGìĐây (Angi) · draft v0.1

> Hiến pháp dự án backend. Dựa trên docs/01 (kiến trúc), docs/02 (API P1), docs/03 (P2/P3).
> Mọi code phải tuân thủ. Đây là bản draft để bạn duyệt trước khi code.

## 0. Mục tiêu
- Backend phục vụ app Flutter ĂnGìĐây, trung thành 100% với hợp đồng /v1.
- Kiến trúc microservice (yêu cầu của bạn) — xem điều chỉnh ở muc 2.
- MVP (P1): auth/guest, roulette (quay món), place (quán + matching), ranking, journal.

## 1. Nguyên tắc cốt lõi (bắt buộc)
1. Trung thành hợp đồng: input/output khớp docs/02, docs/03. App là contract-faithful, sai 1 field là app lỗi.
2. Chỉ backend tính điểm: app không tự tính score. Backend luôn trả score_total + score_breakdown (components[]) để vẽ "Vì sao" (FR-REC-02).
3. Quy tắc dữ liệu (docs/02 muc 1.1): snake_case; thời gian RFC3339 UTC; toạ độ WGS84 6 thập phân; tiền VND số nguyên; score 0-100 2 thập phân; ID = prefix + ULID lower; mảng rỗng [] (không null); bỏ hẳn key khi không có.
4. Envelope lỗi duy nhất: {"error":{code, message, details[], request_id, retryable, doc_url}} + message_key để app tự dịch (server không dịch UI). Bảng mã lỗi docs/01 muc 4.6.
5. Phân trang con trỏ: opaque, HMAC-signed; {"items":[], "page":{next_cursor, has_more, total_estimate}}. limit 1..50, mặc định 20.
6. Header (docs/01 muc 4.2/4.3): request cần Authorization, X-Request-Id, X-Device-Id, X-Platform, X-App-Version, X-Locale, X-Idempotency-Key (write), X-Geo-Precision; response luôn echo X-Request-Id, set X-Data-Quality, X-RateLimit-*.
7. Idempotency: X-Idempotency-Key bắt buộc mọi POST/PUT/PATCH/DELETE có ghi; replay -> 409 IDEMPOTENCY_REPLAY.
8. Hằng số từ remote config: trọng số (0.35/0.25/0.15/0.15/0.10), lambda, tau, m, budget — đọc từ feature flag, không hard-code (docs/01 muc 7).
9. Cache 3 tầng: L0 Flutter (Drift) / L1 Redis Cluster (geohash, provider, rooms, locks, rate limit) / L2 Postgres. Redis Cluster là L1 bắt buộc.
10. Không SSE, không GraphQL ở P1 (docs/01 muc 4.1).

## 2. Quyết định công nghệ (khớp docs/01 muc 1, có điều chỉnh)
- Ngôn ngữ: Java 21 + Spring Boot 3.3 (giữ nguyên doc).
- Build: Maven multi-module (3.9.x). Máy có sẵn Maven + Java 21; doc gốc dùng Gradle, dễ đổi sau (không cần Gradle wrapper).
- Kiến trúc: MICROSERVICE thay vì modular monolith (ĐIỀU CHỈNH theo yêu cầu). Vẫn giữ internal layering (muc 3) và bounded context; mỗi context = 1 service deploy độc lập.
- Gateway: Spring Cloud Gateway — verify JWT RS256, rate limit Redis, /v1, X-Request-Id, forced-upgrade.
- Cache/State: Redis 7 CLUSTER (Lettuce) — ĐẶC BIỆT bạn yêu cầu cluster.
- DB: PostgreSQL 16 + PostGIS — dùng từ Phase 1 làm store chính (L2). Redis Cluster làm L1 cache/state (rate limit, lock, room). port PersistencePort trừu tượng để dễ đổi DB.
- Realtime: Spring WebSocket + Redis Streams (group, P2/P3).
- Queue: RabbitMQ + Outbox (Phase 2). Object: S3-compatible + CDN (Phase 2).
- Auth: Google/Apple/OTP, JWT RS256. Phase 1: guest + refresh + me (+ oauth).

## 3. Cấu trúc thư mục (microservice, derived docs/01 muc 3.2)
    backend/
      pom.xml              # parent reactor (Maven)
      common/              # module chung: api + domain + redis + test (gộp common-api/domain/redis/test)
      services/
      services/
        gateway/  identity/  roulette/  place/  ranking/  journal/
        # P2: group/ community/ admin/ notification/
      infra/
        docker-compose.redis-cluster.yml
        docker-compose.yml
      graphify-out/        # bản đồ domain (graphify)
      constitution.md  specs.md  plan.md  tasks.md  PONYTAIL.md

Mỗi service:
    services/<name>/
      build.gradle.kts
      src/main/java/com/angi/day/<name>/
        api/          # Controller, DTO records, @Valid
        application/  # Service, Assembler
        domain/       # entity thuần Java, không Spring/Jackson/JDBC
        infrastructure/ # Repository impl, Cache, EventPublisher
        port/         # interface hướng ra ngoài (gọi service khác)
      src/test/...

## 4. Lớp trong mỗi service (chuẩn docs/01 muc 3.1)
api -> application -> domain; infrastructure -> domain; application -> infrastructure + port.
ArchUnit enforce (NFR-12): domain không phụ thuộc Spring/Jackson/JDBC; controller không chạm repository; service giao tiếp qua port/rest, cấm import internal của service khác.

## 5. Phân rã microservice (bounded context -> service)
- gateway: edge (JWT, rate limit, version, X-Request-Id, upgrade).
- identity (FR-AUTH + config): guest/oauth/refresh/me/preferences/onboarding/consents + GET /v1/config.
- roulette (FR-ROU): taxonomy, bundle, spins, dismiss, exclusions. Gọi ranking để tính spin bias.
- place (FR-PLC): geocode, user-locations, nearby, matches, urgent, detail, reports. Gọi ranking.
- ranking (FR-REC): Q Bayesian, PlaceScorer, RelaxationLadder, ContextResolver. Service được roulette/place/group gọi.
- journal (FR-JRN P1-lite): visits.
- (P2) group (FR-GRP): rooms WSS + Redis Streams. community, admin, notification.

## 6. Ponytail
Quy tắc viết code chi tiết: backend/PONYTAIL.md — bắt buộc, coi như plugin quy tắc cho AI/team.

## 7. Graphify
Bản đồ thực thể/quan hệ domain: backend/graphify-out/GRAPH_REPORT.md (sinh bởi skill graphify từ docs + frontend).

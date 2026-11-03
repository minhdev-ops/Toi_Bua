# PONYTAIL — Bộ quy tắc viết code (coding-rules plugin)

Áp dụng như plugin quy tắc: AI/team PHẢI tuân thủ khi viết backend. Mỗi rule có mã Rxx.

## R01 Lớp (layering)
Mỗi service = api / application / domain / infrastructure / port. domain không import Spring/Jackson/JDBC. Controller không chạm repository. Giao tiếp service khác qua port/REST, cấm import internal service khác (ArchUnit, docs/01 muc 3.1).

## R02 Bounded context
Mỗi microservice = 1 bounded context (gateway, identity, roulette, place, ranking, journal...). Không chia sẻ DB; chia sẻ dữ liệu qua API hoặc Redis được đồng thuận.

## R03 Hợp đồng dữ liệu
snake_case JSON; thời gian RFC3339 UTC; toạ độ WGS84 6dp; tiền VND số nguyên; score 0-100 2dp; ID prefix+ULID lower; mảng rỗng [] không null; bỏ key khi không có (docs/02 muc 1.1).

## R04 Envelope lỗi
Chỉ một dạng {"error":{code,message,details[],request_id,retryable,doc_url}}; dùng message_key để app dịch; server KHÔNG dịch UI. Dùng bảng mã lỗi docs/01 muc 4.6 (VALIDATION_FAILED, UNAUTHENTICATED, TOKEN_EXPIRED, FORBIDDEN, CONSENT_REQUIRED, NOT_FOUND, CONFLICT, IDEMPOTENCY_REPLAY, ROOM_VERSION_STALE, ROOM_EXPIRED, DIET_FILTER_EMPTY, PROVIDER_UNAVAILABLE, RATE_LIMITED, DEGRADED_NO_RESULT...).

## R05 Phân trang
Con trỏ opaque, HMAC-signed; {"items":[],"page":{next_cursor,has_more,total_estimate}}. limit 1..50 mặc định 20. Không dùng offset.

## R06 Header
Mọi response echo X-Request-Id; set X-Data-Quality (fresh/cached/stale/provider_degraded/offline_bundle); X-RateLimit-Limit/Remaining/Reset. X-Min-App-Version cho forced upgrade.

## R07 Idempotency
X-Idempotency-Key bắt buộc mọi write; key đổi khi body đổi -> 409. Lưu hash theo (user, key).

## R08 Chỉ backend tính điểm
App không tự tính score. Backend luôn trả score_total + score_breakdown (components: key, message_key, value, weight). Không trả weight thô.

## R09 Hằng số từ config
Trọng số, lambda, tau, m, budget, TTL — đọc từ remote config / feature flag. Không hard-code (docs/01 muc 7).

## R10 Redis Cluster
Dùng Lettuce cluster. Mọi key có TTL. Không block thread trên Redis. L1 cache: geo:{geohash6}:{dish}:{filter_hash} 10m; provider 24h. Rate limit sliding window. Lock SET NX. Khi Redis chết: degrade (503 / provider_degraded), không crash (NFR-06).

## R11 ULID & CSPRNG
ID = prefix + ULID lower, sinh từ CSPRNG, không đoán được. Spin lưu (seed, sha256) làm proof; kết quả chốt trước animation (FR-ROU-07).

## R12 Observability
Log kèm request_id; không log PII (token, phone). Metrics OpenTelemetry (NFR-13).

## R13 Test
Contract test mỗi endpoint so với docs/02,03; ArchUnit layering; Testcontainers Redis/PG; unit cho thuật toán (WeightedSampler, BayesianQuality, PlaceScorer). Không merge nếu ArchUnit đỏ.

## R14 Không SSE/GraphQL ở P1
Chỉ REST /v1 + WSS (group, P2). Không business logic ở app (docs/01 muc 4.1).

## R15 Message/event
RabbitMQ + Outbox pattern cho enrich/notify/analytics (Phase 2). Thành phần phụ không làm sập luồng chính (NFR-06).

# 02 · Đặc tả API P1 (MVP) — input / output từng chức năng

*Áp dụng cho `apps:monolith` + `apps:gateway`. Base URL: `https://api.angi.example` · Prefix: `/v1` · TLS 1.2+ · JSON UTF-8*

> Quy ước chung (mục 1–3) **đúng cho mọi endpoint** kể cả P2/P3 trong [`03-api-p2-p3.md`](./03-api-p2-p3.md).
> Sơ đồ luồng và module: [`01-kien-truc-he-thong.md`](./01-kien-truc-he-thong.md)

---

## 1. Hợp đồng chung — đọc mục này trước khi code bất kỳ endpoint nào

### 1.1 Quy tắc dữ liệu

| Loại | Chuẩn | Ví dụ |
| --- | --- | --- |
| Tên field | `snake_case` | `price_level` |
| Thời gian | RFC3339 UTC, chính xác giây | `2026-11-01T03:20:00Z` |
| Giờ mở cửa | `HH:MM` local + tz riêng | `opens_at: "06:30"`, `tz: "Asia/Ho_Chi_Minh"` |
| Toạ độ | WGS84, 6 thập phân (±1,1 m) | `{"lat": 10.779000, "lng": 106.702000}` |
| Khoảng cách | **giấy** số nguyên | `distance_m: 750` |
| Tiền | **VND số nguyên**, không dùng float | `avg_price_vnd: 45000` |
| Điểm/score | number 2 thập phân, thang 0–100 (Q,D,P,O,U là 0–1) | `score_total: 68.85` |
| ID | prefix + ULID lower, không đoán được | `plc_01J8Z6Q9K3M2T7V1X0Y2A3B4C5` |
| Enum | `lower_snake` | `"late_night"` |
| Mảng rỗng | trả `[]`, **không** trả `null` | `"tags": []` |
| Field không có | **bỏ hẳn key**, app dùng default an toàn | — |

Prefix ID: `usr_ device_ cns_ dsh_(món) cat_ tag_ udt_ uxcl_ ulc_(vị trí) plc_(quán) phr_ psr_ pdh_(place_dish) spn_ vst_ uli_(list) rom_ rmr_ rcd_ vot_ vto_ rev_ rpt_ ff_ exp_ upl_(upload)`.

### 1.2 Header — xem bảng đầy đủ ở file `01` mục 4.2/4.3. Tóm tắt bắt buộc:

| Direction | Header | Ghi chú |
| --- | --- | --- |
| → | `Authorization` | `Bearer <jwt>` hoặc `Guest <token>`; client **không** tự nhét user_id |
| → | `X-Request-Id` | ULID do app sinh; server log + echo lại |
| → | `X-Idempotency-Key` | bắt buộc với POST/PUT/PATCH/DELETE có ghi; key đổi khi body đổi → `409` |
| → | `X-Locale` | `vi` \| `en` (quyết định `name` vs `name_en`, `why_*`) |
| → | `X-App-Version` | server so với `X-Min-App-Version` để buộc nâng cấp (NFR-14) |
| → | `X-Geo-Precision` | `exact` (mặc định) \| `coarse` — `coarse` ⇒ server chỉ dùng geohash5 |
| ← | `X-Data-Quality` | `fresh` \| `cached` \| `stale` \| `provider_degraded` \| `offline_bundle` |
| ← | `X-RateLimit-*` | limit / remaining / reset |
| ← | `X-Request-Id` | trace |

### 1.3 Phân trang + lọc + envelope lỗi

```jsonc
// request
GET /v1/places/nearby?geo=10.779000,106.702000&radius_m=1500&cursor=eyJvIjoyMH0&limit=20
// response (mọi endpoint dạng list)
{ "items": [ ... ], "page": { "next_cursor": "...", "has_more": true, "total_estimate": 143 },
  "meta": { "data_quality": "cached", "generated_at": "2026-11-01T03:20:00Z", "cache_age_s": 240 } }
```

Lỗi: **một dạng duy nhất** `{"error": {...}}` như file `01` mục 4.6. Endpoint nào cũng chỉ dùng các code trong bảng đó + code domain riêng nêu dưới từng endpoint.

### 1.4 DTO dùng chung (định nghĩa 1 lần, các endpoint reference tới)

#### `Dish` (món)
| Field | Kiểu | Luôn có | Mô tả |
| --- | --- | --- | --- |
| `id` | string | ✔ | `dsh_...` |
| `name` | string | ✔ | theo `X-Locale` |
| `name_en` | string | khi `locale=vi` | tên Anh (NFR-11) |
| `category_path` | string[] | ✔ | `["món nước","bún","bún bò"]` — taxonomy FR-ROU-01 |
| `category_id` | string | ✔ | node lá |
| `region` | enum | ✔ | `north`\|`central`\|`south`\|`all` |
| `temp` | enum | ✔ | `hot`\|`warm`\|`cold`\|`any` |
| `meal` | enum[] | ✔ | `breakfast`\|`lunch`\|`dinner`\|`late_night`\|`any` |
| `tags` | Tag[] | ✔ | `{id, kind, label}`; `kind ∈ cuisine\|diet\|allergen\|attribute` |
| `price_level` | int 1–4 | ✔ | 1 = ≤ 25k, 2 = 25–50k, 3 = 50–150k, 4 = > 150k |
| `image_url` | string\|null | ✔ | CDN, có thể `null` |
| `is_excluded` | bool | ✔ | có trong danh sách loại (FR-ROU-05) |

#### `Place` (quán) — shape tối thiểu ở list và đầy đủ ở detail
| Field | Kiểu | List | Detail | Mô tả / FR |
| --- | --- | --- | --- | --- |
| `id` | string | ✔ | ✔ | `plc_...` |
| `name` / `name_en` | string | ✔ | ✔ | FR-PLC-02 |
| `address` | string | ✔ | ✔ | |
| `geo` | `{lat,lng}` | ✔ | ✔ | FR-NAV-01 dùng để deep link |
| `travel_mode` | enum | ✔ | ✔ | `walk`\|`bike`\|`car` |
| `distance_m` | int | ✔ | ✔ | ST_Distance |
| `walk_minutes` | int\|null | P2 | P2 | FR-NAV-03 |
| `price_level` | int 1–4 | ✔ | ✔ | |
| `price_range_vnd` | `{min,max}` | ✔ | ✔ | |
| `avg_price_vnd` | int | ✔ | ✔ | dùng cho thành phần P |
| `rating_raw` | number | ✔ | ✔ | trung bình thô |
| `rating_bayesian` | number | ✔ | ✔ | FR-REC-03 |
| `review_count` | int | ✔ | ✔ | |
| `open_status` | OpenStatus | ✔ | ✔ | FR-PLC-06 |
| `cuisine_tags` | string[] | ✔ | ✔ | |
| `dish_highlights` | DishHighlight[] | ✔ | ✔ | FR-REC-01 (`{dish_id, name, confidence, price_vnd}`) |
| `amenities` | `{parking,ac,group_friendly,takeaway,wifi}` | ✖ | ✔ | FR-PLC-04 |
| `phone_e164` | string\|null | ✖ | ✔ | FR-NAV-02 |
| `booking_url` / `delivery_url` | string\|null | ✖ | ✔ | FR-NAV-02 |
| `images` | Image[] | ✖ | ✔ | FR-PLC-05 `{url, credit, source, is_user_submitted}` |
| `hours_by_dow` | PlaceHour[7] | ✖ | ✔ | FR-PLC-05 |
| `source` | SourceInfo | ✔ | ✔ | `{provider, external_id, verified_at, data_confidence}` |
| `badges` | string[] | ✖ | ✔ | `verified` \| `top_rated` \| `new` \| `cheap` |
| `is_sponsored` | bool | P3 | P3 | FR-REC-04 — mặc định `false`, **không ảnh hưởng thứ tự** |
| `natural_rank` | int | P3 | P3 | FR-REC-04 |
| `score_breakdown` | ScoreBreakdown | ✖ | ✔ (khi có query dish) | FR-REC-02 |
| `why` | `{headline, bullets[], key, params}` | ✖ | ✔ | FR-REC-02, i18n key |
| `report_summary` | `{count_30d, last_kind, pending}` | ✖ | ✔ | FR-PLC-07 |

#### `OpenStatus` (trái tim của FR-PLC-06)
```jsonc
{
  "is_open": true,
  "opens_at": "2026-11-01T10:00:00Z",
  "closes_at": "2026-11-01T13:30:00Z",
  "closes_in_min": 47,
  "closing_soon": false,          // true khi closes_in_min < 30  → app hiện cảnh báo
  "o_score": 1.0,                 // server tính sẵn: 1 | 0.5 | loại hẳn
  "tz": "Asia/Ho_Chi_Minh",
  "is_exception_day": false,      // lễ / tạm đóng (place_hours_exception)
  "note_key": null                // "hours.closed_for_holiday"
}
```
**Quy ước**: quán đã đóng → **không xuất hiện** trong kết quả mặc định (`filters.include_closed=true` mới trả về). `0 < closes_in_min < 30` → `closing_soon=true`, `o_score=0.5`. App không tự tính `o_score` — giờ máy điện thoại sai là đổi xếp hạng.

#### `ScoreBreakdown` (FR-REC-02 — mục "Vì sao gợi ý quán này")
```jsonc
{
  "formula_version": "2026.10",
  "weights": { "Q": 0.35, "D": 0.25, "P": 0.15, "O": 0.15, "U": 0.10 },
  "score_total": 68.85,
  "components": [
    { "key": "Q", "label": "Chất lượng", "value_norm": 0.71, "contribution": 24.85, "top": true,
      "facts": { "rating_bayesian": 4.3, "review_count": 182, "m_threshold": 20 },
      "why_key": "why.q.top", "why_params": { "rating": "4.3", "count": "182" } },
    { "key": "D", "label": "Gần bạn", "value_norm": 0.50, "contribution": 12.50,
      "facts": { "distance_m": 420, "lambda": 600, "travel_mode": "walk", "formula": "exp(-420/600)" }, "why_key": "why.d.top" },
    { "key": "P", "label": "Hợp túi tiền", "value_norm": 1.0, "contribution": 15.00,
      "facts": { "avg_price_vnd": 40000, "budget_vnd": 60000 }, "why_key": "why.p.in_budget" },
    { "key": "O", "label": "Đang mở", "value_norm": 1.0, "contribution": 15.00,
      "facts": { "closes_in_min": 47 }, "why_key": "why.o.open_45m" },
    { "key": "U", "label": "Hợp khẩu vị", "value_norm": 0.55, "contribution": 5.50,
      "facts": { "favourite": false, "similarity": 0.62, "never_visited": true }, "why_key": "why.u.explore" }
  ],
  "penalty": { "total": 4.00, "items": [ { "reason": "stale_verification", "days": 205, "value": 4.00 } ] },
  "top_component": "Q"
}
```
App render: `headline` + top 2 `components` có `top=true` hoặc `contribution` lớn nhất → đúng yêu cầu "mọi quán trong top đều hiển thị thành phần đóng góp lớn nhất" (SRS 6.1).

**Quy ước `why.key`** (áp dụng cho mọi `why` và `alternatives[].why_key`): giá trị phải thuộc bảng đăng ký — `why.headline`, `why.{q,d,p,o,u}.*`, `alt.*`, `relax.*`, `substitute.*`, `urgent.*`, `prompt.*`, `err.*`, `hours.*`, `veto.*`, `budget.*`, `grp.*`. App render `key` + `params` qua ARB; `key` không có trong bảng ⇒ **ẩn dòng đó**, không fallback về `headline`/`bullets` thô (`docs/01` §4.6, NFR-11, TC-I18N-01).

---

## 2. Nhóm FR-AUTH · Khởi đầu và tài khoản (module `identity`)

### 2.1 `POST /v1/auth/guest` — dùng ngay không cần đăng ký `FR-AUTH-01`
**Auth**: không · **Idempotency**: bắt buộc `X-Idempotency-Key` · **Rate**: 10/giờ/install_id · **SLA**: p95 < 150 ms

**Input**
| Path | Kiểu | BẮT BUỘC | Ràng buộc | Ví dụ | Ghi chú |
| --- | --- | --- | --- | --- | --- |
| `install_id` | string | ✔ | UUID v4 app sinh, lưuKeychain/Keystore | `"8f2c1a9b-6e2a-..."` | không phải device fingerprint |
| `platform` | enum | ✔ | `ios`\|`android` | `"android"` | |
| `app_version` | string | ✔ | semver | `"1.0.0+120"` | |
| `locale` | enum | ✖ | `vi`\|`en`, mặc định từ header | `"vi"` | |
| `attestation` | string | ✖ | iOS App Attest / Android Play Integrity | | chống abuse (SRS 11); thiếu → tier rủi ro cao hơn |

**Output `201`**
```json
{
  "user": { "id": "usr_01J8Z...", "kind": "guest", "display_name": null, "onboarding_completed": false },
  "access_token": "eyJhbGciOiJSUzI1NiIs...",
  "access_expires_in": 900,
  "refresh_token": "rt_01J8Z...",
  "refresh_expires_in": 2592000,
  "consents_required": ["location"],
  "policy_version": "2026.10"
}
```
**JWT claims**: `sub`(user_id) `kind` `tier` `iat` `exp` `iss` `aud` `jti` `pv`(policy_version) `did`.
**Lỗi**: `429 RATE_LIMITED` · `400 VALIDATION_FAILED` (install_id sai định dạng) · `403 FORBIDDEN` (attestation fail, nếu bật cờ bắt buộc)

**Backend**: upsert `device` theo `install_id` → tạo `user_account(kind=guest)` → ghi `consent(analytics, granted=false)` mặc định → phát token.

---

### 2.2 `POST /v1/auth/oauth` — Google / Apple, gồm cả nâng cấp tài khoản khách `FR-AUTH-02`, `FR-AUTH-03`
**Auth**: `Guest` token (khi nâng cấp) hoặc không · **Idempotency**: có · **Rate**: 20/giờ/ip

| Path | Kiểu | BẮT BUỘC | Ràng buộc | Ví dụ |
| --- | --- | --- | --- | --- |
| `provider` | enum | ✔ | `google`\|`apple` | `"google"` |
| `id_token` | string | ✔ | JWT, verify signature theo JWKS của provider, `aud`=client_id, tuổi < 5′ | `"eyJhbGciOi..."` |
| `nonce` | string | khi `provider=apple` | khớp nonce app đã sinh | `"n-8f2c..."` |
| `auth_server_code` | string | ✖ | để lấy refresh Google (sync email) | |
| `guest_upgrade` | bool | ✖ (mặc định `false`) | `true` ⇒ giữ nguyên user_id hiện tại | `true` |
| `consent_granted` | object[] | ✔ | `[{kind:"terms", policy_version:"2026.10"}]` | |

**Output `200`**
```json
{
  "user": { "id": "usr_01J8Z...", "kind": "full", "display_name": "Minh", "email_verified": true,
            "avatar_url": "https://...", "onboarding_completed": true, "upgraded_from_guest": true },
  "access_token": "...", "access_expires_in": 900,
  "refresh_token": "...", "refresh_expires_in": 2592000,
  "preserved": { "spins": 41, "visits": 12, "lists": 3, "diet": true }
}
```
**Lỗi domain**
| HTTP | code | Khi nào | App làm gì |
| --- | --- | --- | --- |
| 401 | `ID_TOKEN_INVALID` | sai signature/aud/expired | log + retry flow đăng nhập |
| 409 | `IDENTITY_ALREADY_LINKED` | email này đã là user khác | nếu `guest_upgrade`: hỏi "gộp 2 tài khoản?" |
| 403 | `CONSENT_REQUIRED` | thiếu `consent_granted` | hiện màn chính sách |

**FR-AUTH-03 verify**: `user.id` **trước và sau khi nâng cấp phải giống nhau** → toàn bộ `spin/visit/list/user_diet/user_location` tự động còn nguyên vì chúng khoá theo `user_id`. Đây là test TC-AUTH-03.

---

### 2.3 `POST /v1/auth/otp/request` + `POST /v1/auth/otp/verify` — số điện thoại `FR-AUTH-02`

`POST /v1/auth/otp/request`
| Path | Kiểu | BẮT BUỘC | Ràng buộc | Ví dụ |
| --- | --- | --- | --- | --- |
| `phone_e164` | string | ✔ | `^\+84\d{9,10}$` (VN), normalize bỏ số 0 đầu | `"+84901234567"` |
| `purpose` | enum | ✖ | `login`\|`rebind`, mặc định `login` | `"login"` |
| `locale` | enum | ✖ | chọn ngôn ngữ SMS | `"vi"` |

Output `200`: `{ "verification_id": "otp_01J8...", "expires_in": 300, "next_retry_in": 30, "channels": ["sms"], "phone_masked": "+84 90 ••• •567" }`
Lỗi: `400 INVALID_PHONE` · `429 OTP_RATE_LIMIT` (3 code/phone/giờ, 10/ip/ngày) · `403 PHONE_BLOCKED`

`POST /v1/auth/otp/verify`
| Path | Kiểu | BẮT BUỘC | Ràng buộc |
| --- | --- | --- | --- |
| `verification_id` | string | ✔ | còn hạn 5′ |
| `code` | string | ✔ | 6 số; sai 5 lần ⇒ huỷ verification |
| `guest_upgrade` | bool | ✖ | như 2.2 |

Output `200`: cùng shape với `POST /v1/auth/oauth` (+ `new_account: true|false`).
Lỗi: `401 OTP_INVALID` (`attempts_left`) · `410 OTP_EXPIRED` · `423 OTP_LOCKED` (sau 5 lần sai).

---

### 2.4 `POST /v1/auth/refresh` · `POST /v1/auth/logout`
| Path | Kiểu | BẮT BUỘC | Mô tả |
| --- | --- | --- | --- |
| `refresh_token` | string | ✔ | token **hiện hành**; server trả token mới và thu hồi token cũ |

`200`: `{access_token, access_expires_in, refresh_token, refresh_expires_in}` · `401 REFRESH_REUSE_DETECTED` ⇒ thu hồi **toàn bộ** phiên của user (app bắt buộc đăng nhập lại).

`POST /v1/auth/logout` — input `{ "refresh_token": "...", "sign_out_all_devices": false }` → `204`. Header `X-Device-Id` xác định device để thu hồi push token.

---

### 2.5 `GET /v1/me` — hồ sơ hiện tại (mọi tính năng đọc từ đây)
**Input**: query `?sections=profile,preferences,diet,budget,consents,locations,exclusions` (mặc định `profile`)
**Output `200`**
```json
{
  "id": "usr_01J8Z...", "kind": "full", "display_name": "Minh", "avatar_url": "https://...",
  "created_at": "2026-10-12T08:00:00Z", "onboarding_completed": true, "policy_version": "2026.10",
  "profile": { "locale": "vi", "theme": "system", "font_scale": 1.0, "reduce_motion": false,
               "sound": true, "haptics": true, "animation_style": "wheel" },
  "preferences": { "meals": ["lunch","dinner"], "price_level_max": 3,
                   "regions": ["south","central"], "temp": "any",
                   "moods": ["comfort","light"], "party_size_default": 2,
                   "travel_mode": "bike", "radius_default_m": 1500,
                   "personalization_opt_in": true },
  "diet": { "strict": ["seafood","peanut"], "preferred": ["vegetarian"], "spice": "no_spicy",
            "notes": null, "consent": { "kind": "health_diet", "granted": true, "policy_version": "2026.10" } },
  "budget": { "weekly_vnd": 350000, "spent_vnd": 210000, "alert_threshold_pct": 80,
              "alert_active": false, "week_start_dow": 1 },
  "locations": [ { "id": "ulc_01J8...", "label": "work", "name": "Cơ quan Q.1",
                   "geo": { "lat": 10.7790, "lng": 106.7020 }, "address": "...", "is_default": true } ],
  "exclusions": [ { "dish_id": "dsh_01J8...", "name": "Nội tạng", "scope": "permanent", "expires_at": null } ],
  "counts": { "spins": 41, "visits": 12, "favorites": 8, "lists": 3 },
  "flags": { "group_enabled": false, "journal_enabled": false },
  "experiment_arms": { "ranking_weights_v2": "control" }
}
```
`flags` + `experiment_arms` ở đây để app bật/tắt UI ngay một lần, khỏi gọi thêm request (FR-ADM-02, SRS 2.6.6).

### 2.6 `PUT /v1/me/preferences` · `PUT /v1/me/diet` · `PUT /v1/me/settings` · `PUT /v1/me`
Tất cả **partial update** (JSON Merge Patch `application/merge-patch+json`), trả `200` với object bị đổi + `updated_at`.

`PUT /v1/me/preferences` — input: đúng các field như output 2.5 `preferences`, mọi field optional.
`PUT /v1/me/diet` **(FR-ROU-03)**
| Path | Kiểu | BẮT BUỘC | Ràng buộc | Ý nghĩa |
| --- | --- | --- | --- | --- |
| `strict` | string[] | ✔ (có thể `[]`) | id thuộc `tag.kind ∈ {diet, allergen}` | **lọc cứng**, không bao giờ quay trúng |
| `preferred` | string[] | ✖ | | tăng `pref` trong trọng số |
| `spice` | enum | ✖ | `no_spicy`\|`mild`\|`normal`\|`extra` | |
| `notes` | string | ✖ | ≤ 200 ký tự | chỉ dùng để lọc |
| `consent_granted` | bool | ✔ | phải `true` mới lưu được | SRS 11: dữ liệu sức khoẻ chỉ lưu khi user tự nhập |

`PUT /v1/me/settings` **(FR-PER-01)**: `{locale, theme(dark|light|system), font_scale(0.85–1.5), reduce_motion, sound, haptics, animation_style(wheel|chest|draw|none), motion_sensitivity}` → app **áp dụng ngay local** rồi sync (không chờ mạng).
`PUT /v1/me`: `{display_name(≤50), avatar_upload_id}`; avatar upload qua `POST /v1/uploads/policy`.

### 2.7 `PUT /v1/me/onboarding` — tối đa 3 màn, bỏ qua được `FR-AUTH-04`
| Path | Kiểu | BẮT BUỘC | Ràng buộc | Màn |
| --- | --- | --- | --- | --- |
| `step` | enum | ✔ | `location`\|`taste`\|`budget`\|`complete` | |
| `location.user_location_id` | string | ✖ | | 1 |
| `location.geo` | GeoPoint | ✖ | nếu không dùng saved location | 1 |
| `location.address_text` | string | ✖ | server geocode | 1 |
| `taste.meals` / `regions` / `price_level_max` / `moods` | | ✖ | như 2.5 | 2 |
| `budget.weekly_vnd` | int | ✖ | 50000–5000000, `null` = bỏ qua | 3 |
| `skipped_steps` | enum[] | ✖ | mọi step đều bỏ qua được | |

`200` → `{onboarding_completed: bool, steps_done: [...], next_step|null}`. **Ràng buộc test**: gọi xong `steps_done.length ≤ 3`, không màn nào bắt buộc.

### 2.8 `POST /v1/me/consents`
`{ "grants": [ { "kind": "location", "granted": true, "policy_version": "2026.10" } ] }` → `200` danh sách consent hiện tại. `kind ∈ location|health_diet|personalization|marketing|analytics|group_sharing`. Server **từ chối** (`400 POLICY_VERSION_OUTDATED`) nếu `policy_version` < phiên bản hiện hành → app phải fetch `GET /v1/config` để biết phiên bản.

### 2.9 `GET /v1/me/export` (JSON) và `GET /v1/me/export?format=csv` — `FR-AUTH-05`
| Query | Kiểu | Mặc định | Mô tả |
| --- | --- | --- | --- |
| `format` | `json`\|`csv` | `json` | |
| `scope` | `all`\|`profile`\|`spins`\|`visits`\|`reviews`\|`lists`\|`consents` | `all` | |
| `since` / `until` | date-time | từ đầu | |

`200` (async, vì dữ liệu có thể lớn): `{ "export_id": "exp_01J8...", "status": "processing", "poll_url": "/v1/me/export/exp_01J8...", "expires_at": "..." }`
`GET /v1/me/export/{export_id}` → `status: ready` + `download_url` **signed URL TTL 15′** (Object storage). CSV: mỗi scope một file trong zip.
Quyền riêng tư: file export **không chứa** `push_token`, `attestation`, không chứa vị trí chi tiết ngoài các địa điểm user tự lưu (NFR-08).

### 2.10 `DELETE /v1/me` — xóa tài khoản `FR-AUTH-05`, `NFR-08`
**Headers bắt buộc**: `X-Idempotency-Key` + body
| Path | Kiểu | BẮT BUỘC | Mô tả |
| --- | --- | --- | --- |
| `confirm` | bool | ✔ phải `true` | |
| `reason` | enum | ✖ | `privacy`\|`not_useful`\|`dup_account`\|`other` |
| `erase_all` | bool | ✖ (mặc định `true`) | `false` = giữ review đã đóng góp dưới dạng ẩn danh |

`202`: `{ "deletion_id": "...", "status": "scheduled", "due_by": "+30 ngày", "what_will_be_deleted": [...] }`
**Hành vi backend (đây là thứ QA phải verify)**
| Dữ liệu | Kết quả | Thời điểm |
| --- | --- | --- |
| `user_account`, `device`, `push_token` | anon/hoá `usr_anon_...` + mã hoá xoá key | ≤ 72 h, hoàn tất ≤ 30 ngày |
| `spin`, `visit`, `vote`, `room_member.location_enc`, `consent`(trừ bắt buộc pháp lý), `user_location`, `dish_exclusion`, `user_list` | xóa hard | ≤ 72 h |
| `review` của user | xoá hoặc anon theo `erase_all` | ≤ 7 ngày |
| `place` do user đề xuất (FR-COM-01) | **gi lại** (tài sản cộng đồng), `submitted_by` → anon | giữ |
| `provider_call_log`, `audit_log` | giữ, đã bỏ PII, phục vụ pháp lý | 365 ngày |
App: xoá sạch Drift + keychain ngay khi nhận `202`; quay về màn guest.

---

## 3. Nhóm FR-ROU · Food Roulette (module `roulette`)

### 3.1 `GET /v1/dishes/taxonomy` — cây món + tag (đổ vào DB cục bộ)
| Query | Kiểu | Mặc định | Mô tả |
| --- | --- | --- | --- |
| `fields` | enum | `full` | `filters_only` (chỉ những attr được dùng ở FR-ROU-02) \| `full` |
| `locale` | `vi`\|`en` | header | |

`200`
```json
{
  "version": 20261101,
  "categories": [ { "id": "cat_01J8", "slug": "mon-nuoc", "name": "Món nước", "level": 1,
                    "children": [ { "id": "cat_01J9", "name": "Bún", "level": 2,
                                    "children": [ { "id": "cat_01JA", "name": "Bún bò", "level": 3 } ] } ] } ],
  "filter_dimensions": {
    "meal":         ["breakfast","lunch","dinner","late_night"],
    "price_level":  [1,2,3,4],
    "region":       ["north","central","south","all"],
    "temp":         ["hot","warm","cold"],
    "mood":         ["comfort","light","greedy","fresh","local_specialty","quick"],
    "party_size":   [1,2,4,6,8],
    "type":         ["noodle","rice","bread","sweet","grill","salad","drink","snack"],
    "diet":         ["vegetarian","vegan","halal","no_pork","no_beef"]
  },
  "tags": [ { "id": "tag_01J8", "kind": "allergen", "label": "Hải sản", "label_en": "Seafood" } ],
  "counts": { "dishes": 342, "categories": 87, "tags": 46 }
}
```
**Test traceability**: `counts.dishes >= 300` ⇒ chứng minh "tối thiểu 300 món khi ra mắt" (FR-ROU-01).

### 3.2 `GET /v1/dishes/bundle?since_version=20261015` — quay không cần mạng `FR-ROU-10`
**Headers**: `Authorization` optional (bundle là public), `If-None-Match`
**Output `200`** (full hoặc delta)
```json
{
  "version": 20261101, "is_delta": true, "base_version": 20261015,
  "etag": "\"b20261101\"",
  "upsert": [ { "id": "dsh_01J8", "name": "Bún bò Huế", "category_id": "cat_01JA", "region": "central",
                "temp": "hot", "meal": ["breakfast","lunch"], "tags": ["tag_pork","tag_spicy"],
                "price_level": 2, "base_weight": 1.0, "image_url": "https://cdn.../bunbo.webp" } ],
  "deactivate": ["dsh_01J7"],
  "signature": "base64(Ed25519(...))"
}
```
`304 Not Modified` nếu client gửi `If-None-Match` trùng. App verify `signature` bằng public key trong bundle (chống bundle giả), ghi Drift, dùng khi `network=offline`.
**Kích thước mục tiêu**: full < 350 KB gzip, delta < 40 KB (test TC-ROU-10).

### 3.3 ⭐ `POST /v1/spins` — CHỨC NĂNG TRỤ CỘT `FR-ROU-01→08` · `NFR-02 p95 < 300 ms`
**Auth**: Bearer/Guest · **Idempotency**: ✗ (mỗi lần quay là một sự kiện mới, chống spam bằng rate limit) · **Rate**: 60/phút/user
**Offline**: app gọi `RouletteEngine` cục bộ từ bundle → response **không có `places`**, có `network_state:"offline_bundle"`, `spin` ghi vào queue để sync sau.

**Input — `application/json`** (toàn bộ optional, server merge với `preferences` của user)
| Path | Kiểu | BẮT BUỘC | Giá trị / ràng buộc | Mặc định | Ví dụ | FR | Ý nghĩa |
| --- | --- | --- | --- | --- | --- | --- | --- |
| `filters.meal` | enum[] | ✖ | `breakfast,lunch,dinner,late_night`; tối đa 4 | theo giờ hiện tại | `["lunch"]` | 01/02 | bữa |
| `filters.price_level_min` | int | ✖ | 1–4 | 1 | `1` | 02 | |
| `filters.price_level_max` | int | ✖ | 1–4, ≥ min | user pref | `2` | 02 | ngân sách |
| `filters.budget_vnd` | int | ✖ | 5.000–2.000.000 | từ budget | `50000` | 02/PER-02 | vượt → giảm P, không loại |
| `filters.type` | enum[] | ✖ | `noodle,rice,bread,sweet,grill,salad,drink,snack` | `[]` | `["noodle"]` | 02 | loại món |
| `filters.region` | enum[] | ✖ | `north,central,south,all` | `[]` | `["south"]` | 02 | vùng miền |
| `filters.temp` | enum | ✖ | `hot,warm,cold,any` | `any` | `"hot"` | 02 | nóng/lạnh |
| `filters.mood` | enum[] | ✖ | `comfort,light,greedy,fresh,local_specialty,quick` | `[]` | `["comfort"]` | 02 | tâm trạng |
| `filters.party_size` | int | ✖ | 1–12 | 1 | `4` | 02 | số người (ảnh hưởng O,U ở match) |
| `locked.category_id` | string | ✖ | node taxonomy bất kỳ cấp | `null` | `"cat_01J9"` | **04** | **khoá "món nước"** → pool chỉ còn con của node này |
| `locked.region` | enum | ✖ | như trên | `null` | `"central"` | 04 | |
| `locked.temp` | enum | ✖ | | `null` | `"hot"` | 04 | |
| `locked.type` | enum | ✖ | | `null` | `"noodle"` | 04 | |
| `diet.override_strict` | string[] | ✖ | chỉ được **thêm** ràng buộc, không được bỏ ràng buộc đã lưu | `[]` | `["tag_gluten"]` | **03** | an toàn: client không bao giờ được tắt lọc cứng của user |
| `exclude_dish_ids` | string[] | ✖ | ≤ 50 id | `[]` | `["dsh_01J7"]` | 05 | loại tạm thời lượt này |
| `anti_repeat.days` | int | ✖ | 0–30, ghi đè cấu hình | 3 | `5` | **06** | N ngày "chỉnh được" đúng theo SRS |
| `anti_repeat.scope` | enum | ✖ | `dish`\|`category`\|`place` | `dish` | `"category"` | 06 | |
| `wheel_id` | string | ✖ | `whl_...`, P2 | `null` | | 11 | vòng quay tuỳ chỉnh |
| `party_size` / `travel_mode` | | ✖ | như prefs | | `"bike"` | | transfer sang `/matches` |
| `context.overrides` | object | ✖ | `{weather:"rain", is_month_end:true, holiday:"..."}` | server tự suy | | REC-07 (P2) | |
| `client_seed` | string | ✖ | base64 16 B, **chỉ dùng staging/test** để reproduce; prod bị bỏ qua | | | 07 | testability |
| `network_state` | enum | ✖ | `online`\|`offline_bundle` | `online` | | 10 | |

**Output `201`**
```json
{
  "spin_id": "spn_01J8Z6Q9K3M2T7V1",
  "created_at": "2026-11-01T03:20:00Z",
  "dish": { "id": "dsh_01J8", "name": "Bún bò Huế", "name_en": "Bún bò Huế",
            "category_path": ["Món nước","Bún","Bún bò"], "region": "central", "temp": "hot",
            "meal": ["breakfast","lunch"], "price_level": 2,
            "tags": [ {"id":"tag_pork","kind":"diet","label":"Không chay"} ],
            "image_url": "https://cdn.angi.example/dsh_01J8.webp" },
  "proof": { "seed_b64": "kQ2v...=", "sha256_result": "3f9a...c1", "algorithm": "weighted-csprng-v1",
             "pool_hash": "b1e...77", "verify_url": "/v1/spins/spn_01J8Z.../verify" },
  "pool": { "size_initial": 342, "size_after_hard_filters": 61, "size_final": 44   # 342 − (18+3+260) = 61; 61 − 17 = 44,
            "removed": { "diet_hard": 18, "excluded": 3, "locked": 260, "filters": 17, "anti_repeat": 0 } },
  "anti_repeat": { "days_window": 3, "tau_days": 3.0, "applied": [ { "dish_id": "dsh_01KA", "factor": 0.32, "days_since": 1 } ], "max_penalty": 0.68 },
  "applied_filters": { "meal": ["lunch"], "price_level_max": 2, "locked": { "category_id": "cat_01J9" } },
  "animation": { "style": "wheel", "duration_ms": 2600, "reduce_motion": false, "sound": true, "haptics": true,
                 "target_position": 18, "wheel_items": ["dsh_01KG","dsh_01KB","dsh_01J8","dsh_01KC","dsh_01KD","dsh_01KE","dsh_01K4","dsh_01KF"], "result_index": 2 },
  "next": { "action": "fetch_places", "method": "POST", "path": "/v1/matches",
            "suggested_body": { "dish_id": "dsh_01J8", "radius_m": 1500, "limit": 3 } },
  "meta": { "data_quality": "fresh", "personalization_used": true, "experiment_arms": { "anti_repeat_tau": "3d" } }
}
```
**Những field app bắt buộc dùng đúng cách**
- `animation.wheel_items` + `result_index`: server đã **chốt kết quả** (`FR-ROU-07`) và chỉ dẫn hoạt hình dừng ở index nào. App **cấm** đổi kết quả theo hoạt hình.
- **Bất biến `animation`** (server phải guarantee, contract test `TC-ROU-07`): `wheel_items[result_index] == dish.id` và `target_position % wheel_items.length == result_index`. `target_position` là **tổng số ô phải đi qua** từ góc quay ban đầu (đã gồm số vòng quay), không phải index tuyệt đối của ô đích. `wheel_items` là id món; app resolve tên + hue qua `taxonomy`/`dish_bundle` đã cache, **không** tự thêm/bớt phần tử.
- `next.suggested_body`: app gọi thẳng `POST /v1/matches` với body này → đạt "3 chạm đến kết quả" (SRS 2.6.1).
- `pool.size_final == 0` ⇒ không bao giờ xảy ra, server trả lỗi 422 thay vì quay.

**Lỗi domain**
| HTTP | code | Điều kiện | `details` | App |
| --- | --- | --- | --- | --- |
| 422 | `DIET_FILTER_EMPTY` | hard filters loại sạch pool | mảng chính xác từng ràng buộc thủ phạm + `conflicting_with` | đề xuất bỏ **một** ràng buộc mềm |
| 422 | `FILTER_CONTRADICTION` | `temp=cold` ∩ `locked.temp=hot` | | hiện xung đột |
| 409 | `POOL_TOO_SMALL` | `size_final < 3` | `suggested_relaxations[]` | nới 1 bước rồi quay lại |
| 429 | `RATE_LIMITED` | > 60/phút | `retry_after_s` | ẩn nút quay 30 s |
| 404 | `WHEEL_NOT_FOUND` | `wheel_id` sai | | về pool chuẩn |

**Backend — 6 bước, map 1-1 sang thuật toán SRS mục 6.2**
1. `HardFilter`: pool = `dish` active − `user_diet.strict(hard)` − `dish_exclusion(permanent/temporary còn hạn)` − `exclude_dish_ids` − `locked.*` − `filters.*`.
2. `PersonalWeight`: `pref(d)` từ `preferences.mood/region/meal` + `user_diet.preferred`.
3. `AntiRepeat`: query `spin`+`visit` 30 ngày → `exp(−Δdays/τ)`; `τ` từ remote config (mặc định 3).
4. `w = base × pref × decay`; tổng `W`.
5. `r = CSPRNG.nextDouble() * W` → duyệt tích luỹ → `dish`. **Ghi `seed_b64`, `sha256_result = H(seed ‖ dish_id ‖ pool_hash)`** → INSERT `spin`. *Toàn bộ bước 1–5 chạy **trước khi** response được trả, tức trước khi app khởi động hoạt hình.*
6. Build `animation` + `next`.

**Ví dụ gọi thật**
```bash
curl -sS -X POST https://api.angi.example/v1/spins \
  -H "Authorization: Bearer $TOKEN" -H "Content-Type: application/json" \
  -H "X-Request-Id: 01J8Z6Q9K3M2T7V1" -H "X-Locale: vi" -H "X-Device-Id: 8f2c1a9b" \
  -d '{"filters":{"meal":["lunch"],"price_level_max":2,"mood":["quick"]},
       "locked":{"category_id":"cat_01J9"},"anti_repeat":{"days":5}}'
```

### 3.4 `GET /v1/spins/{id}` · `GET /v1/spins?cursor&limit&from` · `POST /v1/spins/{id}/verify`
`GET /v1/spins/{id}` → cùng shape 3.3 + `outcome: {dismissed: bool, place_chosen: plc_...|null, visited: bool}` (phục vụ chỉ số "số lần quay trước khi chốt", SRS 12.2).
`GET /v1/spins` → `items[]` rút gọn `{spin_id, dish{id,name,image_url}, created_at, filters_digest, outcome}`.
`POST /v1/spins/{id}/verify` — input `{ "claim_sha256": "3f9a...c1" }` → `200 {valid: true, method, pool_hash}`: **bằng chứng kiểm chứng** cho FR-GRP-05 và chống nghi ngờ "kết quả bị xếp trước".

### 3.5 `POST /v1/spins/{id}/dismiss` — 3 lần bỏ qua liên tiếp `FR-ROU-12` **[P2]**
Input: `{ "reason": "not_craving"|"too_far"|"too_expensive"|"already_ate"|"other", "note": string≤140 }` → `200 { dismissed_streak: 3, suggestion: { action: "narrow_filters"|"use_urgent", payload: { relax: [{dimension:"mood", remove:"comfort"}], radius_m: 2500 } } }`. Server chỉ gợi ý, **không tự đổi bộ lọc**.

### 3.6 Exclusions — quản lý danh sách loại `FR-ROU-05`
| Method | Path | Input | Output |
| --- | --- | --- | --- |
| `GET` | `/v1/exclusions` | `?scope=all\|temporary\|permanent` | `items[] {dish_id, name, image_url, scope, created_at, expires_at}` |
| `POST` | `/v1/exclusions` | `{dish_id ✔, scope: temporary\|permanent ✔, days: int 1–90 (khi temporary)}` | `201` entity |
| `DELETE` | `/v1/exclusions/{dish_id}` | — | `204` (món quay lại pool từ lần quay kế) |

Idempotency bắt buộc với `POST` (double-tap trên mobile). Duplicate ⇒ `200` entity cũ + `X-Idempotency-Replayed: true`.

---

## 4. Nhóm FR-PLC · Vị trí, quán và báo sai (module `place`)

### 4.1 `POST /v1/geocode` — nhập địa chỉ thủ công (FR-PLC-01, UC-01 ngoại lệ)
| Path | Kiểu | BẮT BUỘC | Ràng buộc | Ví dụ |
| --- | --- | --- | --- | --- |
| `address` | string | ✔ | 4–200 ký tự | `"25 Nguyễn Huệ, Quận 1"` |
| `components.city` | string | ✖ | mặc định thành phố active | `"Hồ Chí Minh"` |
| `bias_geo` | GeoPoint | ✖ | ưu tiên kết quả gần | |
| `limit` | int | ✖ | 1–5 | `3` |

`200`: `{"candidates":[{"id":"ulc_g_...","address":"...","short_address":"25 Nguyễn Huệ","geo":{...},"geohash6":"wgeq7s","kind":"street_address","confidence":0.94,"provider":"nominatim|google"}]}`
Lỗi: `404 GEOCODE_NOT_FOUND` · `424 PROVIDER_UNAVAILABLE` (server tự thử nguồn dự phòng rồi mới lỗi) · `429`.

### 4.2 `GET|POST|PUT|DELETE /v1/user-locations` — lưu nhiều vị trí (nhà, công ty, ghim thủ công)
`POST` input:
| Path | Kiểu | BẮT BUỘC | Ràng buộc | FR |
| --- | --- | --- | --- | --- |
| `label` | enum | ✔ | `home\|work\|pinned\|custom` | PLC-01, PER (du lịch ghim thủ công) |
| `name` | string | khi `custom` | ≤ 60 | |
| `geo` | GeoPoint | ✔ (1 trong 2) | | |
| `geohash6` | string | ✔ (server tính nếu thiếu) | | |
| `address` | string | ✖ | từ geocode | |
| `is_default` | bool | ✖ (mặc định `false`) | `true` ⇒ unset các dòng khác (atomic) | |
| `consent_location` | bool | ✔ | phải `true` | SRS 11 |

`201` → entity `{id, label, name, geo, address, geohash6, is_default, created_at}`. `GET` → `items[]`. `PUT /{id}` patch. `DELETE` → `204`; nếu là `is_default` ⇒ server tự promote vị trí còn lại mới nhất (app phải handle `409 DEFAULT_LOCATION_REFERENCED`).

### 4.3 ⭐ `GET /v1/places/nearby` — tìm quán theo bán kính `FR-PLC-02/03` · `NFR-01`
**Auth**: Bearer/Guest · **Rate**: 120/phút · **SLA**: p95 < 500 ms (cache), < 1,5 s (provider)

| Query | Kiểu | BẮT BUỘC | Ràng buộc | Mặc định | FR | Ghi chú |
| --- | --- | --- | --- | --- | --- | --- |
| `geo` | `lat,lng` 6dp | ✔ **một trong ba** | trong bounding box city active | | PLC-01 | GPS |
| `user_location_id` | string | ⃠ | `ulc_...` của chính user | | PLC-01 | |
| `address` | string | ⃠ | server geocode rồi tìm | | PLC-01 | |
| `radius_m` | int | ✖ | 200–5000, bước 100 | 1500 | PLC-02 | bộ trượt trên app |
| `dish_id` | string[] | ✖ | ≤ 5 id | | REC-01 | nếu có → chỉ quán phục vụ món đó |
| `category_id` | string | ✖ | node taxonomy | | | "quán món nước gần đây" |
| `meal` | enum | ✖ | | suy từ giờ | | |
| `open_now` | bool | ✖ | | **true** | PLC-06 | `false` mới trả quán đã đóng |
| `min_rating` | number | ✖ | 0–5, bước 0.1 | 0 | PLC-04 | **P2** |
| `price_level_max` | int | ✖ | 1–4 | | PLC-02 | |
| `budget_vnd` | int | ✖ | | user budget | REC | |
| `amenities` | csv | ✖ | `parking,ac,group_friendly,takeaway,wifi` | | PLC-04 | **P2** |
| `party_size` | int | ✖ | 1–12 | 1 | PLC-04 | **P2** |
| `diet` | csv | ✖ | tag id; mặc định lấy `user_diet.strict` | | ROU-03 | client **không** xoá được diet đã lưu |
| `sort` | enum | ✖ | `score`\|`distance`\|`rating`\|`newest`\|`price_asc` | `score` | | `score` là mặc định và là duy nhất có `score_breakdown` |
| `view` | enum | ✖ | `list`\|`map` | `list` | PLC-03 | `map` → server trả `cluster` + bỏ `why` để nhẹ payload |
| `zoom` | int | ✖ | 8–20, bắt buộc khi `view=map` | | PLC-03 | clustering geohash |
| `travel_mode` | enum | ✖ | `walk\|bike\|car` | user pref | 6.1 | quyết định `λ` |
| `cursor`,`limit` | | ✖ | limit 1–50 | 20 | | |
| `include_sponsored` | bool | ✖ | | false | REC-04 | **P3** |

**Output `200`**
```json
{
  "items": [
    { "id": "plc_01J8...", "name": "Bún bò O Xuân", "address": "12 Lê Lợi, Q.1",
      "geo": { "lat": 10.7761, "lng": 106.7039 }, "travel_mode": "walk",
      "distance_m": 420, "walk_minutes": 6,
      "price_level": 2, "price_range_vnd": { "min": 35000, "max": 55000 }, "avg_price_vnd": 42000,
      "rating_raw": 4.41, "rating_bayesian": 4.28, "review_count": 182,
      "open_status": { "is_open": true, "closes_in_min": 47, "closing_soon": false, "o_score": 1.0, "tz": "Asia/Ho_Chi_Minh" },
      "cuisine_tags": ["Món nước","Bún bò"],
      "dish_highlights": [ { "dish_id": "dsh_01J8", "name": "Bún bò Huế", "confidence": 0.93, "price_vnd": 45000 } ],
      "badges": ["top_rated"],
      "source": { "provider": "osm+community", "verified_at": "2026-08-14T00:00:00Z", "data_confidence": 0.81 },
      "score_breakdown": { "score_total": 68.85, "top_component": "Q", "components": [ /* DTO §1.4 */ ] },
      "why": { "headline": "4,3★ từ 182 đánh giá · cách 420 m · đang mở tới 13:30",
               "bullets": [ "Điểm cao nhờ 182 đánh giá thật", "Cách bạn 6 phút đi bộ", "Còn mở 47 phút" ],
               "key": "why.headline", "params": { "rating": "4.3", "count": "182", "distance": "420" } } }
  ],
  "page": { "next_cursor": "...", "has_more": true, "total_estimate": 37 },
  "context": { "anchor": { "geo": { "lat": 10.7790, "lng": 106.7020 }, "label": "work" },
               "radius_m": 1500, "requested_dish_ids": ["dsh_01J8"], "now": "2026-11-01T03:20:00Z" },
  "clusters": [ { "geohash": "wgeq7s", "count": 14, "center_geo": { "lat": 10.776, "lng": 106.703 },
                  "top_item_ids": ["plc_01J8"], "expand_cursor": "..." } ],
  "relaxation": null,
  "meta": { "data_quality": "fresh", "generated_at": "...", "cache_age_s": 0, "providers_used": ["db"], "experiment_arms": {} }
}
```
**`clusters` chỉ có khi `view=map`** — app map dùng để gộp pin, khỏi tự tính clustering phía client.
**Lỗi**: `400 LOCATION_REQUIRED` (thiếu cả 3 nguồn vị trí) · `403 LOCATION_NOT_AUTHORIZED` (`user_location_id` của user khác → **IDOR test bắt buộc**) · `422 OUTSIDE_SERVICE_AREA` (ngoài thành phố P1) · `424 PROVIDER_UNAVAILABLE` → nếu cache có, vẫn `200` + `X-Data-Quality: stale` · `429`.

### 4.4 ⭐ `POST /v1/matches` — món → quán + "Vì sao" (chức năng ăn khớp FR-PLC + FR-REC)
Khác `nearby`: endpoint này **bắt buộc có `dish_id` (hoặc `dish_ids`)**, chạy pipeline xếp hạng đầy đủ, trả `relaxation` + `substitute_dishes` (FR-REC-05) và sinh ra ngay sau một lần quay.

**Input**
| Path | Kiểu | BẮT BUỘC | Ràng buộc | Mặc định | FR |
| --- | --- | --- | --- | --- | --- |
| `dish_id` | string | ✔ một trong | `dsh_...` active | | REC-01 |
| `dish_ids` | string[] | ⃠ | ≤ 10, dùng sau khi quay nhóm | | REC-01 |
| `spin_id` | string | ✖ | nếu có → server đọc `spin.filters` + `diet` + `pool_hash` để reproduce đúng lần quay (FR-ROU-07 trace) | | |
| `geo` / `user_location_id` / `address` | | ✔ một trong | như 4.3 | | PLC-01 |
| `radius_m` | int | ✖ | 200–5000 | 1500 | PLC-02 |
| `limit` | int | ✖ | 1–10 | **3** (UC-01 "3 quán phù hợp nhất") | |
| `filters` | object | ✖ | same shape `filters` của `POST /v1/spins` (meal, price, region, temp, mood, party_size, budget_vnd) | từ spin/user | ROU-02 |
| `diet.strict_extra` | string[] | ✖ | chỉ thêm | | ROU-03 |
| `travel_mode` | enum | ✖ | `walk\|bike\|car` | pref | 6.1 |
| `preference_bias` | object | ✖ | `{closer: -1..1, tastier: -1..1, cheaper: -1..1}` — **P2** | 0/0/0 | REC-08 |
| `context` | object | ✖ | `{weather, is_month_end, holiday}` — **P2**, server tự suy nếu thiếu | auto | REC-07 |
| `exclude_place_ids` | string[] | ✖ | quán user vừa bỏ qua | | ROU-12 |
| `include_closed` | bool | ✖ | | false | PLC-06 |
| `personalization` | bool | ✖ | `false` = tắt U (FR-REC-06) | user opt-in | REC-06 |

**Output `200`**
```json
{
  "dish": { "id": "dsh_01J8", "name": "Bún bò Huế", "category_path": ["Món nước","Bún","Bún bò"] },
  "items": [ { /* Place DTO đầy đủ + score_breakdown + why */ } ],
  "relaxation": { "applied": false, "steps_available": [
      { "dimension": "radius_m", "from": 1500, "to": 2500, "expected_extra": 12, "why_key": "relax.radius" },
      { "dimension": "price_level_max", "from": 2, "to": 3, "expected_extra": 4, "why_key": "relax.price" } ] },
  "substitute_dishes": [ { "id": "dsh_01KB", "name": "Bún bò Nam Bộ", "similarity": 0.74,
                           "reason_key": "substitute.similar_category" } ],
  "context_used": { "local_time": "10:20", "dow": "sunday", "weather": "rain", "month_end": false,
                    "weight_overrides": { "D": 0.30, "O": 0.20 } },
  "meta": { "data_quality": "provider_degraded", "providers_used": ["db","osm"],
            "formula_version": "2026.10", "candidate_count": 61, "returned": 3,
            "latency_ms": { "total": 780, "db": 45, "provider": 0, "scoring": 22 } }
}
```
**Bất biến phải test (FR-REC-04)**: `natural_rank` của item `is_sponsored=true` **không được** nhỏ hơn rank tự nhiên của nó; danh sách `sort=score` khi bỏ `include_sponsored` phải giống hệt hệ cũ.
**Khi 0 kết quả**: `items: []` + `relaxation.applied: false` + `steps_available[]` **không rỗng** + `substitute_dishes[]` — app hiện "Không có quán phù hợp, nới bán kính?" (FR-REC-05). Không bao giờ trả `404`.
**Lỗi**: `400 VALIDATION_FAILED` · `404 DISH_NOT_FOUND` · `422 DIET_FILTER_EMPTY` · `424 PROVIDER_UNAVAILABLE` (vẫn `200` nếu cache/db trả được) · `429`.

### 4.5 `GET /v1/places/urgent` — Đói gấp một chạm `FR-ROU-09` · UC-03 · `< 2 s`
**Query** (tất cả optional, server tự điền từ hồ sơ): `geo|user_location_id|address`, `radius_m` (mặc định 1500, tự nới 2500→4000), `travel_mode`, `budget_vnd`, `party_size`, `dish_id` (nếu user vừa quay và muốn giữ món).
**Hành vi cứng**: `open_now=true` + `closes_at − now ≥ 45′` + diet hard filter + **không** chạy bước quay món, **không** chờ provider (chỉ DB+Redis).
**Output `200`**
```json
{
  "place": { /* Place DTO đầy đủ + score_breakdown */ },
  "decision": { "radius_m_used": 2500, "expanded": true, "candidates_considered": 22,
                "one_tap_action": "navigate",
                "fallback_dish": { "id": "dsh_01J8", "name": "Bún bò Huế", "reason_key": "urgent.nearby_match" } },
  "alternatives": [ { "id": "plc_01J9...", "name": "Bún bò Cô Mai", "why_key": "alt.closing",
                      "why_params": { "distance": "900", "minutes": "25" } } ],
  "open_status": { "is_open": true, "closes_in_min": 51, "closing_soon": false, "o_score": 1.0 },
  "meta": { "data_quality": "fresh", "latency_ms": 640 }
}
```
Ngoại lệ UC-03: 0 quán mở trong 4 km → `200` với `place: null`, `decision.expanded: true`, `decision.notify_key: "urgent.none_open"`, `alternatives[]` là quán **sắp mở** (mở trong ≤ 30′). Không trả lỗi — luồng một chạm không được chết.
**`alternatives[].why_key` + `why_params`** (không phải chuỗi đã dịch): server không bao giờ trả text UI (`docs/01` §4.6, NFR-11) ⇒ app render qua `app_vi.arb`/`app_en.arb`. Enum `why_key` cho alternatives: `alt.closing`, `alt.open_later`, `alt.farther`.

### 4.6 `GET /v1/places/{id}` — trang chi tiết `FR-PLC-05`
**Query**: `?sections=core,hours,menu,images,reviews,contact,amenities,source` (mặc định `core,hours,menu,images,contact`)
**Output `200`**: Place DTO đầy đủ +
```json
{
  "hours_by_dow": [ { "dow": 1, "opens_at": "06:30", "closes_at": "13:30", "is_closed": false } ],
  "hours_exceptions": [ { "date": "2026-12-31", "reason": "holiday", "is_closed": true } ],
  "menu": { "dishes": [ { "dish_id": "dsh_01J8", "name": "Bún bò Huế", "price_vnd": 45000, "confidence": 0.93, "popular": true } ],
            "source": "partner|community|osm", "updated_at": "2026-08-14T00:00:00Z" },
  "images": [ { "url": "https://cdn.../1.webp", "credit": "OpenStreetMap contributor", "source": "osm", "is_user_submitted": false } ],
  "reviews": { "summary": { "avg": 4.41, "count": 182, "verdict_split": { "good": 141, "ok": 28, "bad": 13 } },
               "items": [ /* P3: {id, verdict, tags, text, author{anon}, checkin_verified} */ ] },
  "contact": { "phone_e164": "+84903...", "booking_url": null, "delivery_url": "https://..." },
  "report_summary": { "count_30d": 2, "pending": 1, "last_kind": "wrong_hours", "can_report": true, "cooldown_s": 0 },
  "similar_places": [ { "id": "plc_01J9", "name": "...", "distance_m": 640 } ]
}
```
`410 GONE` khi quán đóng vĩnh viễn (vẫn đọc được 30 ngày để trace lịch sử). `404` nếu id sai/ẩn.

### 4.7 `POST /v1/places/{id}/reports` — báo sai thông tin `FR-PLC-07`
**Headers**: `X-Idempotency-Key` bắt buộc (mobile double-tap) · **Auth**: optional (guest cũng báo được — giảm rủi ro "dữ liệu vỉa hè thiếu" SRS 12.3)

| Path | Kiểu | BẮT BUỘC | Ràng buộc | Ví dụ |
| --- | --- | --- | --- | --- |
| `kind` | enum | ✔ | `closed`\|`wrong_hours`\|`wrong_price`\|`wrong_location`\|`wrong_name`\|`duplicate`\|`other` | `"wrong_hours"` |
| `detail` | string | ✖ | ≤ 500 | `"Quán đóng 11h30 chứ không phải 13h30"` |
| `suggested_value` | object | ✖ | theo `kind`: `{closes_at:"11:30"}`, `{price_vnd:35000}`, `{geo:{...}}` | |
| `observation_geo` | GeoPoint | ✖ | nơi user đứng khi báo → tăng độ tin | |
| `observation_at` | date-time | ✖ | default now | |
| `upload_ids` | string[] | ✖ | ≤ 3 ảnh bằng chứng (P2) | |

`201`: `{"report_id":"rpt_01J8...","status":"open","queued_for_review":true,"credited":false,"affects_ranking_after_review":true,"cooldown_s":300}`
**Anti-spam**: unique `dedup_key = (place_id, kind, user_or_device, day)` → duplicate trả `200` + `duplicate_of`. Max 5 report/user/ngày → `429 REPORT_LIMIT`.
**Tác động tới xếp hạng (quan trọng để test FR-REC penalty)**: report chỉ vào `place.report_count_30d` và `data_confidence`; **penalty chỉ áp dụng sau khi kiểm duyệt `accepted`** → tránh một người ghét quán kéo tụt rank. QA verify: `accepted` → `score_breakdown.penalty` tăng trong ≤ 10 phút (enrichment worker).
`404` · `429 RATE_LIMITED` · `409 REPORT_ALREADY_RESOLVED`.

---

## 5. Nhóm FR-PER + config (module `identity`/`admin`)

### 5.1 `GET /v1/config` — remote config + feature flag + tài nguyên động (SRS 2.6.6)
**Query**: `?platform=android&app_version=1.0.0&country=VN` · **Cache**: `Cache-Control: public, max-age=120`
**Output `200`**
```json
{
  "config_version": "2026.11.01.3", "policy_version": "2026.10",
  "min_app_version": { "ios": "1.2.0", "android": "1.2.0" }, "force_upgrade": false,
  "flags": { "roulette_v2": "on", "group_rooms": "off", "journal": "off", "reviews": "off",
             "weather_context": "off", "merchant_portal": "off" },
  "ranking_weights": { "Q": 0.35, "D": 0.25, "P": 0.15, "O": 0.15, "U": 0.10, "version": "2026.10" },
  "spin": { "anti_repeat_days_default": 3, "tau_days": 3.0, "min_pool": 3, "rate_limit_per_min": 60 },
  "place": { "radius_default_m": 1500, "radius_max_m": 5000, "closing_soon_min": 30,
             "open_min_left_to_score_1": 45, "urgent_radius_steps": [1500,2500,4000] },
  "animation_styles": ["wheel","chest","draw"], "locale_supported": ["vi","en"],
  "dish_bundle_version": 20261101,
  "feature_gates": { "requires_consent_location": ["places_nearby","urgent"],
                     "requires_account": ["lists","sync","share_card"] },
  "experiments": { "ranking_weights_v2": "control" }
}
```
**Đây là nơi duy nhất app được lấy hằng số nghiệp vụ** — không hard-code "30 phút", "45 phút", "τ=3 ngày". Đổi trọng số xếp hạng **không cần phát hành lại app** (SRS mục 9).

### 5.2 `PUT /v1/me/settings` — xem §2.6 (FR-PER-01)
### 5.3 `PUT /v1/me/budget` · `GET /v1/me/budget/status` — FR-PER-02 **[P2]**
`PUT`: `{ "weekly_vnd": 350000, "alert_threshold_pct": 80, "week_start_dow": 1, "prioritize_cheap": true }`
`GET`: `{ "weekly_vnd", "spent_vnd", "remaining_vnd", "week_window": {start,end}, "alert_active": true, "alert_message_key": "budget.near_limit", "top_category_this_week": "món nước", "trend_vs_last_week_pct": +12 }`

### 5.4 `PUT /v1/me/reminders` — FR-PER-03 **[P2]**, mặc định TẮT
`{ "enabled": true, "slots": [ { "time": "11:15", "days": [1,2,3,4,5], "tz": "Asia/Ho_Chi_Minh", "kind": "lunch", "deep_link": "angi://spin?mode=urgent" } ] }` (tối đa 4 slot). Backend qua `notification` worker + FCM/APNs; `POST /v1/devices/push-token` để cập nhật token: `{ "token", "provider": "fcm|apns", "platform", "timezone", "locale" }` → `200 {valid: true}`; token hết hạn → server set `device.token_valid=false` (test bằng token giả).

---

## 6. FR-JRN tối thiểu cho P1 (ghi "Tôi đã đến" của UC-01)

### 6.1 `POST /v1/journal/visits` — bản P1-lite (bản đầy đủ + sync ở file `03`)
**Headers**: `X-Idempotency-Key` bắt buộc (offline queue sẽ retry cùng key → không tạo visit trùng)
| Path | Kiểu | BẮT BUỘC | Ràng buộc | FR | Ý nghĩa |
| --- | --- | --- | --- | --- | --- |
| `place_id` | string | ✔ | `plc_...` active | JRN-01 | |
| `dish_id` | string | ✖ | | JRN-01 | |
| `spin_id` | string | ✖ | truy vết "quay → chốt" (chỉ số chính SRS 12.2) | | |
| `status` | enum | ✔ | `chosen`\|`arrived`\|`completed` | NAV-04 | `arrived` = "Tôi đã đến" |
| `source` | enum | ✖ | `manual`\|`checkin`\|`nav_open` | NAV-04 | |
| `spend_vnd` | int | ✖ | 0–10.000.000 (P2) | JRN-03 | |
| `note` | string | ✖ | ≤ 500 (P2) | JRN-03 | |
| `private_rating` | int | ✖ | 1–5 (P2) | JRN-03 | **không** ảnh hưởng `rating_raw` |
| `upload_ids` | string[] | ✖ | ≤ 6 (P2) | JRN-03 | |
| `occurred_at` | date-time | ✖ | `now − 7 ngày ≤ x ≤ now` | | ghi offline |
| `device_updated_at` / `device_version` | | ✖ | cho merge xung đột P2 | JRN-05 | |

`201`: `{ "id": "vst_01J8...", "status": "arrived", "occurred_at": "...", "ask_review": true, "review_prompt_key": "prompt.rate_after_visit", "budget_delta_vnd": 45000 }`
`ask_review` bật theo **tần suất có kiểm soát**: ≤ 1 lời mời/quán/tháng, ≤ 2/tuần/user (chống làm phiền — NFR-09 SUS ≥ 80).
Lỗi: `404 PLACE_NOT_FOUND` · `409 IDEMPOTENCY_REPLAY` (trả bản cũ) · `400 FUTURE_DATE`.

### 6.2 `POST /v1/uploads/policy` — chữ ký upload ảnh (FR-PLC-05, FR-JRN-03, FR-COM-01)
`{ "purpose": "place_image|visit_photo|avatar|dish_image", "mime": "image/jpeg|image/png|image/webp", "size_bytes": int, "client_sha256": string }`
→ `201 { "upload_id": "upl_...", "method": "PUT", "url": "https://s3.../signed", "headers": {"Content-Type":"image/jpeg"}, "expires_in": 300, "max_side_px": 2048, "max_bytes": 8388608 }`
Server verify bằng `client_sha256` khi worker xử lý; ảnh > 8 MB hoặc mime không khớp ⇒ `status: rejected` (test TC-SEC-UPLOAD).

---

## 7. Nhóm FR-ADM — trang quản trị P1 (module `admin`, role `admin|moderator`)

> Auth: `Bearer` với claim `roles=["admin"]`; **mọi** endpoint `/v1/admin/*` trả `403 FORBIDDEN` với user thường. Audit log **mọi** thao tác ghi (`actor`, `before`, `after`, `reason`).

### 7.1 Kho món & taxonomy — `FR-ADM-01`
| Method | Path | Input | Output |
| --- | --- | --- | --- |
| `GET` | `/v1/admin/dishes?search&category_id&tag&is_active&cursor` | query filter | `items[]` Dish DTO + `bundle_version` |
| `POST` | `/v1/admin/dishes` | `{name_vi ✔, name_en, category_id ✔, region ✔, temp ✔, meal[] ✔, price_level ✔, base_weight 0.1–5.0, tags[] , image_upload_id, is_active}` | `201` Dish + `bundle_version` mới |
| `PATCH` | `/v1/admin/dishes/{id}` | merge-patch, kèm `reason` | `200` |
| `POST` | `/v1/admin/dishes/{id}/deactivate` | `{reason ✔}` | `200` — món biến mất khỏi pool quay **ngay** (invalidate cache taxonomy + bundle version++) |
| `GET\|POST\|PATCH\|DELETE` | `/v1/admin/categories` | `{parent_id, name_vi, name_en, slug, level}` | cây taxonomy |
| `GET\|POST\|PATCH` | `/v1/admin/tags` | `{kind ∈ cuisine\|diet\|allergen\|attribute, label_vi, label_en, is_hard_filter}` | `is_hard_filter=true` ⇒ tham gia lọc cứng FR-ROU-03 |
| `POST` | `/v1/admin/bundle/publish` | `{note}` | `200 {bundle_version}` — bước bắt buộc để app nhận món mới offline |

**Ràng buộc nghiệp vụ khi code**: `category_id` phải là **lá** (không có con); đổi `category_id` của món đã có `spin` → không phá `spin` cũ (dish_id vẫn resolve vì `spin` lưu `dish_id` + snapshot tên).

### 7.2 Bảng điều khiển chỉ số — `FR-ADM-02`
| Method | Path | Query | Output chính |
| --- | --- | --- | --- |
| `GET` | `/v1/admin/metrics/overview` | `from`,`to`,`city`,`granularity=hour\|day` | `dau`, `sessions`, `spins`, `spin_to_nav_rate` (**chỉ số chính SRS 12.2**), `avg_spins_to_decision`, `time_to_nav_p50_s`, `d7`, `d30`, `place_result_rate`, `wrong_info_report_rate`, `crash_free_pct`, `api_cost_per_dau`, `series[]` |
| `GET` | `/v1/admin/metrics/funnel` | `from,to` | `open_app → spin_shown → place_shown → nav_opened → arrived`, % từng bước, drop-off |
| `GET` | `/v1/admin/metrics/feature/{key}` | `variant` | so sánh A/B + `significance`, `n_per_arm` |
| `GET` | `/v1/admin/flags` · `POST/PATCH /v1/admin/flags` | | `{key, rollout_pct, variants, targeting jsonb, updated_by}`; thay đổi ⇒ publish `flag.changed` → gateway/monolith refresh < 30 s |
| `GET|POST /v1/admin/experiments` · `POST /v1/admin/experiments/{key}/assign-preview` | `{user_or_device_id}` | arm được gán (bucket = `HMAC(experiment_key, user_id)`) — **hàm thuần, test được** |

### 7.3 Giám sát nhà cung cấp — `FR-ADM-03`
`GET /v1/admin/providers/status?days=7`
```json
{ "providers": [ { "name": "osm", "enabled": true, "health": "ok",
                   "calls_24h": 41200, "cache_hit_pct": 91.3, "error_pct": 0.4,
                   "p95_ms": 320, "quota": { "limit": 50000, "used": 41200, "resets_at": "..." },
                   "cost_estimate_vnd_month": 0, "tos_cache_ttl_h_max": 24 },
                 { "name": "google", "enabled": true, "health": "degraded",
                   "calls_24h": 3100, "cache_hit_pct": 68.0, "error_pct": 7.2,
                   "quota": { "limit": 10000, "used": 9400, "resets_at": "..." },
                   "cost_estimate_vnd_month": 18500000 } ],
  "budget": { "monthly_cap_vnd": 30000000, "spent_vnd": 18500000, "alert_pct": 70, "alert_active": true },
  "fallback_chain": ["db","osm","google","community"],
  "degraded_mode_active": false }
```
`PATCH /v1/admin/providers/{name}` `{enabled, weight, timeout_ms, circuit_breaker:{error_ratio_threshold, open_s}}` → bật/tắt nguồn **nóng**, không restart.
Đây là màn hình bạn dùng để chứng minh **NFR-15** (hạn mức + cảnh báo chi phí) và để test FR-PLC-08: `enabled=false` cho `google` rồi gọi `/v1/places/nearby` ⇒ phải ra kết quả + `meta.data_quality:"provider_degraded"`.

### 7.4 Quản trị quán & hợp nhất nguồn
| Method | Path | Input | Output / hành vi |
| --- | --- | --- | --- |
| `GET` | `/v1/admin/places?city&needs_verification&low_confidence&has_pending_report&cursor` | | danh sách ưu tiên xử lý (SRS 12.3 "ưu tiên xác minh quán top") |
| `GET` | `/v1/admin/places/{id}/sources` | | `place_source_ref[]` theo từng provider, field nào đang lấy từ đâu |
| `POST` | `/v1/admin/places/{id}/merge` | `{loser_place_id ✔, reason ✔}` | chuyển `place_dish`, `visit`, `review`, `room_candidate`; loser → `merged_into`, soft-delete 30 ngày (**reversible** — không xoá hard) |
| `PATCH` | `/v1/admin/places/{id}` | `{name?, address?, geo?, avg_price_vnd?, price_level?, amenities?, verified?:bool}` | `verified:true` ⇒ `verified_at=now`, `data_confidence=0.95`, penalty `stale_verification` = 0 |
| `PUT` | `/v1/admin/places/{id}/hours` | `{hours_by_dow[7], exceptions[]}` | ghi `place_hours` + `place_hours_exception`; invalidate `open_status` cache |
| `GET` | `/v1/admin/reports?status=open&kind&city` · `POST /v1/admin/reports/{id}/decision` | `{decision: accept\|reject, applied_change?, note}` | `accept` → cập nhật field + giảm `data_confidence` + tăng `penalty`; `reject` → strike cho reporter |

---

## 8. Bảng tổng hợp endpoint P1 (dùng làm checklist implement + contract test)

| # | Method + Path | Chức năng | FR | Auth | Idemp | SLA p95 |
| --- | --- | --- | --- | --- | --- | --- |
| 1 | `POST /v1/auth/guest` | dùng ngay | AUTH-01 | – | ✔ | 150 ms |
| 2 | `POST /v1/auth/oauth` | Google/Apple + upgrade | AUTH-02/03 | –/Guest | ✔ | 400 ms |
| 3 | `POST /v1/auth/otp/request` | gửi OTP | AUTH-02 | – | ✔ | 800 ms |
| 4 | `POST /v1/auth/otp/verify` | verify OTP | AUTH-02 | – | ✔ | 200 ms |
| 5 | `POST /v1/auth/refresh` | xoay refresh | – | – | ✖ | 100 ms |
| 6 | `POST /v1/auth/logout` | đăng xuất | – | Bearer | ✖ | 100 ms |
| 7 | `GET /v1/me` | hồ sơ + prefs + flags | AUTH, PER-01 | Bearer | ✖ | 120 ms |
| 8 | `PUT /v1/me` | tên/avatar | AUTH-04 | Bearer | ✔ | 200 ms |
| 9 | `PUT /v1/me/preferences` | khẩu vị | ROU-02 | Bearer | ✔ | 200 ms |
| 10 | `PUT /v1/me/diet` | kiêng/dị ứng | ROU-03 | Bearer | ✔ | 200 ms |
| 11 | `PUT /v1/me/settings` | locale/theme/chữ/animation | PER-01, ROU-08 | Bearer | ✔ | 200 ms |
| 12 | `PUT /v1/me/onboarding` | 3 màn | AUTH-04 | Bearer | ✔ | 250 ms |
| 13 | `POST /v1/me/consents` | đồng ý | privacy | Bearer | ✔ | 150 ms |
| 14 | `GET /v1/me/export` (+`/{id}`) | xuất dữ liệu | AUTH-05 | Bearer | ✖ | 202 async |
| 15 | `DELETE /v1/me` | xóa tài khoản | AUTH-05 | Bearer | ✔ | 202 async |
| 16 | `POST /v1/devices/push-token` | push token | PER-03 | Bearer | ✔ | 150 ms |
| 17 | `GET /v1/dishes/taxonomy` | cây món + chiều lọc | ROU-01/02 | – | ✖ | 100 ms |
| 18 | `GET /v1/dishes/bundle` | kho offline | ROU-10 | – | ✖ | 500 ms |
| 19 | **`POST /v1/spins`** | **quay món** | ROU-01→08 | Bearer/Guest | ✖ | **300 ms** |
| 20 | `GET /v1/spins/{id}` · `GET /v1/spins` | lịch sử quay | ROU, JRN-01 | Bearer | ✖ | 150 ms |
| 21 | `POST /v1/spins/{id}/verify` | kiểm chứng | ROU-07 | Bearer | ✖ | 100 ms |
| 22 | `POST/PATCH/DELETE /v1/exclusions` | loại món | ROU-05 | Bearer | ✔ | 150 ms |
| 23 | `POST /v1/geocode` | địa chỉ → toạ độ | PLC-01 | Bearer | ✖ | 700 ms |
| 24 | CRUD `/v1/user-locations` | nhà/công ty/ghim | PLC-01 | Bearer | ✔ | 150 ms |
| 25 | **`GET /v1/places/nearby`** | **quán gần** | PLC-02/03/06 | Bearer/Guest | ✖ | **500 ms cache / 1,5 s provider** |
| 26 | **`POST /v1/matches`** | món→quán + vì sao | REC-01→05 | Bearer/Guest | ✖ | 600 ms |
| 27 | **`GET /v1/places/urgent`** | **Đói gấp** | ROU-09 | Bearer/Guest | ✖ | **1,5 s** |
| 28 | `GET /v1/places/{id}` | chi tiết quán | PLC-05 | – | ✖ | 400 ms |
| 29 | `POST /v1/places/{id}/reports` | báo sai | PLC-07 | optional | ✔ | 250 ms |
| 30 | `POST /v1/journal/visits` | tôi đã đến | NAV-04, JRN-01 | Bearer | ✔ | 250 ms |
| 31 | `GET /v1/config` | remote config | 2.6.6 | – | ✖ | 100 ms |
| 32 | `POST /v1/uploads/policy` | chữ ký upload | PLC-05 | Bearer | ✔ | 200 ms |
| 33–40 | `/v1/admin/dishes`, `/categories`, `/tags`, `/bundle/publish` | kho món | ADM-01 | admin | ✔ | 300 ms |
| 41–44 | `/v1/admin/metrics/*`, `/flags`, `/experiments` | dashboard | ADM-02 | admin | ✔ | 1 s |
| 45–46 | `/v1/admin/providers/*` | giám sát | ADM-03 | admin | ✔ | 500 ms |
| 47–52 | `/v1/admin/places*`, `/merge`, `/hours`, `/reports` | dữ liệu quán | ADM-04, PLC-07 | admin | ✔ | 600 ms |

**Không có endpoint nào khác ở P1.** App thấy mình gọi nhiều hơn 1 đường ở bảng này ⇒ design sai, phải quay lại file `01` mục 8.

---
feature: UC-01 Quay món → Quán → Vì sao → Chỉ đường, kèm UC-03 Đói gấp
binds_to: .ulpi/design/DESIGN.md (2026.11.01)
register: product
scope: P1
target: app_flutter/lib/features/{spin,discover,urgent,place_detail,onboarding}
api_source: docs/02-api-dac-ta.md §3.3, §4.3, §4.4, §4.5, §4.6, §4.7, §5.1, §6.1
---

# Spec UC-01 / UC-03

Mọi giá trị hình thái lấy từ `DESIGN.md`. File này chỉ định **hành vi, trạng thái, và input/output API**. Không có giá trị màu/chữ nào được phát minh ở đây.

*Every screen must read as the same product if placed side by side.*

## 1. Flow UC-01: Quay món và đi ăn

**Goal:** trong ≤ 3 chạm, người dùng biết hôm nay ăn món gì, ăn ở quán nào, và mở được bản đồ.

**User story:** Là dân văn phòng nghỉ trưa 15 phút, tôi muốn quay cho biết ăn gì rồi thấy luôn 3 quán gần đang mở, để không phải tự tìm.

**Trigger:** mở app (cold/warm) hoặc deep link `angi://spin`.

### Entry points
- Cold start, guest, chưa onboarding → màn onboarding 3 bước (mục 4), rồi về Hub.
- Warm start, đã có vị trí → Hub luôn. tab mặc định là `Quay`.
- Hub với vị trí hết hạn (> 15 phút hoặc `age > 300s`) → sheet chọn lại vị trí, **không** tự âm thầm dùng tọa độ cũ.
- `angi://place/{id}` (từ share card P2) → thẳng `PlaceDetail`, có nút back về Hub.

### Prerequisites
- [ ] Có `guest_token` hoặc Bearer (`POST /v1/auth/guest`, `docs/02` §2.1).
- [ ] Có nguồn vị trí: GPS **hoặc** `user_location_id` **hoặc** `address`. Từ chối quyền vị trí không chặn app.
- [ ] `GET /v1/config` đã trả ít nhất 1 lần (không có config ⇒ chế độ safe defaults đã niêm yết ở §7).
- [ ] `dish_bundle_version` khớp hoặc bundle cục bộ đã tải (FR-ROU-10).

### Flow diagram

```
[Hub] ──chạm 1──▶ [StampButton Quay]
                      │
                      ▼
             POST /v1/spins ── 201 ──▶ [Wheel chạy theo animation.*]
                      │                        │ duration_ms xong
                      │                        ▼
                      │                 [ResultStamp: dish]
                      │                        │ tự động, không chờ chạm
                      │                        ▼
                      ├─ 422/409 ──▶ [Relax sheet] ──nới──▶ POST /v1/spins
                      │                        │
                      ▼                        ▼
             [offline: RouletteEngine]   POST /v1/matches (body = next.suggested_body)
                                               │
                                     ┌─────────┴─────────┐
                                     ▼                   ▼
                              items.length≥1       items==[]
                                     │                   │
                                     ▼                   ▼
                            [Bảng menu 3 quán]    [RelaxEmptyState + steps_available]
                                     │                   │
                        chạm 2: chọn quán              nới radius ──▶ POST /v1/matches
                                     ▼
                          [PlaceDetail] ──chạm 3──▶ [Chỉ đường: url_scheme]
                                     │
                       └── "Tôi đã đến" ──▶ POST /v1/journal/visits
```

**Đếm chạm (SRS 2.6.1):** `Quay`(1) → chọn quán(2) → `Chỉ đường`(3). Việc gọi `/v1/matches` **không** tính là chạm vì app tự gọi ngay sau khi wheel dừng, dùng `next.suggested_body`. Đây là điểm thiết kế, không phải incidental.

### Steps

#### Step 1 · Hub + Quay

**Screen:** `SpinHubScreen` — layout family **Hub** (`DESIGN.md`).
**User action:** chạm `Quay`; hoặc chạm `Bộ lọc` trước (sheet); hoặc giữ `Locked chip` đã bật từ lần trước.
**System response:** `StampButton` lún ngay (120ms, không chờ mạng) → optimistic `Đang quay`; request bay lên; wheel quay theo `animation.*`.
**Data out (request `POST /v1/spins`)** — chỉ gửi field user thật sự động vào; server merge với `preferences`:

```jsonc
{
  "filters": { "meal": ["lunch"], "price_level_max": 2, "budget_vnd": 50000,
               "type": ["noodle"], "region": ["south"], "temp": "hot",
               "mood": ["quick"], "party_size": 1 },
  "locked":  { "category_id": "cat_01J9" },        // FR-ROU-04, optional
  "diet":    { "override_strict": [] },             // CHỈ thêm, không bao giờ bỏ ràng buộc đã lưu
  "exclude_dish_ids": ["dsh_01J7"],                 // ≤ 50
  "anti_repeat": { "days": 5, "scope": "dish" },     // 0–30, mặc định từ config
  "network_state": "online",
  "client_seed": null                                // chỉ staging/test; prod server bỏ qua
}
```
Headers: `Authorization: Bearer|Guest`, `X-Request-Id`, `X-Device-Id`, `X-Platform`, `X-App-Version`, `X-Locale: vi`, `X-Geo-Precision`. **Không** `X-Idempotency-Key` — mỗi lần quay là một sự kiện mới (`docs/02` §3.3).

**Data in (response `201`)** — field nào nuôi thành phần gì:

| field | nuôi | quy tắc xử lý |
| --- | --- | --- |
| `spin_id` | mọi request sau, `POST /v1/matches.spin_id`, `journal/visits.spin_id` | giữ trong state flow, không log PII |
| `dish{id,name,name_en,category_path,region,temp,meal,price_level,tags,image_url}` | `ResultStamp` | tên hiển thị theo `X-Locale`; `image_url==null` ⇒ tem hue `type` + 2 ký tự |
| `animation.style` | chọn renderer `wheel`/`chest`/`draw` | phải ∈ `config.animation_styles`; ngoài list ⇒ fallback `wheel` |
| `animation.duration_ms` | thời lượng | **cấm** hard-code 2600 |
| `animation.reduce_motion` | bật tắt hoạt hình | true ⇒ cắt renderer, render kết quả tức thì |
| `animation.sound` / `animation.haptics` | feedback | hai cờ độc lập, tôn trọng mute hệ thống |
| `animation.wheel_items[]` + `animation.result_index` + `animation.target_position` | vị trí dừng | app **cấm** nhân/xoá item, cấm đổi index (FR-ROU-07) |
| `pool.size_initial/size_after_hard_filters/size_final`, `pool.removed.{diet_hard,excluded,locked,filters,anti_repeat}` | dòng giải thích "342 món, còn 44 sau kiêng + loại" | chỉ hiện trong `Bộ lọc` sheet, không hiện ở Hub |
| `anti_repeat.{days_window,tau_days,applied[].factor,max_penalty}` | sheet giải thích vì sao món này không ra | ẩn với user thường |
| `proof.{seed_b64,sha256_result,algorithm,pool_hash,verify_url}` | mục "Kiểm chứng" | chỉ render, không tự tính hash |
| `next.{action,method,path,suggested_body}` | request kế tiếp | gọi **đúng body server gửi**, không tự assemble |
| `meta.{data_quality,personalization_used,experiment_arms}` | banner + debug | `data_quality` điều phối banner §6 |

**Transitions:** 201 → Step 2 · 422/409 → Relax sheet · 429 → ẩn nút 30s · offline → `RouletteEngine` cục bộ, `network_state:"offline_bundle"`, **không có `places`**, enqueue spin để sync.

#### Step 2 · Kết quả quay → 3 quán

**Screen:** `ResultStamp` (giữa màn) rồi tự chuyển sang `MatchList` (layout **Bảng menu**).
**System:** ngay khi `duration_ms` kết thúc, gọi `POST next.path` với `next.suggested_body` + vị trí hiện hành. Trong lúc chờ: 3 skeleton row (shimmer **cứng**, đổi 2 mức `sunken`→`surface`, không blur mềm).

```jsonc
// POST /v1/matches
{ "dish_id": "dsh_01J8", "spin_id": "spn_01J8Z6Q9K3M2T7V1",
  "geo": "10.779000,106.702000",           // hoặc user_location_id / address — 1 trong 3
  "radius_m": 1500, "limit": 3, "travel_mode": "bike",
  "include_closed": false, "personalization": true,
  "exclude_place_ids": [] }
```

| response field | UI | quy tắc |
| --- | --- | --- |
| `items[].{id,name,address,geo,distance_m,price_level,avg_price_vnd,price_range_vnd,rating_bayesian,rating_raw,review_count,open_status,cuisine_tags,dish_highlights,source,badges}` | `ResultRow` | `rating_bayesian` mới là số hiển thị (FR-REC-03); `rating_raw` chỉ ở tooltip |
| `items[].score_breakdown` | `WhySheet` | app **không tự tính** điểm nào |
| `items[].why{headline,bullets[],key,params}` | dòng "vì sao" rút gọn | render `key`+`params` qua ARB; không hiển thị `headline` gốc của server nếu có `key` |
| `items[].open_status.{is_open,closes_in_min,closing_soon,o_score,is_exception_day,note_key,tz}` | `OpenStatusChip` | `closing_soon` ⇒ tem `SẮP ĐÓNG`; quán đóng **không** xuất hiện (mặc định `include_closed=false`) |
| `items[].is_sponsored` / `natural_rank` (P3) | nhãn `QUẢNG CÁO` | luôn `false` ở P1; nếu true ⇒ tem trung tính + `natural_rank` hiển thị, **không** đổi thứ tự (FR-REC-04) |
| `relaxation.{applied,steps_available[].{dimension,from,to,expected_extra,why_key}}` | `RelaxEmptyState` / nút "Mở rộng" | mỗi bước là một `StampChip` bấm được |
| `substitute_dishes[].{id,name,similarity,reason_key}` | row "Thử món gần giống" | chỉ khi `items.length==0` |
| `context_used` (P2) | caption nhỏ | ẩn ở P1 |
| `meta.{data_quality,providers_used,formula_version,candidate_count,returned,latency_ms}` | banner + debug drawer | `providers_used` hiển thị khi `provider_degraded` |

**Bất biến UI:** `items` luôn giữ đúng thứ tự server trả. Cấm sort lại phía client (kể cả "ưu tiên đang mở") — đó là nguồn bug "app và server hiểu khác nhau".

#### Step 3 · PlaceDetail → Chỉ đường

`GET /v1/places/{id}` → detail đầy đủ thêm `amenities`, `phone_e164`, `booking_url`, `delivery_url`, `images[].{url,credit,source,is_user_submitted}`, `hours_by_dow[7]`, `report_summary{count_30d,last_kind,pending}`, `score_breakdown`, `why`.
- `hours_by_dow` render 7 dòng, hôm nay in đậm; `is_exception_day` ⇒ `note_key` thành dòng cảnh báo.
- `images[].credit` bắt buộc render (điều khoản nhà cung cấp, SRS 1.4).
- `Chỉ đường` (FR-NAV-01): mở deep link từ `geo{lat,lng}` + `travel_mode`; fallback menu khi thiếu app bản đồ.
- `Báo sai` (FR-PLC-07) → sheet `kind` enum 7 giá trị, gửi `X-Idempotency-Key` **bắt buộc**; `201.cooldown_s` ⇒ vô hiệu hoá nút; `200 + duplicate_of` ⇒ báo "Bạn đã báo rồi".
- `Tôi đã đến` → `POST /v1/journal/visits {place_id, dish_id, spin_id, status:"arrived", source:"manual"}` + `X-Idempotency-Key`. `201.ask_review` ⇒ **một** prompt rời rạc, không chặn luồng, không modal.

### Error mapping (đơn nhất `{"error": {...}}`, `docs/01` §4.6)

App render từ `code` + `message_key` + `details[]`, **không bao giờ** hiển thị `error.message` raw.

| HTTP `code` | từ endpoint | UI | recovery |
| --- | --- | --- | --- |
| `VALIDATION_FAILED` 400 | mọi | lỗi đỏ `danger_text` **tại field**, focus về field đầu trong `details[]` | sửa + retry |
| `DIET_FILTER_EMPTY` 422 | spins, matches | sheet: liệt kê đúng ràng buộc thủ phạm từ `details[].conflicting_with`, gợi ý bỏ **một** ràng buộc mềm | nới 1 ⇒ retry |
| `FILTER_CONTRADICTION` 422 | spins | highlight 2 control xung đột (`temp=cold` ∩ `locked.temp=hot`) | sửa 1 trong 2 |
| `POOL_TOO_SMALL` 409 | spins | `RelaxEmptyState` với `suggested_relaxations[]` | nới ⇒ auto quay lại |
| `RATE_LIMITED` 429 | spins 60/phút, nearby 120/phút | **ẩn** `StampButton` + đếm ngược `retry_after_s` | chờ |
| `UNAUTHENTICATED`/`TOKEN_EXPIRED` 401 | mọi | im lặng refresh 1 lần; fail ⇒ sheet guest | retry tự động |
| `CONSENT_REQUIRED` 403 | nearby, urgent | màn giải thích + nút xin quyền (không vào thẳng Setting) | grant |
| `NOT_FOUND`/`DISH_NOT_FOUND` 404 | place, spins | "Không tìm thấy" + về Hub | back |
| `IDEMPOTENCY_REPLAY` 409 | visits, reports | đọc lại bản trả về, coi như thành công | — |
| `PROVIDER_UNAVAILABLE` 424 | nearby, matches | banner `warning_fill` "dùng dữ liệu lưu", **vẫn render kết quả cache** | retry sau |
| `DEGRADED_NO_RESULT` 503 | mọi | empty + 2 CTA: `Thử lại`, `Nhập địa chỉ` | retry |
| `ROOM_EXPIRED` 410 | rooms (P2) | toast + thoát phòng | — |

### Edge cases

| tình huống | xử lý |
| --- | --- |
| Mất mạng giữa quay | wheel đã quay thì **giữ kết quả** (`spin` local), enqueue `/v1/matches` vào `sync_queue`; hiện banner offline; không hoàn tác lần quay |
| Mất mạng hoàn toàn | `RouletteEngine` từ bundle → `network_state:"offline_bundle"`, không có `places`; hàng quán lấy từ cache 24h gần nhất, tem `DỮ LIỆU LƯU` |
| Đang xem kết quả thì xoay màn / app background < 30s | giữ nguyên state, không re-request |
| Vị trí nhảy 3km do GPS sai | không auto re-query; hiện `StampChip` "Vị trí thay đổi · Cập nhật?" (chống thứ tự xếp hạng nhảy loạn khi GPS trôi) |
| `items` trả về rồi user kéo refresh | re-request `/v1/matches` **không** gửi `spin_id` mới; giữ `spin_id` cũ ⇒ kết quả không đổi (FR-ROU-07 trace) |
| Double-tap `Quay` | debounce 300ms + in-flight lock; lần 2 bị nuốt, không tạo 2 spin |
| `animation.duration_ms` > 4000 (cấu hình sai) | clamp 4000ms, log `config_anomaly`; **không** cắt kết quả |
| Session expire khi đang wheel | refresh âm thầm sau animation; không bao giờ cắt giữa hoạt hình |
| Đồng hồ máy sai | app **không** tự tính `o_score`/`closing_soon`; chỉ dùng `open_status` server (`tz: Asia/Ho_Chi_Minh`) |

### State model (mọi màn cùng một machine)

`idle → requesting → success | empty | partial | error | offline_cached`
- `partial` = có `items` nhưng `data_quality ∈ {stale, provider_degraded}` ⇒ banner + nội dung vẫn dùng được.
- `empty` **không bao giờ** là lỗi; `empty` luôn kèm ít nhất 1 CTA hành động (`steps_available` không rỗng).
- Mỗi state phải định nghĩa: skeleton gì, thông điệp ARB key nào, CTA chính, CTA phụ, có retry tự động hay không.

### Analytics (qua `core/telemetry/analytics.dart`, không PII, không tọa độ thô)

| event | trigger | properties |
| --- | --- | --- |
| `spin_started` | chạm Quay | `{has_filters, locked, network_state}` |
| `spin_result_shown` | wheel dừng | `{spin_id, dish_type, duration_ms, reduce_motion}` |
| `places_shown` | matches 200 | `{count, data_quality, latency_ms_total, relaxation_applied}` |
| `place_chosen` | chạm row | `{place_id, rank, distance_m}` |
| `nav_opened` | Chỉ đường | `{place_id, travel_mode}` |
| `visit_marked` | 201 visits | `{status, source}` |
| `error_shown` | mọi error state | `{code, endpoint, retryable}` |

### Accessibility của flow

- Focus order: `Quay` → `Bộ lọc` → `Đói gấp`; sau wheel dừng, `Semantics.serviceAccess()` đọc **"Hôm nay: <tên món>"**, live region `assertive`.
- Wheel là **không thể thao tác**: kết quả được công bố bằng text, không yêu cầu nhìn vòng quay. `result_index` không phải đường duy nhất để biết kết quả.
- Row kết quả = 1 `Semantics(button: true)` gồm: tên, `distance_m`, `rating_bayesian`, trạng thái mở. Không đọc `score_total` (vô nghĩa với user).
- Touch target: `Quay` = `stampButtonH` 56; `ResultRow` ≥ `rowMinH` 76; hạng 1 = `rowMinH` × `rankOneScale` 1.4; tem = `badgeVisualMin` 32 với `badgeTouchMin` 48 nới bằng `Stack`+`Positioned` (không co visual size); vòng focus `focusRing` 3dp cách 2dp.
- `textScaleFactor` 2.0: rank numeral tụt theo quy tắc scale (`numeric`→`title`), `StampBadge` ẩn phần nhìn và chuyển nhãn vào semantics.
- Contrast: đã đo ở `DESIGN.md`, không thêm cặp màu nào mới.
- Reduce-motion: §Motion của `DESIGN.md`, và `AnimationController` phải đọc `MediaQuery.disableAnimations` **tại build time**, không chỉ tại init.

## 2. Flow UC-03: Đói gấp (một chạm, < 2s)

**Screen:** `UrgentScreen`, layout family **Thẻ quyết định**.
**Entry:** chip `Đói gấp` trên Hub (1 chạm) hoặc widget (P3).
**Request:** `GET /v1/places/urgent?geo=...&travel_mode=bike&budget_vnd=50000` (tất cả optional, server tự điền; `radius_m` server tự nới theo `config.place.urgent_radius_steps` = `[1500,2500,4000]`).
**Response render:**

| field | UI |
| --- | --- |
| `place` (Place DTO + `score_breakdown`) | `StampCard`: tên, `numericLg` `distance_m`, `avg_price_vnd`, `rating_bayesian`, `OpenStatusChip` |
| `decision.{radius_m_used, expanded, candidates_considered, one_tap_action}` | caption "đã mở rộng tới 2.5 km · đã xét 22 quán"; `one_tap_action:"navigate"` ⇒ **nút duy nhất** là `Chỉ đường` |
| `decision.fallback_dish{...reason_key}` | tem phụ "Hợp món bạn vừa quay" |
| `alternatives[].{id,name,why_key,why_params}` | 2 dòng dưới, nhỏ, `muted` — render qua ARB (`docs/02` §4.5), không hiển thị chuỗi thô |
| `open_status.{closes_in_min,closing_soon,o_score}` | `closing_soon=true` ⇒ tem `SẮP ĐÓNG` `danger_fill` |
| `meta.{data_quality,latency_ms}` | banner nếu không `fresh` |

**Hành vi cứng:** không chạy bước quay món, không chờ provider (chỉ DB + Redis), hiển thị < 2s. `place:null` ⇒ **vẫn là 200**, render "Bây giờ chưa có quán mở gần bạn" + `alternatives[]` là quán **sắp mở ≤ 30′**, kèm `decision.notify_key`. Luồng một chạm không được chết.
**State thêm:** `requesting` hiện 1 skeleton card duy nhất (không hiện 3, để tránh hint "sẽ có 3 cái").

## 3. Màn hình và thành phần cần build (P1)

| # | screen | layout family | endpoint |
| --- | --- | --- | --- |
| S1 | `OnboardingSheet` (3 bước, bỏ qua được) | Hub-lite | `PUT /v1/me/onboarding`, `POST /v1/me/consents` |
| S2 | `SpinHubScreen` | Hub | `POST /v1/spins`, `GET /v1/config` |
| S3 | `FilterSheet` | Bảng menu (compact) | `GET /v1/dishes/taxonomy` |
| S4 | `MatchListScreen` | Bảng menu | `POST /v1/matches` |
| S5 | `WhySheet` | Thang vì sao | `items[].score_breakdown` (không gọi thêm API) |
| S6 | `PlaceDetailScreen` | Thẻ quyết định + Bảng menu | `GET /v1/places/{id}` |
| S7 | `UrgentScreen` | Thẻ quyết định | `GET /v1/places/urgent` |
| S8 | `ReportSheet` | form | `POST /v1/places/{id}/reports` |
| S9 | `DiscoverListScreen` (tab Quán) | Bảng menu | `GET /v1/places/nearby` (`view=list`) |
| S10 | `RelaxEmptyState` | Thẻ quyết định | data của `relaxation` / `substitute_dishes` |

## 4. Component specs

Ràng buộc chung cho mọi component: **chỉ dùng token từ `DESIGN.md`**, props mang tên field API gốc (không đổi tên, không `camelCase` hoá) để contract test so khớp được. Nhận `X-Data-Quality` qua wrapper, không qua prop riêng.

### 4.1 `StampButton`
**Purpose:** hành động primary. **Mỗi màn đúng 1 cái.**

```dart
StampButton({
  required String labelKey,            // ARB key, không phải chuỗi thô
  required VoidCallback onPressed,
  bool loading = false,                // giữ nguyên chiều cao, đổi label sang trạng thái "đang"
  bool enabled = true,                 // false ≠ ẩn: vẫn thấy, không bấm, lý do ở tooltip
  int? countdownSeconds,               // 429: label + đếm ngược, tự re-enable
  bool primary = true,                 // false = StampButtonTonal: surface + viền ink, không accent
})
```
| state | hình thái | hành vi |
| --- | --- | --- |
| default | `accent` + viền `ink` 2dp + bóng `stamp2` (0,4) | cao 56, radius `md` |
| pressed | translate +4, bóng 0 | `fast` 120 đi / `stampPress` 90 về, **chạy trước khi** có response |
| focus (kbd/bt) | `focusRing` 3dp, cách 2dp | AA 7.26:1 |
| loading | label → `Đang quay`, giữ chiều cao, không spinner mờ | vô hiệu bấm thêm |
| disabled | `disabledOpacity` 0.45, bỏ bóng, giữ viền | semantics `enabled: false` |
| countdown | `Chờ 12s`, ẩn `Quay` | re-enable auto tại 0 |
A11y: `Semantics(button: true, enabled:)`, label từ ARB; không dùng `OnTap` trên Text.

### 4.2 `WheelSpinner` (Signature, 3 kiểu)
**Props:** `items: List<String>` (= `animation.wheel_items`), `resultIndex: int` (= `animation.result_index`), `targetPosition: int`, `durationMs: int`, `style: wheel|chest|draw`, `reduceMotion: bool`, `sound: bool`, `haptics: bool`.
- Segment tô hue theo `type` của món (tra `dish_highlights`/taxonomy). Nhãn segment: role `wheelLabel` (18/700), màu `on_data` — **không dùng size nhỏ hơn `wheelLabel`** (cặp 3:1 đã đo theo đúng size này).
- Con trỏ = `accent` + viền ink; micro-settle ±3° bằng `wheelSettle` 180 sau khi dừng (vật lý, không bounce UI chung).
- `style=chest`:capsule lật 1 lần rồi mở — kết quả vẫn là `result_index`.
- `style=draw`: 3 lá bài rút lần lượt, lá cuối = kết quả.
- `reduceMotion=true` ⇒ **không renderer nào chạy**, `ResultStamp` hiện tức thì.
- `sound`/`haptics` phát đúng 1 lần tại khoảnh khắc dừng.
Cấm tuyệt đối: sinh kết quả phía app, đổi `items` sau khi server trả, cho user "quay lại đến khi hài lòng" bằng cách tu chỉnh index.

### 4.3 `ResultRow`
**Props:** toàn bộ `items[]` Place DTO (list shape), `rank: int`, `showWhy: bool`.
Layout **Bảng menu**: số hạng `numeric` cột trái · tên + `cuisine_tags` (`micro`, `muted`) · phải: `numeric` `distance_m` + `OpenStatusChip` + `avg_price_vnd`. Divider 1dp `line`. Rank 1 cao 1.4×, nền `surface`, tem `HỢP NHẤT` (`accent` + `on_accent`).
Ảnh: `image_url==null` ⇒ ô `thumbFallback` 44 hue `type` + 2 ký tự. Không placeholder xám.
Semantics 1 nút: `"<tên>, cách <n> mét, <sao> điểm, <đang mở|sắp đóng>"`.
`on_dismiss` (P2 ROU-12) gửi `exclude_place_ids` ở request kế.

### 4.4 `WhySheet` (FR-REC-02)
Data: **duy nhất** `score_breakdown` từ server. Không tính lại, không vẽ phần trăm tự chế.
- Header: `score_total` bằng `display` 34 + `formula_version` bằng `micro` `subtle`.
- 5 vạch theo `components[]`: nhãn `label`, độ dài = `contribution`, màu = hue của `key` **nhưng** chỉ 2 vạch `top=true` mới tô; 3 còn lại `line`+`muted` (giữ một điểm nhìn).
- Vạch chạy 0 → giá trị bằng `barGrow` 400ms, các vạch delay nhau `staggerStep` 40ms, easing `curveStamp`.
- `weights` hiển thị dạng caption `Q 35% · D 25% · P 15% · O 15% · U 10%` (đọc từ `score_breakdown.weights`, không tự hard-code).
- `penalty.items[]` ⇒ dòng `danger_text` + icon cảnh báo + `reason`/`days`.
- Chuỗi giải thích = `why_key` + `why_params` qua ARB. `facts{}` chỉ dùng để format params.
- Empty: thiếu `score_breakdown` (`sort!=score`) ⇒ ẩn hoàn toàn entry point, không hiện sheet rỗng.

### 4.5 `OpenStatusChip`
Input: `open_status`. Bảng render (mọi ngưỡng lấy từ `config.place`):

| điều kiện | tem | màu | icon |
| --- | --- | --- | --- |
| `is_open && closes_in_min ≥ config.open_min_left_to_score_1` | `ĐANG MỞ` | `success_fill` + `on_fill` | `schedule_open` |
| `closing_soon` (true khi `< config.closing_soon_min`) | `SẮP ĐÓNG · còn {closes_in_min}′` | `danger_fill` | `timer_alert` |
| `!is_open` (chỉ khi `include_closed=true`) | `ĐÓNG CỬA` | `surface` + viền `ink` | `store_off` |
| `is_exception_day` | `note_key` (VD `NGHỈ LỄ`) | `warning_fill` | `event_busy` |
| `open_status` thiếu | **ẩn chip**, không đoán | — | — |
Nghiêng −6°, role `stampLabel` (12/700) uppercase, **luôn icon + chữ** (không bao giờ chỉ màu).

### 4.6 `DataQualityBanner` (FR-PLC-08, NFR-06)
Input: `X-Data-Quality` / `meta.data_quality`.

| giá trị | template | fill |
| --- | --- | --- |
| `fresh` | không hiện | — |
| `cached` | `Dữ liệu lưu · {cache_age_s}s trước` | `info_fill` |
| `stale` | `Dữ liệu cũ, độ tin giảm` | `warning_fill` |
| `provider_degraded` | `Nguồn quán đang lỗi · dùng {providers_used}` | `warning_fill` |
| `offline_bundle` | `Không có mạng · quay từ máy, quán từ lần lưu gần nhất` | `surface` + viền `ink` |
Một lần / session / kiểu, đóng được, không tự biến mất bằng animation lặp.

### 4.7 `RelaxEmptyState` (FR-REC-05)
Kích hoạt khi `items.length == 0` (matches **không** trả 404). Nội dung: headline `Không có quán phù hợp gần bạn` · 1 `StampChip` cho mỗi `steps_available[]` (`Mở rộng tới {to} m · +{expected_extra} quán`, label qua `why_key`) · `substitute_dishes[]` thành 2 tem hue `type` · primary action = bước relaxation đầu tiên (auto-focus semantics). Cấm hiện nút "Quay lại" ở đây mà không có CTA nới.

### 4.8 `FilterSheet`
Group ≤ 4 field mỗi nhóm (`DESIGN.md` cognitive load): **Bữa** (`meal[]`) · **Tiền** (`budget_vnd`, `price_level_max`) · **Loại/Vùng** (`type[]`, `region[]`, `temp`) · **Tâm trạng/Số người** (`mood[]`, `party_size`).
- `locked.*` thể hiện bằng 4 ổ khoá trên header wheel; mỗi lock là 1 `StampChip` có ×.
- Diet **không** xuất hiện trong filter (chỉ xem + thêm ở `override_strict`); client không được tắt diet đã lưu — check bằng UI test assert control đó `enabled: false`.
- `anti_repeat.days`: slider 0–30, tick mặc định từ `config.spin.anti_repeat_days_default`.
- Debug-only: `client_seed` (ẩn trên build release).

## 5. Binding component → API (checklist chống "app tự bịa field")

| component | endpoint | fields tiêu thụ |
| --- | --- | --- |
| `WheelSpinner`, `ResultStamp` | `POST /v1/spins` | `animation.*`, `dish.*`, `spin_id`, `proof.*`, `next.*` |
| `MatchListScreen`, `ResultRow` | `POST /v1/matches` | `items[]` list-shape Place, `relaxation`, `substitute_dishes`, `meta.*` |
| `WhySheet` | (data từ matches) | `score_breakdown.*`, `why.*` |
| `OpenStatusChip` | matches / nearby / urgent | `open_status.*` |
| `UrgentScreen` | `GET /v1/places/urgent` | `place.*`, `decision.*`, `alternatives[]`, `open_status.*` |
| `PlaceDetailScreen` | `GET /v1/places/{id}` | Place detail-shape: `amenities`, `images[]`, `hours_by_dow[]`, `phone_e164`, `booking_url`, `delivery_url`, `report_summary`, `badges` |
| `DiscoverListScreen` | `GET /v1/places/nearby` | `items[]`, `page.{next_cursor,has_more,total_estimate}`, `meta.*` |
| `ReportSheet` | `POST /v1/places/{id}/reports` | `kind`, `detail`, `suggested_value`, `observation_geo`, `upload_ids` → `report_id`, `cooldown_s`, `duplicate_of` |
| `Tôi đã đến` | `POST /v1/journal/visits` | `place_id`, `dish_id`, `spin_id`, `status:"arrived"`, `source` → `ask_review`, `review_prompt_key`, `budget_delta_vnd` |
| `FilterSheet`, ngưỡng mọi tem | `GET /v1/config` | `place.*`, `spin.*`, `animation_styles`, `ranking_weights`, `flags`, `min_app_version`, `force_upgrade` |
| Fallback offline | `GET /v1/dishes/bundle` | `dish_bundle_version`, taxonomy + ảnh đã cache |

**Kiểm tự động:** contract test so key JSON của fixture (`docs/04` §2.2) với `fromJson` của model; field thiếu ⇒ fail build. Không model nào được có field không tồn tại trong docs.

## 6. Safe defaults khi `GET /v1/config` fail

Chỉ dùng khi config **chưa từng** tải được (không dùng để ghi đè config sống): `closing_soon_min=30`, `open_min_left_to_score_1=45`, `radius_default_m=1500`, `radius_max_m=5000`, `urgent_radius_steps=[1500,2500,4000]`, `anti_repeat_days=3`, `tau_days=3.0`, `min_pool=3`, `animation_styles=["wheel"]`. Ghi `telemetry.config_defaults_used=true` để admin thấy.

## 7. Build handoff

**design_system:** Material 3 (Flutter `material` library) — theme qua `ColorScheme.fromSeed(seedColor: accent)` **rồi override từng role** bằng token `DESIGN.md` qua `ThemeExtension<AngiTokens>`; shape qua `StadiumBorder`/`RoundedRectangleBorder` + `ShapeDecoration(side: BorderSide(ink, 2), shadows: [])`. Dùng `ButtonStyle` subclass cho `StampButton` để giữ semantics của Material Button. **Theme đúng, không viết lại** `Scaffold`, `AppBar`, `BottomSheet`, `ListView`, `Chip`, `TextField`, `Switch` — `flutter-add-widget-preview` cho từng component mới.

**Thứ tự build đề xuất:** (1) `AngiTokens` + light/dark ThemeData + font assets (Bricolage Grotesque, Be Vietnam Pro, JetBrains Mono — subset `vietnamese` đã verify) → (2) `StampButton`/`StampBadge`/`OpenStatusChip` + preview gallery → (3) models + Dio client + error mapper + `/v1/config` cache → (4) `WheelSpinner` (wheel trước, chest/draw sau) → (5) `MatchList` + `WhySheet` → (6) `UrgentScreen` → (7) `PlaceDetail` + visits/reports.

**Acceptance criteria**
- [ ] 0 giá trị màu/chữ/spacing nào không lấy từ `AngiTokens`; grep `Colors.` ngoài file tokens = 0.
- [ ] Hub → bản đồ đúng 3 chạm, đo bằng integration test `uc01_spin_to_nav_test.dart` (**TC-UX-03**).
- [ ] `reduce_motion=true` ⇒ không `AnimationController` nào chạy, kết quả hiện tức thì (**FR-ROU-08**).
- [ ] Kết quả quay do server quyết định: assert với `client_seed` trên staging, 200 lần quay cùng seed ⇒ cùng `dish.id` (**TC-ROU-07**).
- [ ] 0 quán `is_open=false` trong kết quả mặc định; 0 `o_score` nào tính phía app (**TC-PLC-06-A1..A7**).
- [ ] `WhySheet` số học khớp: `sum(components[].contribution) − penalty.total == score_total`, ±0.01 (**TC-REC-02-A2/A3**).
- [ ] Diet không tắt được từ UI; 1.000 mẫu quay ⇒ 0 vi phạm (**TC-ROU-03-A1**, **TC-BIZ-11**).
- [ ] Mất 100% provider ⇒ vẫn có kết quả + banner `provider_degraded` (**TC-CHAO-03**); mất 100% mạng ⇒ vẫn quay được (**TC-ROU-10-A1**).
- [ ] Mọi lỗi đi qua `code`+`message_key`; 0 chuỗi server raw trên UI (**TC-I18N-01**).
- [ ] `X-Idempotency-Key` có ở 100% POST ghi; retry yếu mạng ⇒ 0 record trùng (**TC-API-04**, **TC-MOB-02**).
- [ ] Text scaling 2.0, Dark, High contrast, TalkBack/VoiceOver: luồng UC-01 hoàn thành được, 0 chữ cắt.
- [ ] Touch target: 100% ≥ 48dp (đo bằng `SemanticsTree`, không eyeball).
- [ ] 0 em-dash, 0 buzzword trong ARB `app_vi.arb` (lint script).

**Không nằm trong file này:** FR-GRP (phòng nhóm, WSS) — spec riêng ở `docs/03` §1, dùng cùng `DESIGN.md`; FR-COM, journal sync, budget.

---

## 8. Design Pre-Flight (đã chạy, `2026.11.01`)

**Identity lock**
- [x] 0 giá trị ngoài hệ. Đo bằng script: `#[0-9A-F]{6}` trong file này = **0**; size `NNsp` ngoài bảng role = **0**; mọi token viện dẫn (37 tên) đều tồn tại trong `DESIGN.md`.
- [x] Một accent, một radius scale, một icon family, một type pairing.
- [x] Identity-lock sentence có mặt ở đầu file.
- [x] Spec này viết **sau** khi lock `DESIGN.md`; 4 chỗ buộc phải mở rộng lock được ghi tường minh trong change log của lock, không âm thầm.

**Anti-slop**
- [x] 0 font bị ban (Bricolage Grotesque + Be Vietnam Pro + JetBrains Mono, không Inter/Roboto/Fraunces/Playfair/Space Grotesk).
- [x] 0 color cliché: nền jade lạnh không kem-beige, không purple-blue glow, không gradient text, không acid-accent-trên-near-black.
- [x] 0 layout bị ban: không 3 card đều nhau, không nested card, không eyebrow `01/02/03`, không hero over mesh.
- [x] 0 buzzword, 0 tên giả, 0 số giả chính xác, **0 em-dash trong chuỗi UI** (kiểm tự động trên 18 label; prose kỹ thuật vẫn dùng dấu gạch, không phải copy hiển thị).
- [x] Slop test + counterfactual test: có bảng "default bị từ chối" ở `DESIGN.md`.
- [x] Signature (con dấu) có mặt và mang brief: wheel + stamp + tem nghiêng −6°.

**State & edge**
- [x] Mọi element interactive có loading/empty/partial/error/offline; `empty` luôn kèm ≥1 CTA thật.
- [x] 10 edge case: mất mạng giữa quay, mất mạng hẳn, xoay màn, GPS trôi 3km, refresh kết quả, double-tap, duration cấu hình sai, expire giữa animation, đồng hồ máy sai, diet không tắt được.

**Accessibility**
- [x] 25 cặp tương phản **đo bằng số** (OKLCH→sRGB→WCAG), light + dark, tất cả ≥4.5 (text) / ≥3.0 (UI). 4 token từng fail/out-of-gamut đã sửa trước khi lock.
- [x] Focus ring `focus` 3dp, đạt 7.26/6.02. Keyboard + switch-access documented.
- [x] `reduce_motion` là hợp đồng có hành vi cụ thể, không phải tắt animation chung.
- [x] Semantics cho wheel (kết quả công bố bằng text, không bắt nhìn), row, live region `assertive`, `hint` khi disabled.
- [x] Touch target 100% ≥48dp, đo bằng `SemanticsTree` trong test chứ không nhìn mắt; safe area + padding 20 khi có notch ngang.
- [x] Text scaling tới 2.0 với quy tắc tụt role, không sinh size lạ.

**Layout craft / cognitive load**
- [x] 5 layout family luân phiên (Hub · Bảng menu · Thang vì sao · Thẻ quyết định · Bảng phiếu).
- [x] Đúng 1 primary action mỗi view; filter chia nhóm ≤4 field; nav 4 tab.

**Self-critique (0-4, trần 32)**

| trục | điểm | ghi chú |
| --- | --- | --- |
| distinctiveness | 4 | tem nhựa + jade lạnh + hue ánh xạ theo enum API: không app đồ ăn nào giống |
| hierarchy & focus | 3 | rank 1 to 1.4× giữ một điểm nhìn; urgent card cần đo thật trên máy nhỏ |
| consistency | 4 | 0 off-system sau gate (trước gate là 3, vì 4 giá trị lạ) |
| accessibility | 4 | có số đo, có quy tắc cặp-cấm, không chỉ "đạt AA" suông |
| state/edge | 4 | error map đủ 12 code, offline có đường riêng |
| copy quality | 3 | 18 label nhất quán; vài chuỗi dài (`Nguồn quán đang lỗi · dùng {providers_used}`) cần test truncation |
| restraint | 3 | 8 hue là nhiều; khống chế bằng 3 ngữ cảnh + shadow-c-only-on-stamp |
| motion motivation | 4 | mỗi animation có cột "vì sao", cắt được là cắt |
| **tổng** | **28/32** | không trục nào ≤2 → qua gate |

**Revise-and-justify (đã áp tại gate)**
1. Thêm role `stampLabel 12` và `wheelLabel 18`: spec gốc dùng "12sp/700", "18sp/700" là size ngoài bảng → gộp vào lock để truy vết được.
2. `numeric 40sp` trên UrgentCard → vai trò mới `numericLg 40` + quy tắc tụt scale, thay vì để size lạ trôi nổi.
3. `opacity 0.45` → token `disabledOpacity`, kèm quy tắc "vô hiệu vẫn giữ viền ink".
4. `delay 60ms` / `300 + 400 vạch` mâu thuẫn `staggerStep 40` / `barGrow 400` đã lock → sửa spec khớp lock.
5. Thêm nhóm `sizing` (`touchMin`, `stampButtonH`, `rowMinH`, `rankOneScale`, `thumbFallback`, `badgeVisualMin/TouchMin`, `focusRing`) vì spec viện dẫn 7 số chưa có trong lock.

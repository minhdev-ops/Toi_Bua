# 04 · Kịch bản kiểm thử (Test Plan & Test Cases) ĂnGìĐây

*Dựa trên SRS v1.0 (mã FR-\*/NFR-\*) và đặc tả API [`02`](./02-api-dac-ta.md) · [`03`](./03-api-p2-p3.md) · phiên bản test plan 1.0 · 01/11/2026*

> Mục tiêu: bạn chạy theo từng mục và **tự trả lời được "luồng đã ổn chưa"** bằng con số, không bằng cảm giác.
> Muốn kiểm nhanh trong 10 phút → xuống thẳng **§7.4 Flow validation script**.

---

## 0. Cách dùng tài liệu

1. Mỗi test case có **ID ổn định** `TC-<NHÓM>-<FR#>-<biến thể>`, đặt y hệt trong tên hàm test → search được từ FR sang test và ngược lại.
2. Cột **Loại**: `U` unit · `I` integration (Testcontainers) · `C` contract/schema · `E` E2E thiết bị · `P` performance · `X` chaos/bảo mật · `M` manual (UX, cảm quan).
3. Cột **P** (ưu tiên): `B` blocker — fail là không release · `1` critical · `2` major · `3` minor.
4. Một TC chỉ pass khi **toàn bộ** assertion ở cột "Kết quả mong đợi" đúng. Thiếu 1 assertion = fail. Không có "pass có điều kiện".
5. Mọi test đụng thời gian (`opening hours`, anti-repeat N ngày, room TTL 2h, "cuối tháng") **phải** đi qua `ClockPort` (fake clock). **Cấm** `Thread.sleep`/chờ đồng hồ thật. Đây là điều kiện tiên quyết để test được FR-PLC-06, FR-GRP-07, FR-ROU-06 — và là chỗ team hay skip nhất.

### Definition of Ready (test viết được)
- [ ] Endpoint có trong OpenAPI + có ví dụ request/response ở file `02`/`03`
- [ ] Dataset seed chứa trường hợp biên: quán 2 review, quán 200 review, quán đóng trong 20 phút, quán 0 giờ mở
- [ ] Fake clock set được tới mọi thời điểm (kể cả 23:50 và 00:10)
- [ ] Feature flag set được từ test, không phụ thuộc trạng thái môi trường

### Definition of Done (tính năng được coi là xong)
- [ ] 100 % TC `P=B` pass trên `staging`
- [ ] Phủ unit ≥ 70 % cho `roulette`, `ranking`, `group`; ≥ 90 % cho `domain/` của 3 module đó (NFR-12)
- [ ] Contract test pass cả OpenAPI **và** fixture của app
- [ ] Không còn `Known issue` mức S1/S2 mở (§12)
- [ ] Perf đạt số §8.1 trên môi trường dataset đúng cỡ

---

## 1. Chiến lược theo tầng

| Tầng | Tool | Chạy ở | Tần suất | Phạm vi |
| --- | --- | --- | --- | --- |
| Unit (`U`) | JUnit 5 + AssertJ + Mockito; Flutter: `flutter_test` | CI, local | mỗi commit, < 90 s | `domain/` thuần: `PlaceScorer`, `BayesianQuality`, `WeightedSampler`, `TallyResolver`, `OpenStatusResolver`, `RelaxationLadder`, `Money`, `Geohash`. **Không** mock domain — domain là hàm thuần |
| Integration (`I`) | Testcontainers: Postgres+PostGIS+Redis+RabbitMQ | CI | mỗi PR | repository + SQL `ST_DWithin`, `pg_trgm`, adapter với WireMock (OSM/Google), queue outbox |
| Contract (`C`) | OpenAPI diff (oasdiff) + Pact/snapshot fixture cho app | CI | mỗi PR API | schema request/response, mã lỗi, tính tương thích ngược NFR-14 |
| E2E app (`E`) | Flutter `integration_test` + Patrol; Firebase Test Lab / DeviceFlight | CI nightly + trước release | mỗi release | UC-01, UC-02 (2 device), UC-03, onboarding, offline, permission |
| Admin web (`E`) | Playwright | CI nightly | mỗi release | CRUD món, kiểm duyệt, dashboard, tắt provider |
| Perf (`P`) | k6 (REST) + tự viết load WSS; `flutter test --dart-define=PROFILE` + Firebase Perf | `staging` | tuần 1 lần + pre-release | mục tiêu NFR-01/02/05 |
| Chaos / Security (`X`) | ToxiProxy, WireMock fault, Zap baseline, MobSF, dependency scan | `staging` | mỗi release | NFR-06/07/08, FR-PLC-08 |

**Không làm ở P1**: test đa vùng, test merchant (P3), test bàn phím/tuỳ biến cho người khuyết tật chuyên sâu — chỉ test WCAG AA cơ bản (§8.6).

**Tỷ lệ mong muốn**: unit 70 %, integration 25 %, e2e 5 %. Nếu e2e > 15 % tổng test ⇒ kiến trúc đang thiếu seam, phải thêm integration thay vì thêm e2e.

---

## 2. Môi trường, dữ liệu và đồng hồ

### 2.1 Môi trường

| env | Provider | Dataset | Ghi chú |
| --- | --- | --- | --- |
| `dev` | Google sandbox **off** — WireMock giả lập OSM+Google | 300 món, 500 quán Q.1 | adapter `provider=mock` bật bằng flag `angi.providers.mode=MOCK` |
| `staging` | provider thật (budget thấp) | 3.000 món, 5.000 quán TP.HCM + 20.000 user giả | dữ liệu anonymised; user test tên tiền tố `qa_` |
| `prod` | thật | thật | canary 5 % → 100 %, tự rollback nếu `error_rate > 1 %` hoặc `p95 > 2× SLO` trong 5 phút |

### 2.2 Seed fixture (bắt buộc có, để số test luôn đúng)

**Món** — `qa/fixtures/dishes.yaml`, tối thiểu **300 dòng active** (FR-ROU-01): đủ 4 miền, 8 loại, 3 cấp giá, 20 tag `allergen`, 10 tag `diet`, và **cố tình** có:
- `dsh_peanut_only` — món chứa đậu phộng, không có biến thể không đậu phộng
- `dsh_halal_only` — 1 món halal duy nhất trong category `món chiên`
- `dsh_internal` — nội tạng (để test exclusion)
- `dsh_bun_bo_hue` + `dsh_bun_bo_nam_bo` (cùng category lá `cat_01JA`) — test anchor taxonomy và `substitute_dishes.similarity`

**Quán** — `qa/fixtures/places.yaml`, 45 quán quanh `10.7790,106.7020`, **bắt buộc phủ đúng 12 hoản cảnh**:

| Fixture id | Toạ độ/cách anchor | review | Rating | Giá | Giờ mở (giờ địa phương) | Dùng để test |
| --- | --- | --- | --- | --- | --- | --- |
| `plc_small_hi` | 60 m | **2** | **5,0** | 30.000 | 06:00–22:00 | **FR-REC-03** Bayesian: quán ít review không được vượt |
| `plc_big_mid` | 200 m | **200** | 4,2 | 45.000 | 06:00–22:00 | FR-REC-03 |
| `plc_far_best` | 2.400 m | 150 | 4,8 | 60.000 | 06:00–22:00 | D vs Q trade-off, FR-REC-08 |
| `plc_closing_44` | 100 m | 80 | 4,5 | 35.000 | 06:00–**<code>fake_now</code>+44 phút** | biên `o_score` 0,5 / FR-PLC-06 |
| `plc_closing_45` | 110 m | 80 | 4,5 | 35.000 | +45 phút | biên `o_score` 1,0 |
| `plc_closing_29` | 120 m | 80 | 4,5 | 35.000 | +29 phút | `closing_soon=true` |
| `plc_closing_30` | 130 m | 80 | 4,5 | 35.000 | +30 phút | `closing_soon=false` |
| `plc_closed` | 150 m | 300 | 4,9 | 30.000 | đã đóng 3 tiếng | bị loại mặc định (FR-PLC-06) |
| `plc_expensive` | 300 m | 90 | 4,6 | **300.000** | 06:00–22:00 | P=0, FR-PER-02 |
| `plc_no_hours` | 400 m | 40 | 4,1 | 40.000 | **không có `place_hours`** | FR-PLC-08 / dữ liệu thiếu |
| `plc_osm_only` | 500 m | 0 | – | 25.000 | có | provider degraded path, Google tắt |
| `plc_stale` | 550 m | 70 | 4,4 | 40.000 | có, `verified_at = 2026-04-01` | penalty `stale_verification` (> 180 ngày) |
| `plc_reported` | 600 m | 60 | 4,4 | 40.000 | có, 12 report accepted/30 ngày | penalty `report_ratio` |

`fake_now` = giá trị `ClockPort` đang set; fixture render giờ mở theo nó để không có test nào "trúng giờ thật một cách tình cờ".

### 2.3 Fake clock và vùng giờ

```java
@Test void closingSoon() {
    clock.set(Instant.parse("2026-11-01T03:20:00Z")); // 10:20 giờ VN
    // plc_closing_44 closes_at 10:64 => 11:04 local
}
```
- Toàn bộ backend nhận `Clock` qua bean, **không** gọi `LocalDateTime.now()` trực tiếp (ArchUnit rule: `noClasses().should().callMethod(LocalDate.class,"now")`).
- Test tz: `2026-11-01T23:50Z` (= 06:50 sáng hôm sau giờ VN) và `2026-10-31T17:00Z` (= 00:00 ngày 01/11 giờ VN) → **dow và "cuối tháng" phải đổi theo giờ VN, không theo UTC**. TC-REC-07-A1.

---

## 3. Ma trận truy vết FR → Test (bảng này là thứ audit "test đủ chưa")

| FR | Test cases | Bản | P=B |
| --- | --- | --- | --- |
| AUTH-01 | TC-AUTH-01-A1..A4 | P1 | ✔ |
| AUTH-02 | TC-AUTH-02-A1..A7 | P1 | ✔ |
| AUTH-03 | TC-AUTH-03-A1..A4 | P1 | ✔ |
| AUTH-04 | TC-AUTH-04-A1..A5 | P1 | ✔ |
| AUTH-05 | TC-AUTH-05-A1..A6 | P1 | ✔ |
| ROU-01 | TC-ROU-01-A1..A5 | P1 | ✔ |
| ROU-02 | TC-ROU-02-A1..A9 | P1 | |
| ROU-03 | TC-ROU-03-A1..A6 | P1 | ✔ |
| ROU-04 | TC-ROU-04-A1..A5 | P1 | ✔ |
| ROU-05 | TC-ROU-05-A1..A5 | P1 | |
| ROU-06 | TC-ROU-06-A1..A7 | P1 | ✔ |
| ROU-07 | TC-ROU-07-A1..A4 | P1 | ✔ |
| ROU-08 | TC-ROU-08-A1..A5 | P1 | |
| ROU-09 | TC-ROU-09-A1..A6 | P1 | ✔ |
| ROU-10 | TC-ROU-10-A1..A6 | P1 | ✔ |
| ROU-11 | TC-ROU-11-A1..A4 | P2 | |
| ROU-12 | TC-ROU-12-A1..A3 | P2 | |
| ROU-13 | TC-ROU-13-A1..A3 | P2 | |
| PLC-01 | TC-PLC-01-A1..A8 | P1 | ✔ |
| PLC-02 | TC-PLC-02-A1..A7 | P1 | ✔ |
| PLC-03 | TC-PLC-03-A1..A4 | P1 | |
| PLC-04 | TC-PLC-04-A1..A5 | P2 | |
| PLC-05 | TC-PLC-05-A1..A5 | P1 | |
| PLC-06 | TC-PLC-06-A1..A8 | P1 | ✔ |
| PLC-07 | TC-PLC-07-A1..A6 | P1 | ✔ |
| PLC-08 | TC-PLC-08-A1..A7 | P1 | ✔ |
| REC-01 | TC-REC-01-A1..A5 | P1 | ✔ |
| REC-02 | TC-REC-02-A1..A5 | P1 | ✔ |
| REC-03 | TC-REC-03-A1..A4 | P1 | ✔ |
| REC-04 | TC-REC-04-A1..A4 | P3 | ✔ |
| REC-05 | TC-REC-05-A1..A6 | P1 | ✔ |
| REC-06 | TC-REC-06-A1..A4 | P2 | |
| REC-07 | TC-REC-07-A1..A6 | P2 | |
| REC-08 | TC-REC-08-A1..A4 | P2 | |
| NAV-01 | TC-NAV-01-A1..A5 | P1 | ✔ |
| NAV-02 | TC-NAV-02-A1..A3 | P3 | |
| NAV-03 | TC-NAV-03-A1..A4 | P2 | |
| NAV-04 | TC-NAV-04-A1..A4 | P2 | |
| GRP-01 | TC-GRP-01-A1..A6 | P2 | ✔ |
| GRP-02 | TC-GRP-02-A1..A7 | P2 | ✔ |
| GRP-03 | TC-GRP-03-A1..A6 | P2 | ✔ |
| GRP-04 | TC-GRP-04-A1..A5 | P2 | |
| GRP-05 | TC-GRP-05-A1..A6 | P2 | ✔ |
| GRP-06 | TC-GRP-06-A1..A8 | P2 | ✔ |
| GRP-07 | TC-GRP-07-A1..A5 | P2 | ✔ |
| JRN-01 | TC-JRN-01-A1..A5 | P2 | |
| JRN-02 | TC-JRN-02-A1..A5 | P2 | |
| JRN-03 | TC-JRN-03-A1..A6 | P2 | |
| JRN-04 | TC-JRN-04-A1..A4 | P3 | |
| JRN-05 | TC-JRN-05-A1..A9 | P2 | ✔ |
| JRN-06 | TC-JRN-06-A1..A4 | P2 | |
| COM-01 | TC-COM-01-A1..A6 | P2 | ✔ |
| COM-02 | TC-COM-02-A1..A5 | P3 | |
| COM-03 | TC-COM-03-A1..A7 | P3 | ✔ |
| COM-04 | TC-COM-04-A1..A5 | P3 | |
| COM-05 | TC-COM-05-A1..A3 | P3 | |
| PER-01 | TC-PER-01-A1..A7 | P1 | |
| PER-02 | TC-PER-02-A1..A6 | P2 | |
| PER-03 | TC-PER-03-A1..A5 | P2 | |
| PER-04 | TC-PER-04-A1..A4 | P3 | |
| ADM-01 | TC-ADM-01-A1..A7 | P1 | ✔ |
| ADM-02 | TC-ADM-02-A1..A5 | P1 | |
| ADM-03 | TC-ADM-03-A1..A6 | P1 | ✔ |
| ADM-04 | TC-ADM-04-A1..A6 | P2 | ✔ |
| MER-01 | TC-MER-01-A1..A5 | P3 | ✔ |
| MER-02 | TC-MER-02-A1..A5 | P3 | ✔ |
| NFR-01..15 | §8 (TC-NFR-*) | P1→P3 | ✔ |

**Cách dùng**: `grep -r "TC-ROU-06" backend modules app_flutter` ⇒ mọi test của FR đó phải hiện ra. TC nào không có file test tương ứng ⇒ thiếu, chưa được test.

---

## 4. Test case chức năng

### 4.1 FR-AUTH · Khởi đầu và tài khoản

| ID | Loại | P | Tiền điều kiện | Bước + Input | Kết quả mong đợi (assert) |
| --- | --- | --- | --- | --- | --- |
| TC-AUTH-01-A1 | C | B | app cài mới | gọi `POST /v1/auth/guest {install_id, platform:"android"}` | `201`; `user.kind="guest"`; có `access_token` (TTL 900), `refresh_token`; **không** screen nào khác hiện ra trước màn spin |
| TC-AUTH-01-A2 | E | B | guest | chạm **Quay** ngay sau mở app | ra kết quả món; **0** lần bị bắt đăng nhập; `X-Request-Id` có trong log server |
| TC-AUTH-01-A3 | I | 1 | guest, 200 spin | `POST /v1/spins` lần 201 | vẫn `201` — guest không bị chặn đọc; chỉ **write** cần tài khoản (`feature_gates.requires_account`) → kiểm `403 FORBIDDEN` + `message_key` khi `POST /v1/lists` |
| TC-AUTH-01-A4 | X | 1 | guest | 10.000 request `POST /v1/auth/guest` từ cùng IP | `429 RATE_LIMITED` sau limit; `Retry-After` hợp lệ; không có user nào tạo trùng `install_id` (unique) |
| TC-AUTH-02-A1 | I | B | id_token Google thật (sandbox) | `POST /v1/auth/oauth {provider:"google", id_token, consent_granted:[{kind:"terms",policy_version:"2026.10"}]}` | `200 user.kind="full"`, `email_verified=true`, 1 `user_account`, 1 `consent` ghi `policy_version` |
| TC-AUTH-02-A2 | I | B | id_token chữ ký sai | như trên với token giả | `401 ID_TOKEN_INVALID`; **không** ghi user nào; log có `X-Request-Id` |
| TC-AUTH-02-A3 | I | 1 | token `aud` không phải client_id mình | | `401 ID_TOKEN_INVALID` (chống confusion-of-audience, OWASP ASVS) |
| TC-AUTH-02-A4 | I | 1 | Apple, nonce khác | `provider:"apple", nonce:"wrong"` | `401 ID_TOKEN_INVALID` |
| TC-AUTH-02-A5 | I | B | phone `0901234567` | `POST /v1/auth/otp/request {phone_e164:"+84901234567"}` → `POST /v1/auth/otp/verify {verification_id, code:"<6 số từ mock>"}` | `200` có `access_token`; DB lưu `+84901234567` (đã normalize, không còn số 0 đầu); `code` **không** bao giờ xuất hiện trong log |
| TC-AUTH-02-A6 | I | 1 | code sai 5 lần | verify 5 lần sai | lần 5 → `423 OTP_LOCKED`; verification bị thu hồi; lần 6 với code **đúng** vẫn fail |
| TC-AUTH-02-A7 | I | 1 | 4 phone / 1 IP | request OTP | 4 OK, cái 5 → `429 OTP_RATE_LIMIT` |
| TC-AUTH-03-A1 | E | B | guest có 41 spin, 12 visit, 3 list, diet `peanut` | guest → đăng nhập Google với `guest_upgrade:true` | cùng **một** `user.id` trước/sau; `preserved.spins=41 visits=12 lists=3`, diet còn nguyên. Assert bằng SQL count, không bằng UI |
| TC-AUTH-03-A2 | I | B | user Google đã tồn tại + guest đang đăng nhập | oauth cùng email | `409 IDENTITY_ALREADY_LINKED` + `details.merge_options=["keep_this","merge_into_existing"]`; **không** im lặng ghi đè |
| TC-AUTH-03-A3 | I | 1 | sau khi upgrade | refresh token cũ của guest | `401 REFRESH_REUSE_DETECTED` ⇒ thu hồi mọi phiên guest cũ |
| TC-AUTH-03-A4 | E | 1 | upgrade xong, tắt mạng | mở app | vẫn đọc được list/favorite từ cache, không màn hình lỗi |
| TC-AUTH-04-A1 | E | B | cài mới | đi hết onboarding | đúng **3** màn: vị trí → khẩu vị → ngân sách; mỗi màn **1** nút "Bỏ qua"; tổng chạm ≤ 7 |
| TC-AUTH-04-A2 | E | B | màn 1 | bấm Bỏ qua cả 3 màn rồi quay | vẫn quay được; `preferences` = default; `onboarding_completed=true`; spin trả kết quả (không crash vì thiếu prefs) |
| TC-AUTH-04-A3 | I | 1 | chỉ gửi step `location` | `PUT /v1/me/onboarding {step:"location", location:{geo:{...}}}` | `200 {next_step:"taste"}`; `onboarding_completed=false`; không tự complete |
| TC-AUTH-04-A4 | I | 1 | bước 3 ngân sách `weekly_vnd: 10000000` | | `400 VALIDATION_FAILED details[{field:"weekly_vnd", rule:"max", allowed:5000000}]` |
| TC-AUTH-04-A5 | E | 2 | app EN (`X-Locale: en`) | onboarding | mọi label tiếng Anh, không chuỗi Việt lẫn vào (NFR-11) |
| TC-AUTH-05-A1 | I | B | user đầy đủ có dữ liệu | `GET /v1/me/export?format=json` | `202` + poll; file chứa **đủ** 7 scope (profile, spins, visits, lists, reviews, consents, locations) |
| TC-AUTH-05-A2 | X | B | user có 5 devices | `DELETE /v1/me {confirm:true, erase_all:true}` | `202`; job chạy; **assert SQL**: `spin/visit/vote/user_diet/user_location/dish_exclusion/user_list/device` count = 0 hoặc anon; `consent` giữ tối đa 1 dòng anon (căn cứ pháp lý) |
| TC-AUTH-05-A3 | X | B | sau xóa | đăng nhập lại bằng cùng Google | tạo user mới hoàn toàn sạch (`counts.spins=0`); không "hồi sinh" dữ liệu cũ; không còn trong admin search theo email |
| TC-AUTH-05-A4 | I | 1 | `erase_all=false` | xóa | review còn nhưng `author.kind="anonymous"`, `user_id` NULL; `place` cộng đồng do user đề xuất **vẫn còn** (không phá dữ liệu chung) |
| TC-AUTH-05-A5 | E | 1 | app | chạm "Xóa tài khoản" | confirm 2 bước + giải thích thời hạn 30 ngày; sau đó app về màn guest, **keychain/Drift sạch** (assert bằng `flutter test` đọc DB cục bộ) |
| TC-AUTH-05-A6 | X | 2 | SLA | đo `deleted_at` → `deleted_complete_at` | ≤ 30 ngày, thực tế job chạy < 72 h; có alert nếu job fail (NFR-08) |

### 4.2 FR-ROU · Food Roulette

| ID | Loại | P | Tiền điều kiện | Bước + Input | Kết quả mong đợi |
| --- | --- | --- | --- | --- | --- |
| TC-ROU-01-A1 | I | B | `GET /v1/dishes/taxonomy` | | `counts.dishes >= 300`; mỗi dish có `category_path.length>=1`; `region ∈ {north,central,south,all}` phủ cả 4 giá trị (FR-ROU-01 "phân loại theo miền, loại, bữa") |
| TC-ROU-01-A2 | I | B | `POST /v1/spins {}` 10.000 lần, diet rỗng | | mọi kết quả là `dish.is_active=true`; **0** lần trả món inactive |
| TC-ROU-01-A3 | U | B | pool = 4 món weight bằng nhau, CSPRNG seed cố định | chạy 1.000.000 mẫu | tần suất mỗi món trong `[0.24, 0.26]` (χ² p > 0.01) — phân phối đều thật, không thiên vị phần tử đầu/cuối |
| TC-ROU-01-A4 | U | 1 | weight {A:6, B:3, C:1} | 1.000.000 mẫu | tỷ lệ ~ `[0.60, 0.30, 0.10] ±0.01`; **assert tổng mẫu == số lần chạy** |
| TC-ROU-01-A5 | I | 1 | gọi 1000 spin | | `pool_hash` khác nhau ≥ 2 giá trị (không cache pool một lần rồi quay mãi trên cùng 44 món) |
| TC-ROU-02-A1 | I | B | `filters.meal=["lunch"]` ×2000 mẫu | | 100 % `dish.meal` chứa `"lunch"` (kể cả `meal=["any"]` — **quy tắc phải viết rõ trong test**: `any` được tính là khớp) |
| TC-ROU-02-A2 | I | 1 | `price_level_max=2`, `budget_vnd=50000` ×2000 | | mọi `dish.price_level <= 2` |
| TC-ROU-02-A3 | I | 1 | `filters.type=["noodle"]`, `filters.region=["central"]` | | khớp cả 2 chiều đồng thời (AND giữa dimension, OR trong cùng dimension — **chốt quy tắc này trong test, không để dev tự đoán**) |
| TC-ROU-02-A4 | I | 1 | `locked.category_id=cat_bun` + `filters.type=["rice"]` | | xung đột → `pool.size_final=0` ⇒ **`409 POOL_TOO_SMALL`** với `suggested_relaxations`, **không** phải `201` với kết quả sai |
| TC-ROU-02-A5 | I | 2 | `filters.temp="cold"` | | `temp="hot"` bị loại; `temp="any"` còn (quy tắc OR-of-any) |
| TC-ROU-02-A6 | I | 1 | `filters.mood=["comfort"]` | | `pref>1` cho món có tag comfort ⇒ `w` cao hơn nhưng vẫn **có thể** ra món khác (kiểm: ≥ 1 kết quả ngoài mood trong 2000 mẫu — không biến filter mềm thành cứng) |
| TC-ROU-02-A7 | I | 2 | `party_size=8` | | spin thành công; field này chỉ tác động ở `/v1/matches` (assert `spin.filters` lưu đúng, `matches` nhận cùng value) |
| TC-ROU-02-A8 | I | 2 | 8 chiều filter cùng lúc, 3000 mẫu | | `applied_filters` response khớp **chính xác** 8 chiều gửi lên (không mất filter) |
| TC-ROU-02-A9 | E | 2 | app | chọn 3 filter → quay → tắt app → mở lại | filter **được nhớ** (persist), không reset về default |
| TC-ROU-03-A1 | I | B | `PUT /v1/me/diet {strict:["tag_peanut"], consent_granted:true}` → 5000 spin | | **0** kết quả có tag `peanut` (FR-ROU-03 "không bao giờ bị quay trúng") — test chạy mỗi CI, đây là test an toàn sức khoẻ |
| TC-ROU-03-A2 | I | B | diet strict `seafood`, món chỉ có `dsh_peanut_only` trong category | `POST /v1/spins {locked:{category_id:...}}` | `422 DIET_FILTER_EMPTY` + `details[]` nêu `strict=["seafood"]` ∩ `locked.category_id` và `suggested_relaxations[]` |
| TC-ROU-03-A3 | I | B | user có diet `peanut` | `POST /v1/spins {diet:{override_strict:[]}}` — cố bỏ | diet đã lưu **vẫn áp dụng**; `override_strict` chỉ thêm. Assert: client không có cách nào tạo spin không-peanut-filter. Đây là test **bảo mật người dùng**, dễ sai nhất |
| TC-ROU-03-A4 | I | 1 | `PUT /v1/me/diet {strict:["tag_sushi"], consent_granted:false}` | | `403 CONSENT_REQUIRED`; DB không đổi (dữ liệu sức khoẻ chỉ lưu khi đồng ý — SRS 11) |
| TC-ROU-03-A5 | I | 1 | `strict=["tag_pork","halal"]` | spin | `201`; `pool.removed.diet_hard` > 0; response `pool.size_after_hard_filters` khớp SQL count (chứng minh filter cứng chạy **trước** khi sample, không phải "quay xong rồi ẩn") |
| TC-ROU-03-A6 | E | 1 | app, 2 dị ứng | bật rồi quay 20 lần | UI có khu vực "Đang loại: hải sản, đậu phộng"; không món nào vi phạm; sau khi xoá dị ứng → món quay lại pool lần quay sau |
| TC-ROU-04-A1 | I | B | `locked:{category_id:"cat_mon_nuoc"}` 2000 mẫu | | 100 % kết quả là con của `món nước` (kể cả node cấp 1 → phải resolve **cả cây**, không chỉ lá trực tiếp) |
| TC-ROU-04-A2 | I | B | `locked:{category_id:"cat_bun", region:"central"}` | | 100 % khớp **cả hai** thuộc tính khoá; `pool.removed.locked` phản ánh đúng số bị cắt |
| TC-ROU-04-A3 | I | 1 | `locked.temp="hot"` + `filters.temp="any"` | | lock thắng; `applied_filters.locked.temp="hot"` trong response |
| TC-ROU-04-A4 | E | 1 | app | chạm khoá "món nước", quay 3 lần, bấm "Bỏ khoá" | sau 1 chạm bỏ khoá → pool trở lại ≥ 300 (kiểm `pool.size_initial` đổi giữa 2 response) |
| TC-ROU-04-A5 | U | 2 | `locked.category_id` không tồn tại | | `400 VALIDATION_FAILED details[{field:"locked.category_id", rule:"exists"}]` |
| TC-ROU-05-A1 | I | B | `POST /v1/exclusions {dish_id:"dsh_internal", scope:"permanent"}` → 3000 spin | | món đó **0** lần xuất hiện; `pool.removed.excluded=1` |
| TC-ROU-05-A2 | I | 1 | `scope:"temporary", days:2` | clock +3 ngày | `GET /v1/exclusions` rỗng; món quay lại pool |
| TC-ROU-05-A3 | I | 1 | `GET /v1/exclusions` | | màn quản lý list hiển thị đúng scope, có nút bỏ từng món (assert API, UI manual) |
| TC-ROU-05-A4 | X | 1 | `POST /v1/exclusions` với `dish_id` của user khác | | `404` hoặc `400`, **không** phải `500` |
| TC-ROU-05-A5 | I | 2 | cùng dish, 2 lần POST scope khác nhau | | `permanent` thắng `temporary`; xoá → mất cả 2 (không còn "shadow exclusion") |
| TC-ROU-06-A1 | I | B | user vừa ăn `dsh_bun_bo` (`visit` hôm nay), `anti_repeat.days=3` | 5000 spin | xác suất `dsh_bun_bo` giảm theo `exp(-1/3)=0,7165` **so với** baseline; đo: `p_with / p_without ≈ 0,7165 ± 0,02`. Assert bằng tỷ lệ mẫu lớn, không assert "không ra" (đây là giảm xác suất, không phải loại) |
| TC-ROU-06-A2 | I | B | cùng món, visit cách 10 ngày, `days=3` | | window cắt ở 3 ngày → món **không** bị phạt; `anti_repeat.applied=[]` |
| TC-ROU-06-A3 | I | 1 | `anti_repeat:{days:30, scope:"category"}` | | cả category bị phạt; `anti_repeat.max_penalty` phản ánh trọng số nhỏ nhất; `tau_days` đúng cấu hình |
| TC-ROU-06-A4 | I | 1 | đổi `tau` qua remote config `3.0 → 1.5` | | kết quả mẫu đổi theo **mà không restart** service (chứng minh "N chỉnh được" + config từ xa) |
| TC-ROU-06-A5 | U | 1 | Δdays = 0 | | factor = 1,0 (không chia 0, không âm) |
| TC-ROU-06-A6 | I | 1 | spin hôm nay, spin tiếp ngay trong cùng phút | | spin #2 **có** phạt món vừa ra ở spin #1 (chống "ra món A, A, A") |
| TC-ROU-06-A7 | E | 2 | app | bật "chống lặp = 5 ngày" trong cài đặt | request gửi `anti_repeat.days=5`; giá trị được lưu và restore khi mở lại app |
| TC-ROU-07-A1 | I | B | `POST /v1/spins` | | response chứa `proof.seed_b64`, `proof.sha256_result` **trước khi** app vẽ frame đầu tiên của hoạt hình (assert client: gọi API xong mới `setState` kết quả). Test bằng cách cho mock API delay 3 s → app **không** hiện "đang quay ra món X" nào trước đó |
| TC-ROU-07-A2 | I | B | cùng `client_seed` + cùng dataset (staging) | spin 2 lần | **cùng một** `dish_id` + cùng `sha256_result` ⇒ reproduce được để debug (và CSPRNG không được bỏ qua seed ở prod: `400` nếu `client_seed` gửi từ prod token) |
| TC-ROU-07-A3 | I | 1 | `POST /v1/spins/{id}/verify {claim_sha256: <kết quả app nhận>}` | | `200 {valid:true}`; gửi `claim_sha256` sai → `valid:false` (chứng minh app không tự đổi kết quả được) |
| TC-ROU-07-A4 | E | 1 | app | hoạt hình dừng ở ô món B, UI hiển thị món **B** | `animation.result_index` đúng vị trí `dish.id` trong `animation.wheel_items` — test chệch 1 index là bug kinh điển của roulette |
| TC-ROU-08-A1 | E | 1 | chọn `chest` / `draw` / `wheel` | quay | mỗi kiểu chạy ≥ 24 fps trên máy tầm trung; `duration_ms` theo response; kết quả **không đổi** khi đổi kiểu (assert `dish_id` với cùng seed) |
| TC-ROU-08-A2 | E | B | `sound=false, haptics=false, reduce_motion=true` | quay | **0** âm thanh, **0** rung, hoạt hình tắt/khô (ảnh + text); kết quả hiện ngay |
| TC-ROU-08-A3 | E | 1 | hệ thống bật "Reduce motion" (iOS/Android) | | app tự tôn trọng dù user chưa set trong app (NFR-10/WCAG 2.3.3) |
| TC-ROU-08-A4 | E | 2 | `animation_style="none"` từ `/v1/config` default | | mặc định theo `GET /v1/config.animation_styles[0]`; có fallback nếu style bị admin tắt |
| TC-ROU-08-A5 | E | 2 | gọi trong lúc điện thoại đang quay video/clock tick | | hoạt hình không bị drop gây hiểu "app treo"; có "Bỏ qua" chạm 1 lần hiện ngay kết quả (touch target ≥ 44 pt) |
| TC-ROU-09-A1 | E | B | `plc_closing_45` + `plc_big_mid` + 3 quán đang đóng | chạm **Đói gấp** 1 lần | kết quả **1 quán** duy nhất + nút "Đi ngay"; quán trả về có `open_status.is_open=true` và `closes_in_min >= 45`; **không** màn filter nào ở giữa; tổng chạm từ mở app ≤ 3 (SRS 2.6.1) |
| TC-ROU-09-A2 | P | B | 1000 user ảo ở cùng geohash | `GET /v1/places/urgent` | p95 ≤ 1500 ms; **0 provider call** (`meta.providers_used` chỉ có `db`/`redis`); UC-03 yêu cầu "dưới 2 giây" |
| TC-ROU-09-A3 | I | 1 | 0 quán mở trong 1,5 km, 1 quán mở ở 3 km | urgent | `200`, `decision.expanded=true`, `radius_m_used=2500` rồi 4000, `place` = quán 3 km |
| TC-ROU-09-A4 | I | 1 | 0 quán mở trong 4 km | urgent | **`200`** với `place=null`, `alternatives[]` là quán sắp mở ≤ 30′, `notify_key="urgent.none_open"`. Assert **không** phải `404` — luồng một chạm không được chết |
| TC-ROU-09-A5 | I | 1 | user dị ứng đậu phộng, quán gần nhất bán món đậu phộng | | quán bị loại, trả quán xa hơn; `why` không lộ ràng buộc sức khoẻ (SRS 11) |
| TC-ROU-09-A6 | E | 1 | đang offline | chạm Đói gấp | app hiện hướng dẫn (không spinner vô hạn): "Cần mạng để tìm quán"; và fallback gợi ý quán **đã cache** gần nhất với nhãn cũ |
| TC-ROU-10-A1 | E | B | tắt máy bay (Airplane mode) | quay 10 lần | ra 10 kết quả hợp lệ từ bundle Drift; `network_state="offline_bundle"` khi back online + sync; **0** crash |
| TC-ROU-10-A2 | I | 1 | bundle `If-None-Match` trùng | `GET /v1/dishes/bundle` | `304 Not Modified`; payload 0 byte |
| TC-ROU-10-A3 | I | 1 | `since_version=20261015`, hiện tại `20261101` | | `is_delta=true`, `upsert` chỉ món thay đổi, `deactivate` đúng danh sách; app merge **không** tạo duplicate (assert `local_id` unique) |
| TC-ROU-10-A4 | X | 1 | bundle signature bị sửa 1 byte | | app từ chối merge, giữ bundle cũ, báo telemetry; **không** crash |
| TC-ROU-10-A5 | P | 1 | bundle đầy đủ | | full < 350 KB gzip, delta < 40 KB; app load bundle 300 món vào Drift < 800 ms (cold start NFR-02 2,5 s có phần này) |
| TC-ROU-10-A6 | E | 1 | offline quay xong | bật mạng, chạm "tìm quán" | `POST /v1/matches` chạy với `spin_id` của spin offline; server **không** `404` vì spin chưa được sync (app phải push spin qua `POST /v1/journal/sync` hoặc spin POST bù — chốt hành vi ở test này, tránh mỗi nơi làm một kiểu) |
| TC-ROU-11-A1 | I | 1 | `POST /v1/wheels {name:"Món nhà nấu", dish_ids:[10 id]}` → spin `wheel_id` | | 100 % kết quả ∈ 10 id; `pool.source="wheel"`; `pool.size_initial=10` |
| TC-ROU-11-A2 | I | B | wheel chứa 1 món đậu phộng, user diet đậu phộng | | món đó **không bao giờ** ra — diet hard vẫn thắng wheel (ưu tiên an toàn) |
| TC-ROU-11-A3 | I | 2 | wheel 1 id | | `400 VALIDATION_FAILED` (yêu cầu ≥ 2) |
| TC-ROU-11-A4 | I | 2 | share wheel qua `share_url`, người nhận `POST /v1/wheels/from-share` | | bản copy độc lập (sửa của A không ảnh hưởng B) |
| TC-ROU-12-A1 | I | 1 | 3 `POST /v1/spins/{id}/dismiss` liên tiếp | spin #4 | response spin #4 có `dismissed_streak=3` + `suggestion.action ∈ {narrow_filters, use_urgent}` với payload cụ thể |
| TC-ROU-12-A2 | I | 1 | dismissal xen kẽ 1 lần chốt thành công | | `dismissed_streak` reset về 0 |
| TC-ROU-12-A3 | I | 2 | server gợi ý nới | | bộ lọc user **không** bị đổi âm thầm (assert `preferences` không đổi); user phải chạm xác nhận |
| TC-ROU-13-A1 | E | 2 | share kết quả | `POST /v1/spins/{id}/share-card {style:"story"}` | ảnh WebP có tên món + ảnh + QR/shortlink; `alt_text_vi` có (accessibility khi share); signed URL hết hạn 15′ |
| TC-ROU-13-A2 | I | 2 | share card của spin user khác (đoán `spin_id`) | | `403 FORBIDDEN` — IDOR |
| TC-ROU-13-A3 | I | 3 | `include_place=true` | | card có quán; **không** chứa thông tin vị trí của user |

### 4.3 FR-PLC · Vị trí và quán gần

| ID | Loại | P | Tiền điều kiện | Bước + Input | Kết quả mong đợi |
| --- | --- | --- | --- | --- | --- |
| TC-PLC-01-A1 | E | B | từ chối quyền vị trí | chạm tìm quán | app **không** crash, không loop xin quyền; hiện ô nhập địa chỉ; `GET /v1/places/nearby?address=` hoạt động (UC-01 ngoại lệ) |
| TC-PLC-01-A2 | I | B | thiếu cả `geo`, `user_location_id`, `address` | `GET /v1/places/nearby` | `400 LOCATION_REQUIRED` + `message_key` |
| TC-PLC-01-A3 | I | 1 | 1500 quán, geo ở tâm | `radius_m=200` vs `5000` | count tăng đơn điệu theo radius; mỗi item `distance_m` ≤ radius + 100 (sai số geodesic); `distance_m` tính **geodesic** (ST_DistanceSphere), không Euclidean trên SRID 4326 — test bằng cặp điểm cách nhau đúng 1 km thật |
| TC-PLC-01-A4 | E | 1 | lưu "Nhà" + "Cơ quan" | `POST /v1/user-locations` 2 cái, `is_default` cái sau | chỉ **1** default (atomic unset cái cũ); đổi default → request tiếp theo anchor theo default mới |
| TC-PLC-01-A5 | X | B | user A dùng `user_location_id` của user B | `GET /v1/places/nearby?user_location_id=ulc_B` | `403 LOCATION_NOT_AUTHORIZED`, **không** trả toạ độ B trong message (IDOR test bắt buộc) |
| TC-PLC-01-A6 | X | 1 | `X-Geo-Precision: coarse`, gửi `geo` 6 decimal | | server chỉ dùng geohash **5**; log/metrics **không** chứa toạ độ chi tiết (grep access log) |
| TC-PLC-01-A7 | I | 1 | du lịch: ghim quận khác thành phố | `POST /v1/geocode {address:"...Đà Nẵng"}` | `422 OUTSIDE_SERVICE_AREA` (P1 1 thành phố) **kèm** hướng dẫn, không phải lỗi khô khan |
| TC-PLC-01-A8 | E | 2 | GPS trả toạ độ rác (mock 0,0 / -90,0) | | app validate + fallback nhập tay; server `400` cho `lat=0,lng=0` ngoài bbox city |
| TC-PLC-02-A1 | E | B | kết quả 20 quán | bật list | mỗi card có **đủ 4** element bắt buộc FR-PLC-02: khoảng cách, giờ mở, mức giá, điểm + số đánh giá. Test bằng widget assertions, không bằng screenshot so màu |
| TC-PLC-02-A2 | I | 1 | radius slider 200→5000 | `radius_m=50` và `6000` | `400` cho ngoài khoảng 200–5000; `radius_m=5000` OK |
| TC-PLC-02-A3 | I | 1 | `plc_small_hi` 60 m rating 5,0 (2 review) vs `plc_big_mid` 200 m 4,2 (200) | `sort=score` | `plc_big_mid` **trên** `plc_small_hi` nếu chỉ tính Q (chứng minh Bayesian) — nhưng kết quả cuối cùng có thể đảo vì D; **assert đồng thời** `score_breakdown.Q` của `plc_small_hi` < `plc_big_mid` |
| TC-PLC-02-A4 | I | 1 | `sort=distance` | | `distance_m` tăng đơn điệu; `score_breakdown` **không** xuất hiện khi `sort != score` (giảm payload) |
| TC-PLC-02-A5 | C | 1 | 25 item, `has_more=true` | `cursor` tiếp | item 26 là kế tiếp, **không** trùng/không thiếu (ổn định thứ tự bằng `(score DESC, id ASC)` tiebreaker; test: phân trang không bị lặp quán khi data đổi giữa 2 trang) |
| TC-PLC-02-A6 | P | B | cache L1 trắng vs đã warm | `GET /v1/places/nearby` | warm p95 ≤ 500 ms; cold (kèm provider) ≤ 1500 ms (NFR-01) |
| TC-PLC-02-A7 | I | 2 | quán nằm **đúng** trên biên radius (distance == radius) | | có mặt (`<=` không phải `<`) — bug biên hay gặp với PostGIS |
| TC-PLC-03-A1 | E | B | cùng bộ lọc, đổi list ↔ map | | danh sách **giống hệt** theo tập id, không đổi filter khi đổi view (FR-PLC-03) |
| TC-PLC-03-A2 | I | 1 | `view=map&zoom=15` 40 quán trong 2 km | | có `clusters[]`, `sum(cluster.count) == total_estimate`, `center_geo` của cluster nằm trong bbox cluster |
| TC-PLC-03-A3 | E | 2 | pinch zoom | zoom 13→17 | request mới đúng `zoom`; không spam API (debounce ≥ 300 ms — assert số request trong 2 s) |
| TC-PLC-03-A4 | E | 2 | `view=list` với 500 quán | | scroll 60 fps, cache trang, không reload ảnh (manual + Firebase Perf) |
| TC-PLC-04-A1 | I | 1 | `amenities=ac,parking` | | chỉ quán có **cả 2** amenity (AND); quán null amenities bị loại |
| TC-PLC-04-A2 | I | 1 | `min_rating=4.5` | | dùng `rating_bayesian` **không phải** `rating_raw` (assert chọn field); quán 2 review 5,0 bị loại |
| TC-PLC-04-A3 | I | 2 | `party_size=8` | | ưu tiên `group_friendly=true`; quán 4 chỗ ngồi ra sau |
| TC-PLC-04-A4 | I | 2 | `takeaway=true` | | |
| TC-PLC-04-A5 | I | 2 | filter combo | | `meta.applied_filters` echo đúng để debug |
| TC-PLC-05-A1 | E | B | `plc_big_mid` | mở chi tiết | đủ: ảnh ≥ 1, món nổi bật, địa chỉ, điện thoại (nếu có), giờ mở theo 7 ngày, đánh giá (FR-PLC-05); `?sections=` trả đủ các section yêu cầu |
| TC-PLC-05-A2 | I | 1 | quán không có `place_hours` (`plc_no_hours`) | | `open_status.is_open=null`, `note_key="hours.unknown"`, **vẫn hiển thị** quán, không crash, `o_score` mặc định = 0.5 (quy ước phải viết trong test) |
| TC-PLC-05-A3 | X | 1 | `place_id` sai/hex decode lỗi | `GET /v1/places/notanid` | `404` (không `500`); message không lộ stack trace / SQL |
| TC-PLC-05-A4 | I | 1 | quán bị merge | `GET /v1/admin/places/{loser}` | `301`-style payload có `merged_into` (app redirect tới winner, history visit vẫn đọc được) |
| TC-PLC-05-A5 | E | 2 | quán có 0 ảnh | | placeholder không vỡ layout; `images=[]` (không null) |
| TC-PLC-06-A1 | I | B | fixtures `plc_closing_45`/`plc_closing_44`/`plc_closed` | `GET /v1/places/nearby?open_now=true`, `fake_now=10:20` | `plc_closed` **không có** trong items (FR-PLC-06 "loại quán đã đóng khỏi kết quả mặc định"); `plc_closing_45.o_score=1.0`; `plc_closing_44.o_score=0.5` |
| TC-PLC-06-A2 | I | B | `plc_closing_30` vs `plc_closing_29` | | `closing_soon`: `false` và `true` (ngưỡng **dưới 30 phút** — strict `<`; test 30 chính xác và 29) |
| TC-PLC-06-A3 | E | B | `fake_now` = quán đóng trong 20 phút | mở list | app hiện cảnh báo "Chỉ còn 20 phút nữa đóng" tại **card** và **detail**; banner dùng `closing_soon` từ server, **không** tự tính từ giờ máy (test bằng cách chỉnh giờ máy -3 h ⇒ vẫn đúng) |
| TC-PLC-06-A4 | I | 1 | quán có `place_hours_exception` đúng hôm nay, `is_closed=true` | | bị loại khỏi `open_now=true` dù `hours_by_dow` nói mở (ngoại lệ thắng lịch tuần) — TC dễ sai nhất khi code |
| TC-PLC-06-A5 | I | 1 | quán mở qua nửa đêm `18:00–02:00` | `fake_now=00:30` | `is_open=true`, `closes_in_min=90`; **không** tính ra −10 giờ (bug wrap-around) |
| TC-PLC-06-A6 | I | 2 | `include_closed=true` | | quán đã đóng xuất hiện, `o_score=0.0`, có nhãn rõ ràng |
| TC-PLC-06-A7 | U | 1 | quán mở 06:00–22:00, tz `Asia/Ho_Chi_Minh`, request lúc `2026-11-01T23:00:00Z` (=06:00 sáng hôm sau VN) | | `is_open=true` **của ngày kế tiếp**; dow phải lấy theo tz quán, không theo UTC |
| TC-PLC-06-A8 | I | 2 | quán vừa bị admin `POST /v1/merchant/places/{id}/status closed_temporarily` | | rời khỏi kết quả trong ≤ 60 s (cache invalidation — TC-ADM-03) |
| TC-PLC-07-A1 | E | B | chạm "Báo sai" → chọn `wrong_hours` → gửi | | `POST /v1/places/{id}/reports {kind:"wrong_hours", suggested_value:{closes_at:"11:30"}}` → `201 status="open"`; app xác nhận + nói rõ quán sẽ được kiểm tra (FR-PLC-07) |
| TC-PLC-07-A2 | I | B | cùng user, cùng place, cùng kind, **cùng ngày**, 5 lần | | lần 2+ trả `200 duplicate_of=<report_id>`, DB chỉ 1 dòng (unique `dedup_key`) |
| TC-PLC-07-A3 | I | 1 | 6 report/ngày/user | | lần 6 → `429 REPORT_LIMIT` |
| TC-PLC-07-A4 | I | B | report được admin `accept` | | `place.report_count_30d` ↑; **`score_breakdown.penalty.items` có `report_ratio`** trong ≤ 10 phút; `data_confidence` giảm. Ngược lại report `reject` ⇒ penalty **không** đổi |
| TC-PLC-07-A5 | X | 1 | 200 user giả report 1 quán tốt trong 5 phút, **không** qua moderation | | xếp hạng **không** đổi cho tới khi accept (chống "một người ghét quán kéo tụt rank") — test this: run A/B `nearby` trước-sau |
| TC-PLC-07-A6 | I | 2 | guest (không token) báo | | `201`, dedup theo `device_id` (giảm rủi ro dữ liệu vỉa hè — SRS 12.3) |
| TC-PLC-08-A1 | X | B | `PATCH /v1/admin/providers/google {enabled:false}` | `GET /v1/places/nearby` | `200` **vẫn có quán**; `meta.data_quality ∈ {cached, provider_degraded, stale}`; `X-Data-Quality` header set; app hiện banner (FR-PLC-08) |
| TC-PLC-08-A2 | X | B | WireMock trả `503` + delay 8 s cho OSM | | circuit breaker mở sau threshold; request tự fallback **Postgres-only**, p95 không vượt 1,5 s; timeout adapter 1200 ms độc lập với SLA |
| TC-PLC-08-A3 | X | 1 | Google quota hết hạn mức (`429 QUOTA_EXCEEDED` từ provider) | | gọi Google **dừng hẳn** 1 chu kỳ (backoff), fallback sang `osm` + `community`; `GET /v1/admin/providers/status` báo `health:"degraded"`, quota `used/limit` chính xác; **chi phí phát sinh = 0** trong thời gian backoff (assert không có call) |
| TC-PLC-08-A4 | I | 1 | cache đã hết TTL **theo ToS** của provider | | server **không** trả `stale-while-revalidate` quá TTL ToS; `meta.tos_cache_age_ok=true`; nếu ToS buộc xoá → `place_source_ref.raw` bị xoá đúng hạn (TC-PRIV-02) |
| TC-PLC-08-A5 | E | 1 | mất mạng hoàn toàn, chưa từng mở app ở khu vực đó | | app hướng dẫn nhập địa chỉ + giải thích "không tìm được quán offline"; **không** spinner vô hạn; không crash |
| TC-PLC-08-A6 | I | 2 | `plc_osm_only` (không có trong Google) | tắt Google | vẫn hiển thị (hợp nhất đa nguồn không phụ thuộc 1 provider) |
| TC-PLC-08-A7 | I | 2 | provider trả dữ liệu **trùng** quán đã có (`external_id` khác, cùng tên+50 m) | enrichment | `place-merge` **không** tạo bản duplicate mới; `place_source_ref` thêm nguồn thứ 2 cho cùng `plc_...` |

### 4.4 FR-REC · Matching và gợi ý

| ID | Loại | P | Tiền điều kiện | Bước + Input | Kết quả mong đợi |
| --- | --- | --- | --- | --- | --- |
| TC-REC-01-A1 | I | B | `dsh_bun_bo_hue` → 3 quán có `place_dish.confidence 0.93/0.6/0.3` | `POST /v1/matches {dish_id, geo, radius_m:2000}` | chỉ quán confidence ≥ ngưỡng cấu hình (mặc định 0.5) được xếp hạng; `items.length ≥ 1`; `meta.candidate_count` khớp SQL |
| TC-REC-01-A2 | I | B | quán có tên "Bún bò" nhưng `place_dish` **rỗng** | | **không** match (assert: match dựa trên `place_dish` + tag, **không** dựa vào substring tên quán). Chốt rõ trong test để tránh dev "đoán tên" |
| TC-REC-01-A3 | I | 1 | `spin_id` được gửi kèm | | `context_used` đọc đúng `spin.filters`; reproduce cùng pool như spin (FR-REC-01 "ánh xạ món sang quán") |
| TC-REC-01-A4 | U | 1 | món cấp lá vs quán tag cấp cha | | anchor taxonomy đúng: quán tag "bún" match món "bún bò" (đi **ngược** lên cha), nhưng quán tag "cơm tấm" không match |
| TC-REC-01-A5 | I | 2 | `dish_ids` 5 món | | mỗi item có `matched_dish_id` thuộc danh sách; `limit=3` trả 3 |
| TC-REC-02-A1 | E | B | top 1 quán | | app hiện mục **"Vì sao gợi ý quán này"** chứa ≥ 2 lý do bằng tiếng người, dẫn từ `why.headline` + top components (FR-REC-02) |
| TC-REC-02-A2 | I | B | bất kỳ response `POST /v1/matches` | | `Σ components.contribution − penalty.total == score_total` (sai số ≤ 0,05) **với mọi item**; `weights` khớp `formula_version` từ config; `top_component` là component có `contribution` lớn nhất |
| TC-REC-02-A3 | I | B | mọi quán trong top | | quán nào cũng có **ít nhất 1** component có `top=true` (SRS 6.1: "mọi quán trong top đều hiển thị thành phần đóng góp lớn nhất") — test loop qua items, không chỉ item 0 |
| TC-REC-02-A4 | X | 1 | mở mục vì sao, đổi ngôn ngữ EN | | `why_key` dịch sang EN; không còn chuỗi Việt hard-code (NFR-11) |
| TC-REC-02-A5 | M | 2 | 5 người dùng thật đọc mục "Vì sao" | | ≥ 4/5 nói được lý do quán này được gợi ý (đo bằng usability test; SRS 2.6.3 "minh bạch") |
| TC-REC-03-A1 | U | B | `R=5.0,v=2,C=4.0,m=20` vs `R=4.2,v=200` | | `Q_small = (2·5 + 20·4)/22 = 4,045`; `Q_big = (200·4.2 + 20·4)/220 = 4,182`; `Q_big > Q_small` — quán ít review **không** vượt quán nhiều review (FR-REC-03) |
| TC-REC-03-A2 | I | B | `plc_small_hi` vs `plc_big_mid` cùng distance/price | `sort=score` | `rating_bayesian` của `plc_small_hi` **thấp hơn** `plc_big_mid` dù raw 5,0 > 4,2; `score_breakdown.Q.facts.m_threshold == 20` |
| TC-REC-03-A3 | U | 1 | `v=0` | | `Q = C` (điểm hệ thống), không NaN/chia 0; `review_count=0` hiển thị "Chưa có đánh giá", không ra 0★ |
| TC-REC-03-A4 | U | 2 | `v=25 ≥ m` | | ảnh hưởng `m` gần như 0 (độ lệch giữ `Q` và `R` nhỏ hơn 0,04) |
| TC-REC-04-A1 | I | B | chạy `POST /v1/matches` với và không với `include_sponsored=true` | | **danh sách tự nhiên giữ nguyên thứ tự tuyệt đối**; ad được **chèn thêm** và mang `is_sponsored=true` + `natural_rank` (FR-REC-04) |
| TC-REC-04-A2 | X | B | promotion đang chạy, `score_breakdown` | | `score_total` của quán đó **giống hệt** khi không bật promotion (assert 100% equality, không phải "gần giống") |
| TC-REC-04-A3 | E | 1 | app | | card ad có nhãn **"Quảng cáo"** tương phản đạt AA; ad không chiếm quá N vị trí đầu (config `ads.max_per_page`) |
| TC-REC-04-A4 | I | 1 | server thiếu label cho ad | | `403 SPONSORED_LABEL_MISSING` hoặc promotion tự tắt (FR-MER-02) |
| TC-REC-05-A1 | I | B | `radius_m=200`, `dish_id` món chỉ có quán ở 1,8 km | `POST /v1/matches` | `200`, `items=[]`, `relaxation.steps_available[0] = {dimension:"radius_m", from:200, to:500..., expected_extra:N}` **và** `substitute_dishes[]` không rỗng (FR-REC-05: nới **đồng thời** gợi ý món thay thế) |
| TC-REC-05-A2 | E | B | tiếp theo A1 | | app hiện đúng **một** đề xuất nới có con số ("Nới bán kính lên 800 m?"), user chạm → request mới với radius nới, không tự nới âm thầm |
| TC-REC-05-A3 | I | 1 | nới 3 bậc vẫn 0 kết quả | | `steps_available=[]`, `substitute_dishes[]` có ≥ 2, `no_result_key="nomatch.all"` — không bao giờ `404` |
| TC-REC-05-A4 | I | 1 | nới theo thứ tự ưu tiên | | `steps_available` đúng thứ tự: radius → price → meal → category (assert index, đây là UX consistency) |
| TC-REC-05-A5 | X | 1 | diet hard `peanut` + nới filter | | relaxation **không bao giờ** nới ràng buộc diet/allergen — assert mọi candidate đầu ra không chứa peanut (an toàn) |
| TC-REC-05-A6 | I | 2 | `substitute_dishes.similarity` | | 0 < similarity ≤ 1, sắp giảm dần; món thay thế **không** vi phạm diet của user |
| TC-REC-06-A1 | I | 1 | user có 20 visit cùng category "món nước", `personalization_opt_in=true` | | `U > 0.3`, `score_breakdown.U.facts.favourite/similarity` populated; kết quả **khác** với user mới (cold start) trên cùng geo |
| TC-REC-06-A2 | I | B | `personalization_opt_in=false` | | `U = 0.0`, `meta.personalization_used=false`, trọng số redistribute về tổng 1 (`weights` trong response phản ánh thật) |
| TC-REC-06-A3 | I | 1 | tắt cá nhân hoá rồi bật lại | | state nhất quán, không "hố" cache cũ (`cache key` phải chứa biến cá nhân hoá — test: 2 user khác nhau **không** cùng một `page.items` khi cùng geo/bộ lọc) |
| TC-REC-06-A4 | E | 2 | user "Quên tôi"/xoá visit | | kết quả trở về baseline sau cache TTL ≤ 10 phút (quyền kiểm soát dữ liệu — NFR-08) |
| TC-REC-07-A1 | I | 1 | fake clock `2026-10-31T17:00:00Z` = 01/11 00:00 giờ VN | `POST /v1/matches` | `context_used.dow`, `hour_bucket`, `is_month_end` tính **theo giờ VN**; `is_month_end` = true ngày cuối tháng dương lịch và false ngày 2 tháng sau |
| TC-REC-07-A2 | I | 1 | `context:{weather:"rain"}` gửi tường minh | | `weight_overrides` áp dụng, `meta.context_used.weather="rain"`; **client override không được vượt trần** (assert trọng số vẫn normalize = 1) |
| TC-REC-07-A3 | X | 1 | WeatherPort trả 500 | | `context_used.weather=null`, request vẫn `200` và p95 không đổi ≥ 100 ms (thành phần phụ chết không sập luồng chính — NFR-06) |
| TC-REC-07-A4 | I | 2 | trời mưa + 21:00 + cuối tháng, 3 bộ | | thứ tự top-3 thay đổi theo từng điều kiện; **nhưng** quán `plc_closed` luôn vắng mặt (ràng buộc cứng không bị context ghi đè) |
| TC-REC-07-A5 | U | 2 | `GET /v1/context?geo&at` vs `matches.context_used` | | hai bên **khớp từng field** (endpoint debug dùng để bắt bug cache context) |
| TC-REC-07-A6 | E | 3 | app | | app không tự suy thời tiết từ API riêng (assert: app chỉ 1 nguồn config, không có key weather trong bundle) |
| TC-REC-08-A1 | I | B | `preference_bias:{closer:1,tastier:-1,cheaper:-1}` trên dataset 45 quán | | `plc_far_best` tụt hạng so với bias 0; `items[0].distance_m ≤ items[0].distance_m` khi bias 0 (đơn điệu theo chiều đúng) |
| TC-REC-08-A2 | I | 1 | bias `cheaper:1` | | `plc_expensive` (300k) tụt/xuống sau `plc_small_hi` (30k) |
| TC-REC-08-A3 | C | 1 | bias ∈ {−1, 0, 1, −1.2, 2} | | `−1.2` và `2` → `400 VALIDATION_FAILED rule:"range"`; ba giá trị hợp lệ cho **3 thứ tự khác nhau được** nhưng `formula_version` và `penalty` không đổi |
| TC-REC-08-A4 | E | 2 | kéo slider trong app | | debounce ≤ 300 ms, tổng request kéo slider hết cỡ ≤ 3 (không spam API); kết quả cập nhật < 1 s |

### 4.5 FR-NAV · Chỉ đường

| ID | Loại | P | Tiền điều kiện | Bước + Input | Kết quả mong đợi |
| --- | --- | --- | --- | --- | --- |
| TC-NAV-01-A1 | E | B | Android, Google Maps cài | chạm "Chỉ đường" | mở **Google Maps** với `daddr=<lat,lng>`; đi đúng quán (so toạ độ request vs intent). Assert bằng `adb shell dumpsys activity` / Patrol, không assert bằng mắt |
| TC-NAV-01-A2 | E | B | iOS, chưa cài Google Maps | | fallback **Apple Maps**; không màn hình trắng; lựa chọn phương tiện (`travel_mode`) được truyền (CarPlay/Maps mode) |
| TC-NAV-01-A3 | X | 1 | `place.geo` bị null (dữ liệu bẩn từ OSM) | | app **ẩn** nút chỉ đường + hiện chỉ dẫn thủ công; server `422 PLACE_GEO_MISSING`; **không** deep link với `lat=0&lng=0` (đưa user ra vịnh Guinea) |
| TC-NAV-01-A4 | I | 1 | backend không được gọi khi chạm chỉ đường | | assert số request = 1 (tạo `visit status:"chosen"` nếu user đồng ý) — chứng minh "chỉ đường là client-side" (FR-NAV-01), tránh dev gọi API đường đi vô ích tốn tiền |
| TC-NAV-01-A5 | E | 2 | quán có `delivery_url`/`booking_url` (P3) | | mở đúng URL trong in-app browser có cảnh báo "rời khỏi ứng dụng" |
| TC-NAV-02-A1 | E | 1 | `phone_e164="+84903..."` | chạm gọi | `tel:` intent hợp lệ; quán không có phone ⇒ ẩn nút |
| TC-NAV-02-A2 | I | 2 | đối tác thay đổi affiliate URL | | URL lấy từ `place`, **không** hard-code trong app (NFR-11/cắm-rút) |
| TC-NAV-02-A3 | X | 2 | `delivery_url` chứa script/`javascript:` | | server reject khi ghi (validation), app từ chối mở scheme lạ |
| TC-NAV-03-A1 | I | 1 | 20 `place_ids`, mode bike | `GET /v1/routes/estimate` | mỗi item có `duration_min` ≥ 1; cache hit khi gọi lại trong TTL (`meta.cache_age_s > 0`); origin/destination **không** log chi tiết quá geohash6 |
| TC-NAV-03-A2 | X | 1 | provider Distance Matrix chết | | vẫn trả `duration_min` ước tính từ distance (`meta.provider:"estimated"`) — UI không được trống (NFR-06) |
| TC-NAV-03-A3 | P | 2 | 20 id × 200 req/phút | | p95 ≤ 800 ms; **số call provider thật ≤ số ô cache miss** (chứng minh tiết kiệm — NFR-15) |
| TC-NAV-03-A4 | E | 2 | app list | | `walk_minutes` hiện trên card khi `travel_mode=walk`; không hiện `null phút` |
| TC-NAV-04-A1 | E | B | tới quán, mở chi tiết | chạm **"Tôi đã đến"** | `POST /v1/journal/visits {status:"arrived", source:"nav_open"}` → `201`; **ask_review=true** → hiện mời đánh giá (FR-NAV-04) |
| TC-NAV-04-A2 | I | 1 | bấm "Tôi đã đến" ở quán cách 40 km | | server vẫn ghi (`manual`), nhưng **không** `checkin_verified=true` cho review (chống FR-COM-03). Test: `POST /v1/reviews` sau visit đó ⇒ `status:"pending"` |
| TC-NAV-04-A3 | I | 1 | dismiss lời mời đánh giá 3 lần | | ≤ 1 lời mời/quán/tháng, ≤ 2/tuần/user (assert bằng 2 tuần dữ liệu giả lập) — chỉ số anti-noise cho NFR-09 |
| TC-NAV-04-A4 | E | 2 | offline | chạm "Tôi đã đến" | ghi local + queue sync (`sync_state:"pending"`), badge hiện; sau khi online → `201` và id từ local được map |

### 4.6 FR-GRP · Quyết định nhóm (P2)

| ID | Loại | P | Tiền điều kiện | Bước + Input | Kết quả mong đợi |
| --- | --- | --- | --- | --- | --- |
| TC-GRP-01-A1 | I | B | `POST /v1/rooms {radius_m:2000}` | | `201` có `code` 6 ký tự (không thuộc bảng gây nhầm `0O1IL`), `join_url` **không** chứa code, `expires_at − created_at == 2h` (FR-GRP-07/01) |
| TC-GRP-01-A2 | E | B | 3 thành viên **không** có tài khoản | join bằng code | cả 3 vào được, `role:"member"`, không màn đăng nhập nào (FR-GRP-01 "khách tham gia không cần tài khoản") |
| TC-GRP-01-A3 | X | B | join `code` random 10.000 lần | | 100 % `404 ROOM_NOT_FOUND`, `429` chặn brute force, server **không** phân biệt "sai code" vs "không tồn tại" |
| TC-GRP-01-A4 | I | 1 | host không gửi position, `anchor:"host"` | | room vẫn tạo; server dùng geohash5 coarse, `member.location_shared=false`; **không** có toạ độ chính xác trong DB nếu chưa consent |
| TC-GRP-01-A5 | I | 1 | `guest_label` trùng trong phòng | | `409 LABEL_TAKEN`; label chứa control chars/HTML → sanitize, không XSS trong UI người khác (test render) |
| TC-GRP-01-A6 | I | 2 | 13 thành viên | | thứ 13 → `409 ROOM_FULL` (cap 12) |
| TC-GRP-02-A1 | E | B | 5 member, 5 candidates | mỗi người vote 2 ứng viên | `tally.votes_cast` tăng realtime; `vote.updated` tới **4** client khác; app hiện thanh tiến trình; chế độ bình chọn nhiều lựa chọn đúng "điểm = số phiếu thuận" (SRS 6.3) |
| TC-GRP-02-A2 | I | B | 1 người vote 2 lần cùng round | | phiếu sau **ghi đè** (không cộng dồn); `tally` không double count; unique `(room, member, candidate, round)` chặn |
| TC-GRP-02-A3 | I | B | mỗi người thử 2 veto trong 1 round | | veto #2 → `409 VETO_LIMIT_REACHED` (SRS 6.3 "tối đa một veto mỗi người mỗi vòng") |
| TC-GRP-02-A4 | I | 1 | 1 người bỏ phiếu **sau** người khác veto ứng viên đó | | `409 CANDIDATE_VETOED` (không cho vote ứng viên đã chết); `candidates` cập nhật `status:"vetoed"` |
| TC-GRP-02-A5 | I | 1 | người cuối cùng còn lại, mọi người veto | | `422 CANNOT_VETO_LAST_CANDIDATE` — phòng không được tự chết (edge case hay quên nhất) |
| TC-GRP-02-A6 | I | 2 | `veto_enabled=false` | veto | `403 VETO_DISABLED` |
| TC-GRP-02-A7 | E | 1 | "quay chung" | `spin.request` qua WSS | `spin.result` tới **tất cả** member **cùng một** món + cùng `seed_b64` (assert 5 client nhận giá trị giống hệt — đây là bug "mỗi máy ra một món" kinh điển) |
| TC-GRP-03-A1 | I | B | 4 member, constraint: A `peanut`, B `seafood`, C `budget:50000`, D `vegetarian` | `POST /v1/rooms/{id}/candidates` | `room_constraints_aggregate.hard_diet_union = [peanut, seafood, vegetarian]` (union) và `budget_min_vnd = 50000` (**min**, không max) — FR-GRP-03 "các ràng buộc cứng được tôn trọng" |
| TC-GRP-03-A2 | X | B | nghe traffic WSS của member C | | **không** frame nào có `{member_id: constraint}`; `constraints_summary` chỉ aggregate. Nếu lộ tên ai ăn chay ⇒ fail release (đây là yêu cầu cốt lõi "không ai bị bỏ quên") |
| TC-GRP-03-A3 | I | 1 | 1 candidate vi phạm constraint của một thành viên | | `rejected_by_hard_constraints[]` có `{reason:"diet:peanut", count:4}` **không kèm** member_id |
| TC-GRP-03-A4 | I | 1 | thành viên đổi constraint sau khi có candidates | | `409 CONSTRAINTS_CHANGED_REGENERATE`; ứng viên đang hợp lệ bị loại; không có trạng thái "vote cho ứng viên đã cấm" |
| TC-GRP-03-A5 | E | 2 | UI | nhập constraint | hiện "Chỉ nhóm thấy tổng hợp, không thấy bạn chọn gì"; người khuyết màn hình vẫn không đoán được qua `members[].constraints_provided` (chỉ bool) |
| TC-GRP-03-A6 | I | 2 | 2 member trùng hết constraint | | aggregate không duplicate; `members_counted` đúng |
| TC-GRP-04-A1 | I | 1 | 3 member `share_location=true`, 2 `false` | `candidates {anchor:"midpoint"}` | `anchor.members_used == 3` (`max_spread_m` có); app hiện "3/5 người chia sẻ vị trí"; 2 người không chia sẻ **không** có dòng nào trong geo payload |
| TC-GRP-04-A2 | X | B | `share_location=false` mà client tự gửi `geo` | | server **bỏ qua** geo + `403 CONSENT_REQUIRED`; DB `room_member.location_enc` NULL (FR-GRP-04 "vị trí chia sẻ tự nguyện") |
| TC-GRP-04-A3 | U | 1 | 3 điểm: (10.78,106.70), (10.79,106.71), (10.80,106.69) | | centroid tính trên **geography** (PostGIS `ST_Collect + ST_Centroid(geography)`), sai số ≤ 5 m so với `ST_MakePoint` trung bình số học; không dùng centroid Euclidean trên 4326 |
| TC-GRP-04-A4 | I | 2 | các member cách nhau 20 km | | candidates rỗng trong `radius_m`; `steps_available` đề nghị nới; `meta.anchor_spread_m` báo cho UI biết nhóm quá xa nhau |
| TC-GRP-04-A5 | E | 2 | tắt midpoint trong config | | app ẩn toggle, không gửi `anchor:midpoint` (feature gate) |
| TC-GRP-05-A1 | I | B | A=3 phiếu, B=2 | `finalize` | `decision.method="majority"`, `winner=A`, `proof.algorithm` set |
| TC-GRP-05-A2 | I | B | A=2, B=2 (hòa) | finalize | `method="tie_weighted_spin"`, `decision.tied_candidate_ids=[A,B]`, `weights_used` đúng số phiếu; `proof.sha256_result == H(seed ‖ candidate_ids_sorted ‖ winner_id ‖ round)` verify bằng tool độc lập (Python `hashlib`) |
| TC-GRP-05-A3 | I | B | chạy lại `TallyResolver` với **cùng** `seed` + cùng input trong unit test | | **cùng** winner (deterministic by seed) — chứng minh "bằng chứng kiểm chứng" có nghĩa |
| TC-GRP-05-A4 | X | B | 1 member (không token admin) gọi `GET /v1/rooms/{id}/proof` | | `200` — proof **phải public với mọi thành viên** và verify được độc lập; nếu bắt token ⇒ fail FR-GRP-05 |
| TC-GRP-05-A5 | I | 1 | 0 người vote, `force=false` | finalize | `409 QUORUM_NOT_MET`; `force=true + force_reason` ⇒ `200`, `method="no_votes_top_score"` + UI phải nói "hệ thống chọn, nhóm chưa bỏ phiếu" (không được giả vờ là quyết định nhóm) |
| TC-GRP-05-A6 | I | 1 | 2 client cùng gửi finalize `expected_version=8` | | đúng **1** `200`, client kia `409 ROOM_VERSION_STALE`; không tạo 2 winner khác nhau; `spin`/proof chỉ 1 bản |
| TC-GRP-06-A1 | P | B | 5 phòng × 12 client, mỗi client 1 vote/giây trong 60 s | | p95 thời gian từ `vote.cast` → `vote.updated` tới client thứ 12 **< 2000 ms** (FR-GRP-06); 0 event mất (`seq` liên tục) |
| TC-GRP-06-A2 | E | B | member mất mạng 90 s | bỏ phiếu, mất kết nối, online lại | reconnect với `last_seq` → replay thiếu đúng 1 event; **phiếu cũ vẫn còn**, không vote 2 lần (FR-GRP-06) |
| TC-GRP-06-A3 | E | 1 | member vào lại bằng thiết bị khác, cùng `device_id` logic | | `already_present:true`, `member_id` cũ, phiếu giữ nguyên |
| TC-GRP-06-A4 | X | 1 | client gửi `last_seq` quá xa (săn stream) | | trả `room.snapshot` (resync), không 500; stream `MAXLEN ~500` |
| TC-GRP-06-A5 | E | 1 | 2 client gửi event cùng ms | | `seq` vẫn đơn điệu và không trùng (Redis INCR), thứ tự nghiệp vụ ổn định |
| TC-GRP-06-A6 | X | B | `POST /v1/rooms/{id}/ws-ticket`, dùng lại ticket | | lần 2 `401 TICKET_INVALID` (TTL 30 s, one-time); ticket không có trong access log (test grep log) |
| TC-GRP-06-A7 | I | 1 | member gửi `vote.cast` với `member_id` của người khác | | `403 MEMBER_MISMATCH` (server verify token ↔ member — IDOR) |
| TC-GRP-06-A8 | X | 1 | client gửi message > 64 KB / `type` lạ | | `error:BAD_FRAME`, kết nối vẫn sống (fuzz bằng k6 WSS 50 loại payload) |
| TC-GRP-07-A1 | I | B | fake clock +2h sau tạo phòng | | `phase="expired"`; `GET /v1/rooms/{id}` → `410 ROOM_EXPIRED`; app tự thoát (FR-GRP-07) |
| TC-GRP-07-A2 | X | B | phòng có 5 member `location_enc` | `POST /v1/rooms/{id}/close` hoặc expiry | **SQL assert**: `room_member.location_enc IS NULL` cho 100 % member ngay sau close; `constraints` raw bị xoá; `room_candidate` chi tiết bị xoá/anon; `room.proof` **còn** (phải giữ để kiểm chứng) — FR-GRP-07 "dữ liệu vị trí trong phòng xóa ngay khi đóng phòng" |
| TC-GRP-07-A3 | I | 1 | `room.expiring` ở T−5 phút | | app hiện nhắc + nút "gia hạn 1 giờ" (assert message `type` có gửi), `expires_at` update, `phase` giữ |
| TC-GRP-07-A4 | I | 1 | host rời phòng | | `room.host_changed` → member có `joined_at` nhỏ nhất làm host (UC-02 ngoại lệ); phòng không mồ côi |
| TC-GRP-07-A5 | X | 2 | 5.000 phòng hết hạn cùng lúc | | sweeper không bão hoà DB (batch 100/batch, có jitter); p95 `POST /v1/spins` không đổi trong lúc sweep |

### 4.7 FR-JRN · Nhật ký ăn uống (P2)

| ID | Loại | P | Tiền điều kiện | Bước + Input | Kết quả mong đợi |
| --- | --- | --- | --- | --- | --- |
| TC-JRN-01-A1 | I | B | 100 spin + 40 visit giả lập | `GET /v1/journal/visits?from&to` | đủ 3 loại dữ liệu FR-JRN-01: lịch sử quay (`spin`), quán đã chọn (`status:"chosen"`), quán đã đến (`"arrived"`); sắp giảm dần theo `occurred_at` |
| TC-JRN-01-A2 | I | 1 | visit `occurred_at` = `now + 2 ngày` | `POST /v1/journal/visits` | `400 FUTURE_DATE`; visit = `now − 8 ngày` cũng `400` (ngoài cửa sổ 7 ngày, chống spam clock sai) |
| TC-JRN-01-A3 | E | 1 | xem lịch sử 3 tháng | | cuộn tới đâu load tới đó (cursor), không "pull all" (assert số request ≤ trang hiển thị) |
| TC-JRN-01-A4 | I | 2 | xóa tài khoản | | visits = 0 (xác nhận chéo TC-AUTH-05-A2) |
| TC-JRN-01-A5 | I | 2 | query `q="quán công ty"` trên note | | dùng `pg_trgm`, tìm kiếm không dấu vẫn ra kết quả ("quan cong ty" không dấu → có gợi ý); không dùng `LIKE %..%` toàn bảng (assert `EXPLAIN` dùng index) |
| TC-JRN-02-A1 | I | B | favorite cùng quán 2 lần | `POST /v1/journal/favorites {place_id}` ×2 | `200` bản cũ, **1** dòng DB (không duplicate) |
| TC-JRN-02-A2 | I | 1 | `POST /v1/lists {name:"Quán công ty"}` + 8 item | `GET /v1/lists` | `item_count=8`; `is_default_favorites` **không** bị xoá bằng `DELETE` list custom |
| TC-JRN-02-A3 | I | 1 | `POST /v1/lists/{id}/reorder` với thứ tự mới | `GET` lại | `position` khớp **chính xác** thứ tự gửi; gửi thiếu 1 id → `400` (bắt buộc đủ tập) |
| TC-JRN-02-A4 | E | 2 | app | thêm/xóa favorite ở list rồi quay lại | state đúng, không "nhớ nhầm" giữa list custom và favorites chung |
| TC-JRN-02-A5 | I | 2 | xóa list có item là favorite chung | | favorite **không** biến mất (chỉ gỡ quan hệ list_item) |
| TC-JRN-03-A1 | I | 1 | `PATCH /v1/journal/visits/{id} {note:"Nước ngọt, hơi mặn", spend_vnd:45000, private_rating:4}` | | đọc lại đủ 3 field; `private_rating` **không** cộng vào `place.rating_raw`/`review_count` (assert số liệu quán không đổi) — đây là rule riêng tư quan trọng |
| TC-JRN-03-A2 | X | 1 | `note` = 5.000 ký tự / chứa `<script>` / chứa SQL | | `400` cho quá 500; sanitize stored; render escape (XSS test trên admin và app) |
| TC-JRN-03-A3 | I | 1 | upload 6 ảnh | | `201`/`400` theo cap 6; ảnh EXIF GPS bị **strip** trước khi CDN (assert `exif_read` không còn `GPSInfo`) — SRS 11 |
| TC-JRN-03-A4 | I | 2 | ảnh > 8 MB / mime giả (`image/jpeg` nhưng là `.exe`) | | upload policy reject khi verify `client_sha256` + magic bytes |
| TC-JRN-03-A5 | U | 2 | `spend_vnd = 45999` | | export/summary làm tròn theo đơn vị 1.000 VND có quy tắc rõ (khai báo trong test, không mặc định float) |
| TC-JRN-03-A6 | E | 2 | nhập chi tiêu cho bữa ở máy khác | | tổng tuần cập nhật ≤ 60 s (budget FR-PER-02 đọc từ cùng nguồn, không hai chỗ tính) |
| TC-JRN-04-A1 | I | 1 | 9 visit giả lập trong tuần, tổng 385.000 VND | `GET /v1/journal/summary?period=week` | `meals_count=9`, `total_spend_vnd=385000`, `avg_spend_vnd=42778` (làm tròn theo quy tắc integer, không float), `places_count=7`, `new_places=2` — **đối chiếu bằng SQL đếm tay** |
| TC-JRN-04-A2 | I | 1 | cùng dữ liệu, `date` rơi vào tuần chứa 2 tháng | | `period.start/end` đúng theo `week_start_dow` + `tz` gửi lên; không tính nhầm sang tuần kế (bug ISO week hay gặp) |
| TC-JRN-04-A3 | U | 2 | 5 bữa cùng category, 4 category khác | | `distinct_categories=5`, `hhi_index` khớp công thức khai báo (assert 2 thập phân), `label_key` chọn đúng ngưỡng ("varied" vs "repetitive") |
| TC-JRN-04-A4 | E | 2 | user tắt `personalization_opt_in` | `GET /v1/journal/summary` | **vẫn trả** (tự tính từ dữ liệu của chính họ, không cần opt-in) nhưng `insights` không dùng hành vi suy rộng; `budget_over_pct` đúng vì đọc từ `spend_vnd`; UI không hiện "so với người khác" |
| TC-JRN-05-A1 | I | B | device A tạo 3 visits offline, device B tạo 2 | mỗi device `POST /v1/journal/sync` | sau sync, cả 2 device `GET` ra **đúng 5** visit, không trùng, không mất (FR-JRN-05) |
| TC-JRN-05-A2 | I | B | cùng `vst_1`, device A sửa `note="A"`, device B sửa `note="B"`, cả 2 push | | 1 bên `accepted`, 1 bên `rejected[VERSION_CONFLICT]` với `server_entity` + `client_entity` + `resolution_options`; **không** im lặng ghi đè mất dữ liệu; auto_resolution = LWW theo **server received_at** khi clock skew > 5 phút |
| TC-JRN-05-A3 | I | B | device A `device_updated_at` = 2020 (clock sai), nội dung mới hơn | | `clock_warning:true`, `device_clock_skew_s` ≈ −6 năm, server dùng received_at; client **không** bị bắt user chọn (UI không hiện conflict vì server tự xử) — test này bắt bug "đồng hồ điện thoại sai làm mất dữ liệu" |
| TC-JRN-05-A4 | I | 1 | device A **xoá** visit, device B **sửa** cùng visit | | conflict `deleted_then_edited`, `resolution_options` có `keep_both`; default **không** xoá silently |
| TC-JRN-05-A5 | I | 1 | same `local_id` push 2 lần (retry sau timeout) | | idempotent — 1 visit, `rejected` rỗng; không cần `X-Idempotency-Key` riêng cho sync |
| TC-JRN-05-A6 | I | 1 | favorite thêm trên A, xóa trên B | | set-union cho add + tombstone LWW cho remove; sau 30 ngày tombstone bị compaction, trạng thái cuối ổn định và **giống nhau trên 2 máy** (assert equality) |
| TC-JRN-05-A7 | P | 1 | push 500 ops | | `200` trong ≤ 2 s; 501 ops → `413 PAYLOAD_TOO_LARGE`; client tự chia trang (app test) |
| TC-JRN-05-A8 | E | B | 2 thiết bị thật, cùng tài khoản, bật tắt máy bay luân phiên 30 phút dùng | | không mất bản ghi nào; không có "bữa ăn ma" (visit duplicate); `sync_state` về `synced` sau khi online |
| TC-JRN-05-A9 | X | 2 | device A sync `device_id` của device B (user khác) | | `403 DEVICE_MISMATCH`; không đọc/ghi dữ liệu user khác |
| TC-JRN-06-A1 | I | 1 | `GET /v1/journal/export?format=csv` | | zip có file CSV; UTF-8 **BOM**; `\r\n`; mở bằng Excel VN hiển thị dấu tiếng Việt đúng (test bằng Excel thật, không chỉ `cat`) |
| TC-JRN-06-A2 | I | 1 | `format=json` | | JSON hợp lệ, đủ cột khai báo ở `03` §2.7; signed URL hết hạn 15 phút (sau đó `403`) |
| TC-JRN-06-A3 | X | 1 | export của user khác qua `export_id` đoán được | | `404`/`403`; `export_id` ULID không tuần tự |
| TC-JRN-06-A4 | I | 2 | export khi có 10.000 visit | | async `202`, không timeout HTTP; progress qua poll; giới hạn 3 export/giờ (chốngDoS) |

### 4.8 FR-COM · Cộng đồng (P2 đề xuất / P3 đánh giá)

| ID | Loại | P | Tiền điều kiện | Bước + Input | Kết quả mong đợi |
| --- | --- | --- | --- | --- | --- |
| TC-COM-01-A1 | I | B | user `full` đề xuất quán mới hợp lệ | `POST /v1/places` | `201 status="pending_review"`; **assert quán KHÔNG xuất hiện** trong `GET /v1/places/nearby` của bất kỳ ai (kể cả chính user) tới khi admin accept — đây là test visibility, không phải test 201 |
| TC-COM-01-A2 | X | B | guest đề xuất | | `403 REQUIRES_ACCOUNT`; user bị ban → `403` |
| TC-COM-01-A3 | I | 1 | `geo` cách vị trí user 400 km, không có `observation_geo` | | `422 GEO_DISTANCE_SUSPECT` (chống quán ảo — FR-COM-01 qua kiểm duyệt) |
| TC-COM-01-A4 | I | 1 | quán trùng tên + cách 30 m quán đã có | | `201` nhưng `duplicate_suspect:true`, `similarity_pct:94`, admin queue highlight |
| TC-COM-01-A5 | E | 2 | đề xuất 6 ảnh | | EXIF bị strip (assert không còn GPSInfo), 1 ảnh/portrait được chọn làm chủ |
| TC-COM-01-A6 | I | 2 | `PATCH /v1/places/{id}` sửa `geo` lệch 300 m | | `202` pending, `diff.geo` có `from/to`; không tự apply; admin accept mới đổi |
| TC-COM-02-A1 | E | B | 3 chạm: `verdict:"good"` → tag `["cheap","friendly"]` → gửi | `POST /v1/reviews` | `201`; **không** màn nào bắt nhập text (text optional) ⇒ đúng định nghĩa "đánh giá nhanh 3 chạm" (FR-COM-02). Đếm chạm bằng instrumentation ≤ 3 |
| TC-COM-02-A2 | I | 1 | review kèm `visit_id` của check-in 2 ngày trước | | `checkin_verified=true`, `is_effective=true`, xuất hiện **trên** review không check-in khi `sort=relevant` |
| TC-COM-02-A3 | I | 1 | review không visit, `verdict:"bad"` | | `status:"pending"` (lớp 3 chống review ảo), `is_effective=false` |
| TC-COM-02-A4 | I | 1 | rating suy từ verdict | | `good→5`, `ok→3`, `bad→1`; nếu gửi `rating` tường minh thì tôn trọng |
| TC-COM-02-A5 | E | 2 | `place_rating_after` | | UI cập nhật ngay sau khi gửi (không chờ reload) |
| TC-COM-03-A1 | I | B | user đã có review `is_effective` cho quán, gửi lần 2 | | lần 2 `superseded_review_id` trỏ bản cũ; bản cũ `is_effective=false`; `place.review_count` **không đổi** (1 người 1 đánh giá hiệu lực — FR-COM-03) |
| TC-COM-03-A2 | I | B | `rating_raw` sau 2 lần review của cùng 1 user | | tính lại = trung bình các review `is_effective` **duy nhất theo user**; assert bằng SQL |
| TC-COM-03-A3 | I | 1 | 6 review/ngày | | lần 6 `429 REVIEW_RATE_LIMIT` |
| TC-COM-03-A4 | X | B | 3 review `bad` cho cùng quán từ 3 device mới, cùng IP range, trong 10 phút | | tự `flagged`, `place.review_suspicion ≥ 0.7`, penalty trong `score_breakdown.penalty.items` có `suspect_fake`; review không vào `rating_raw` |
| TC-COM-03-A5 | X | 1 | guest tier mới, 2 review/ngày | | cap 1/ngày ⇒ `429` |
| TC-COM-03-A6 | I | 1 | `DELETE /v1/reviews/{id}` | | `is_effective=false`, `place.review_count` giảm, `rating_raw` recomputed; bản ghi **không** hard delete (audit còn) |
| TC-COM-03-A7 | I | 2 | `PUT /v1/reviews/{id}` sửa | | `edited_at` set, UI gắn nhãn "Đã sửa", `version` tăng; sửa sau 30 ngày → vẫn được nhưng bị re-flag |
| TC-COM-04-A1 | I | 1 | báo cáo review spam | `POST /v1/reports {target_type:"review", kind:"spam"}` | `201`, `moderation_sla_hours:72`; item vào `GET /v1/admin/moderation/queue` |
| TC-COM-04-A2 | E | 1 | sau khi reject | | `GET /v1/reports/mine` hiện `decision` + `appeal_open:true` + `appeal_deadline` (quy trình kháng nghị FR-COM-04) |
| TC-COM-04-A3 | X | 1 | user báo 20 lần/ngày cùng target | | `429` + strike (chống weaponize report để kéo rank đối thủ) |
| TC-COM-04-A4 | I | 1 | admin accept report review | | review `hidden`, `place` không đổi; user bị `strike` + `note_to_user` gửi đi |
| TC-COM-04-A5 | E | 2 | app | review vi phạm còn hiển thị | phải ẩn/che trong ≤ 5 phút sau khi hidden (SLA kiểm duyệt) |
| TC-COM-05-A1 | I | 1 | `profile_visibility:"public"` | `GET /v1/users/{id}/profile` | trả `display_name`, `top_dishes`, `lists_shared[]` **không** trả `visit` chi tiết, `spend_vnd`, `diet`, `locations` (opt-in + thu thập tối thiểu) |
| TC-COM-05-A2 | X | B | `profile_visibility:"private"` | `GET /v1/users/{id}/profile` | `403 PROFILE_PRIVATE`; không suy ra được "tồn tại nhưng private" qua timing (constant-time check) |
| TC-COM-05-A3 | I | 2 | follow/unfollow 2 chiều | | `mutual:true`; unfollow tức thì; không spam push |

### 4.9 FR-PER · Cá nhân hoá và tiện ích

| ID | Loại | P | Tiền điều kiện | Bước + Input | Kết quả mong đợi |
| --- | --- | --- | --- | --- | --- |
| TC-PER-01-A1 | E | B | `theme:"dark"`, `font_scale:1.5` | đổi trong app | áp dụng **ngay không restart**, không vỡ layout ở 1.5 (kiểm tra 8 màn khó nhất: card quán, vì sao, vòng quay, phòng nhóm, onboarding); giá trị persist qua kill app |
| TC-PER-01-A2 | I | 1 | `PUT /v1/me/settings {font_scale:2.0}` | | `400` (khoảng cho phép 0,85–1,5); server clamp + báo rõ |
| TC-PER-01-A3 | E | 1 | hệ thống EN, app default VI | `X-Locale: en` | món `name_en`, quán `name_en`, toàn bộ chuỗi UI Anh, **tên quán tiếng Việt giữ nguyên** (không dịch tên riêng) |
| TC-PER-01-A4 | I | 2 | `locale:"ja"` | | `400 UNSUPPORTED_LOCALE` — chỉ vi/en ở P1 |
| TC-PER-01-A5 | X | 1 | system font scale lớn + trình đọc màn hình | | mọi focusable có semantic label; thứ tự đọc đúng (assert bằng `Semantics` widget test, không chỉ manual) |
| TC-PER-01-A6 | E | 2 | đổi ngôn ngữ giữa chừng khi đang quay | | kết quả quay không mất, không quay lại món khác (assert `spin_id` giữ) |
| TC-PER-01-A7 | I | 2 | `theme:"system"`, điện thoại auto dark 21:00 | | app theo system, không ghi đè |
| TC-PER-02-A1 | I | B | `weekly_vnd:350000`, chi 285.000 (81 %), `alert_threshold_pct:80` | `GET /v1/me/budget/status` | `alert_active:true`, `alert_message_key:"budget.near_limit"`, `remaining_vnd:65000`, tuần tính theo `week_start_dow` |
| TC-PER-02-A2 | I | 1 | `prioritize_cheap:true` + alert đang bật | `POST /v1/matches` | `P` weight tăng (assert `weights` response), quán `plc_expensive` (300 k) tụt xuống sau `plc_small_hi`; **không** loại hẳn quán đắt (user vẫn có quyền chọn) |
| TC-PER-02-A3 | E | 1 | chạm 300 k cho bữa | | app hiện cảnh báo chi tiêu; `spent_vnd` cập nhật ≤ 60 s; không gửi push spam (≤ 1 push/tuần cho budget) |
| TC-PER-02-A4 | I | 1 | sang tuần mới (fake clock +7 ngày) | | `spent_vnd` reset 0, `week_window` đổi; lịch sử tuần cũ vẫn đọc được (không xoá) |
| TC-PER-02-A5 | X | 1 | `weekly_vnd = -5` / `alert_threshold_pct = 150` | | `400` range; server không tự "đẹp hoá" input |
| TC-PER-02-A6 | I | 2 | `PUT /v1/me/budget {weekly_vnd:null}` | | tắt tính năng, `alert_active:false`, `prioritize_cheap` reset false |
| TC-PER-03-A1 | I | B | user chưa bật nhắc | | **0** push nào được gửi (mặc định tắt theo SRS FR-PER-03) — test bằng cách spin 1 tuần giả lập và đếm message trong mock FCM |
| TC-PER-03-A2 | I | 1 | `PUT /v1/me/reminders {enabled:true, slots:[{time:"11:15", days:[1..5]}]}` | fake clock 03:15Z | push gửi đúng ngày thường, không gửi T7/CN; không gửi 2 lần cùng slot (dedup theo `slot_date`) |
| TC-PER-03-A3 | I | 1 | slot lúc 23:55, tz VN, server UTC | | gửi đúng 23:55 **giờ VN** (không thành 00:55 hôm sau); 5 slot chồng ngày lễ → tôn trọng `days` |
| TC-PER-03-A4 | I | 1 | `device.token_valid=false` (token FCM bị từ chối) | | server đánh dấu không gửi lại, không retry vô hạn (chống đốt quota); push fail không làm fail job khác (queue isolation) |
| TC-PER-03-A5 | E | 2 | user tap push | | deep link `angi://spin?mode=urgent` mở thẳng Đói gấp; không mở màn hình splash 3 lần |
| TC-PER-04-A1 | E | 2 | iOS widget / Android Glance | chạm "Quay nhanh" | `GET /v1/widget/quick-spin?token=` trả kết quả, tap → app mở đúng màn kết quả của `spin_id` đó (không quay lại lần nữa trong app — bug "2 món khác nhau" hay gặp) |
| TC-PER-04-A2 | X | 2 | widget token hết hạn | | widget hiện "Mở app để quay", không crash, không gọi API vô hạn (backoff) |
| TC-PER-04-A3 | I | 2 | widget khi diet `peanut` bật | | diet hard **vẫn** áp dụng ở widget (assert output) |
| TC-PER-04-A4 | E | 3 | App Group data bị xoá (user gỡ app chính) | | widget fail gracefully |

### 4.10 FR-ADM · Quản trị (P1) và FR-MER · Chủ quán (P3)

| ID | Loại | P | Tiền điều kiện | Bước + Input | Kết quả mong đợi |
| --- | --- | --- | --- | --- | --- |
| TC-ADM-01-A1 | I | B | admin thêm món mới valid | `POST /v1/admin/dishes` + `POST /v1/admin/bundle/publish` | món mới **có thể** được quay trong ≤ 5 phút; `bundle_version` tăng; app offline nhận delta (assert TC-ROU-10-A3 chain) |
| TC-ADM-01-A2 | I | B | admin `POST /v1/admin/dishes/{id}/deactivate {reason}` | | 5000 spin tiếp theo **0** lần ra món đó; `spin` **cũ** vẫn resolve được tên món (snapshot) — lịch sử không vỡ |
| TC-ADM-01-A3 | I | 1 | `category_id` trỏ node **có con** (không phải lá) | | `400 CATEGORY_NOT_LEAF` |
| TC-ADM-01-A4 | I | 1 | tag mới `kind:"allergen"`, `is_hard_filter:true` | | tag xuất hiện trong `PUT /v1/me/diet` hợp lệ và trong lọc cứng của spin (assert sau 1 lần publish) |
| TC-ADM-01-A5 | X | B | user thường (role none) gọi `POST /v1/admin/dishes` | | `403 FORBIDDEN`; **mọi** endpoint `/v1/admin/*` trả 403 cho non-admin (matrix test 52 endpoint × 3 role, không test mẫu) |
| TC-ADM-01-A6 | I | 1 | mọi thao tác sửa/xóa món | | `audit_log` có `actor, before, after, reason`; không có ghi nào không dấu vết |
| TC-ADM-01-A7 | E | 2 | admin web | sửa taxonomy ảnh hưởng 200 món | UI báo số món bị ảnh hưởng **trước** khi lưu (chống sập kho món vì 1 click) |
| TC-ADM-02-A1 | I | B | dữ liệu 7 ngày giả lập | `GET /v1/admin/metrics/overview` | `spin_to_nav_rate` khớp **tính tay** trên cùng tập dữ liệu (SQL đối chiếu) — chỉ số chính SRS 12.2 phải đúng, sai số = quyết định sai |
| TC-ADM-02-A2 | I | 1 | 3 user/device cố định | `POST /v1/admin/experiments/{key}/assign-preview` | cùng `user_id` luôn ra **cùng** arm (HMAC stable), `n_per_arm` cân bằng ±5 % trên 10.000 user |
| TC-ADM-02-A3 | X | B | admin không có quyền `metrics` | | `403`; RBAC theo permission, không theo "hidden button" ở web |
| TC-ADM-02-A4 | I | 1 | `PATCH /v1/admin/flags {key:"weather_context", rollout_pct:50}` | | 30 s sau, ~50 % request trả `flags.weather_context="on"` (bucket theo user, stable, không đổi giữa 2 request liên tiếp của cùng user) |
| TC-ADM-02-A5 | E | 2 | web | xem funnel | `open_app → spin_shown → place_shown → nav_opened → arrived` tổng % khớp 100 session giả lập đếm tay |
| TC-ADM-03-A1 | X | B | WireMock: Google `429`, OSM `200` | `GET /v1/admin/providers/status` | `google.health="degraded"`, `error_pct` > 0, `fallback_chain` hiển thị; **và** `GET /v1/places/nearby` vẫn 200 (assert cross-check, không chỉ nhìn dashboard) |
| TC-ADM-03-A2 | I | 1 | `PATCH /v1/admin/providers/google {enabled:false}` | | **nóng**, không restart; request kế tiếp `meta.providers_used` không còn `google` |
| TC-ADM-03-A3 | P | B | cache L1 đầy | 1.000 request cùng geohash6 | `cache_hit_pct ≥ 90 %`, số call provider ≤ 100 (FR-ADM-03/NFR-15 cache theo ô địa lý) |
| TC-ADM-03-A4 | I | 1 | `budget.monthly_cap_vnd = 30.000.000`, spent 21.000.000 (70 %) | | `alert_active:true`, cảnh báo gửi 1 lần/ngày (không spam) |
| TC-ADM-03-A5 | X | 1 | `PATCH /v1/admin/providers/google {enabled:true}` khi hết hạn mức thật | | không burst 100 % traffic ngay (ramp-up / half-open circuit), assert số call trong 60 s sau đóng circuit ≤ threshold |
| TC-ADM-03-A6 | I | 2 | TTL cache của provider bị siết từ 24 h → 6 h qua ToS | | cấu hình ToS ở config, không hard-code; cache cũ hơn 6 h bị purge (TC-PLC-08-A4) |
| TC-ADM-04-A1 | E | B | 5 report pending | web: accept 1, reject 1, needs_more_info 1 | accept ⇒ field quán đổi + `publish_now:true`; reject ⇒ reporter bị strike; mọi decision có `note` và audit |
| TC-ADM-04-A2 | I | B | accept report `wrong_hours` sửa `closes_at` 13:30 → 11:30 | | `open_status` đổi **ngay** (cache invalidated); quán không còn trong `open_now=true` sau 11:30 — đóng loop FR-PLC-07 → FR-PLC-06 |
| TC-ADM-04-A3 | I | 1 | `POST /v1/admin/users/{id}/ban {duration_days:7}` | | user đó mọi request → `403 ACCOUNT_BANNED` kèm `until`; guest vẫn dùng được nếu chưa ban device |
| TC-ADM-04-A4 | X | 1 | admin tự ban chính mình | | `400 CANNOT_BAN_SELF` (tự khoá mình là tai vận hành) |
| TC-ADM-04-A5 | I | 2 | 3 strike | | auto soft-ban + notification; 4 strike → permanent |
| TC-ADM-04-A6 | E | 2 | queue 500 mục | | filter `kind/city`, sắp theo `contributor_trust`, không timeout > 3 s |
| TC-MER-01-A1 | I | B | chủ quán claim | `POST /v1/merchant/claims` → verify phone + email | `status:"verified_owner"`, `role:"merchant"`, `place_ids_managed` đúng 1 quán |
| TC-MER-01-A2 | X | B | user B claim quán đã có owner | | `409 ALREADY_CLAIMED` + `appeal_url`; **không** cho 2 owner cùng sửa |
| TC-MER-01-A3 | I | 1 | merchant A sửa `hours` của quán B (`place_id` của người khác) | | `403 NOT_YOUR_PLACE` (matrix test với 20 endpoint merchant) |
| TC-MER-01-A4 | I | B | `PUT /v1/merchant/places/{id}/hours` | | đổi **ngay** không qua kiểm duyệt (FR-MER-01) + giới hạn 5 sửa/ngày; audit `source:"merchant"`; `data_confidence` → 0.95 |
| TC-MER-01-A5 | X | 2 | upload giấy tờ | | lưu mã hoá, xoá sau 90 ngày nếu reject (assert job), không lộ qua `/v1/merchant/claims/{id}` của owner khác |
| TC-MER-02-A1 | I | B | promotion `budget_vnd:2.000.000`, `ends_at:+7 ngày` | `POST /v1/merchant/promotions` | `201 affects_natural_rank:false`; assert lại `natural_rank` bằng test A/B như TC-REC-04-A1 |
| TC-MER-02-A2 | X | B | promotion hết budget | | ad **dừng ngay** (không overrun), `spend_vnd ≤ budget_vnd`; `is_sponsored` không còn |
| TC-MER-02-A3 | I | 1 | `GET /v1/merchant/promotions/{id}/report` | | `impressions/taps/nav_opens/cost_per_nav_vnd` khớp sự kiện thật được phát (seed 100 sự kiện → đếm được 100, không double count) |
| TC-MER-02-A4 | I | 1 | `targeting:{meal:["dinner"]}` | | ad chỉ xuất hiện khi `hour_bucket=dinner` (assert bằng fake clock 2 múi giờ) |
| TC-MER-02-A5 | X | 2 | label quảng cáo bị thiếu locale EN | | fallback + cảnh báo admin, **không** hiển thị ad không nhãn |

---

## 5. Test cắt ngang cho mọi API (cross-cutting — viết 1 lần, chạy cho 52+ endpoint)

Nhóm này **tham số hoá theo endpoint** (`@ParameterizedTest` với danh sách route từ OpenAPI). Đây là nhóm bắt lỗi rẻ nhất và hay bị bỏ nhất.

| ID | Áp dụng | Input | Kết quả mong đợi |
| --- | --- | --- | --- |
| TC-API-01 | mọi endpoint | không có `Authorization` (endpoint bắt buộc auth) | `401 UNAUTHENTICATED`, envelope lỗi đúng chuẩn, không `500` |
| TC-API-02 | mọi endpoint | JWT hết hạn (`exp` quá) | `401 TOKEN_EXPIRED` (client phân biệt được để refresh tự động) |
| TC-API-03 | mọi endpoint | JWT chữ ký sai / `alg:none` / `aud` sai | `401` — **không** được bỏ qua `aud` (ASVS 3.5) |
| TC-API-04 | mọi endpoint ghi | gửi 2 lần **cùng** `X-Idempotency-Key` + **khác** body | lần 2 `409 IDEMPOTENCY_CONFLICT`; cùng body ⇒ replay đúng response cũ + `X-Idempotency-Replayed:true` |
| TC-API-05 | `POST /v1/spins`, `POST /v1/matches`, `GET /v1/places/nearby` | replay idempotency | spin **không** bị chặn replay (mỗi lần quay là sự kiện mới) ⇒ chứng minh key được khai báo đúng chỗ, không phải chỗ nào cũng bật |
| TC-API-06 | mọi endpoint list | `limit=0`, `limit=51`, `limit=-1`, `cursor=<bịa>` | `400`/`422`; cursor giả ⇒ `400 INVALID_CURSOR` (HMAC verify), **không** `500` |
| TC-API-07 | mọi endpoint | field thừa không có trong schema | ignore (không fail) + log warning; field thừa **không** được ghi vào DB |
| TC-API-08 | mọi endpoint | body `null` từng field bắt buộc, chuỗi rỗng, mảng rỗng, chuỗi 10.000 ký tự, số NaN/Infinity, `{"geo":{"lat":"abc"}}` | `400 VALIDATION_FAILED` với `details[]` trỏ đúng field; 0 lần `500` (fuzz 200 payload/endpoint) |
| TC-API-09 | mọi response | kiểm schema | không field nào ngoài OpenAPI spec (không rò rỉ `location_enc`, `phone_raw`, `internal_confidence`, `seed` ở endpoint không được phép) |
| TC-API-10 | mọi response lỗi | | luôn có `request_id`, `code`, `retryable`, `message_key` (không chuỗi dịch sẵn — NFR-11) |
| TC-API-11 | mọi endpoint | `X-Locale: en` vs `vi` | khác nhau đúng ở field có `*_en`/`*_vi`; **không** khác ở số/id |
| TC-API-12 | mọi endpoint | `X-Request-Id` gửi lên | server **echo** nguyên giá trị + có trong log/trace (NFR-13) |
| TC-API-13 | `X-App-Version: 0.9.0` (< `X-Min-App-Version`) | | `426 UPGRADE_REQUIRED` + app hiện màn buộc nâng cấp (NFR-14) |
| TC-API-14 | mọi endpoint | gọi 200 lần liên tục không sleep | `429` đúng ngưỡng, `X-RateLimit-Remaining` giảm, **không** deadlock/reset kết nối |
| TC-API-15 | TLS | `curl -v --tlsv1.1` | bị từ chối; chỉ TLS 1.2/1.3 (SRS mục 7) |
| TC-API-16 | CORS (admin web) | `Origin` lạ | không trả `Access-Control-Allow-Origin:*` cho endpoint có dữ liệu user |
| TC-API-17 | mọi endpoint ghi | time-out giữa chừng (client abort) | không ghi dữ liệu half-done (transaction + outbox nguyên tử); test bằng ToxiProxy cắt connection |
| TC-API-18 | `GET` id không tồn tại ở 12 dạng | `plc_0`, `plc_%`, `plc_../../`, 300 ký tự, unicode, SQL `' OR 1=1--`, empty | `404`/`400` đồng nhất, **không** `500`, không SQL error trong log |
| TC-API-19 | JSON size | body 2 MB | `413 PAYLOAD_TOO_LARGE`; giới hạn khai báo ở gateway |
| TC-API-20 | log | grep toàn bộ log sau 100 request | **không** có: `code` OTP, refresh token, JWT đầy đủ, toạ độ chi tiết, `diet` user, nội dung `note`, số điện thoại đầy đủ (chỉ masked) |

---

## 6. Test tính đúng đắn nghiệp vụ (cái mà unit test hay "xanh" nhưng logic vẫn sai)

| ID | Assertion | Cách đo |
| --- | --- | --- |
| TC-BIZ-01 | **Spin → place không tự đổi món**: `POST /v1/spins` trả `dsh_A`, `POST /v1/matches {spin_id}` trả quán có `dish_highlights` chứa `dsh_A`, **không** âm thầm đổi sang `dsh_B` | 1000 chain spin→match, assert 100 % |
| TC-BIZ-02 | **Tổng trọng số luôn = 1** với mọi tổ hợp bias/context/flag: `Σw_Q+w_D+w_P+w_O+w_U == 1.0 ± 0.001` | property-based test (jqwik) 100.000 case random bias ∈ [−1,1], context random |
| TC-BIZ-03 | **Score ∈ [0, 100]**: không bao giờ âm dù penalty lớn | property-based; nếu `penalty > raw` ⇒ `score_total = 0.00` (clamp) và có `penalty.clamped:true` |
| TC-BIZ-04 | **Thứ tự đơn điệu**: thêm ràng buộc lọc **không** làm nhiều kết quả hơn; tăng radius **không** làm ít kết quả hơn | run 2 request, so tập id bằng assertion tập hợp |
| TC-BIZ-05 | **Kết quả là tập con của pool**: mọi `dish_id` trả về nằm trong `pool.size_after_hard_filters` đếm được bằng SQL | integration, 200 case |
| TC-BIZ-06 | **Không có "quán ma"**: mọi `place_id` trong response tồn tại `is_active=true` và không bị merge | 1000 items |
| TC-BIZ-07 | **Determinism của ranking**: cùng dataset + cùng `fake_now` + cùng bias ⇒ **cùng thứ tự** 20 lần chạy (bắt bug sort không ổn định / phụ thuộc hash map order) | test chạy 20 lần, so `sha256(items.map(id))` |
| TC-BIZ-08 | **Cache không trả dữ liệu user-cá nhân hoá cho user khác**: key cache phải chứa `user_bucket` khi `personalization=true` | 2 user, cùng geo/filters ⇒ `page.items` **khác nhau**; `personalization=false` ⇒ giống nhau |
| TC-BIZ-09 | **Idempotency của group finalize**: 2 finalize cùng version ⇒ cùng `winner` | TC-GRP-05-A6 mở rộng: assert không có `spin` thứ hai được tạo |
| TC-BIZ-10 | **Anti-repeat không được triệt tiêu bởi lock**: `locked.category_id` chứa đúng 1 món vừa ăn hôm nay ⇒ phải trả `409 POOL_TOO_SMALL`, không được "quay trúng món vừa ăn" hay crash | TC-ROU-06 × TC-ROU-04 kết hợp — cặp feature tương tác là nơi bug ở |
| TC-BIZ-11 | **Diet thắng mọi thứ**: duyệt qua 12 tổ hợp feature flag (urgent, wheel, group midpoint, sponsored, bias, context, offline, personalization off, party_size, relaxation, dismiss streak, budget) ⇒ **không tổ hợp nào** trả món vi phạm `user_diet.strict` | matrix test tự sinh tổ hợp; đây là **test danh dự** của sản phẩm (an toàn sức khoẻ) |
| TC-BIZ-12 | **Không suy đoán dữ liệu**: quán `plc_no_hours` không được "bịa" `opens_at`; response phải có `note_key` | assert field absent + confidence thấp |
| TC-BIZ-13 | **Tiền không dùng float**: `45000 + 45999` không ra `90998.99999`; mọi `*_vnd` là integer, phép tổng dùng `long` | unit + `POST /v1/journal/visits` 10.000 bản ghi rồi sum |
| TC-BIZ-14 | **Tương thích app cũ / server mới**: app 1.0 gọi API 1.4 với field mới → app không crash (field thừa bị ignore — TC-API-07) | chạy `integration_test` app 1.0 thật trên staging 1.4 |

---

## 7. Kịch bản E2E theo use case (SRS mục 5)

### 7.1 UC-01 · Quay món và đi ăn — `E`, P=B

| Bước | Hành động | Kỳ vọng + ngưỡng |
| --- | --- | --- |
| 1 | Cài app, mở lần đầu, **từ chối** quyền vị trí | không crash; không loop xin quyền; hướng dẫn nhập địa chỉ hiện ra (UC-01 ngoại lệ) |
| 2 | Nhập "25 Nguyễn Huệ, Q.1" → chọn kết quả | `POST /v1/geocode` 1 lần; `POST /v1/user-locations` lưu; vị trí hiển thị trên UI |
| 3 | Chạm **Quay** | `POST /v1/spins` **1 request**; kết quả hiện ≤ 300 ms (NFR-02); hoạt hình chạy nhưng kết quả **đã** chốt (TC-ROU-07-A1) |
| 4 | Đọc tên món | khớp `dish.name` response, khớp `animation.result_index` |
| 5 | Hệ thống tự gọi `POST /v1/matches` | ≤ 1,5 s; đúng **3** quán; mỗi quán có `score_breakdown` + `why`; tất cả `open_status.is_open=true` |
| 6 | Bấm "Vì sao" ở quán #1 | hiện ≥ 2 lý do từ `components`, không có `%` thô, ngôn ngữ theo `X-Locale` |
| 7 | Bấm **Chỉ đường** | maps app mở với `daddr` đúng toạ độ; **tổng chạm từ mở app ≤ 3** (chạm: Quay → quán → Chỉ đường) — đây là metric cốt lõi 2.6.1, phải đo bằng automation |
| 8 | Quay lại app, bấm **Tôi đã đến** | `POST /v1/journal/visits` `status:"arrived"`; `ask_review:true`; vào `GET /v1/journal/visits` thấy bản ghi |
| 9 | Mở lại app, nhìn lịch sử | bữa vừa rồi hiện đúng thứ tự thời gian, đủ tên món + quán + distance |
| **Ngoại lệ** | bước 5: 0 quán trong 1,5 km | app hiện "Nới bán kính lên 800 m/2 km?" (1 chạm), **không** màn trống (TC-REC-05-A2) |
| **Ngoại lệ** | bước 5: mất mạng | hiện quán **đã cache** gần nhất với nhãn "Ngoại tuyến" + nút thử lại; không spinner vô hạn |
| **Ngoại lệ** | bước 3: diet `peanut` + category lock chỉ có món peanut | hiện thông báo xung đột + gợi ý bỏ **một** ràng buộc; không "quay mãi không ra" (TC-ROU-03-A2) |

### 7.2 UC-02 · Quyết định nhóm — `E`, P=B (2–5 device thật, không chỉ emulator)

| Bước | Hành động | Kỳ vọng |
| --- | --- | --- |
| 1 | Chủ phòng tạo phòng, gửi link (chạm ≤ 2 để tới bước gửi) | `POST /v1/rooms` `201`; link + code `K7P3QM` |
| 2 | 4 người **không** có tài khoản vào bằng link | 4/4 vào; `guest_label` nhập được; không ai bị bắt đăng nhập (FR-GRP-01) |
| 3 | Mỗi người nhập ràng buộc riêng (2 người diet, 1 budget, 1 distance) | app chỉ hiện **aggregate**; không lộ ai là ai (TC-GRP-03-A2) |
| 4 | Host lập danh sách 5 ứng viên | `candidates` không ứng viên nào vi phạm union diet; `budget ≤ min(budget)`; `anchor=midpoint` dùng đúng số người chia sẻ |
| 5 | Mọi người vote + 1 người veto | `vote.updated` tới các máy khác **< 2 s** (FR-GRP-06); veto ẩn danh; người thứ 2 veto cùng ứng viên ⇒ `vetoes:2` |
| 6 | Host bấm Chốt | 1 winner duy nhất trên **mọi** máy (không "máy tôi ra A, máy bạn ra B"); `decision.method` hiển thị đúng |
| 7 | 1 thành viên bấm "Kiểm chứng kết quả" | `GET /proof` hiện seed + hash + cách tính; UI giải thích được bằng lời đơn giản |
| 8 | Bấm Chỉ đường | maps mở với quán winner |
| **Ngoại lệ** | 1 member mất mạng 2 phút | vào lại, **phiếu còn nguyên**, `last_seq` replay đúng (TC-GRP-06-A2) |
| **Ngoại lệ** | host thoát phòng | quyền host chuyển cho member kế tiếp, không "mồ côi" (TC-GRP-07-A4) |
| **Ngoại lệ** | không ai vote trong 10 phút | app nhắc, không tự chốt khi chưa `force` (TC-GRP-05-A5) |
| **Privacy** | sau `close` | `location_enc` = NULL trên DB; app không còn hiện "vị trí của bạn trong phòng" (TC-GRP-07-A2) |

### 7.3 UC-03 · Đói gấp — `E`, P=B

| Bước | Kỳ vọng |
| --- | --- |
| Mở app → chạm **Đói gấp** (1 chạm) | kết quả ≤ 2 s (UC-03); **1** quán; không màn filter trung gian |
| Quán trả về | `is_open=true` và `closes_in_min ≥ 45`; gần nhất hợp lệ; hợp diet; **không** gọi provider (NFR-06) |
| Chạm "Đi ngay" | maps mở — **tổng 2 chạm** từ mở app |
| Không quán nào mở trong 4 km | `200` với `place:null` + alternatives "mở sau 15 phút"; app hiện lời thân thiện, **không** lỗi (TC-ROU-09-A4) |
| 1000 lần chạm ở cùng khu | p95 ≤ 1,5 s; 0 timeout |

### 7.4 ⭐ Flow validation script — chạy 10 phút, trả lời "luồng đã ổn chưa"

Chạy theo thứ tự, mỗi dòng **pass/fail** phải ghi được. Đây là smoke test thủ công + script.

```bash
BASE=https://api.angi.example/staging
Q() { curl -sS -H "Content-Type: application/json" -H "X-Request-id: $(uuidgen)" "$@"; }

# 0) guest
T=$(Q -X POST $BASE/v1/auth/guest -d '{"install_id":"'"$(uuidgen)"'","platform":"android","app_version":"1.0.0"}' | jq -r .access_token)
H="Authorization: Bearer $T"

# 1) diet cứng: dị ứng đậu phộng → PHẢI không bao giờ ra món đậu phộng
Q -X PUT $BASE/v1/me/diet -H "$H" -H "X-Idempotency-Key: $(uuidgen)" \
  -d '{"strict":["tag_peanut"],"consent_granted":true}' >/dev/null
for i in $(seq 1 200); do
  Q -X POST $BASE/v1/spins -H "$H" -d '{"filters":{"meal":["lunch"]}}' | jq -r '.dish.tags[].id'
done | grep -c tag_peanut   # ==> KỲ VỌNG: 0

# 2) vị trí + 3 chạm đến chỉ đường (đo thời gian)
G="10.779000,106.702000"
time Q "$BASE/v1/places/urgent?geo=$G&radius_m=1500" -H "$H" | jq '.place.name, .open_status.closes_in_min'
# ==> KỲ VỌNG: 1 quán, is_open true, closes_in_min >= 45, real < 2s

# 3) spin -> matches, kiểm minh bạch
S=$(Q -X POST $BASE/v1/spins -H "$H" -d '{"locked":{"category_id":"cat_mon_nuoc"}}' | jq -r '.spin_id + " " + .dish.id')
SP=$(echo $S | cut -d' ' -f1); SD=$(echo $S | cut -d' ' -f2)
Q -X POST $BASE/v1/matches -H "$H" -d "{\"spin_id\":\"$SP\",\"dish_id\":\"$SD\",\"geo\":{\"lat\":10.779,\"lng\":106.702},\"limit\":3}" \
  | jq '.items[] | {name, score: .score_breakdown.score_total, top: .score_breakdown.top_component, why: .why.headline}'
# ==> KỲ VỌNG: 3 items, mỗi item có why.headline != null, sum(contributions)-penalty == score

# 4) provider chết → vẫn phải ra kết quả
Q -X PATCH $BASE/v1/admin/providers/google -H "$ADMIN_H" -d '{"enabled":false}' >/dev/null
Q "$BASE/v1/places/nearby?geo=$G" -H "$H" -D- -o/dev/null | grep -i x-data-quality
# ==> KỲ VỌNG: HTTP 200, x-data-quality: cached|stale|provider_degraded (KHÔNG 5xx)
Q -X PATCH $BASE/v1/admin/providers/google -H "$ADMIN_H" -d '{"enabled":true}' >/dev/null

# 5) offline bundle
curl -sS $BASE/v1/dishes/bundle | gzip | wc -c   # ==> < 350000
curl -sSI $BASE/v1/dishes/bundle -H 'If-None-Match: "b<version>"' | head -1  # ==> 304

# 6) idempotency replay
K=$(uuidgen); Q -X POST $BASE/v1/journal/visits -H "$H" -H "X-Idempotency-Key: $K" -d '{"place_id":"plc_QA_001","status":"arrived"}' >/dev/null
Q -X POST $BASE/v1/journal/visits -H "$H" -H "X-Idempotency-Key: $K" -d '{"place_id":"plc_QA_001","status":"arrived"}' -D- -o/dev/null | grep -i idempotency-replayed
# ==> KỲ VỌNG: X-Idempotency-Replayed: true và visit_count không đổi

# 7) báo sai → ranking đổi sau kiểm duyệt
Q -X POST $BASE/v1/places/plc_QA_002/reports -H "$H" -H "X-Idempotency-Key: $(uuidgen)" -d '{"kind":"wrong_hours","suggested_value":{"closes_at":"11:30"}}' | jq .status
Q -X POST $BASE/v1/admin/reports/1/decision -H "$ADMIN_H" -d '{"decision":"accept","applied_change":{"closes_at":"11:30"}}' >/dev/null
sleep 300; Q "$BASE/v1/places/plc_QA_002?sections=core,hours" -H "$H" | jq '.open_status, .score_breakdown.penalty'
# ==> KỲ VỌNG: giờ mới áp dụng, penalty có report_ratio
```

**Bảng kết quả phải điền khi chạy** (bản in ra để check nhanh):

| # | Kiểm | Đạt? | Số đo thực tế | Ghi chú |
| --- | --- | --- | --- | --- |
| 1 | Diet hard: 0/200 vi phạm | ☐ | | |
| 2 | Đói gấp 1 chạm < 2 s | ☐ | | |
| 3 | Vì sao gợi ý có cho 3/3 quán | ☐ | | |
| 4 | Provider tắt vẫn 200 + nhãn | ☐ | | |
| 5 | Bundle < 350 KB, 304 hoạt động | ☐ | | |
| 6 | Idempotency replay không tạo trùng | ☐ | | |
| 7 | Report accepted đổi data + penalty | ☐ | | |
| 8 | UC-01 tổng chạm ≤ 3 (trên device) | ☐ | | |
| 9 | UC-02 5 device cùng 1 winner < 2 s | ☐ | | |
| 10 | Offline quay ra 10/10 kết quả | ☐ | | |

**Kết luận nhanh**: fail dòng 1, 2, 4, 8, 9, 10 ⇒ **luồng chưa ổn**, chưa được release (đúng 6 cái này là giá trị cốt lõi của sản phẩm).

---

## 8. Test phi chức năng (map NFR SRS mục 8)

### 8.1 Hiệu năng — NFR-01, NFR-02, NFR-05

| ID | Kịch bản k6 | Profile | Ngưỡng (p95) | Ghi chú đo |
| --- | --- | --- | --- | --- |
| TC-NFR-01-A1 | `GET /v1/places/nearby` cache **đã warm** | 500 VU, 10 phút | **< 500 ms** | 0 provider call |
| TC-NFR-01-A2 | cùng endpoint, cache **lạnh** (flush Redis mỗi 30 s) | 200 VU, 5 phút | **< 1500 ms** | tính cả provider |
| TC-NFR-01-A3 | `POST /v1/matches` limit 3 | 300 VU, 10 phút | < 600 ms | |
| TC-NFR-02-A1 | `POST /v1/spins` | 1000 VU, 10 phút | **< 300 ms** | không có provider trong chuỗi |
| TC-NFR-02-A2 | Cold start app trên thiết bị tầm trung (Redmi Note 11 / Galaxy A14) | 20 lần | **< 2,5 s** tới màn có thể quay | Firebase Perf + `Stopwatch` trong app; đo cả lần đầu (DB init bundle) |
| TC-NFR-05-A1 | 100.000 MAU: 8.000 req/phút hỗn hợp 70 % nearby / 25 % spin / 5 % auth | 30 phút | p95 đạt A1/A2, error < 0,1 % | |
| TC-NFR-05-A2 | 5.000 phòng × 6 client, 1 vote/giây/client | 15 phút | fan-out < 2 s tại 95 %; 0 mất event; Redis memory < 70 % | **phải** bật `room_id` consistent hashing, nếu không fail |
| TC-NFR-05-A3 | 100.000 spin/phút (trend viral, rủi ro SRS 12.3) | 5 phút | không lỗi dây chuyền; `degraded_mode` tự bật đúng thiết kế; `POST /v1/rooms` bị `403 SYSTEM_BUSY` | kiểm tra **tính chủ động** của degradation |
| TC-NFR-02-A3 | `GET /v1/dishes/bundle` 200 VU | 5 phút | < 500 ms, bandwidth < 350 KB | |

**Cách báo cáo**: luôn kèm `meta.latency_ms` breakdown (db / provider / scoring / total) — nếu total đạt mà `scoring` > 100 ms thì có vấn đề thuật toán, phải ghi rõ.

### 8.2 Sẵn sàng & chịu lỗi — NFR-03, NFR-04, NFR-06

| ID | Fault tiêm vào | Kỳ vọng |
| --- | --- | --- |
| TC-CHAO-01 | tắt adapter `google` hoàn toàn | `nearby`/`matches` vẫn `200` từ Postgres+OSM; `X-Data-Quality:"provider_degraded"`; không alert page |
| TC-CHAO-02 | tắt `osm` | như trên, chuỗi fallback kế tiếp |
| TC-CHAO-03 | **tắt cả 2 provider** | vẫn `200` (nguồn DB + cache) — đây là test chính của **FR-PLC-08 + NFR-06**; nếu 5xx ⇒ fail release |
| TC-CHAO-04 | Redis chết | rate limit fail-open có cảnh báo; spin vẫn chạy (Postgres path); **group** fail — phải trả `503` rõ ràng (chấp nhận được vì phòng là P2, nhưng **phải** có thông điệp) |
| TC-CHAO-05 | Postgres replica lag 10 s | đọc vẫn từ primary cho write-after-read (user không mất visit vừa ghi); không đọc dữ liệu cũ hơn 15 s |
| TC-CHAO-06 | RabbitMQ chết | luồng chính (spin/matches) **không** bị ảnh hưởng; outbox giữ event, phát lại khi hồi phục; push/enrichment delay có metric |
| TC-CHAO-07 | WeatherPort `500` | `context_used.weather:null`, p95 không đổi (TC-REC-07-A3) |
| TC-CHAO-08 | Object storage/CDN chết | app hiện placeholder, không vỡ; tên món + quán vẫn đọc được (ảnh không phải dữ liệu cốt lõi) |
| TC-CHAO-09 | kill 1 monolith pod giữa 500 VU | 0 request `500` (retry + graceful drain); p95 tăng ≤ 20 % |
| TC-CHAO-10 | kill 1 `group-ws` pod có 1000 kết nối | client tự reconnect + `last_seq` resync trong < 5 s; không mất phiếu |
| TC-CHAO-11 | FCM/APNs trả `400 INVALID_TOKEN` hàng loạt | device bị disable token, **job push không chặn** job enrichment |
| TC-CHAO-12 | delay 3 s ở mọi provider (mạng yếu) | circuit mở đúng ngưỡng, SLA `nearby` không vượt 2×; app hiện skeleton, không "treo" |
| TC-AVAIL-01 | đo 30 ngày SLO | uptime ≥ 99,5 % (P1) / 99,9 % (P2) theo error budget; SLO dashboard có alert burn-rate |
| TC-AVAIL-02 | restore drill | RPO ≤ 15 phút (WAL), RTO ≤ 1 giờ; drill tự động hàng tháng **phải** pass trước release P2 |
| TC-CRASH-01 | 7 ngày Firebase Crashlytics | crash-free sessions ≥ 99,5 %, crash-free users ≥ 99,7 % (NFR-04) |

### 8.3 Bảo mật — NFR-07 (OWASP ASVS/MASVS)

| ID | Kiểm tra | Kỳ vọng |
| --- | --- | --- |
| TC-SEC-01 | IDOR ma trận: 12 endpoint có `{id}` × user A/B (place, spin, visit, list, review, room, room member, export, merchant place, admin) | **100 %** `403/404`, không rò rỉ dữ liệu qua timing hay message |
| TC-SEC-02 | `GET /v1/admin/*` với token không admin | `403` mọi endpoint (matrix tự sinh từ OpenAPI, không test mẫu) |
| TC-SEC-03 | JWT: `alg:none`, chữ ký sai, `exp` quá, `aud` sai, token của env khác | `401` cả 5; **không** có path nào bỏ qua verify ở gateway |
| TC-SEC-04 | Refresh token reuse | `401 REFRESH_REUSE_DETECTED` + thu hồi mọi phiên (TC-AUTH-03-A3) |
| TC-SEC-05 | XSS: `<script>`, `"><img onerror>`, `javascript:` trong `note`, `guest_label`, `detail` report, `dish.name` (admin), review text | stored escaped; render app/web không thực thi; `javascript:` URL bị chặn ở deep link |
| TC-SEC-06 | SQLi: `' OR 1=1--`, `\'; DROP`, unicode escape trong `q`, `search`, `address` | không lỗi SQL; dùng parameterized (assert qua log không có SQL nối chuỗi) |
| TC-SEC-07 | Injection vào `filters` (mảng object lồng, prototype pollution `"__proto__"`) | `400`, không phá JVM/JS |
| TC-SEC-08 | Rate limit trên `auth`, `otp`, `reports`, `reviews`, `places` (POST), `rooms` | đúng ngưỡng, phân biệt theo user **và** IP (chống burner) |
| TC-SEC-09 | secrets | `grep -riE "(api_key\|secret\|password)"` trong APK/AAB **không** match; không có key provider trong app (SRS 11); dependency scan 0 CVE `Critical` |
| TC-SEC-10 | Khi truyền | HSTS, TLS 1.2+, không chấp nhận `http://`; certificate pinning cho API (app), OCSP stapling |
| TC-SEC-11 | Lưu trữ local | keychain (iOS) / Keystore (Android) cho token; **không** ghi token vào SharedPreferences/plaintext file; `Drift` DB không chứa `refresh_token` |
| TC-SEC-12 | Push token & log | log không có PII (TC-API-20); admin export log có mask; Sentry `beforeSend` scrub toạ độ + diet |
| TC-SEC-13 | Upload | magic bytes, anti virus/quarantine, giới hạn kích thước, signed URL một lần, ảnh served qua CDN không thực thi |
| TC-SEC-14 | Enumeration | `POST /v1/rooms/join` code sai → `404` chung; `POST /v1/auth/otp/request` phone đã tồn tại → **vẫn** trả `200` generic (không lộ "số này đã có tài khoản") |
| TC-SEC-15 | WSS | ticket one-time (TC-GRP-06-A6), origin check, không nhận frame > 64 KB, auth per message, không cho `member_id` giả |
| TC-SEC-16 | MobSF + zap baseline scan | report `0 High`; lưu artifact làm bằng chứng ASVS |

### 8.4 Quyền riêng tư — NFR-08, SRS mục 11

| ID | Kiểm tra | Kỳ vọng |
| --- | --- | --- |
| TC-PRIV-01 | vị trí | không có bảng/job nào lưu **chuỗi** vị trí liên tục; chỉ `geohash6` trong cache + `user_location` do user tự lưu. Assert: 100 request nearby → DB **không** phát sinh dòng nào chứa `lat/lng` chi tiết của user |
| TC-PRIV-02 | ToS cache | TTL cache provider đúng điều khoản (TC-PLC-08-A4); quá hạn ⇒ purge, `place_source_ref.raw` bị cắt |
| TC-PRIV-03 | consent version | mỗi consent lưu `policy_version` + `granted_at`; request thiếu consent cần thiết → `403 CONSENT_REQUIRED` |
| TC-PRIV-04 | diet/allergen | mã hoá at-rest (assert `user_diet` raw = ciphertext), **chỉ** dùng để lọc, không bao giờ xuất trong response của người khác, không vào analytics event |
| TC-PRIV-05 | room location | `location_enc` mã hoá + xoá khi close/expiry (TC-GRP-07-A2) |
| TC-PRIV-06 | export & xóa | export **không** chứa push token; xóa hoàn tất ≤ 30 ngày, có bằng chứng job (TC-AUTH-05-A6) |
| TC-PRIV-07 | xin quyền đúng lúc | app **không** xin quyền vị trí ở màn đầu (chỉ khi chạm tính năng cần); có dòng giải thích bằng lời người dùng trước hệ điều hành dialog (SRS 11 + store policy) |
| TC-PRIV-08 | analytics | event không gửi `user_id` thô (dùng bucket hash), không gửi toạ độ chính xác (chỉ geohash5), opt-out tôn trọng |
| TC-PRIV-09 | EXIF | ảnh user upload bị strip GPS **trước** khi CDN (TC-COM-01-A5) |

### 8.5 Khả dụng & tiếp cận — NFR-09, NFR-10, mục 7 SRS

| ID | Kiểm tra | Kỳ vọng |
| --- | --- | --- |
| TC-A11Y-01 | touch target | mọi nút chạm ≥ 44 pt / 48 dp — assert bằng widget test trên Spin, Match, Room (đo rect thật, không mắt nhìn) |
| TC-A11Y-02 | tương phản | toàn bộ text đạt WCAG 2.1 AA (4,5:1; large text 3:1), cả dark mode — script đo màu từ theme tokens, chạy trong CI |
| TC-A11Y-03 | trình đọc màn hình | VoiceOver + TalkBack đi hết 5 màn chính, thứ tự hợp lý, mọi phần tử có label; kết quả quay **đọc được tên món** (không chỉ hoạt hình) |
| TC-A11Y-04 | `reduce_motion` | hoạt hình tắt, không tự chạy vô hạn, không flashing > 3 Hz (WCAG 2.3.1) |
| TC-A11Y-05 | cỡ chữ hệ thống 200 % | không cắt chữ, không che nút ở 8 màn chính (screenshot test) |
| TC-UX-01 | người dùng mới không hướng dẫn | 5 người chưa dùng bao giờ hoàn thành UC-01 trong ≤ 3 chạm mà **không** được ai giải thích; đo thời gian + số nhầm lẫn |
| TC-UX-02 | SUS | ≥ 80 ở cuối P1 (NFR-09) — chạy sau 10 phiên dùng thật |
| TC-UX-03 | "3 chạm" | automation: mở app → spin → match → nav = **3** chạm; nếu thêm 1 màn trung gian ⇒ fail 2.6.1 |
| TC-UX-04 | thao tác một tay | nút chính nằm trong nửa dưới màn hình 6,1″ (screenshot overlay) |

### 8.6 Quốc tế hoá & bảo trì — NFR-11, NFR-12, NFR-13, NFR-14, NFR-15

| ID | Kiểm tra | Kỳ vọng |
| --- | --- | --- |
| TC-I18N-01 | quét mã nguồn | 0 chuỗi UI hard-code (lint rule `prefer-intl`); 0 chuỗi dịch trong backend response (chỉ `message_key`) |
| TC-I18N-02 | định dạng | `45.000 ₫` (vi) vs `VND 45,000` (en); ngày `01/11` vs `Nov 1`; không dùng `double` cho tiền (TC-BIZ-13) |
| TC-I18N-03 | tiếng Việt | không missing diacritics khi render + khi export CSV (BOM, TC-JRN-06-A1); search không dấu vẫn ra kết quả |
| TC-Maint-01 | CI coverage gate | `roulette`, `ranking`, `group` domain ≥ 70 % (NFR-12); PR fail nếu giảm coverage bất kỳ module nào |
| TC-Maint-02 | ArchUnit | 4 quy tắc `01` §3.1 xanh; module không import nội bộ module khác; domain không import Spring |
| TC-Maint-03 | Flyway | migrate `V1..Vn` trên DB prod-snapshot chạy được + **rollback drill** được; không có migration tay |
| TC-Maint-04 | IaC | `terraform plan` diff rỗng sau apply; môi trường rebuild được từ 0 trong < 45 phút |
| TC-OBS-01 | 1 request bất kỳ | trace đủ span gateway→module→adapter→DB; `X-Request-Id` có trong **mọi** log line của request đó (NFR-13) |
| TC-OBS-02 | SLO dashboard | có `spin_result_latency`, `nearby_latency`, `room_fanout`, `provider_error_ratio`, `degraded_response_ratio`, `cost_per_dau`, `crash_free` + alert chạy được test-fire |
| TC-OBS-03 | alert | giả lập `provider_error_ratio=0.3` ⇒ alert trong < 5 phút, `degraded_mode` bật tự động |
| TC-COMPAT-01 | API versioning | app 1.0 (P1) gọi API bản hiện tại: toàn bộ **endpoint nó dùng** còn sống và semantics không đổi (NFR-14); field mới phải optional |
| TC-COMPAT-02 | 2 phiên bản gần nhất | chạy integration test với fixture request/response của app N-2 và N-1 (golden files) |
| TC-COST-01 | NFR-15 | 24 h traffic giả lập ⇒ `cost_estimate_vnd / DAU` đo được, ≤ ngưỡng; cache hit geohash ≥ 90 %; có cảnh báo ở 70 % cap (TC-ADM-03-A4) |

---

## 9. Catalog trường hợp biên và tiêu cực (edge & negative)

| # | Tình huống | Kết quả mong đợi |
| --- | --- | --- |
| N1 | `budget_vnd` = 0 / âm / 10^9 | `400` range |
| N2 | `radius_m` = 199 / 5001 | `400`; 200 và 5000 hợp lệ (biên) |
| N3 | geo ở biển (106.5, 17.0) / cực / (0,0) | `422 OUTSIDE_SERVICE_AREA` |
| N4 | `lat` = `10.77900000001` (8 decimal) | server round về 6; **không** fail, **không** cache key phân mảnh |
| N5 | 300 món nhưng 299 bị diet loại hết | `422 DIET_FILTER_EMPTY`, **không** trả món bị cấm |
| N6 | `locked.category_id` rỗng chuỗi | `400` |
| N7 | spin đang chạy thì user đổi diet | spin trả theo diet **tại thời điểm quay** (snapshot), spin kế theo diet mới — không "lẫn lộn" |
| N8 | `POST /v1/spins` 5 lần trong 200 ms (double-tap) | server chấp nhận nhưng **app** khoá nút; kiểm app không gửi quá 1 bằng instrumentation |
| N9 | response `pool.size_final=1` | quay hợp lệ, ra món đó, app hiện "Chỉ còn 1 món hợp lệ — nới bộ lọc?" (cảnh báo, không lỗi) |
| N10 | `place_hours` = 00:00–00:00 (toàn ngày "đóng") | `is_open=false` mọi lúc, `o_score=0`, không crash, không NaN `closes_in_min` |
| N11 | quán mở 24 giờ (`00:00–23:59`) | `closes_in_min` lớn, `is_open=true` lúc 00:30 |
| N12 | `review_count` tăng giữa 2 trang phân trang | không trùng item (cursor tiebreaker `id`) |
| N13 | 2 user join cùng `guest_label` trong cùng 1 ms | unique → `409 LABEL_TAKEN`, không có member "ma" |
| N14 | vote đúng lúc `round.advanced` xảy ra | `409 ROUND_CLOSED`, client tự vote lại ở round mới (không mất thao tác) |
| N15 | finalize đúng lúc member cuối rời phòng | quorum tính lại; nếu < quorum ⇒ `409 QUORUM_NOT_MET` |
| N16 | tất cả 5 candidate bị veto | `422 CANNOT_VETO_LAST_CANDIDATE` giữ ≥ 1; hoặc host phải regenerate |
| N17 | host ở Việt Nam, member ở UTC+7/+8, tz server UTC | `expires_at` đồng nhất, không phòng nào "hết hạn sớm 1 giờ" |
| N18 | đồng hồ device sai −8 tiếng, tạo visit | server dùng `received_at` clamp (`occurred_at` trong cửa sổ 7 ngày), `clock_warning` |
| N19 | JSON có duplicate key `{"geo":..,"geo":..}` | parser strict reject `400` |
| N20 | field kiểu số gửi dạng chuỗi `"45000"` | reject `400` (không âm thầm cast — tránh tiền sai) |
| N21 | mảng 10.000 `exclude_dish_ids` | `400` cap 50, thông báo rõ cap |
| N22 | quán tên 80 ký tự + emoji + dấu cách đầu/cuối | trim; ≤ 80; không vỡ layout card (screenshot test) |
| N23 | tên món chỉ có `name_en`, `X-Locale: vi` | fallback `name_en`, không hiện `null` |
| N24 | admin xoá category còn món | `409 CATEGORY_NOT_EMPTY` (không orphan món — nếu orphan thì không spin được = tai nạn production) |
| N25 | `feature_flag` rollout 50 % rồi rollback | user đã vào arm **không** nhảy arm (sticky bucket, TC-ADM-02-A4) |
| N26 | Redis flush giữa chừng phòng đang live | `room.snapshot` rebuild từ Postgres; user không mất phòng nhưng mất `seq` → app resync (TC-CHAO-04) |
| N27 | 5.000 phòng tạo trong 1 phút | `201` hết, TTL chính xác, không room nào `expires_at` sai (test sweeper) |
| N28 | user mở 2 device cùng 1 phòng với 2 `member_id` | 2 member riêng (device-scoped) — chấp nhận; không "phiếu nhân đôi" vì unique theo member |
| N29 | provider trả kết quả **rỗng** nhưng HTTP 200 | không ghi `place` giả; `meta.providers_used` log; fallback DB |
| N30 | provider trả lat/lng đảo ngược (lng trước lat) | adapter validate `lat ∈ [-90,90]`; reject + metric `provider_bad_data` (lỗi thực tế hay gặp với OSM) |
| N31 | ảnh CDN trả 404 | placeholder, không crash loop retry |
| N32 | app bị OS giết khi đang spin (`onDetach`) | không có spin "ma" trong history; mở lại về màn chính |
| N33 | deep link `angi://room/<token>` khi token sai/hết hạn | mở app + thông báo "Phòng không còn tồn tại", không crash, không vào trạng thái loading vĩnh viễn |
| N34 | push tới user đã xóa tài khoản | không gửi (device bị thu hồi cùng user) — kiểm queue |
| N35 | `POST /v1/journal/sync` với `push` rỗng + `last_server_seq=0` | full pull hợp lệ, không timeout |
| N36 | export của user 0 dữ liệu | file hợp lệ, header đủ, **không** lỗi "empty stream" |

---

## 10. Test đặc thù mobile

| ID | Kiểm tra | Kỳ vọng |
| --- | --- | --- |
| TC-MOB-01 | mạng: offline → 3G → EDGE → online (network profile) | không crash; timeout app 5 s với retry có backoff; skeleton UI; **spin offline hoạt động** (FR-ROU-10) |
| TC-MOB-02 | request trùng lặp khi reconnect (queue) | idempotency key giữ, không tạo 2 visit (TC-JRN-05-A5) |
| TC-MOB-03 | app background 15 phút rồi foreground (WSS đóng) | reconnect + resync `last_seq`; phiếu còn; không "double spin" |
| TC-MOB-04 | khóa/mở màn hình giữa hoạt hình quay | hoạt hình dừng/tiếp tục hợp lý; kết quả **không đổi** (đã chốt server-side) |
| TC-MOB-05 | permission: vị trí "Only this time" rồi tắt | app rơi về nhập địa chỉ, không loop |
| TC-MOB-06 | mock location / GPS spoof | backend sanity: khoảng cách bất thường → gắn `suspicious`, không ảnh hưởng user khác (chống review ảo qua check-in giả) |
| TC-MOB-07 | iOS App Attest / Play Integrity fail | vẫn dùng guest ở tier thấp (không lockout tính năng cơ bản), nhưng chặn write cộng đồng |
| TC-MOB-08 | deep link từ push, từ share card, từ room link, từ `maps` quay lại | 4 đường vào, mỗi đường mở đúng màn, không stack màn hình vô hạn |
| TC-MOB-09 | low battery / power saver bật (giới hạn background) | widget + reminder vẫn gửi **server-side push** (không phụ thuộc background task của app) |
| TC-MOB-10 | Android 8 / iOS 15 (máy tối thiểu) | khởi động < 2,5 s; hoạt hình ≥ 24 fps; không crash API level (espresso/XCUITest trên máy min spec) |
| TC-MOB-11 | dung lượng Drift 100 MB / 5000 visit | sync không timeout; app có chiến lược prune (chỉ giữ 180 ngày local, còn lại server) |
| TC-MOB-12 | nâng cấp app 1.0 → 1.1 với DB cục bộ cũ | migration Drift chạy, dữ liệu local không mất (TC-COMPAT-01 song song) |
| TC-MOB-13 | bật/tắt sound+haptics khi đang có cuộc gọi | không rung/âm thanh chồng lấn; tôn trọng audio focus |

---

## 11. Regression và dataset cố định

| ID | Cơ chế | Ngưỡng |
| --- | --- | --- |
| TC-REG-01 | **Golden ranking**: dataset 45 quán + 3 tổ hợp user (cold, peanut-allergic, frequent-out) → so `items[0..2].id` với golden file | khác ⇒ phải có `formula_version` change hoặc `weights` change **được chấp nhận**; không có thì fail |
| TC-REG-02 | **Golden spin distribution**: seed cố định, 100.000 mẫu | KL-divergence với expected < 0,01 |
| TC-REG-03 | Chạy lại toàn bộ **P1 test suite** khi bật từng flag của P2 (ma trận flag × test) | không flag P2 nào làm fail P1 (feature isolation) |
| TC-REG-04 | API diff OpenAPI | chỉ **additive** trong cùng major version; breaking ⇒ cần `/v2` hoặc deprecation header |
| TC-REG-05 | UI screenshot test 12 màn, 2 theme, 2 locale, 2 font scale | diff < 0,5 % có review người; chống "fix chỗ này hỏng chỗ kia" |

---

## 12. Phân mức lỗi, tiêu chí vào/ra

### 12.1 Severity

| Mức | Định nghĩa | Ví dụ dự án này | SLA fix |
| --- | --- | --- | --- |
| **S1 Blocker** | Luồng chính chết, dữ liệu mất/lộ, an toàn sức khoẻ | ra món chứa dị ứng của user; spin trả 500; mất visit; `location_enc` không xoá; provider chết ⇒ app chết | 24 h, **chặn release** |
| **S2 Critical** | Tính năng chính sai kết quả/quy tắc nghiệp vụ | quán đã đóng hiện trong mặc định; "Vì sao" rỗng; 2 phòng ra 2 winner; Bayesian sai chiều; cache trả dữ liệu cá nhân hoá cho user khác | 3 ngày, chặn release |
| **S3 Major** | Tính năng phụ sai, UX nghiêm trọng | badge `closing_soon` không hiện; phân trang lặp item; filter không persist; push gửi khi tắt reminder | 1 sprint |
| **S4 Minor** | Mỹ thuật, chuỗi, edge rare | lỗi chính tả EN; thiếu alt text; skeleton lệch 4 px | backlog |

### 12.2 Entry criteria (bắt đầu test 1 featureset)
- Code merge `develop`, CI xanh, build `staging` có **release notes chỉ rõ FR nào**
- OpenAPI/contract đã review + fixture của app đã commit
- Dataset seed đạt §2.2, fake clock hoạt động
- Feature flag cho featureset đó set được về `off` (để test tắt/bật)

### 12.3 Exit criteria (được release P1)
- 100 % TC `P=B` pass; `P=1` pass ≥ 95 % (còn lại phải có **waiver** có chữ ký chủ sản phẩm, ghi vào release notes)
- 0 bug S1/S2 mở; S3 tồn tại ≤ 5 và **không** nằm trên UC-01/03
- Perf §8.1 đạt, SLO §8.2 đạt, bảo mật §8.3 không S1/S2
- Accessibility §8.5 đạt AA (trừ mục đã ghi nhận là technical debt có plan)
- NFR-12: phủ unit logic lõi ≥ 70 %; 52 endpoint P1 có contract test
- Regression §11 chạy pass sau lần phát hành kế tiếp (không chỉ lúc release)
- **Đo được**: `spin_to_nav_rate` có số liệu đầu tiên (SRS 12.2) — không có metric = chưa chứng minh luồng chạy được thật

---

## 13. Automation pipeline

```
on: pull_request
  1. lint + ArchUnit + i18n-hardcode-scan + OpenAPI diff     (< 3 min)
  2. unit (U) + property-based (TC-BIZ-02/03)                (< 5 min)
  3. integration (I) Testcontainers Postgres/PostGIS/Redis    (< 12 min)
  4. contract (C): server↔OpenAPI, server↔Flutter fixture
  5. flutter analyze + unit + golden spin distribution
  fail → chặn merge

nightly (staging)
  6. E2E UC-01/02/03 + offline + permission (Patrol, 2 device + 5 device room)
  7. cross-cutting §5 ma trận endpoint × 20 loại lỗi
  8. edge/negative §9 + fuzz
  9. chaos §8.2 (CHAO-01..12)
 10. golden regression §11
 11. a11y: touch target + contrast script + screenshot 12 màn

weekly / pre-release
 12. perf §8.1 (k6 + WSS load) trên dataset 5.000 quán
 13. security §8.3 (Zap baseline, MobSF, dependency scan)
 14. restore drill + RTO/RPO verify
 15. SUS/UX test với người thật (5 user / tuần, §8.5)
```

**Test data hygiene**: mọi user test prefix `qa_`, mọi label chứa `qa-`; script **pre-release** chạy `DELETE FROM ... WHERE display_name LIKE 'qa\_%'` ở prod nếu có leak; không dùng dữ liệu thật của user để test logic diet (sức khoẻ = sensitive).

---

## 14. Mẫu báo cáo kết quả test (dùng khi nghiệm thu từng bản)

```
Bản: P1 – Sprint 6           Ngày: 2026-11-XX        Người báo: QA
FR đã test: ROU-01..10, PLC-01..08, REC-01..05, NAV-01, AUTH-01..05, ADM-01..03, PER-01
Tổng TC: 412 | Pass: 398 | Fail: 9 | Blocked: 3 | Skip(có waiver): 2
Blocker (P=B): 61/61 pass ☐   ← nếu ☐ thì KHÔNG release
S1 mở: 0 | S2 mở: 1 (TC-PLC-06-A4: hours exception không thắng hours_by_dow) | S3: 4
Perf: nearby w/ cache p95=410ms (mục tiêu 500) ☑ | w/ provider p95=1.31s (1.5) ☑
      spin p95=220ms (300) ☑ | cold start device thấp nhất 2.35s (2.5) ☑
Chaos: CHAO-03 (mất 2 provider) → 200, data_quality=stale ☑ | CHAO-06 outbox replay ☑
Privacy: TC-PRIV-04 diet ciphertext ☑ | TC-PRIV-05 location_enc NULL ☑
Rủi ro còn lại / kiến nghị:
  - TC-GRP-06-A1 (5k phòng) chưa chạy vì group chưa bật flag → dời P2, không ảnh hưởng P1
  - Chi phí Google: cache_hit 78 % (mục tiêu ≥ 90 %) → cần thêm cache theo geohash6
```

### Checklist "luồng có ổn không" (in ra dán lên tường)

- [ ] Diet/allergen: 0 vi phạm trên ≥ 1.000 mẫu (mọi đường vào: spin, urgent, wheel, group, relaxation) — **TC-ROU-03-A1, TC-BIZ-11**
- [ ] Không quán đã đóng trong kết quả mặc định, mọi múi giờ/biên giờ — **TC-PLC-06-A1..A7**
- [ ] 3 chạm đến chỉ đường, đo bằng automation — **TC-UX-03**
- [ ] "Vì sao" có cho mọi quán top, số học khớp `score_total` — **TC-REC-02-A2/A3**
- [ ] Mất 100 % provider → app vẫn ra kết quả có nhãn — **TC-CHAO-03**
- [ ] Mất mạng 100 % vẫn quay được món — **TC-ROU-10-A1**
- [ ] Xóa tài khoản: dữ liệu sạch thật (assert SQL) — **TC-AUTH-05-A2**
- [ ] Idempotency: 0 bản ghi trùng khi retry yếu mạng — **TC-API-04, TC-MOB-02**
- [ ] Phòng nhóm: mọi device cùng 1 kết quả, ràng buộc không lộ ai — **TC-GRP-02-A7, TC-GRP-03-A2**
- [ ] Quảng cáo không đổi `score_total` — **TC-REC-04-A2**
- [ ] Không endpoint nào trả chuỗi dịch sẵn / không `message_key` — **TC-I18N-01**
- [ ] Không PII trong log — **TC-API-20, TC-SEC-12**


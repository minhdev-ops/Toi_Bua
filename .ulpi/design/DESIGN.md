---
project: ĂnGìĐây
register: product
aesthetic_direction: playful/toy (thực thi thành "tem nhựa" — stamp/sticker)
color_strategy: full-palette
design_system: Material 3 (thư viện `material` của Flutter), theme bằng ColorScheme + ThemeExtension
design_variance: 7
motion_intensity: 8
visual_density: 4
version: 2026.11.01
---

# DESIGN.md — Ngôn ngữ thiết kế ĐÃ CHỐT

> **Every screen must read as the same product if placed side by side.**

Đây là nguồn sự thật duy nhất về hình thái. Mọi giá trị nằm ngoài file này là defect, không phải "quyết định tại chỗ của màn hình".

## Design Read

*Một cỗ máy trò chơi bỏ túi cho bữa ăn: người ta mở app vì tò mò "hôm nay quay ra gì", ở lại vì kết quả đáng tin.* Cược thiết kế: đổi độ tin lấy **độ chạm tay được** — mọi thứ trông như đồ nhựa in lụa có thể bấm, kéo, lật.

## Counterfactual test (đã chạy, và đã từ chối)

Với brief "app món ăn Việt cho giới trẻ", phản xạ default là: nền kem `#F7F3EC`, chữ terracotta, serif editorial (Playfair/Fraunces), thẻ bo tròn + shadow mờ mềm, ảnh món ăn to chiếm màn hình. **Đó chính xác là tổ hợp bị cấm.** Nên hệ này chọn ngược lại có chủ đích:

| Default bị từ chối | ĂnGìĐây dùng | Lý do từ brief |
| --- | --- | --- |
| Nền kem/marron "món ăn" | Nền **jade lạnh** | món ăn Việt bán ở biển hiệu đỏ–vàng–xanh, không ở giấy kraft |
| Serif editorial | **Grotesque quirky** | đối tượng 18–30, app dùng 30 giây mỗi lần, không phải tạp chí |
| Shadow mềm tan | **Shadow cứng, offset, 0 blur** | shadow mềm = "app 2019"; offset cứng = đồ in lụa, tem, sticker |
| Card nổi viền mảnh | **Viền mực 2dp** bao mọi control | đồ chơi nhựa có đường viền, và viền đậm chính là thứ làm border đạt tương phản |
| Accent cầu vồng quá tải | **Một accent nắng**, 8 hue dữ liệu bị nhốt trong 3 ngữ cảnh | vòng quay *cần* nhiều màu; UI thì không |

## Signature: CON DẤU (the stamp)

Một đối tượng duy nhất, lặp lại ở mọi màn: **mặt màu + viền mực 2dp + bóng cứng offset 0 blur**. Khi bấm, nó **lún thật**: translate đúng bằng offset bóng, bóng về 0, rồi bật lên. Cảm giác Physical.

Xuất hiện dưới 4 dạng, không thêm:
1. `StampButton` — nút primary (accent + nhãn `on_accent`), cao ≥ 52dp.
2. `StampBadge` — tem trạng thái, nghiêng **−6°**, `stampLabel` (VD: `ĐANG MỞ`, `SẮP ĐÓNG`).
3. `StampCard` — 1 vật thể nổi mỗi màn (kết quả urgent, kết quả quay).
4. `StampChip` — bộ lọc đang bật, có dấu ×.

**Bóng chỉ tồn tại trên stamp.** Không có object nào khác trong app được đổ bóng. Đây là kỷ luật giữ cho 8 màu dữ liệu không biến màn hình thành mớ hỗn độn.

## Color (locked)

Chiến lược: **full-palette**. Trung tính always jade-tinted (chroma 0.006–0.028, hue 175–205), **không có gray thuần `#808080` nào trong hệ**.

### LIGHT

| role | hex | OKLCH | dùng cho |
| --- | --- | --- | --- |
| `background` | `#E8F7F3` | 0.965 0.017 175 | nền app, canvas |
| `surface` | `#FAFFFD` | 0.995 0.006 175 | sheet, list row, stamp mặt |
| `sunken` | `#D9EDE8` | 0.930 0.022 178 | well trũng: thanh trượt, vùng ảnh chờ |
| `ink` | `#152725` | 0.255 0.024 190 | chữ chính **và mọi viền 2dp** |
| `muted` | `#4C615F` | 0.475 0.026 190 | chữ phụ |
| `subtle` | `#5E7270` | 0.535 0.024 190 | caption, số thứ cấp (chỉ trên `surface`) |
| `line` | `#BCCDC9` | 0.835 0.020 178 | **chỉ** divider 1dp, không dùng làm viền control |
| `accent` | `#F2CD20` | 0.855 0.170 95 | **một accent duy nhất**: CTA, con trỏ vòng quay, focus của wheel |
| `on_accent` | `#211E10` | 0.235 0.025 100 | nhãn trên accent |
| `on_fill` | `#211E10` | 0.235 0.025 100 | nhãn trên mọi fill trạng thái |
| `focus` | `#125B84` | 0.450 0.095 240 | vòng focus 3dp |
| `success_fill` | `#86D29B` | 0.800 0.110 152 | tem "ĐÃ XÁC MINH", "CÒN MỞ LÂU" |
| `warning_fill` | `#F9B87F` | 0.830 0.105 62 | banner nhà cung cấp lỗi |
| `danger_fill` | `#FC9D95` | 0.790 0.115 25 | tem `SẮP ĐÓNG` |
| `info_fill` | `#95C8ED` | 0.810 0.075 240 | tem dữ liệu cache |
| `success_text` | `#137D41` | 0.520 0.130 152 | chỉ trên `surface`/`sunken` |
| `danger_text` | `#CD1F2A` | 0.545 0.205 25 | giờ đóng còn lại < 30′ |
| `info_text` | `#1B77AC` | 0.545 0.115 240 | chỉ trên `surface` |
| `accent_text` | `#654B07` | 0.430 0.085 85 | số tiền, điểm (khi cần tô màu, không bắt buộc) |

### DARK (derive lại, không đảo màu)

| role | hex | OKLCH | role | hex | OKLCH |
| --- | --- | --- | --- | --- | --- |
| `background` | `#0C1C1E` | 0.215 0.022 205 | `on_accent` | `#201D0F` | 0.230 0.025 100 |
| `surface` | `#182B2E` | 0.275 0.026 205 | `on_fill` | `#201D0F` | 0.230 0.025 100 |
| `sunken` | `#061213` | 0.170 0.018 205 | `focus` | `#5AAEE5` | 0.720 0.115 240 |
| `ink` | `#E8F3F0` | 0.955 0.012 175 | `success_fill` | `#86D29B` | 0.800 0.110 152 |
| `muted` | `#A3B5B4` | 0.760 0.020 190 | `warning_fill` | `#EFAE75` | 0.800 0.105 62 |
| `subtle` | `#899D9C` | 0.680 0.022 195 | `danger_fill` | `#EB827B` | 0.720 0.130 25 |
| `line` | `#314749` | 0.380 0.028 205 | `info_fill` | `#85B8DC` | 0.760 0.075 240 |
| `accent` | `#E3C023` | 0.815 0.160 95 | `success_text` | `#5EBC7B` | 0.720 0.130 152 |
| | | | `danger_text` | `#F75D59` | 0.680 0.190 25 |
| | | | `info_text` | `#4FA8E1` | 0.700 0.120 240 |
| | | | `accent_text` | `#D8BD51` | 0.800 0.130 95 |

`ink` ở dark là chữ sáng; **viền stamp ở dark dùng `on_accent`/`ink` viền sáng 2dp** — đọc như đèn biển hiệu quán đêm, cùng một hành vi với light.

### Tương phản, đã đo (OKLCH → sRGB → WCAG)

| cặp | LIGHT | DARK | ngưỡng |
| --- | --- | --- | --- |
| `ink` / `surface` | **15.45** | **12.95** | 4.5 |
| `muted` / `surface` | **6.51** | **6.90** | 4.5 |
| `subtle` / `surface` | **5.04** | **5.15** | 4.5 |
| `ink` / `background` | **14.22** | **15.35** | 4.5 |
| `success_text` / `surface` | **5.12** | **6.25** | 4.5 |
| `danger_text` / `surface` | **5.44** | **4.68** | 4.5 |
| `info_text` / `surface` | **4.82** | **5.59** | 4.5 |
| `on_accent` / `accent` | **10.72** | **9.51** | 4.5 |
| `on_fill` / `success_fill` | **9.30** | **9.42** | 4.5 |
| `on_fill` / `warning_fill` | **9.65** | **8.83** | 4.5 |
| `on_fill` / `danger_fill` | **8.22** | **6.43** | 4.5 |
| `on_fill` / `info_fill` | **9.32** | **7.94** | 4.5 |
| viền `ink` / `background` (UI, 1.4.11) | **14.22** | **15.35** | 3.0 |
| `focus` / `surface` (UI) | **7.26** | **6.02** | 3.0 |
| `accent` fill / `surface` | 1.53 | 8.29 | *không yêu cầu* — xem quy tắc dưới |

**Quy tắc tương phản bắt buộc**
1. Boundary của control **không bao giờ** do nền màu đảm nhận. `accent`/`*_fill` trên `surface` chỉ đạt 1.5–2.0:1 → đường viền `ink` 2dp (14:1) mới là thứ đạt WCAG 1.4.11. Xoá viền khỏi stamp là vi phạm a11y, không phải tinh chỉnh thẩm mỹ.
2. Màu trạng thái **không bao giờ mang nghĩa một mình**. Mọi `*_fill`/`*_text` đi kèm icon + chuỗi chữ (`SẮP ĐÓNG`, không phải một chấm đỏ).
3. Trên nền `sunken`, mức chữ thấp nhất được phép là `muted` (5.41/8.95). `subtle` trên `sunken` = **4.19 → cấm**.
4. `*_text` chỉ dùng trên `surface`/`sunken`, không dùng trên `background`.
5. Không tồn tại cặp `subtle` trên `accent`. Nhãn trên accent chỉ là `on_accent`.

### 8 hue dữ liệu, ánh xạ thẳng vào enum `filters.type` của API

Bảng màu này **ánh xạ 1-1 sang enum `type` trong `POST /v1/spins.filters.type`** (`docs/02` §3.3). Không tự ý thêm hue, không đặt tên lại.

| `type` | hex L | hex D | hue | nhãn VI |
| --- | --- | --- | --- | --- |
| `noodle` | `#0698A4` | `#48BECA` | 0.620 0.105 205 | Món nước |
| `rice` | `#B18C39` | `#D8B260` | 0.660 0.110 85 | Cơm |
| `bread` | `#CF802E` | `#F8A558` | 0.670 0.135 62 | Bánh |
| `sweet` | `#C33887` | `#ED60AC` | 0.570 0.190 350 | Ngọt |
| `grill` | `#C83C25` | `#F3654C` | 0.560 0.180 32 | Nướng |
| `salad` | `#42A357` | `#6ACA7B` | 0.640 0.145 148 | Rau / chay |
| `drink` | `#297FBD` | `#52A4E5` | 0.575 0.125 245 | Đồ uống |
| `snack` | `#CE475C` | `#F96E7F` | 0.590 0.170 15 | Ăn vặt |

**Chỉ được dùng ở đúng 3 chỗ:** phân khúc vòng quay, `StampChip` loại món, vạch `ScoreBreakdown`. Không bao giờ làm nền nút, không bao giờ làm màu link, không bao giờ quá 1 hue ngoài vật thể nó gắn nhãn.

Đo trên `surface` và nhãn `on_data` đặt trên hue (nhãn wheel dùng role `wheelLabel` → ngưỡng AA-large 3.0):

| type | hue vs surface L/D | `on_data` trên hue L/D |
| --- | --- | --- |
| noodle | 3.44 / 6.63 | **4.78** / 7.61 |
| rice | 3.10 / 7.30 | **5.31** / 8.38 |
| bread | 3.06 / 7.38 | **5.37** / 8.47 |
| sweet | 4.90 / 4.82 | 3.36 / 5.53 |
| grill | 5.01 / 4.72 | 3.28 / 5.42 |
| salad | 3.13 / 7.23 | **5.26** / 8.30 |
| drink | 4.28 / 5.46 | 3.84 / 6.26 |
| snack | 4.43 / 5.28 | 3.71 / 6.05 |

light: `sweet`/`grill`/`snack`/`drink` chỉ đạt 3.3–3.8 với nhãn đậm → **bắt buộc dùng `wheelLabel`** (18/700) khi chữ nằm trên các segment đó. dark: an toàn tuyệt đối.

## Type (locked)

Ràng buộc thật của sản phẩm: **tiếng Việt có dấu**. Đã verify bằng CSS thực tế từ Google Fonts (`fonts.googleapis.com/css2?family=...`, grep `/* vietnamese */`): cả hai mặt đều có subset `vietnamese` với `unicode-range U+0102-0103, U+0110-0111, U+1EA0-1EF9` — nghĩa là dấu sắc/huyền/hỏi/ngã/nặng và `ă, â, ê, ô, ơ, ư, đ` không bị fallback vỡ chữ.

| role | family | usage | notes |
| --- | --- | --- | --- |
| `display` | **Bricolage Grotesque** 600–700 | headline 1 màn/screen, số tiền, kết quả quay, nhãn wheel | quirky grotesque, có `opsz` + `wdth`. Tracking floor −0.02em. **Tối đa 1 dòng display mỗi view** |
| `body` | **Be Vietnam Pro** 400–600 | toàn bộ văn bản đọc, nhãn control | humanist, thiết kế cho tiếng Việt. Measure ≤ 40ch trên mobile (đọc 1 tay) |
| `utility` | **JetBrains Mono** 500 | `request_id`, ULID, toạ độ debug, bảng phiếu `tally` | tabular-by-construction; dùng khi chữ số phải thẳng cột |

Pairing axis: **grotesque quirky × humanist sans** (không serif — serif cho app món ăn chính là reflex đã bị từ chối ở trên).

Fallback metric-matched để không jump layout khi font tải chậm: `Be Vietnam Pro` → `sans-serif`; `Bricolage Grotesque` → `sans-serif-black`.

| token | size/line (sp) | role font | weight | ghi chú |
| --- | --- | --- | --- | --- |
| `display` | 34 / 1.1 | display | 700 | tối đa 1 dòng mỗi view |
| `title` | 22 / 1.25 | display | 600 | |
| `sectionLabel` | 13 / 1.2 | body | 700 | uppercase, tracking +0.06em |
| `body` | 16 / 1.5 | body | 400 | 500 khi cần nặng |
| `label` | 13 / 1.3 | body | 600 | nhãn control |
| `micro` | 11 / 1.3 | body | 500 | chỉ chi tiết không bắt buộc, **cấm trên `sunken`** |
| `stampLabel` | 12 / 1.1 | body | 700 | uppercase, tracking +0.04em; **chỉ** trên `StampBadge` |
| `wheelLabel` | 18 / 1.0 | display | 700 | **chỉ** chữ nằm trên phân khúc vòng quay; ngưỡng AA-large 3.0 đã đo theo size này |
| `numeric` | 28 / 1.0 | display | 700 | tiền, `score_total`, `distance_m` trong list |
| `numericLg` | 40 / 1.0 | display | 700 | **chỉ** số chính trên `StampCard` Đói gấp, 1 số mỗi màn |

**Quy tắc tụt scale khi chữ to:** ở `textScaleFactor ≥ 1.6`, mỗi role số tụt về **role kế tiếp có thật trong bảng** (`numericLg`→`numeric`, `numeric`→`title`, `display`→`title`). Không sinh size trung gian (24sp, 30sp...) — đó là nguồn drift.

**Text scaling (NFR-10):** app phải đúng ở 1.0 → 2.0. Mọi Text có `maxLines` xác định + `overflow: ellipsis`; mọi hàng list dùng `minHeight` chứ không khóa chiều. Ở ≥1.6, `StampBadge` ẩn phần nhìn và chuyển nhãn vào `Semantics`, không được cắt chữ. Test bằng `mediaQuery.textScaler` trong widget test.

## Scales (locked)

**spacing** (4pt rhythm, Flutter logical px) — `0, 2, 4, 8, 12, 16, 20, 24, 32, 40, 48, 64`. Padding màn 16; 20 khi có safe-area ngang.

**radius** — `xs 8 · sm 14 · md 20 · lg 28 · pill 999`. Stamp button = `md`. Sheet = `lg` ở 2 góc trên. Chip = `sm`. Vòng quay = tròn tuyệt đối (`pill`). Không có shape nào khác.

**shadow** — `flat` (0) · `stamp1` offset (0,2) blur 0 · `stamp2` offset (0,4) blur 0 · `stamp3` offset (0,6) blur 0. **Blur luôn bằng 0.**

**disabled** — `disabledOpacity 0.45` (giá trị duy nhất được phép; không làm mờ bằng cách đổi màu chữ khác). Trạng thái vô hiệu luôn **giữ viền `ink`** và có lý do trong `Semantics.hint`.

**z / layer** — `base 0 · sticky 10 · sheet 20 · dialog 30 · toast 40` (Flutter: `elevation` + `Material` ordering, không dùng magic number).

**motion** — `fast 120ms · base 260ms · emphasis 520ms`. Easing duy nhất cho UI: `curveStamp = cubic-bezier(0.2, 0, 0, 1)`. Exit = 200ms (≈75% enter). **Không bounce, không elastic cho UI.** Vòng quay dùng vật lý riêng (xem dưới) vì đó là Signature, không phải UI chrome.

Bốn mốc phụ được phép, nằm trong hệ, không ai được tự chế thêm: `stampPress 90ms` (nhả nút), `staggerStep 40ms` (list, tối đa 3 item), `barGrow 400ms` (vạch `contribution`), `staggerStep 40ms` đã nêu, `wheelSettle 180ms` (micro-settle ±3° sau khi dừng). Thời lượng vòng quay **không phải token** — lấy từ `animation.duration_ms` của server.

**sizing (control & touch)** — `touchMin 48` (bất biến, SRS mục 7) · `stampButtonH 56` · `rowMinH 76` (hàng kết quả) · `rankOneScale 1.4` (hàng hạng 1 so với `rowMinH`) · `thumbFallback 44` (ô tem thay ảnh khi `image_url=null`) · `badgeVisualMin 32` + `badgeTouchMin 48` (tem nhỏ về mặt nhìn nhưng vùng chạm buộc 48, nới bằng `Stack`+`Positioned`, **không** co visual) · `focusRing 3dp` cách mục tiêu `2dp`.

## Motion: ngân sách và hợp đồng

Nguyên tắc: **một khoảnh khắc được dàn dựng, phần còn lại im lặng.** Khoảnh khắc đó là lần quay.

| trigger | animation | duration | curve | vì sao có |
| --- | --- | --- | --- | --- |
| Bấm stamp | lún `translateY(+offset)` + shadow → 0, nhả bật lại | 120 / 90 | `easeOut` / `easeIn` | xác nhận "đã bấm" khi chưa có response |
| Kết quả quay → kết thúc | **không fade**: tem `dish` bay từ tâm + wheel khóa | theo `animation.duration_ms` | xem dưới | phần thưởng của hành động |
| Wheel | xoay giảm tốc vật lý, dừng tại `animation.result_index` | `animation.duration_ms` (server gửi, mặc định 2600) | `decelerateCubic(0.05)` rồi micro-settle 180ms trong ±3° | FR-ROU-07: kết quả **đã chốt trước**, hoạt hình chỉ hiển thị |
| List kết quả | `staggerStep` 40/row, dịch `spacing-2` 8 + opacity, **tối đa 3 row** | `base` 260 | `curveStamp` | hướng mắt xuống rank 1 |
| Mở sheet "Vì sao" | sheet trượt + các vạch `contribution` lớn dần từ 0 | `base` 260 (sheet) + `barGrow` 400 (vạch), delay nhau `staggerStep` | `curveStamp` | giải thích bằng chuyển động, không bằng chữ dài |
| `closing_soon` | KHÔNG nhấp nháy. Chỉ 1 lần scale 1.00→1.04→1.00 khi row vào viewport | 260 | `curveStamp` | cảnh báo mà không tra tấn |
| Banner `data_quality` | trượt xuống 1 lần/session/kiểu, có nút đóng | 260 | `curveStamp` | NFR-06 |
| Vote room (P2) | thanh phiếu dài theo delta, số đếm nhảy | 300 | `curveStamp` | FR-GRP-06 < 2s |

**`reduce_motion` là hợp đồng, không phải toggle trang trí** (FR-ROU-08 + `MediaQuery.disableAnimations`):
- wheel/chest/draw → **cắt hẳn**, render `StampCard` kết quả ngay tại index giữa màn, 0ms.
- stagger → 0; sheet → fade 120ms; stamp lún → đổi thành viền `focus` 3dp khi active.
- `haptics` + `sound` là 2 cờ **độc lập** với reduce-motion, lấy từ `animation.haptics` / `animation.sound`.
- Tự động bật reduce-motion khi `AccessibilityFeatures` có `reduceMotion` **hoặc** `highContrast`.

## Iconography

Một họ duy nhất: **Material Symbols Rounded**, weight 600, kích thước 24 (20 trong dòng chữ, 32 trong stamp). Cấm: emoji làm icon UI, hai họ icon lẫn lộn, icon không kèm nhãn cho tác vụ không thể đảo ngược. Icon mô tả món lấy từ `dish.image_url`; khi `null` → render **tem hue của `type` + 2 ký tự đầu tên món viết hoa** (`display` 700, `on_data`). Không dùng ảnh placeholder xám.

## Voice

`register:` plain, tự tin, hơi tinh nghịch — như bạn bè nhắc nhau đi ăn, không như brand nói với khách. Xưng "bạn", không "người dùng". Câu ≤ 8 từ cho label, ≤ 16 từ cho trợ giúp.

**Action vocabulary (nhất quán toàn luồng, không đổi tên giữa chừng):**

| hành động | label | trạng thái sau |
| --- | --- | --- |
| quay | `Quay` | `Đang quay` → `Hôm nay: <món>` |
| quay lại | `Quay lại` | (không dùng `Spin again` / `Làm lại`) |
| mở bộ lọc | `Bộ lọc` | `Áp dụng` |
| chỉ đường | `Chỉ đường` | `Đang mở bản đồ` |
| xác nhận đến | `Tôi đã đến` | `Đã ghi` |
| loại món | `Loại` | `Đã loại` |
| lưu yêu thích | `Lưu` | `Đã lưu` |
| báo sai | `Báo sai` | `Đã gửi báo sai` |
| đói gấp | `Đói gấp` | `Chọn giúp bạn: <quán>` |

**Cấm trong copy hiển thị:** buzzword (nâng cấp, tối ưu hoá, trải nghiệm liền mạch, thế hệ mới, cá nhân hoá thông minh); tên giả (Nguyễn Văn A, Quán Acme); số giả chính xác (`99.9%`, `gấp 3 lần`) khi không có nguồn; **em-dash trong mọi chuỗi UI** — dùng dấu chấm hoặc viết lại.

Mọi chuỗi nghiệp vụ lấy từ `message_key`/`why_key`/`reason_key` do server trả + ARB cục bộ (`app_vi.arb`, `app_en.arb`). **Server không trả chuỗi đã dịch** (`docs/01` §4.6) → app không bao giờ hiển thị `error.message` gốc.

## Layout families (≥3, dùng luân phiên)

1. **Hub** — wheel chiếm 62% chiều cao, `StampButton` duy nhất phía dưới, filter là bottom sheet. Một điểm nhìn.
2. **Bảng menu** — list kết quả: số thứ tự lớn bằng `display` cột trái, divider 1dp `line`, rank 1 cao hơn 1.4×. Không card lồng card.
3. **Thang vì sao** — `ScoreBreakdown`: 2 cột, nhãn trái / vạch + `contribution` phải, dòng `penalty` cuối bằng `danger_text` + icon.
4. **Thẻ quyết định** — Đói gấp: 1 `StampCard` full-bleed, `distance_m` bằng `numeric` 40sp, không list.
5. **Bảng phiếu** (P2) — `table-first` cho tally, không dùng card.

## Hằng số nghiệp vụ: không hard-code

App **chỉ** lấy từ `GET /v1/config` (`docs/02` §5.1): `place.closing_soon_min`, `place.open_min_left_to_score_1`, `place.radius_default_m`, `place.radius_max_m`, `place.urgent_radius_steps`, `spin.anti_repeat_days_default`, `spin.tau_days`, `spin.min_pool`, `animation_styles`, `ranking_weights`, `locale_supported`, `feature_flags`, `min_app_version`/`force_upgrade`. Không có file `theme_const.dart` nào chứa `30` hay `45` cho nghiệp vụ. `o_score`, `closing_soon`, `score_total` do server tính — app không tự tính (FR-PLC-06, FR-REC-02).

## Anti-slop nội quy (cấm tuyệt đối trong dự án này)

0 card lồng card · 0 glassmorphism · 0 gradient text · 0 purple/blue glow · 0 nền kem-beige · 0 dot status trang trí · 0 eyebrow `01/02/03` · 0 con số "tin cậy" giả · 0 bounce easing cho UI · 0 vô số vi-anh-hoa chạy vô hạn · 0 màn hình có 2 nút primary · 0 ảnh món làm nền toàn màn.

## Change log

`2026.11.01` bản chốt đầu tiên. Đã đo lại toàn bộ tương phản sau 3 vòng sửa: `subtle` 0.585→0.535 (4.10→5.04), `success_text`/`warning_text` tách thành `*_fill` + `*_text` (warning bỏ hẳn vai trò màu chữ), `on_accent` tách khỏi `ink` (dark mode từng fail 1.56:1), 4 hue `rice/salad/bread/noodle` hạ sáng để đạt 3:1, 4 token out-of-gamut ép về `danger_fill` 0.115 / `focus` 0.095 / `accent_text` 0.085 / `info_text` 0.115.

`2026.11.01.2` bổ sung có chủ đích sau Pre-Flight gate (spec UC-01 viện dẫn 4 giá trị chưa có trong hệ): thêm role `numericLg 40`, quy tắc tụt scale khi `textScaleFactor ≥ 1.6`, group token `sizing` (`touchMin`, `stampButtonH`, `rowMinH`, `rankOneScale`, `thumbFallback`, `badgeVisualMin/TouchMin`, `focusRing`), `disabledOpacity 0.45`, và 4 mốc motion phụ (`stampPress 90`, `staggerStep 40`, `barGrow 400`, `wheelSettle 180`). Không đổi màu, không đổi font, không đổi signature.

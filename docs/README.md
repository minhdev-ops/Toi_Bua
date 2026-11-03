# Tài liệu kỹ thuật ĂnGìĐây

Bộ tài liệu triển khai, derived từ [`ĂnGìĐây – Tài liệu đặc tả yêu cầu phần mềm (SRS).md`](../%E1%BA%A8nG%C3%AC%C4%90%C3%A2y%20%E2%80%93%20T%C3%A0i%20li%E1%BB%87u%20%C4%91%E1%BA%B7c%20t%E1%BA%A3%20y%C3%AAu%20c%E1%BA%A7u%20ph%E1%BA%A7n%20m%E1%BB%81m%20%28SRS%29.md) v1.0.

| File | Nội dung | Dùng khi nào |
| --- | --- | --- |
| [`01-kien-truc-he-thong.md`](./01-kien-truc-he-thong.md) | Công nghệ chốt, sơ đồ C4 + Mermaid, cấu trúc module backend & Flutter, cơ chế FE↔BE (header, auth, WSS, cache 3 tầng), ERD + DDL + index, sơ đồ tuần tự UC-01/02/03, công thức ranking, **bảng truy vết FR → module → API**, hạ tầng | Trước khi code tính năng bất kỳ. Mục 8 là bảng trả lời "chức năng này call API gì" |
| [`02-api-dac-ta.md`](./02-api-dac-ta.md) | Hợp đồng API chung (quy tắc dữ liệu, DTO dùng chung, envelope lỗi, mã lỗi) + **input/output từng field** cho toàn bộ endpoint **P1** | Khi viết controller/DTO client. Mỗi endpoint có bảng field, ràng buộc, ví dụ curl + JSON, lỗi domain, backend xử lý mấy bước |
| [`03-api-p2-p3.md`](./03-api-p2-p3.md) | Endpoint **P2/P3** chi tiết: phòng nhóm (REST + WSS frame), journal & offline sync, cộng đồng/đánh giá/kiểm duyệt, ngữ cảnh, chủ quán, quảng cáo | Khi sang P2/P3. Đọc `02` §1 trước vì mọi quy ước dùng chung |
| [`04-kich-ban-test.md`](./04-kich-ban-test.md) | Chiến lược 6 tầng, fixture dữ liệu, **ma trận truy vết FR → TC**, ~400 test case có input/số đo kỳ vọng, test thuật toán bằng con số, test NFR (perf/chaos/security/privacy/a11y), catalog edge case, **§7.4 flow validation script chạy 10 phút** | Viết test song song với code. §7.4 dùng để nghiệm thu nhanh "luồng đã ổn chưa" |
| [`.ulpi/design/DESIGN.md`](../.ulpi/design/DESIGN.md) | **Design language đã chốt** cho app: hướng thẩm mỹ, palette OKLCH kèm số đo tương phản 25 cặp light+dark, type pairing có subset `vietnamese` đã verify, scale spacing/radius/shadow/motion, Signature "con dấu", voice + vốn từ hành động | Trước khi dựng bất kỳ màn nào. Mọi giá trị hình thái phải lấy từ file này |
| [`.ulpi/design/uc01-quay-den-chi-duong.md`](../.ulpi/design/uc01-quay-den-chi-duong.md) | Spec UX/UI cho UC-01 + UC-03: flow có đếm chạm, state machine, bảng error code → UI, 10 edge case, 8 component spec, **binding component → endpoint → field tiêu thụ**, acceptance criteria map vào TC của `04`, kết quả Pre-Flight gate | Khi build `app_flutter/`. Mục 5 là bảng đối chiếu input/output chống "app tự bịa field" |

## Thứ tự đọc để bắt đầu

1. `01` §1 (công nghệ) → §3 (thành phần) → §4 (FE↔BE) → **§8 (FR → API)**
2. `02` §1 (hợp đồng chung, DTO dùng chung) → endpoint của tính năng bạn sắp làm
3. `04` §2.2 (seed fixture) → §4.x (test case của tính năng đó) → §5 (test cắt ngang)

## Quy ước sửa tài liệu

- **Đổi một field**: sửa ở `02`/`03` trước, rồi kiểm tra `04` có TC nào assert field đó (`grep <tên_field> docs/`).
- **Đổi công thức ranking / hằng số** (τ, ngưỡng 30/45 phút, `m=20`, trọng số): sửa SRS → `01` §7 → `02` §5.1 (`/v1/config`) → `04` §6 (TC-BIZ-02/03) + golden file `TC-REG-01`. Không sửa một chỗ — đó là cách bug "app và server hiểu khác nhau" sinh ra.
- **Thêm tính năng**: thêm dòng vào bảng `01` §8 (traceability) **trước**, rồi mới viết endpoint + TC. Bảng đó là mục lục thật của hệ thống.
- Mã ID không bao giờ bị tái sử dụng. Bỏ tính năng ⇒ đánh dấu `DEPRECATED`, giữ ID.

## Việc cần chốt (đang chặn sprint 1)

| # | Quyết định | Xem thêm |
| --- | --- | --- |
| 1 | Thành phố khởi đầu + bounding box | `01` §10 |
| 2 | Hợp đồng/chi phí OSM + Google (quyết định TTL cache được phép) | `01` §4.8, `04` TC-PLC-08-A4 |
| 3 | Ai là người phê duyệt chính sách dữ liệu cá nhân (dị ứng = dữ liệu sức khoẻ) | `04` §8.4 |
| 4 | Chốt ngưỡng "cuối tháng", "món đa dạng", `hhi_index` để test được | `03` §2.6, `04` TC-JRN-04-A3 |
| 5 | Quy tắc match món→quán: chỉ dựa `place_dish` hay cho phép fuzzy tên | `04` TC-REC-01-A2 (đang ghi nhận: **chỉ** `place_dish`) |

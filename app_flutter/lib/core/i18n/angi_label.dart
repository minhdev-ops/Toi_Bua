import 'app_localizations.dart';

/// Nhãn UI **luôn** là hàm lấy từ ARB ⇒ không có đường nào truyền chuỗi thô vào widget
/// (NFR-11, TC-I18N-01). Muốn đổi chữ, thêm message mới vào `app_*.arb`, không thêm
/// constructor nhận `String`.
typedef AngiLabel = String Function(S s);

/// Nhãn có tham số (VD `Chờ {seconds}s`).
typedef AngiLabelArg<T> = String Function(S s, T value);

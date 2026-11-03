import 'package:intl/intl.dart';

import 'app_localizations.dart';

/// Format số **theo ARB**: ARB giữ đơn vị và dấu câu, file này chỉ quyết định đổi đơn vị
/// nào dùng mẫu nào (m/km, ★, ₫). Widget không tự nối chuỗi UI (NFR-11).
abstract final class AngiFormat {
  /// < 1 km ⇒ mét nguyên, ≥ 1 km ⇒ một chữ số thập phân.
  static String distance(S s, int meters) {
    if (meters < 1000) return s.distanceMeters(meters);
    return s.distanceKm(NumberFormat.decimalPattern(s.localeName).format(meters / 1000.0));
  }

  static String price(S s, int vnd) => s.priceVnd(NumberFormat.decimalPattern(s.localeName).format(vnd));

  /// `rating_bayesian` là số hiển thị (FR-REC-03); `rating_raw` chỉ đi vào hint.
  static String rating(S s, double value) => s.ratingValue(value.toStringAsFixed(1));

  static String ratingWithCount(S s, double value, int count) =>
      s.ratingWithCount(value.toStringAsFixed(1), count);

  static String rawRating(S s, double value) => s.rawRatingHint(value.toStringAsFixed(1));

  /// Giá trị tuyệt đối cho `score_total`/`contribution`: 2 số lẻ, bỏ số 0 thừa.
  static String score(double value) {
    final rounded = (value * 100).roundToDouble() / 100;
    return rounded == rounded.roundToDouble() ? rounded.toStringAsFixed(0) : rounded.toStringAsFixed(2);
  }

  /// `score_breakdown.weights` là fraction 0–1 ⇒ `%` nguyên cho caption.
  static String percent(double weight) => (weight * 100).round().toString();
}

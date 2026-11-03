import 'package:dio/dio.dart';

import '../i18n/app_localizations.dart';
import 'models/misc.dart';

/// Cách UI **must** render một lỗi. Ánh xạ 1-1 bảng "Error mapping" của spec UC-01.
enum ErrorSlot {
  /// lỗi đỏ `danger_text` tại field, focus field đầu trong `details[]`
  fieldInline,

  /// sheet liệt kê đúng ràng buộc thủ phạm (`details[].conflicting_with`)
  dietSheet,

  /// highlight 2 control xung đột
  contradictionSheet,

  /// `RelaxEmptyState` + `suggested_relaxations[]`
  relaxEmpty,

  /// ẩn `StampButton`, đếm ngược `retry_after_s`
  countdown,

  /// refresh âm thầm 1 lần; fail ⇒ sheet guest
  silentRefresh,

  /// màn giải thích + nút xin quyền
  consentScreen,

  /// "Không tìm thấy" + về Hub
  notFound,

  /// coi như thành công, đọc lại bản trả về
  replayAsSuccess,

  /// banner `warning_fill`, **vẫn render cache**
  providerBanner,

  /// empty + 2 CTA `Thử lại` / `Nhập địa chỉ`
  degradedEmpty,

  /// toast + thoát phòng (P2)
  roomToast,

  /// màn hình/panel chung
  generic,
}

/// Sánh `DioException` ra `ApiError` duy nhất. Không có nhánh nào ném chuỗi raw ra UI.
ApiError mapDioError(DioException error) {
  final response = error.response;
  final status = response?.statusCode ?? 0;
  final retryAfter = int.tryParse(response?.headers.value('Retry-After') ?? '');
  final data = response?.data;
  if (data is Map<String, dynamic> && data['error'] is Map<String, dynamic>) {
    return ApiError.fromJson(data, status, retryAfterHeader: retryAfter);
  }
  // Không có envelope (cổng, timeout, DNS chết) ⇒ vẫn một kiểu, retryable.
  return ApiError.transport(httpStatus: status, message: error.type.name, retryAfterHeader: retryAfter);
}

/// `code` + `message_key` → chuỗi ARB + slot hiển thị.
/// `error.message` của server **không** được dùng ở bất kỳ nhánh nào (TC-I18N-01).
class UiError {
  const UiError({required this.slot, required this.headline, this.retryAfterS, this.showRetry = false});

  final ErrorSlot slot;
  final String headline;
  final int? retryAfterS;
  final bool showRetry;
}

abstract final class ErrorMapper {
  static UiError toUi(S s, ApiError error) {
    // message_key của server chọn biến thể cụ thể; code chọn slot.
    final keyText = ServerErrorText.resolve(s, error.messageKey);
    final headline = keyText ?? fallbackText(s, error.code);

    switch (error.code) {
      case ErrorCode.validationFailed:
        return UiError(slot: ErrorSlot.fieldInline, headline: headline ?? s.errValidation);
      case ErrorCode.dietFilterEmpty:
        return UiError(slot: ErrorSlot.dietSheet, headline: headline ?? s.errDietEmptyPool);
      case ErrorCode.filterContradiction:
        return UiError(slot: ErrorSlot.contradictionSheet, headline: s.errFilterContradiction);
      case ErrorCode.poolTooSmall:
        return UiError(slot: ErrorSlot.relaxEmpty, headline: s.errPoolTooSmall, showRetry: true);
      case ErrorCode.rateLimited:
        return UiError(
          slot: ErrorSlot.countdown,
          headline: s.errRateLimited(error.retryAfterS ?? 30),
          retryAfterS: error.retryAfterS ?? 30,
        );
      case ErrorCode.unauthenticated:
      case ErrorCode.tokenExpired:
        return UiError(slot: ErrorSlot.silentRefresh, headline: s.errUnauthenticated);
      case ErrorCode.consentRequired:
      case ErrorCode.forbidden:
        return UiError(slot: ErrorSlot.consentScreen, headline: s.errConsentRequired);
      case ErrorCode.notFound:
        return UiError(slot: ErrorSlot.notFound, headline: s.errNotFound);
      case ErrorCode.dishNotFound:
        return UiError(slot: ErrorSlot.notFound, headline: s.errDishNotFound);
      case ErrorCode.gone:
        return UiError(slot: ErrorSlot.notFound, headline: s.errNotFound);
      case ErrorCode.idempotencyReplay:
      case ErrorCode.conflict:
        return UiError(slot: ErrorSlot.replayAsSuccess, headline: s.errIdempotencyReplay);
      case ErrorCode.reportAlreadyResolved:
        return UiError(slot: ErrorSlot.replayAsSuccess, headline: s.errReportDuplicate);
      case ErrorCode.reportLimit:
        return UiError(slot: ErrorSlot.generic, headline: s.errReportLimit);
      case ErrorCode.providerUnavailable:
        return UiError(slot: ErrorSlot.providerBanner, headline: s.errProviderUnavailable, showRetry: true);
      case ErrorCode.degradedNoResult:
        return UiError(slot: ErrorSlot.degradedEmpty, headline: s.errDegradedNoResult, showRetry: true);
      case ErrorCode.roomExpired:
        return UiError(slot: ErrorSlot.roomToast, headline: s.errRoomExpired);
      case ErrorCode.roomVersionStale:
        // docs/03 §5: client tự GET /v1/rooms/{id} rồi re-apply ý định → chỉ toast nhẹ.
        return UiError(slot: ErrorSlot.silentRefresh, headline: s.errRoomUpdated);
      case ErrorCode.outsideServiceArea:
        return UiError(slot: ErrorSlot.relaxEmpty, headline: s.errOutsideServiceArea, showRetry: true);
      case ErrorCode.locationRequired:
      case ErrorCode.locationNotAuthorized:
        return UiError(slot: ErrorSlot.consentScreen, headline: s.errLocationRequired);
      case ErrorCode.policyVersionOutdated:
        return UiError(slot: ErrorSlot.generic, headline: s.errUnknown, showRetry: true);
      case ErrorCode.serverError:
      case ErrorCode.unavailable:
        return UiError(
          slot: error.httpStatus == 0 ? ErrorSlot.degradedEmpty : ErrorSlot.generic,
          headline: headline ?? s.errDegradedNoResult,
          showRetry: true,
        );
    }
  }

  static String? fallbackText(S s, ErrorCode code) {
    switch (code) {
      case ErrorCode.validationFailed:
        return s.errValidation;
      case ErrorCode.dietFilterEmpty:
        return s.errDietEmptyPool;
      case ErrorCode.poolTooSmall:
        return s.errPoolTooSmall;
      case ErrorCode.rateLimited:
        return null;
      default:
        return s.errUnknown;
    }
  }
}

/// `err.*` mà server có thể trả trong `details[].message_key`.
abstract final class ServerErrorText {
  static String? resolve(S s, String? key) {
    switch (key) {
      case 'err.budget.too_low':
        return s.errBudgetTooLow;
      case 'err.diet.empty_pool':
        return s.errDietEmptyPool;
      case 'err.diet.conflict_with_type':
        return s.errDietConflictWithType;
      case 'err.pool.too_small':
        return s.errPoolTooSmall;
      case 'err.spin.rate_limited':
        return null;
      case 'err.future_date':
        return s.errFutureDate;
      default:
        return null;
    }
  }
}

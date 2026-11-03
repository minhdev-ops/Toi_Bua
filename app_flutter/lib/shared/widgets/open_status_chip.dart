import 'package:flutter/material.dart';

import '../../core/api/models/place.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/server_keys.dart';
import '../../core/theme/angi_icons.dart';
import '../../core/theme/angi_tokens.dart';
import 'stamp_badge.dart';

/// Tem trạng thái mở cửa (spec §4.5). App **không** tự tính ngưỡng: `closing_soon` và
/// `closes_in_min` là server gửi (`docs/02` §1.4), nên chip không cần `config.place`.
class OpenStatusChip extends StatelessWidget {
  const OpenStatusChip({required this.openStatus, super.key});

  /// `null` ⇒ ẩn chip, không đoán (docs/02: `open_status` là field bắt buộc, thiếu là lỗi dữ liệu).
  final OpenStatus? openStatus;

  @override
  Widget build(BuildContext context) {
    final status = openStatus;
    if (status == null) return const SizedBox.shrink();
    final s = S.of(context);
    final t = AngiTokens.of(context);

    if (status.isExceptionDay) {
      final note = ServerKeys.text(s, status.noteKey, const {}) ?? s.noteHoliday;
      return StampBadge(
        label: (_) => note,
        fill: t.warningFill,
        onFill: t.onFill,
        icon: AngiIcons.eventBusy,
      );
    }

    // docs/02 §1.4: `closing_soon=true` kéo theo `closes_in_min` có số. Mất số thì chỉ
    // còn nói "đang mở", app không được tự điền phút.
    if (status.closingSoon && status.closesInMin != null) {
      final minutes = status.closesInMin!;
      return StampBadge(
        label: (_) => s.badgeClosingSoon(minutes),
        fill: t.dangerFill,
        onFill: t.onFill,
        icon: AngiIcons.timerAlert,
      );
    }

    if (status.isOpen) {
      return StampBadge(label: (_) => s.badgeOpen, fill: t.successFill, onFill: t.onFill, icon: AngiIcons.scheduleOpen);
    }

    return StampBadge(
      label: (_) => s.badgeClosed,
      fill: t.surface,
      onFill: t.ink,
      outline: t.ink,
      icon: AngiIcons.storeOff,
    );
  }
}

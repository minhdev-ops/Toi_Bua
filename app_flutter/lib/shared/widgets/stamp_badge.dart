import 'package:flutter/material.dart';

import '../../core/i18n/angi_label.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/angi_icons.dart';
import '../../core/theme/angi_tokens.dart';

/// Tem dữ liệu: hình viên đạn nghiêng −6°, `stampLabel` 12/700 uppercase, **luôn** icon + chữ.
/// Mọi màu đi vào qua token của caller; component không tự chọn bảng màu.
class StampBadge extends StatelessWidget {
  const StampBadge({
    required this.label,
    required this.fill,
    required this.onFill,
    this.icon,
    this.outline,
    this.tilt = true,
    super.key,
  });

  final AngiLabel label;
  final Color fill;
  final Color onFill;
  final IconData? icon;

  /// Viền 2dp cho tem nền nhạt (`surface`, `sunken`) — bắt buộc để đạt AA.
  final Color? outline;
  final bool tilt;

  @override
  Widget build(BuildContext context) {
    final roles = AngiRoles.of(context);
    final text = Text(label(S.of(context)).toUpperCase(), style: roles.stampLabel.copyWith(color: onFill));

    final chip = Container(
      constraints: const BoxConstraints(minHeight: AngiScale.badgeVisualMin),
      padding: const EdgeInsets.symmetric(horizontal: AngiScale.s3, vertical: AngiScale.s1),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AngiScale.radiusSm),
        border: outline == null ? null : Border.all(color: outline!, width: AngiScale.outline),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: AngiIcons.sizeInline, color: onFill, weight: 600),
            const SizedBox(width: AngiScale.s2),
          ],
          Flexible(child: text),
        ],
      ),
    );

    if (!tilt) return chip;
    return Transform.rotate(angle: AngiScale.stampTilt, child: chip);
  }
}

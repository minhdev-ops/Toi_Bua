import 'package:flutter/material.dart';

import '../../core/i18n/angi_label.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/angi_icons.dart';
import '../../core/theme/angi_tokens.dart';

/// Tem bấm được: bước nới lỏng (`RelaxEmptyState`), khoá vòng quay (`locked.*`),
/// lựa chọn trong `FilterSheet`. Cao 48dp để đủ touch target (SRS mục 7).
class StampChip extends StatelessWidget {
  const StampChip({
    required this.label,
    this.onTap,
    this.selected = false,
    this.onRemove,
    this.hue,
    this.icon,
    super.key,
  });

  final AngiLabel label;
  final VoidCallback? onTap;
  final bool selected;

  /// != null ⇒ hiện × để bỏ (khoá, tag đã chọn).
  final VoidCallback? onRemove;

  /// Hue dữ liệu (màu `type` của món) — luôn kèm nhãn chữ, không bao giờ chỉ màu.
  final Color? hue;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final enabled = onTap != null || onRemove != null;
    final fill = selected ? (hue ?? t.accent) : t.surface;
    final onFill = selected ? (hue == null ? t.onAccent : t.onData) : t.ink;

    return Semantics(
      button: true,
      selected: selected,
      enabled: enabled,
      label: label(s),
      child: Ink(
        decoration: BoxDecoration(
          color: fill.withValues(alpha: enabled ? 1 : AngiScale.disabledOpacity),
          borderRadius: BorderRadius.circular(AngiScale.radiusSm),
          border: Border.all(color: t.ink, width: AngiScale.outline),
        ),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(AngiScale.radiusSm),
          child: ConstrainedBox(
            constraints: const BoxConstraints(minHeight: AngiScale.touchMin),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: AngiScale.s4, vertical: AngiScale.s2),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: AngiIcons.sizeInline, color: onFill, weight: 600),
                    const SizedBox(width: AngiScale.s2),
                  ],
                  Text(
                    label(s),
                    style: roles.label.copyWith(color: onFill),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (onRemove != null)
                    Semantics(
                      button: true,
                      label: s.ctaClose,
                      child: Ink(
                        color: Colors.transparent,
                        child: SizedBox(
                          width: AngiScale.touchMin,
                          height: AngiScale.touchMin,
                          child: InkWell(
                            onTap: onRemove,
                            child: Icon(AngiIcons.close, size: AngiIcons.size, color: t.ink),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

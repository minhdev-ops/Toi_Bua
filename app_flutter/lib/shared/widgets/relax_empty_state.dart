import 'package:flutter/material.dart';

import '../../core/api/models/dish.dart';
import '../../core/api/models/matches.dart';
import '../../core/i18n/angi_label.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/i18n/server_keys.dart';
import '../../core/theme/angi_icons.dart';
import '../../core/theme/angi_tokens.dart';
import 'stamp_badge.dart';
import 'stamp_button.dart';
import 'stamp_card.dart';
import 'stamp_chip.dart';

/// S10 — `POST /v1/matches` trả `items: []` **chứ không phải 404** (FR-REC-05):
/// màn phải chỉ ra cách nới, không chỉ báo hết. Primary action = bước relaxation
/// đầu tiên trong `steps_available`; các bước còn lại là chip phụ.
///
/// Cấm đặt nút "Quay lại" ở đây khi chưa có CTA nới — quay lại chỉ ra đúng quán cũ.
class RelaxEmptyState extends StatelessWidget {
  const RelaxEmptyState({
    required this.relaxation,
    required this.onRelax,
    this.substituteDishes = const [],
    this.headline,
    this.onRetry,
    this.onEnterAddress,
    super.key,
  });

  /// `relaxation` nguyên vẹn từ response — app không tự thêm bước nào.
  final Relaxation? relaxation;
  final List<SubstituteDish> substituteDishes;

  final ValueChanged<RelaxationStep> onRelax;

  /// `UiError.headline` khi màn do lỗi dựng (POOL_TOO_SMALL, OUTSIDE_SERVICE_AREA).
  final String? headline;

  /// Chỉ dùng khi server **không** gửi bước nới nào (DEGRADED_NO_RESULT).
  final VoidCallback? onRetry;
  final VoidCallback? onEnterAddress;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final roles = AngiRoles.of(context);
    final steps = relaxation?.stepsAvailable ?? const <RelaxationStep>[];

    return StampCard(
      padding: const EdgeInsets.all(AngiScale.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(headline ?? s.emptyMatchesHeadline, style: roles.title.copyWith(color: AngiTokens.of(context).ink)),
          const SizedBox(height: AngiScale.s2),
          Text(
            steps.isEmpty ? s.genericEmpty : s.emptyMatchesBody,
            style: roles.body.copyWith(color: AngiTokens.of(context).muted),
          ),
          if (steps.isNotEmpty) ...[
            const SizedBox(height: AngiScale.s6),
            StampButton(label: _stepAction(steps.first), onPressed: () => onRelax(steps.first)),
            if (steps.length > 1) ...[
              const SizedBox(height: AngiScale.s4),
              Wrap(
                spacing: AngiScale.s3,
                runSpacing: AngiScale.s3,
                children: [for (final step in steps.skip(1)) StampChip(label: _stepChip(step), icon: AngiIcons.chevronRight, onTap: () => onRelax(step))],
              ),
            ],
          ] else ...[
            if (onRetry != null || onEnterAddress != null) ...[
              const SizedBox(height: AngiScale.s6),
              Row(
                children: [
                  if (onRetry != null)
                    Expanded(child: StampButton(label: _retryLabel, primary: false, onPressed: onRetry)),
                  if (onRetry != null && onEnterAddress != null) const SizedBox(width: AngiScale.s4),
                  if (onEnterAddress != null)
                    Expanded(child: StampButton(label: _addressLabel, primary: false, onPressed: onEnterAddress)),
                ],
              ),
            ],
          ],
          ..._substitutes(context, s, roles),
        ],
      ),
    );
  }

  /// `substitute_dishes[]` chỉ có nghĩa khi `items.length == 0` (spec §4.7) — tối đa 2 tem.
  List<Widget> _substitutes(BuildContext context, S s, AngiRoles roles) {
    if (substituteDishes.isEmpty) return const [];
    final tokens = AngiTokens.of(context);
    return [
      const SizedBox(height: AngiScale.s7),
      Text(s.substituteHeading, style: roles.sectionLabel.copyWith(color: tokens.muted)),
      const SizedBox(height: AngiScale.s3),
      Wrap(
        spacing: AngiScale.s3,
        runSpacing: AngiScale.s3,
        children: [
          for (final dish in substituteDishes.take(2))
            StampBadge(
              label: (strings) => ServerKeys.text(strings, dish.reasonKey, const {}) ?? dish.name,
              fill: tokens.hue(TaxonomyTypeIndex.of(null, name: dish.name)),
              onFill: tokens.onData,
              icon: AngiIcons.chevronRight,
            ),
        ],
      ),
    ];
  }

  /// Lời giải thích cho hành động: `relax.radius` / `relax.price` / `relax.diet` server chọn,
  /// app chỉ render qua ARB. Key lạ ⇒ về `relaxStep`, không hiển thị chuỗi thô.
  static AngiLabel _stepAction(RelaxationStep step) {
    return (strings) {
      final why = ServerKeys.text(strings, step.whyKey, {'to': step.to});
      return why ?? strings.relaxStep(step.to, step.expectedExtra);
    };
  }

  /// Chip phụ mang **số** server dự đoán (`expected_extra`), không mang lời thoại.
  static AngiLabel _stepChip(RelaxationStep step) => (strings) => strings.relaxStep(step.to, step.expectedExtra);

  static String _retryLabel(S s) => s.ctaRetry;
  static String _addressLabel(S s) => s.ctaEnterAddress;
}

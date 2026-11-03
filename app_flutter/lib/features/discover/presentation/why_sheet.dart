import 'package:flutter/material.dart';

import '../../../core/api/models/score.dart';
import '../../../core/i18n/angi_format.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/server_keys.dart';
import '../../../core/theme/angi_icons.dart';
import '../../../core/theme/angi_motion.dart';
import '../../../core/theme/angi_tokens.dart';

/// S5. "Vì sao gợi ý quán này?" (FR-REC-02). Chỉ vẽ score_breakdown server gửi,
/// app không tính lại bất kỳ con số nào.
class WhySheet extends StatelessWidget {
  const WhySheet({required this.breakdown, super.key});

  final ScoreBreakdown breakdown;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final maxContribution = breakdown.components.fold<double>(
      1,
      (acc, c) => c.contribution > acc ? c.contribution : acc,
    );

    return Padding(
      padding: const EdgeInsets.fromLTRB(AngiScale.s6, 0, AngiScale.s6, AngiScale.s6),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: Text(s.whyTitle, style: roles.title.copyWith(color: t.ink))),
              IconButton(
                tooltip: s.ctaClose,
                icon: const Icon(AngiIcons.close),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ],
          ),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AngiFormat.score(breakdown.scoreTotal),
                style: roles.display.copyWith(color: t.ink),
              ),
              const SizedBox(width: AngiScale.s2),
              Padding(
                padding: const EdgeInsets.only(bottom: AngiScale.s2),
                child: Text(
                  s.whyFormulaVersion(breakdown.formulaVersion),
                  style: roles.micro.copyWith(color: t.subtle),
                ),
              ),
            ],
          ),
          const SizedBox(height: AngiScale.s2),
          Text(
            s.whyWeights(
              AngiFormat.percent(breakdown.weights['Q'] ?? 0),
              AngiFormat.percent(breakdown.weights['D'] ?? 0),
              AngiFormat.percent(breakdown.weights['P'] ?? 0),
              AngiFormat.percent(breakdown.weights['O'] ?? 0),
              AngiFormat.percent(breakdown.weights['U'] ?? 0),
            ),
            style: roles.label.copyWith(color: t.muted),
          ),
          const SizedBox(height: AngiScale.s5),
          const Divider(),
          const SizedBox(height: AngiScale.s3),
          for (var i = 0; i < breakdown.components.length; i++)
            _Bar(
              component: breakdown.components[i],
              index: i,
              maxContribution: maxContribution,
              highlight: breakdown.components[i].top && i < 2,
            ),
          if (breakdown.penalty != null && breakdown.penalty!.items.isNotEmpty) ...[
            const SizedBox(height: AngiScale.s4),
            Row(
              children: [
                Icon(AngiIcons.warning, size: AngiIcons.sizeInline, color: t.dangerText),
                const SizedBox(width: AngiScale.s2),
                Text(s.whyPenaltyTitle, style: roles.sectionLabel.copyWith(color: t.dangerText)),
              ],
            ),
            const SizedBox(height: AngiScale.s2),
            for (final item in breakdown.penalty!.items)
              Padding(
                padding: const EdgeInsets.only(bottom: AngiScale.s2),
                child: Text(
                  s.whyPenalty(
                    AngiFormat.score(item.value),
                    ServerKeys.penaltyReason(s, item.reason, {'days': item.days?.toString() ?? ''}) ?? item.reason,
                  ),
                  style: roles.body.copyWith(color: t.dangerText),
                ),
              ),
          ],
          const SizedBox(height: AngiScale.s2),
        ],
      ),
    );
  }
}

class _Bar extends StatefulWidget {
  const _Bar({
    required this.component,
    required this.index,
    required this.maxContribution,
    required this.highlight,
  });

  final ScoreComponent component;
  final int index;
  final double maxContribution;
  final bool highlight;

  @override
  State<_Bar> createState() => _BarState();
}

class _BarState extends State<_Bar> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: AngiScale.barGrow);
  late final Animation<double> _value = CurvedAnimation(parent: _controller, curve: AngiScale.curveStamp);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AngiMotion.of(context).animates) {
      Future<void>.delayed(AngiScale.staggerStep * widget.index, () {
        if (mounted) _controller.forward();
      });
    } else {
      _controller.value = 1;
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final component = widget.component;
    final why = ServerKeys.text(s, component.whyKey, component.whyParams);

    // Nhãn là tên tiêu chí server gửi (label), còn câu giải thích (why) xuống dưới
    // thanh: để nguyên một hàng thì cột nhãn chỉ còn ~90dp và bị cắt cụt.
    return Padding(
      padding: const EdgeInsets.only(bottom: AngiScale.s4),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Expanded(
                child: Text(
                  component.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: roles.label.copyWith(
                    color: widget.highlight ? t.ink : t.muted,
                    fontWeight: widget.highlight ? FontWeight.w700 : FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(width: AngiScale.s3),
              Text(
                s.whyContribution(component.contribution.toStringAsFixed(2)),
                style: roles.numeric.copyWith(
                  color: widget.highlight ? t.accentText : t.muted,
                  fontSize: 18,
                ),
              ),
            ],
          ),
          const SizedBox(height: AngiScale.s2),
          LayoutBuilder(
            builder: (context, constraints) {
              final ratio = (component.contribution / widget.maxContribution).clamp(0.0, 1.0);
              return AnimatedBuilder(
                animation: _value,
                builder: (context, _) => Container(
                  height: 12,
                  width: constraints.maxWidth * ratio * _value.value,
                  decoration: BoxDecoration(
                    color: widget.highlight ? t.accent : t.line,
                    borderRadius: BorderRadius.circular(AngiScale.radiusXs),
                    border: Border.all(color: t.ink, width: AngiScale.outline),
                  ),
                ),
              );
            },
          ),
          if (why != null) ...[
            const SizedBox(height: AngiScale.s1),
            Text(
              why,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: roles.micro.copyWith(color: t.muted),
            ),
          ],
        ],
      ),
    );
  }
}

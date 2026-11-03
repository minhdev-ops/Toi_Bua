import 'package:flutter/material.dart';

import '../../../core/api/models/dish.dart';
import '../../../core/api/models/place.dart';
import '../../../core/i18n/angi_format.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/angi_icons.dart';
import '../../../core/theme/angi_tokens.dart';
import '../../../shared/widgets/angi_thumb.dart';
import '../../../shared/widgets/open_status_chip.dart';
import '../../../shared/widgets/stamp_badge.dart';

/// Một hàng trong bảng menu kết quả (spec §4.3).
///
/// Props mang tên field API gốc (place, rank) để contract test so được với docs/02.
/// Thứ tự hàng là thứ tự server trả: screen này cấm sort lại.
class ResultRow extends StatelessWidget {
  const ResultRow({
    required this.place,
    required this.rank,
    required this.onOpen,
    this.showWhy = true,
    this.onWhy,
    super.key,
  });

  final Place place;

  /// 1-based, đúng vị trí trong items[].
  final int rank;

  final VoidCallback onOpen;
  final bool showWhy;
  final VoidCallback? onWhy;

  /// Hạng 1 cao 1.4 lần (spec §4.3).
  static double heightFor(int rank) =>
      rank == 1 ? AngiScale.rowMinH * AngiScale.rankOneScale : AngiScale.rowMinH;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final first = rank == 1;
    final hue = t.hue(TaxonomyTypeIndex.of(null, name: place.highlightTypeSeed ?? place.name));

    final content = Padding(
      padding: EdgeInsets.fromLTRB(
        AngiScale.s5 + (first ? 6 : 0),
        first ? AngiScale.s4 : AngiScale.s3,
        AngiScale.s3,
        first ? AngiScale.s4 : AngiScale.s3,
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '$rank',
              style: roles.numeric.copyWith(
                color: first ? t.ink : t.subtle,
                fontSize: first ? 34 : 24,
              ),
            ),
          ),
          AngiThumb(
            name: place.name,
            hue: hue,
            imageUrl: place.images.isEmpty ? null : place.images.first.url,
            size: first ? 56 : 46,
          ),
          const SizedBox(width: AngiScale.s3),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  place.name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: (first ? roles.title : roles.body).copyWith(
                    color: t.ink,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: AngiScale.s1),
                Text(
                  place.cuisineTags.take(2).join(' · '),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: roles.micro.copyWith(color: t.muted),
                ),
                const SizedBox(height: AngiScale.s2),
                Wrap(
                  spacing: AngiScale.s2,
                  runSpacing: AngiScale.s2,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    if (first)
                      StampBadge(
                        label: (strings) => strings.badgeBestMatch,
                        fill: t.accent,
                        onFill: t.onAccent,
                        icon: AngiIcons.bestMatch,
                      ),
                    OpenStatusChip(openStatus: place.openStatus),
                    _rating(context, s, t, roles),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: AngiScale.s1),
          Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                AngiFormat.distance(s, place.distanceM),
                style: roles.numeric.copyWith(color: t.ink, fontSize: first ? 26 : 20),
              ),
              const SizedBox(height: AngiScale.s1),
              Text(
                AngiFormat.price(s, place.avgPriceVnd),
                style: roles.micro.copyWith(color: t.muted),
              ),
              if (showWhy && onWhy != null)
                Semantics(
                  button: true,
                  label: s.ctaWhy,
                  child: InkWell(
                    onTap: onWhy,
                    borderRadius: BorderRadius.circular(AngiScale.radiusXs),
                    child: ConstrainedBox(
                      constraints: const BoxConstraints(minHeight: AngiScale.touchMin, minWidth: AngiScale.touchMin),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        mainAxisAlignment: MainAxisAlignment.end,
                        children: [
                          Icon(AngiIcons.why, size: 16, color: t.infoText),
                          const SizedBox(width: AngiScale.s1),
                          Text(s.whyShort, style: roles.micro.copyWith(color: t.infoText)),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );

    return ConstrainedBox(
      constraints: BoxConstraints(minHeight: heightFor(rank)),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: first ? t.surface : Colors.transparent,
          border: Border(
            bottom: BorderSide(color: t.line, width: AngiScale.divider),
            left: first ? BorderSide(color: t.accent, width: 6) : BorderSide.none,
          ),
        ),
        child: Semantics(
          button: true,
          label: s.semRowLabel(
            place.name,
            place.distanceM,
            place.ratingBayesian.toStringAsFixed(1),
            _openState(s),
          ),
          child: InkWell(onTap: onOpen, child: content),
        ),
      ),
    );
  }

  Widget _rating(BuildContext context, S s, AngiTokens t, AngiRoles roles) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(AngiIcons.star, size: 14, color: t.accentText),
        const SizedBox(width: 2),
        Text(
          s.ratingWithCount(place.ratingBayesian.toStringAsFixed(1), place.reviewCount),
          style: roles.micro.copyWith(color: t.muted),
        ),
      ],
    );
  }

  String _openState(S s) {
    final status = place.openStatus;
    if (status == null) return '';
    if (status.closingSoon) return s.semClosingSoon;
    return status.isOpen ? s.semOpen : s.semClosed;
  }
}

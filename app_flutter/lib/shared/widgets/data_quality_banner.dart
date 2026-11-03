import 'package:flutter/material.dart';

import '../../core/api/models/data_quality.dart';
import '../../core/api/models/meta.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/angi_icons.dart';
import '../../core/theme/angi_motion.dart';
import '../../core/theme/angi_tokens.dart';

/// "Một lần / session / kiểu" (spec §4.6): đã hiện `stale` thì không hiện lại `stale`
/// nữa trong cùng lần mở app, kể cả khi response sau vẫn stale.
abstract final class DataQualityBannerPolicy {
  static final Set<DataQuality> _shown = {};

  static bool shouldShow(DataQuality quality) =>
      quality != DataQuality.fresh && !_shown.contains(quality);

  static void markShown(DataQuality quality) => _shown.add(quality);

  @visibleForTesting
  static void reset() => _shown.clear();
}

/// Banner chất lượng dữ liệu (FR-PLC-08, NFR-06). Nhận `meta` đã merge header
/// `X-Data-Quality`, không nhận prop rời riêng.
class DataQualityBanner extends StatefulWidget {
  const DataQualityBanner({required this.meta, this.onDismiss, super.key});

  final ResponseMeta meta;
  final VoidCallback? onDismiss;

  @override
  State<DataQualityBanner> createState() => _DataQualityBannerState();
}

class _DataQualityBannerState extends State<DataQualityBanner> {
  bool _dismissed = false;

  @override
  void initState() {
    super.initState();
    DataQualityBannerPolicy.markShown(widget.meta.dataQuality);
  }

  @override
  void didUpdateWidget(DataQualityBanner oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.meta.dataQuality != widget.meta.dataQuality) {
      DataQualityBannerPolicy.markShown(widget.meta.dataQuality);
    }
  }

  @override
  Widget build(BuildContext context) {
    final quality = widget.meta.dataQuality;
    if (_dismissed || quality == DataQuality.fresh) return const SizedBox.shrink();

    final s = S.of(context);
    final t = AngiTokens.of(context);
    final motion = AngiMotion.of(context);

    final String text;
    final Color fill;
    final Color onFill;
    Color? outline;
    final IconData icon;

    switch (quality) {
      case DataQuality.fresh:
        return const SizedBox.shrink();
      case DataQuality.cached:
        final age = widget.meta.cacheAgeS;
        text = age == null ? s.badgeCachedData : s.dqCached(age);
        fill = t.infoFill;
        onFill = t.onFill;
        icon = AngiIcons.cached;
      case DataQuality.stale:
        text = s.dqStale;
        fill = t.warningFill;
        onFill = t.onFill;
        icon = AngiIcons.stale;
      case DataQuality.providerDegraded:
        final providers = widget.meta.providersUsed;
        text = providers.isEmpty ? s.errProviderUnavailable : s.dqProviderDegraded(providers.join(' + '));
        fill = t.warningFill;
        onFill = t.onFill;
        icon = AngiIcons.offline;
      case DataQuality.offlineBundle:
        text = s.dqOfflineBundle;
        fill = t.surface;
        onFill = t.ink;
        outline = t.ink;
        icon = AngiIcons.offline;
    }

    final banner = Container(
      margin: const EdgeInsets.symmetric(horizontal: AngiScale.s5, vertical: AngiScale.s3),
      padding: const EdgeInsets.symmetric(horizontal: AngiScale.s4, vertical: AngiScale.s3),
      decoration: BoxDecoration(
        color: fill,
        borderRadius: BorderRadius.circular(AngiScale.radiusSm),
        border: outline == null ? null : Border.all(color: outline, width: AngiScale.outline),
      ),
      child: Row(
        children: [
          Icon(icon, size: AngiIcons.sizeInline, color: onFill, weight: 600),
          const SizedBox(width: AngiScale.s3),
          Expanded(
            child: Text(
              text,
              style: AngiRoles.of(context).label.copyWith(color: onFill),
            ),
          ),
          Semantics(
            button: true,
            label: s.ctaClose,
            child: InkWell(
              onTap: () {
                setState(() => _dismissed = true);
                widget.onDismiss?.call();
              },
              customBorder: const CircleBorder(),
              child: SizedBox(
                width: AngiScale.touchMin,
                height: AngiScale.touchMin,
                child: Center(child: Icon(AngiIcons.close, size: AngiIcons.size, color: onFill)),
              ),
            ),
          ),
        ],
      ),
    );

    // Trượt xuống đúng 1 lần, không lặp (spec §4.6); reduce-motion ⇒ hiện tức thì.
    if (motion.reduceMotion) return banner;
    return TweenAnimationBuilder<double>(
      key: ValueKey(quality),
      tween: Tween(begin: 0, end: 1),
      duration: AngiScale.base,
      curve: AngiScale.curveStamp,
      builder: (_, value, child) => ClipRect(
        child: Align(alignment: Alignment.topCenter, heightFactor: value, child: child),
      ),
      child: banner,
    );
  }
}

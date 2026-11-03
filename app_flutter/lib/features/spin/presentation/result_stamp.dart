import 'package:flutter/material.dart';

import '../../../core/api/models/dish.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/angi_motion.dart';
import '../../../core/theme/angi_tokens.dart';
import '../../../shared/widgets/angi_thumb.dart';
import '../../../shared/widgets/stamp_card.dart';

/// Tem kết quả quay — vật thể nổi duy nhất của màn Hub (S2).
///
/// Tiêu điểm của "khoảnh khắc được dàn dựng": tem bay từ tâm ra theo `emphasis`,
/// và là nơi screen reader đọc **"Hôm nay: (tên món)"** (spec §Accessibility).
class ResultStamp extends StatelessWidget {
  const ResultStamp({required this.dish, this.maxSize = 260, super.key});

  /// `dish` của `POST /v1/spins` — tên theo locale, `type` suy từ taxonomy.
  final Dish dish;
  final double maxSize;

  @override
  Widget build(BuildContext context) {
    final tokens = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final strings = S.of(context);
    final motion = AngiMotion.of(context);
    final hue = tokens.hue(dish.type);
    final label = strings.resultToday(dish.displayLabel);

    final card = StampCard(
      fill: hue,
      padding: const EdgeInsets.all(AngiScale.s6),
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxSize, maxHeight: maxSize),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AngiThumb(name: dish.displayLabel, hue: hue, imageUrl: dish.imageUrl, size: maxSize * 0.34),
            const SizedBox(height: AngiScale.s5),
            Text(
              dish.displayLabel,
              textAlign: TextAlign.center,
              style: roles.display.copyWith(color: tokens.onData),
            ),
            if (dish.categoryPath.isNotEmpty) ...[
              const SizedBox(height: AngiScale.s2),
              Text(
                dish.categoryPath.join(' · '),
                textAlign: TextAlign.center,
                style: roles.micro.copyWith(color: tokens.onData),
              ),
            ],
          ],
        ),
      ),
    );

    // liveRegion: kết quả công bố ngay khi wheel khoá, không bắt user nhìn vòng quay.
    final announced = Semantics(liveRegion: true, label: label, child: card);

    if (!motion.animates) return announced;
    return _FlyFromCenter(child: announced);
  }
}

/// Bay từ tâm + scale 0.6 → 1, `curveStamp`; không fade (DESIGN.md §Motion).
class _FlyFromCenter extends StatefulWidget {
  const _FlyFromCenter({required this.child});

  final Widget child;

  @override
  State<_FlyFromCenter> createState() => _FlyFromCenterState();
}

class _FlyFromCenterState extends State<_FlyFromCenter> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: AngiScale.emphasis)..forward();
  late final Animation<double> _scale = CurvedAnimation(parent: _controller, curve: AngiScale.curveStamp);

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _scale,
      builder: (context, child) {
        final t = _scale.value;
        return Transform.translate(offset: Offset(0, (1 - t) * 24), child: Transform.scale(scale: 0.6 + 0.4 * t, child: child));
      },
      child: widget.child,
    );
  }
}

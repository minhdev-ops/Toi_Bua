import 'package:flutter/material.dart';

import '../../core/theme/angi_motion.dart';
import '../../core/theme/angi_tokens.dart';

/// Skeleton khi chờ `POST /v1/matches`: 2 mức rời rạc `sunken`↔`surface`, không blur mềm
/// (spec UC-01 §Flow). reduce-motion ⇒ khối tĩnh, **0 controller chạy** (test đếm được).
class SkeletonRow extends StatefulWidget {
  const SkeletonRow({this.height = AngiScale.rowMinH, super.key});

  final double height;

  @override
  State<SkeletonRow> createState() => _SkeletonRowState();
}

class _SkeletonRowState extends State<SkeletonRow> with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(vsync: this, duration: AngiScale.emphasis);

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (AngiMotion.of(context).animates) {
      if (!_controller.isAnimating) _controller.repeat();
    } else if (_controller.isAnimating) {
      _controller.stop();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final t = AngiTokens.of(context);
    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final low = _controller.value < 0.5;
        Color block() => low ? t.sunken : t.surface;
        Widget bar(double width, double height, {double radius = AngiScale.radiusXs}) => Padding(
              padding: const EdgeInsets.only(right: AngiScale.s3),
              child: Container(
                width: width,
                height: height,
                decoration: BoxDecoration(color: block(), borderRadius: BorderRadius.circular(radius)),
              ),
            );

        return SizedBox(
          height: widget.height,
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: AngiScale.s3),
            child: Row(
              children: [
                bar(44, 44, radius: AngiScale.radiusSm),
                const SizedBox(width: AngiScale.s4),
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [bar(160, 14), bar(96, 12)])),
                bar(56, 20, radius: AngiScale.radiusPill),
              ],
            ),
          ),
        );
      },
    );
  }
}

/// 3 row cho matches, 1 card cho Đói gấp (spec: tránh hint "sẽ có 3 cái").
class SkeletonList extends StatelessWidget {
  const SkeletonList({this.rows = 3, super.key});

  final int rows;

  @override
  Widget build(BuildContext context) => Column(children: [for (var i = 0; i < rows; i++) const SkeletonRow()]);
}

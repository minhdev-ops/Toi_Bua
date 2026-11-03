import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/angi_tokens.dart';
import 'wheel_spinner.dart';

/// `animation.style == draw`: 3 lá bài rút lần lượt, **lá cuối là kết quả**.
/// Bộ ba lấy từ `wheel_items` quanh `result_index` ⇒ không có lựa chọn nào phía app.
class DrawFace extends StatelessWidget {
  const DrawFace({required this.segments, required this.resultIndex, required this.progress, super.key});

  final List<WheelSegment> segments;
  final int resultIndex;
  final double progress;

  static const double _cardW = 104;
  static const double _cardH = 140;
  static const double _step = 0.22;

  @override
  Widget build(BuildContext context) {
    final n = segments.length;
    final cards = [for (final offset in [-2, -1, 0]) segments[(resultIndex + offset) % n]];

    return Center(
      child: SizedBox(
        width: _cardW * 3 + AngiScale.s5 * 2,
        height: _cardH + AngiScale.s5,
        child: Stack(
          alignment: Alignment.bottomCenter,
          children: [
            for (var i = 0; i < cards.length; i++)
              _card(context, i, cards[i], math.min(1, math.max(0, (progress - i * _step) / (1 - 2 * _step)))),
          ],
        ),
      ),
    );
  }

  Widget _card(BuildContext context, int index, WheelSegment segment, double t) {
    final tokens = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final isResult = index == 2;
    final lifted = AngiScale.curveStamp.transform(t);

    return Align(
      alignment: Alignment(-1 + index * 1.0, 0),
      child: Transform.translate(
        offset: Offset(0, (1 - lifted) * (_cardH + AngiScale.s6)),
        child: Transform.rotate(
          angle: (1 - lifted) * 0.12 * (index - 1),
          child: Container(
            width: _cardW,
            height: _cardH,
            decoration: BoxDecoration(
              color: tokens.surface,
              borderRadius: BorderRadius.circular(AngiScale.radiusMd),
              border: Border.all(color: tokens.ink, width: AngiScale.outline),
              boxShadow: [
                // Chỉ lá kết quả mang bóng — dấu ấn của khoảnh khắc, không phải trang trí.
                if (isResult)
                  BoxShadow(color: tokens.ink, offset: const Offset(0, AngiScale.stamp2), blurRadius: AngiScale.shadowBlur),
              ],
            ),
            child: Column(
              children: [
                Container(
                  height: 10,
                  decoration: BoxDecoration(
                    color: tokens.hue(segment.type),
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(AngiScale.radiusXs)),
                  ),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(AngiScale.s3),
                    child: Center(
                      child: Text(
                        segment.label,
                        maxLines: 3,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: (isResult ? roles.label : roles.body).copyWith(color: tokens.ink),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

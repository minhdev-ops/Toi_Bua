import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/angi_tokens.dart';
import 'wheel_spinner.dart';

/// `animation.style == chest`: capsule lật **một lần** rồi mở — kết quả vẫn là
/// `result_index`, chỉ khác cách đưa nó ra trước mắt user (FR-ROU-08).
class ChestFace extends StatelessWidget {
  const ChestFace({required this.segments, required this.resultIndex, required this.progress, super.key});

  final List<WheelSegment> segments;
  final int resultIndex;

  /// 0 → 1 theo `animation.duration_ms`; `1` khi reduce-motion (render tức thì).
  final double progress;

  static const double _flipEnd = 0.55;

  @override
  Widget build(BuildContext context) {
    final tokens = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final result = segments[resultIndex.clamp(0, segments.length - 1)];

    final flip = const Cubic(0.05, 0, 0.25, 1).transform(math.min(1, progress / _flipEnd));
    final open = progress <= _flipEnd ? 0.0 : AngiScale.curveStamp.transform((progress - _flipEnd) / (1 - _flipEnd));

    final body = Container(
      decoration: BoxDecoration(
        color: tokens.hue(result.type),
        borderRadius: BorderRadius.circular(AngiScale.radiusMd),
        border: Border.all(color: tokens.ink, width: AngiScale.outline),
        boxShadow: [BoxShadow(color: tokens.ink, offset: const Offset(0, AngiScale.stamp2), blurRadius: AngiScale.shadowBlur)],
      ),
      alignment: Alignment.center,
      padding: const EdgeInsets.all(AngiScale.s4),
      child: Text(
        result.label,
        maxLines: 2,
        overflow: TextOverflow.ellipsis,
        textAlign: TextAlign.center,
        style: roles.title.copyWith(color: tokens.onData),
      ),
    );

    final lid = Container(
      decoration: BoxDecoration(
        color: tokens.accent,
        borderRadius: BorderRadius.circular(AngiScale.radiusMd),
        border: Border.all(color: tokens.ink, width: AngiScale.outline),
      ),
    );

    return Center(
      child: SizedBox(
        width: 200,
        height: 132,
        child: Transform(
          alignment: Alignment.center,
          // Lật một lần quanh trục ngang, có phối cảnh để thấy là vật thể thật.
          transform: Matrix4.identity()
            ..setEntry(3, 2, 0.0025)
            ..rotateX(flip * math.pi),
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              Positioned.fill(child: body),
              Positioned(
                left: 0,
                right: 0,
                top: -open * 84,
                height: 66,
                child: Transform.rotate(
                  angle: -open * 0.35,
                  child: lid,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

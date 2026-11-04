import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../core/theme/angi_tokens.dart';
import 'wheel_spinner.dart';

/// Mặt vòng quay: 8 hue dữ liệu tô theo type của món, viền mực 2dp, con trỏ accent.
/// Widget thuần hình học, mọi góc đến từ WheelSpinner (nơi giữ bất biến FR-ROU-07).
class WheelFace extends StatelessWidget {
  const WheelFace({
    required this.segments,
    required this.slotAngle,
    required this.rotation,
    this.rotationAnimation,
    this.showLabels = true,
    super.key,
  });

  final List<WheelSegment> segments;

  /// 2π / wheel_items.length. Ô tính theo tâm, nên con trỏ ở đỉnh chỉ đúng
  /// result_index khi target_position % n == result_index.
  final double slotAngle;

  /// Góc tĩnh. Dùng khi không truyền [rotationAnimation].
  final double rotation;

  /// Góc động. Khi có, phần đĩa + nhãn được dựng **một lần** và chỉ đổi ma trận
  /// xoay ở tầng paint; 8 nhãn không bị layout lại 60 lần/giây.
  final Animation<double>? rotationAnimation;

  final bool showLabels;

  static const double _labelRadiusFactor = 0.64;

  @override
  Widget build(BuildContext context) {
    final tokens = AngiTokens.of(context);
    final roles = AngiRoles.of(context);

    return LayoutBuilder(
      builder: (context, constraints) {
        final side = math.min(
          constraints.maxWidth.isFinite ? constraints.maxWidth : 300.0,
          constraints.maxHeight.isFinite ? constraints.maxHeight : 300.0,
        );
        final radius = side / 2 - AngiScale.outline * 2;
        // Nhãn phải nằm trong cung của ô: cung rộng = bán kính × góc ô. Lấy 56% để
        // còn khe giữa hai nhãn kề nhau, và hạ cỡ chữ theo bán kính (vòng 340dp ⇒ 14px).
        final labelWidth = (radius * _labelRadiusFactor * slotAngle * 0.95).clamp(56.0, 96.0);
        final labelSize = (radius * 0.085).clamp(11.0, 15.0);

        final disc = SizedBox(
          width: side,
          height: side,
          child: Stack(
            alignment: Alignment.center,
            clipBehavior: Clip.none,
            children: [
              CustomPaint(
                size: Size(side, side),
                painter: _WheelPainter(
                  segments: segments,
                  slotAngle: slotAngle,
                  radius: radius,
                  tokens: tokens,
                ),
              ),
              if (showLabels)
                for (var i = 0; i < segments.length; i++)
                  _label(i, segments[i], roles, tokens, radius, labelWidth, labelSize),
            ],
          ),
        );

        final animation = rotationAnimation;
        final Widget rotating = animation == null
            ? Transform.rotate(angle: rotation, child: RepaintBoundary(child: disc))
            : AnimatedBuilder(
                animation: animation,
                // child dựng một lần: mỗi frame chỉ có Transform.rotate được tạo lại.
                child: RepaintBoundary(child: disc),
                builder: (_, child) => Transform.rotate(angle: animation.value, child: child),
              );

        return SizedBox(
          width: side,
          height: side,
          child: Stack(
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            children: [
              rotating,
              // Trục bánh: một vòng tròn surface, không thêm màu mới.
              Container(
                width: side * 0.16,
                height: side * 0.16,
                decoration: BoxDecoration(
                  color: tokens.surface,
                  shape: BoxShape.circle,
                  border: Border.all(color: tokens.ink, width: AngiScale.outline),
                ),
                child: Center(
                  child: Container(
                    width: side * 0.05,
                    height: side * 0.05,
                    decoration: BoxDecoration(color: tokens.accent, shape: BoxShape.circle),
                  ),
                ),
              ),
              Positioned(
                top: -AngiScale.s1,
                child: CustomPaint(
                  size: const Size(34, 26),
                  painter: _PointerPainter(fill: tokens.accent, ink: tokens.ink),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _label(
    int index,
    WheelSegment segment,
    AngiRoles roles,
    AngiTokens tokens,
    double radius,
    double width,
    double fontSize,
  ) {
    final mid = index * slotAngle;
    // Nửa dưới vòng: để nguyên thì chữ ngược, nên xoay khung lại π và đặt nhãn ở đáy.
    final flipped = mid > math.pi / 2 && mid < 3 * math.pi / 2;
    final frameAngle = flipped ? mid - math.pi : mid;
    final y = (flipped ? 1.0 : -1.0) * _labelRadiusFactor;

    return Transform.rotate(
      angle: frameAngle,
      child: SizedBox(
        width: radius * 2,
        height: radius * 2,
        child: Align(
          alignment: Alignment(0, y),
          child: SizedBox(
            width: width,
            child: Text(
              segment.label,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: roles.wheelLabel.copyWith(
                color: tokens.onData,
                fontSize: fontSize,
                height: 1.05,
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _WheelPainter extends CustomPainter {
  const _WheelPainter({
    required this.segments,
    required this.slotAngle,
    required this.radius,
    required this.tokens,
  });

  final List<WheelSegment> segments;
  final double slotAngle;
  final double radius;
  final AngiTokens tokens;

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final disc = Rect.fromCircle(center: center, radius: radius);
    final fill = Paint();
    final ink = Paint()
      ..color = tokens.ink
      ..style = PaintingStyle.stroke
      ..strokeWidth = AngiScale.outline;

    for (var i = 0; i < segments.length; i++) {
      final start = -math.pi / 2 + i * slotAngle - slotAngle / 2;
      fill.color = tokens.hue(segments[i].type);
      canvas.drawArc(disc, start, slotAngle, true, fill);
      canvas.drawLine(
        center,
        Offset(center.dx + math.cos(start) * radius, center.dy + math.sin(start) * radius),
        ink,
      );
    }
    canvas.drawCircle(center, radius, ink);
  }

  @override
  bool shouldRepaint(_WheelPainter old) =>
      old.slotAngle != slotAngle ||
      old.radius != radius ||
      !identical(old.tokens, tokens) ||
      !_sameSegments(old.segments, segments);

  /// So cả type: hai lượt quay có cùng số ô nhưng món khác nhau vẫn phải vẽ lại
  /// hue, nếu chỉ so length thì đĩa giữ màu của lượt trước.
  static bool _sameSegments(List<WheelSegment> a, List<WheelSegment> b) {
    if (a.length != b.length) return false;
    for (var i = 0; i < a.length; i++) {
      if (a[i].id != b[i].id || a[i].type != b[i].type || a[i].label != b[i].label) return false;
    }
    return true;
  }
}

class _PointerPainter extends CustomPainter {
  const _PointerPainter({required this.fill, required this.ink});

  final Color fill;
  final Color ink;

  @override
  void paint(Canvas canvas, Size size) {
    final tip = Path()
      ..moveTo(0, 0)
      ..lineTo(size.width, 0)
      ..lineTo(size.width / 2, size.height)
      ..close();
    canvas.drawPath(tip, Paint()..color = fill);
    canvas.drawPath(
      tip,
      Paint()
        ..color = ink
        ..style = PaintingStyle.stroke
        ..strokeWidth = AngiScale.outline
        ..strokeJoin = StrokeJoin.miter,
    );
  }

  @override
  bool shouldRepaint(_PointerPainter old) => old.fill != fill || old.ink != ink;
}

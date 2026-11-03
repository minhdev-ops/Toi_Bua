import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/api/models/spin.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/angi_motion.dart';
import '../../../core/theme/angi_tokens.dart';
import 'chest_face.dart';
import 'draw_face.dart';
import 'wheel_face.dart';

/// Một ô trên vòng quay. `animation.wheel_items[]` chỉ chứa `dish_id` ⇒ tên và hue
/// phải resolve qua bundle đã cache (docs/02 §3.2); renderer không tự bịa nhãn.
class WheelSegment {
  const WheelSegment({required this.id, required this.label, this.type});

  final String id;
  final String label;
  final DishType? type;
}

typedef WheelSegmentResolver = WheelSegment Function(String dishId);

/// `WheelSpinner` — chữ ký của app (spec §4.2), 3 kiểu theo `animation.style`.
///
/// Kết quả **đã chốt server-side** trước khi widget tồn tại (FR-ROU-07): ở đây chỉ có
/// hình học dừng đúng `target_position`, không có ngẫu nhiên nào phía app.
class WheelSpinner extends StatefulWidget {
  const WheelSpinner({
    required this.items,
    required this.resultIndex,
    required this.targetPosition,
    required this.durationMs,
    required this.style,
    required this.reduceMotion,
    required this.sound,
    required this.haptics,
    required this.resolve,
    required this.onSettled,
    this.size = 300,
    super.key,
  });

  /// `animation.wheel_items` — giữ nguyên thứ tự và độ dài server trả.
  final List<String> items;

  /// `animation.result_index` / `animation.target_position`. Cấm sửa (TC-ROU-07).
  final int resultIndex;
  final int targetPosition;

  /// `animation.duration_ms` — không có mặc định phía app, chỉ clamp trần.
  final int durationMs;
  final WheelStyle style;
  final bool reduceMotion;

  /// Hai cờ độc lập, từ `animation.sound` / `animation.haptics` (DESIGN.md §Motion).
  final bool sound;
  final bool haptics;

  final WheelSegmentResolver resolve;

  /// Gọi **đúng một lần** khi vòng đã dừng (hoặc ngay khi mount nếu reduce-motion).
  final VoidCallback onSettled;

  final double size;

  @override
  State<WheelSpinner> createState() => _WheelSpinnerState();
}

class _WheelSpinnerState extends State<WheelSpinner> with SingleTickerProviderStateMixin {
  AnimationController? _controller;
  AngiMotion? _motion;
  bool _settled = false;

  /// Vòng tối thiểu trước khi đáp: `target_position` có thể chỉ hơn `result_index` vài ô.
  /// Cộng thêm nguyên vòng không đổi ô đích vì `n * slotAngle = 2π` — bất biến FR-ROU-07
  /// vẫn đúng, nên đây là chuyện trình diễn, không phải chuyện kết quả.
  static const int _minTurns = 5;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final motion = AngiMotion.of(context);
    final wasAnimated = _motion?.animates ?? true;
    _motion = motion;
    if (!motion.animates || widget.reduceMotion) {
      _stopAndFinish();
      return;
    }
    if (_controller != null && !wasAnimated) _disposeController();
    _sync();
  }

  @override
  void didUpdateWidget(WheelSpinner oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Lượt quay mới ⇒ góc đích khác ⇒ dựng lại từ đầu; cùng một lượt thì giữ controller.
    if (oldWidget.targetPosition != widget.targetPosition || oldWidget.items.length != widget.items.length) {
      _disposeController();
      _settled = false;
      _sync();
    }
  }

  @override
  void dispose() {
    _disposeController();
    super.dispose();
  }

  Duration _spinDuration() {
    final motion = _motion;
    if (widget.reduceMotion || motion == null || !motion.animates) return Duration.zero;
    return motion.wheelDuration(widget.durationMs);
  }

  void _sync() {
    if (_settled || _controller != null) return;
    final spin = _spinDuration();
    if (spin == Duration.zero) {
      _stopAndFinish();
      return;
    }
    _controller = AnimationController(vsync: this, duration: spin + AngiScale.wheelSettle)
      ..addStatusListener(_onStatus);
    _controller!.forward();
  }

  void _onStatus(AnimationStatus status) {
    if (status != AnimationStatus.completed) return;
    _disposeController();
    _announce();
  }

  /// Reduce-motion ⇒ không renderer nào chạy: kết quả ở tư thế dừng ngay tức thì.
  void _stopAndFinish() {
    if (_settled) return;
    _disposeController();
    _announce();
  }

  void _announce() {
    if (_settled) return;
    _settled = true;
    final motion = _motion;
    if (widget.haptics && (motion?.haptics ?? true)) HapticFeedback.mediumImpact();
    if (widget.sound && (motion?.sound ?? true)) SystemSound.play(SystemSoundType.click);
    // onSettled gọi ở frame kế tiếp: notifier đổi state giữa lúc build là hợp lệ nhưng
    // không được làm hỏng cây widget đang dựng.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) widget.onSettled();
    });
  }

  void _disposeController() {
    _controller?.removeStatusListener(_onStatus);
    _controller?.dispose();
    _controller = null;
  }

  double get _slotAngle => 2 * math.pi / widget.items.length;

  double get _progress => math.min(1, _controller?.value ?? 1);

  /// Góc cuối để `target_position` nằm dưới con trỏ ở đỉnh, quay theo chiều dương.
  double get _endAngle {
    final n = widget.items.length;
    final landingOffset = (n - widget.targetPosition % n) % n;
    return (n * _minTurns + landingOffset) * _slotAngle;
  }

  /// `decelerateCubic(0.05)` cho pha quay, rồi micro-settle ±3° tắt dần trong `wheelSettle`.
  double _rotationAt(double t) {
    final spin = _spinDuration();
    if (spin == Duration.zero) return _endAngle;
    final total = spin + AngiScale.wheelSettle;
    final spinFraction = spin.inMicroseconds / total.inMicroseconds;
    if (t <= spinFraction) {
      return _endAngle * const Cubic(AngiScale.wheelDecelerate, 0, 0.25, 1).transform(t / spinFraction);
    }
    final u = (t - spinFraction) / (1 - spinFraction);
    final wobble = math.sin(math.pi * 2 * u) * AngiScale.wheelSettleDegrees * (1 - u) * math.pi / 180;
    return _endAngle + wobble;
  }

  @override
  Widget build(BuildContext context) {
    final segments = widget.items.map(widget.resolve).toList(growable: false);
    final strings = S.of(context);
    final face = switch (widget.style) {
      WheelStyle.wheel => WheelFace(
          segments: segments,
          slotAngle: _slotAngle,
          rotation: _rotationAt(_progress),
        ),
      WheelStyle.chest => ChestFace(segments: segments, resultIndex: widget.resultIndex, progress: _progress),
      WheelStyle.draw => DrawFace(segments: segments, resultIndex: widget.resultIndex, progress: _progress),
    };

    // Vòng quay không phải thứ để thao tác: kết quả công bố bằng chữ (spec §Accessibility).
    return Semantics(
      label: strings.semWheelUnfocusable,
      excludeSemantics: true,
      child: SizedBox(width: widget.size, height: widget.size, child: face),
    );
  }
}

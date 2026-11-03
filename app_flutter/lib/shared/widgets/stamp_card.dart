import 'package:flutter/material.dart';

import '../../core/theme/angi_tokens.dart';

/// Dạng 3 của signature (DESIGN.md §Signature): **mặt màu + viền mực 2dp + bóng cứng
/// offset, blur 0**. Mỗi màn đúng một `StampCard` — đó là vật thể nổi duy nhất được
/// đổ bóng trong app.
class StampCard extends StatelessWidget {
  const StampCard({
    required this.child,
    this.fill,
    this.shadow = AngiScale.stamp3,
    this.radius = AngiScale.radiusLg,
    this.padding = const EdgeInsets.all(AngiScale.s6),
    this.borderOn = true,
    super.key,
  });

  final Widget child;

  /// Vắng ⇒ `surface`. Hue dữ liệu chỉ dùng cho tem kết quả, không dùng cho container thường.
  final Color? fill;
  final double shadow;
  final double radius;
  final EdgeInsetsGeometry padding;

  /// `false` khi chính caller tự vẽ viền (ví dụ card có nhiều ô trong).
  final bool borderOn;

  @override
  Widget build(BuildContext context) {
    final tokens = AngiTokens.of(context);
    final face = fill ?? tokens.surface;
    return Container(
      decoration: BoxDecoration(
        color: face,
        borderRadius: BorderRadius.circular(radius),
        border: borderOn ? Border.all(color: tokens.ink, width: AngiScale.outline) : null,
        boxShadow: [
          // Bóng là offset thuần, không blur: dấu mực đóng lên giấy.
          BoxShadow(color: tokens.ink, offset: Offset(0, shadow), blurRadius: AngiScale.shadowBlur),
        ],
      ),
      padding: padding,
      child: child,
    );
  }
}

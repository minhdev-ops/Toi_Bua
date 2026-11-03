import 'package:flutter/material.dart';

import '../../core/i18n/angi_label.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/angi_motion.dart';
import '../../core/theme/angi_tokens.dart';

/// Hành động primary — **mỗi màn đúng 1 cái** (spec §4.1).
///
/// `label` là hàm từ ARB chứ không phải chuỗi: hết đường hard-code UI string (TC-I18N-01).
class StampButton extends StatefulWidget {
  const StampButton({
    required this.label,
    this.onPressed,
    this.loading = false,
    this.loadingLabel,
    this.enabled = true,
    this.disabledReason,
    this.countdownSeconds,
    this.primary = true,
    super.key,
  });

  final AngiLabel label;
  final VoidCallback? onPressed;
  final bool loading;

  /// `null` ⇒ giữ nhãn gốc khi đang tải.
  final AngiLabel? loadingLabel;

  /// `false` ≠ ẩn: vẫn thấy, không bấm, lý do đọc bằng screen reader.
  final bool enabled;
  final AngiLabel? disabledReason;

  /// 429: nhãn thành `Chờ 12s`, caller trả 0/null thì nút bấm được lại.
  final int? countdownSeconds;

  /// `false` = bản tonal: `surface` + viền `ink`, không accent.
  final bool primary;

  @override
  State<StampButton> createState() => _StampButtonState();
}

class _StampButtonState extends State<StampButton> {
  final FocusNode _focusNode = FocusNode();
  bool _pressed = false;
  bool _focused = false;

  @override
  void initState() {
    super.initState();
    _focusNode.addListener(() {
      if (mounted) setState(() => _focused = _focusNode.hasFocus);
    });
  }

  @override
  void dispose() {
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final motion = AngiMotion.of(context);

    final counting = (widget.countdownSeconds ?? 0) > 0;
    final blocked = widget.loading || counting || !widget.enabled || widget.onPressed == null;
    final fill = widget.primary ? t.accent : t.surface;
    final onFill = widget.primary ? t.onAccent : t.ink;

    final String text;
    if (counting) {
      text = s.resultSpinCountdown(widget.countdownSeconds!);
    } else if (widget.loading) {
      text = (widget.loadingLabel ?? widget.label)(s);
    } else {
      text = widget.label(s);
    }

    // reduce-motion: bỏ cú lún, thay bằng viền `focus` 3dp khi đang bấm (DESIGN.md §Motion).
    final sink = _pressed && !motion.reduceMotion;
    final ringWidth = (_focused || (_pressed && motion.reduceMotion)) ? AngiScale.focusRing : AngiScale.outline;
    final ringColor = (_focused || (_pressed && motion.reduceMotion)) ? t.focus : t.ink;

    return Opacity(
      opacity: widget.enabled ? 1 : AngiScale.disabledOpacity,
      child: Semantics(
        button: true,
        enabled: widget.enabled && !counting,
        hint: widget.enabled || widget.disabledReason == null ? null : widget.disabledReason!(s),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            focusNode: _focusNode,
            onTap: blocked ? null : widget.onPressed,
            onTapDown: (_) => setState(() => _pressed = true),
            onTapUp: (_) => setState(() => _pressed = false),
            onTapCancel: () => setState(() => _pressed = false),
            customBorder: const RoundedRectangleBorder(
              borderRadius: BorderRadius.all(Radius.circular(AngiScale.radiusMd)),
            ),
            child: AnimatedContainer(
              duration: _pressed ? AngiScale.fast : AngiScale.stampPress,
              curve: AngiScale.curveStamp,
              transform: Matrix4.translationValues(0, sink ? AngiScale.stamp2 : 0, 0),
              constraints: const BoxConstraints(minHeight: AngiScale.touchMin, minWidth: AngiScale.touchMin),
              height: AngiScale.stampButtonH,
              padding: const EdgeInsets.symmetric(horizontal: AngiScale.s6),
              decoration: BoxDecoration(
                color: fill,
                borderRadius: BorderRadius.circular(AngiScale.radiusMd),
                border: Border.all(color: ringColor, width: ringWidth),
                boxShadow: (widget.enabled && !_pressed)
                    ? [BoxShadow(color: t.ink, offset: const Offset(0, AngiScale.stamp2), blurRadius: AngiScale.shadowBlur)]
                    : null,
              ),
              child: Center(
                child: Text(
                  text.toUpperCase(),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: roles.stampLabel.copyWith(color: onFill),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../bootstrap.dart';
import '../../core/geo/anchor_store.dart';
import '../../core/i18n/app_localizations.dart';
import '../../core/theme/angi_icons.dart';
import '../../core/theme/angi_tokens.dart';
import '../../features/app/application/app_providers.dart';
import 'stamp_button.dart';
import 'stamp_chip.dart';

/// Chọn nơi đang đứng. Ba dạng đúng docs/02 §4.3, nhưng P1 chỉ dùng address hoặc geo:
/// app không tự bịa toạ độ, và từ chối GPS vẫn dùng được (SRS 11).
Future<void> showLocationSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    builder: (_) => const _LocationSheet(),
  );
}

class _LocationSheet extends ConsumerStatefulWidget {
  const _LocationSheet();

  @override
  ConsumerState<_LocationSheet> createState() => _LocationSheetState();
}

class _LocationSheetState extends ConsumerState<_LocationSheet> {
  late final TextEditingController _controller;
  static const List<String> _suggestions = [
    'Nguyễn Huệ, Quận 1',
    'Lê Lợi, Quận 1',
    'Thảo Điền, Thủ Đức',
  ];

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: ref.read(anchorProvider).address ?? '');
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _save(String raw) async {
    final text = raw.trim();
    if (text.length < 4) return;
    final anchor = Anchor(address: text, label: text);
    await sl<AnchorStore>().write(anchor);
    ref.read(anchorProvider.notifier).state = anchor;
    if (mounted) Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final bottom = MediaQuery.viewInsetsOf(context).bottom;

    return Padding(
      padding: EdgeInsets.fromLTRB(AngiScale.s6, AngiScale.s2, AngiScale.s6, AngiScale.s6 + bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(s.settingsLocation, style: roles.title.copyWith(color: t.ink)),
          const SizedBox(height: AngiScale.s2),
          Text(s.hubLocationDemo, style: roles.body.copyWith(color: t.muted)),
          const SizedBox(height: AngiScale.s5),
          TextField(
            controller: _controller,
            autofocus: true,
            textInputAction: TextInputAction.done,
            onSubmitted: _save,
            style: roles.body.copyWith(color: t.ink),
            decoration: InputDecoration(
              hintText: s.onboardAddressHint,
              hintStyle: roles.body.copyWith(color: t.muted),
              filled: true,
              fillColor: t.sunken,
              contentPadding: const EdgeInsets.all(AngiScale.s4),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AngiScale.radiusMd),
                borderSide: BorderSide(color: t.ink, width: AngiScale.outline),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(AngiScale.radiusMd),
                borderSide: BorderSide(color: t.focus, width: AngiScale.focusRing),
              ),
            ),
          ),
          const SizedBox(height: AngiScale.s5),
          Text(s.onboardAddressPick, style: roles.sectionLabel.copyWith(color: t.muted)),
          const SizedBox(height: AngiScale.s3),
          Wrap(
            spacing: AngiScale.s3,
            runSpacing: AngiScale.s3,
            children: [
              for (final place in _suggestions)
                StampChip(
                  label: (_) => place,
                  icon: AngiIcons.place,
                  onTap: () => _save(place),
                ),
            ],
          ),
          const SizedBox(height: AngiScale.s6),
          StampButton(
            label: (strings) => strings.ctaSave,
            onPressed: () => _save(_controller.text),
          ),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/services.dart' show Clipboard, ClipboardData;
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/angi_icons.dart';
import '../../../core/theme/angi_tokens.dart';
import '../../../shared/widgets/location_sheet.dart';
import '../../../shared/widgets/stamp_badge.dart';
import '../../../shared/widgets/stamp_card.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../app/application/app_providers.dart';
import '../../spin/application/spin_flow.dart';

const String _appVersion = String.fromEnvironment('ANGI_APP_VERSION', defaultValue: '1.0.0+1');

/// Tab Của bạn: cài đặt máy-local + kiểm chứng lần quay gần nhất.
class YouScreen extends ConsumerWidget {
  const YouScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final settings = ref.watch(settingsProvider);
    final anchor = ref.watch(anchorProvider);
    final spin = ref.watch(spinFlowProvider).spin;

    return SafeArea(
      bottom: false,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(AngiScale.s5, AngiScale.s4, AngiScale.s5, AngiScale.s11),
        children: [
          Text(s.youTitle, style: roles.display.copyWith(color: t.ink)),
          const SizedBox(height: AngiScale.s2),
          Align(
            alignment: Alignment.centerLeft,
            child: StampBadge(
              label: (strings) => strings.youGuest,
              fill: t.sunken,
              onFill: t.ink,
              outline: t.ink,
              icon: AngiIcons.check,
              tilt: false,
            ),
          ),
          const SizedBox(height: AngiScale.s6),
          _sectionLabel(context, s.themeLabel, t, roles),
          Wrap(
            spacing: AngiScale.s2,
            runSpacing: AngiScale.s2,
            children: [
              StampChip(
                label: (strings) => strings.settingsThemeSystem,
                icon: AngiIcons.auto,
                selected: settings.value.theme == 'system',
                onTap: () => settings.setTheme('system'),
              ),
              StampChip(
                label: (strings) => strings.settingsThemeLight,
                icon: AngiIcons.sun,
                selected: settings.value.theme == 'light',
                onTap: () => settings.setTheme('light'),
              ),
              StampChip(
                label: (strings) => strings.settingsThemeDark,
                icon: AngiIcons.moon,
                selected: settings.value.theme == 'dark',
                onTap: () => settings.setTheme('dark'),
              ),
            ],
          ),
          const SizedBox(height: AngiScale.s6),
          _sectionLabel(context, s.settingsLanguage, t, roles),
          Wrap(
            spacing: AngiScale.s2,
            runSpacing: AngiScale.s2,
            children: [
              StampChip(
                label: (strings) => strings.languageVi,
                selected: settings.value.locale == 'vi',
                onTap: () => settings.setLocale('vi'),
              ),
              StampChip(
                label: (strings) => strings.languageEn,
                selected: settings.value.locale == 'en',
                onTap: () => settings.setLocale('en'),
              ),
            ],
          ),
          const SizedBox(height: AngiScale.s6),
          _sectionLabel(context, s.settingsMotionSection, t, roles),
          _switch(
            context,
            title: s.settingsReduceMotion,
            subtitle: s.settingsReduceMotionHint,
            value: settings.value.reduceMotion,
            onChanged: settings.setReduceMotion,
          ),
          _switch(
            context,
            title: s.settingsSound,
            subtitle: s.settingsSoundHint,
            value: settings.value.sound,
            onChanged: settings.setSound,
          ),
          _switch(
            context,
            title: s.settingsHaptics,
            subtitle: s.settingsHapticsHint,
            value: settings.value.haptics,
            onChanged: settings.setHaptics,
          ),
          const SizedBox(height: AngiScale.s5),
          _sectionLabel(context, s.settingsLocation, t, roles),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(AngiIcons.place, color: t.ink),
            title: Text(
              anchor.displayLabel.isEmpty ? s.hubLocationMissing : anchor.displayLabel,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(s.hubLocationDemo),
            trailing: const Icon(AngiIcons.chevronRight),
            onTap: () => showLocationSheet(context),
          ),
          const SizedBox(height: AngiScale.s5),
          _sectionLabel(context, s.settingsProof, t, roles),
          const SizedBox(height: AngiScale.s2),
          if (spin == null)
            Text(s.youProofEmpty, style: roles.body.copyWith(color: t.muted))
          else
            StampCard(
              fill: t.surface,
              shadow: AngiScale.stamp2,
              padding: const EdgeInsets.fromLTRB(AngiScale.s4, AngiScale.s2, AngiScale.s2, AngiScale.s2),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _proofLine(context, s, roles, t, s.settingsProofSeed(spin.proof?.seedB64 ?? '—'), spin.proof?.seedB64, t.ink),
                  _proofLine(context, s, roles, t, s.settingsProofHash(spin.proof?.sha256Result ?? '—'), spin.proof?.sha256Result, t.muted),
                ],
              ),
            ),
          const SizedBox(height: AngiScale.s6),
          Text(s.youVersion(_appVersion), style: roles.micro.copyWith(color: t.subtle)),
        ],
      ),
    );
  }

  /// seed/sha256 dài hơn bề ngang điện thoại: hiển thị 1 dòng rút gọn, nút sao chép
  /// đưa nguyên văn vào clipboard để người dùng tự kiểm chứng.
  Widget _proofLine(
    BuildContext context,
    S s,
    AngiRoles roles,
    AngiTokens t,
    String text,
    String? raw,
    Color color,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            text,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: roles.mono.copyWith(color: color),
          ),
        ),
        IconButton(
          tooltip: s.proofCopy,
          visualDensity: VisualDensity.compact,
          icon: const Icon(Icons.copy_all_outlined, size: 18),
          color: t.muted,
          onPressed: raw == null
              ? null
              : () async {
                  await Clipboard.setData(ClipboardData(text: raw));
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.proofCopied)));
                },
        ),
      ],
    );
  }

  Widget _sectionLabel(BuildContext context, String text, AngiTokens t, AngiRoles roles) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AngiScale.s2),
      child: Text(text, style: roles.sectionLabel.copyWith(color: t.muted)),
    );
  }

  Widget _switch(
    BuildContext context, {
    required String title,
    String? subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return SwitchListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(title),
      subtitle: subtitle == null ? null : Text(subtitle),
      value: value,
      onChanged: onChanged,
    );
  }
}

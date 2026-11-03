import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../bootstrap.dart';
import '../../../core/api/models/spin.dart';
import '../../../core/geo/anchor_store.dart';
import '../../../core/i18n/angi_format.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/angi_icons.dart';
import '../../../core/theme/angi_tokens.dart';
import '../../../shared/widgets/stamp_button.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../app/application/app_providers.dart';
import '../../spin/application/spin_flow.dart';

/// S1. Ba bước, bỏ qua được (FR-AUTH-04). Bước 1 ghi vị trí, bước 2 ghi kiêng,
/// bước 3 ghi ngân sách; cả ba đều dùng được ngay ở lượt quay đầu.
class OnboardingScreen extends ConsumerStatefulWidget {
  const OnboardingScreen({super.key});

  @override
  ConsumerState<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends ConsumerState<OnboardingScreen> {
  final PageController _pages = PageController();
  final TextEditingController _address = TextEditingController();
  final Set<String> _diet = {};
  int _index = 0;
  int _budget = 50000;

  static const List<String> _suggestions = [
    'Nguyễn Huệ, Quận 1',
    'Lê Lợi, Quận 1',
    'Thảo Điền, Thủ Đức',
  ];

  @override
  void dispose() {
    _pages.dispose();
    _address.dispose();
    super.dispose();
  }

  Future<void> _finish() async {
    final prefs = sl<SharedPreferences>();
    await prefs.setInt('angi.budget', _budget);
    await prefs.setStringList('angi.diet', _diet.toList(growable: false));

    final text = _address.text.trim();
    if (text.length >= 4) {
      final anchor = Anchor(address: text, label: text);
      await sl<AnchorStore>().write(anchor);
      ref.read(anchorProvider.notifier).state = anchor;
    }

    await ref.read(settingsProvider).setOnboarded();
    ref.read(spinFlowProvider.notifier).updateRequest(
          SpinRequest(
            filters: SpinFilters(budgetVnd: _budget),
            diet: _diet.isEmpty ? null : SpinDiet(overrideStrict: _diet.toList(growable: false)),
          ),
        );
    if (mounted) Navigator.of(context).pop();
  }

  void _next() {
    if (_index >= 2) {
      _finish();
      return;
    }
    _pages.nextPage(duration: AngiScale.base, curve: AngiScale.curveStamp);
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AngiScale.s5, AngiScale.s3, AngiScale.s5, 0),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        for (var i = 0; i < 3; i++) ...[
                          AnimatedContainer(
                            duration: AngiScale.base,
                            curve: AngiScale.curveStamp,
                            width: i == _index ? 40 : 18,
                            height: 6,
                            decoration: BoxDecoration(
                              color: i <= _index ? t.accent : t.sunken,
                              borderRadius: BorderRadius.circular(AngiScale.radiusPill),
                              border: Border.all(color: t.ink, width: AngiScale.outline),
                            ),
                          ),
                          const SizedBox(width: AngiScale.s2),
                        ],
                      ],
                    ),
                  ),
                  TextButton(
                    onPressed: _finish,
                    child: Text(s.ctaSkip),
                  ),
                ],
              ),
            ),
            Expanded(
              child: PageView(
                controller: _pages,
                onPageChanged: (value) => setState(() => _index = value),
                children: [
                  _page(
                    context,
                    icon: AngiIcons.place,
                    title: s.onboardStep1Title,
                    body: s.onboardStep1Body,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        TextField(
                          controller: _address,
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
                          spacing: AngiScale.s2,
                          runSpacing: AngiScale.s2,
                          children: [
                            for (final place in _suggestions)
                              StampChip(
                                label: (_) => place,
                                onTap: () => setState(() => _address.text = place),
                              ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  _page(
                    context,
                    icon: AngiIcons.leaf,
                    title: s.onboardStep2Title,
                    body: s.onboardStep2Body,
                    child: Wrap(
                      spacing: AngiScale.s2,
                      runSpacing: AngiScale.s2,
                      children: [
                        for (final diet in const [
                          ('tag_vegetarian', 'dietVegetarian'),
                          ('tag_vegan', 'dietVegan'),
                          ('tag_halal', 'dietHalal'),
                          ('tag_no_pork', 'dietNoPork'),
                          ('tag_no_beef', 'dietNoBeef'),
                        ])
                          StampChip(
                            label: (strings) => _dietLabel(strings, diet.$2),
                            selected: _diet.contains(diet.$1),
                            onTap: () => setState(() {
                              if (!_diet.remove(diet.$1)) _diet.add(diet.$1);
                            }),
                          ),
                      ],
                    ),
                  ),
                  _page(
                    context,
                    icon: AngiIcons.wallet,
                    title: s.onboardStep3Title,
                    body: s.onboardStep3Body,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.budgetPerMeal(AngiFormat.price(s, _budget)),
                          style: roles.numeric.copyWith(color: t.accentText),
                        ),
                        Slider(
                          value: _budget.toDouble(),
                          min: 10000,
                          max: 200000,
                          divisions: 38,
                          onChanged: (value) => setState(
                            () => _budget = (value / 5000).round() * 5000,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(AngiScale.s5),
              child: Column(
                children: [
                  StampButton(
                    label: (strings) => _index >= 2 ? strings.ctaDone : strings.ctaNext,
                    onPressed: _next,
                  ),
                  const SizedBox(height: AngiScale.s2),
                  Text(s.onboardSkipHint, style: roles.micro.copyWith(color: t.muted)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _page(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String body,
    required Widget child,
  }) {
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    // Căn giữa theo chiều dọc để bước ngắn (kiêng/ngân sách) không bỏ trống nửa màn hình;
    // vẫn cuộn được khi bàn phím mở.
    return LayoutBuilder(
      builder: (context, constraints) => SingleChildScrollView(
        padding: const EdgeInsets.all(AngiScale.s5),
        child: ConstrainedBox(
          constraints: BoxConstraints(minHeight: constraints.maxHeight - AngiScale.s5 * 2),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tem bước: khối accent nghiêng nhẹ, cùng ngôn ngữ "con dấu" với StampBadge.
              Transform.rotate(
                angle: AngiScale.stampTilt,
                child: Container(
                  width: 76,
                  height: 76,
                  decoration: BoxDecoration(
                    color: t.accent,
                    borderRadius: BorderRadius.circular(AngiScale.radiusMd),
                    border: Border.all(color: t.ink, width: AngiScale.outline),
                    boxShadow: [BoxShadow(color: t.ink, offset: const Offset(0, AngiScale.stamp2), blurRadius: 0)],
                  ),
                  child: Icon(icon, size: 38, color: t.onAccent),
                ),
              ),
              const SizedBox(height: AngiScale.s6),
              Text(title, style: roles.display.copyWith(color: t.ink)),
              const SizedBox(height: AngiScale.s3),
              Text(body, style: roles.body.copyWith(color: t.muted)),
              const SizedBox(height: AngiScale.s7),
              child,
            ],
          ),
        ),
      ),
    );
  }

  static String _dietLabel(S s, String key) => switch (key) {
        'dietVegetarian' => s.dietVegetarian,
        'dietVegan' => s.dietVegan,
        'dietHalal' => s.dietHalal,
        'dietNoPork' => s.dietNoPork,
        _ => s.dietNoBeef,
      };
}

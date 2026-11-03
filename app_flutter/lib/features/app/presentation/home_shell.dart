import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/angi_icons.dart';
import '../../../core/theme/angi_tokens.dart';
import '../../discover/presentation/discover_screen.dart';
import '../../onboarding/presentation/onboarding_screen.dart';
import '../../spin/presentation/spin_hub_screen.dart';
import '../../urgent/presentation/urgent_screen.dart';
import '../../you/presentation/you_screen.dart';
import '../application/app_providers.dart';

/// Khung 4 tab: Quay · Quán · Đói gấp · Của bạn.
///
/// Mỗi tab là một màn hình độc lập, giữ state bằng `IndexedStack` để quay lại
/// không mất kết quả vừa quay (spec §Edge cases: xoay màn không re-request).
class HomeShell extends ConsumerStatefulWidget {
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  int _index = 0;
  bool _onboardingChecked = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_onboardingChecked) return;
    _onboardingChecked = true;
    final settings = ref.read(settingsProvider);
    if (settings.onboarded) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute<void>(builder: (_) => const OnboardingScreen(), fullscreenDialog: true),
      );
    });
  }

  void _go(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final t = AngiTokens.of(context);
    final s = S.of(context);

    return Scaffold(
      backgroundColor: t.background,
      body: SafeArea(
        bottom: false,
        child: IndexedStack(
          index: _index,
          children: [
            SpinHubScreen(onOpenUrgent: () => _go(2), onOpenDiscover: () => _go(1)),
            const DiscoverScreen(),
            const UrgentScreen(),
            const YouScreen(),
          ],
        ),
      ),
      bottomNavigationBar: DecoratedBox(
        decoration: BoxDecoration(
          color: t.surface,
          border: Border(top: BorderSide(color: t.ink, width: AngiScale.outline)),
        ),
        child: SafeArea(
          top: false,
          child: NavigationBar(
            selectedIndex: _index,
            onDestinationSelected: _go,
            destinations: [
              NavigationDestination(
                icon: const Icon(Icons.casino_outlined),
                selectedIcon: const Icon(Icons.casino),
                label: s.tabSpin,
              ),
              NavigationDestination(
                icon: const Icon(Icons.place_outlined),
                selectedIcon: const Icon(Icons.place),
                label: s.tabPlaces,
              ),
              NavigationDestination(
                icon: const Icon(AngiIcons.boltOutlined),
                selectedIcon: const Icon(AngiIcons.bolt),
                label: s.tabUrgent,
              ),
              NavigationDestination(
                icon: const Icon(Icons.person_outline),
                selectedIcon: const Icon(Icons.person),
                label: s.tabYou,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

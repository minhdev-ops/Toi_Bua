import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_mapper.dart';
import '../../../core/api/models/meta.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/geo/anchor_store.dart';
import '../../../core/theme/angi_icons.dart';
import '../../../core/theme/angi_motion.dart';
import '../../../core/theme/angi_tokens.dart';
import '../../../shared/widgets/data_quality_banner.dart';
import '../../../shared/widgets/location_sheet.dart';
import '../../../shared/widgets/stamp_badge.dart';
import '../../../shared/widgets/stamp_button.dart';
import '../../../shared/widgets/stamp_card.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../app/application/app_providers.dart';
import '../../discover/presentation/match_list_screen.dart';
import '../application/spin_flow.dart';
import '../data/dish_catalog.dart';
import 'filter_sheet.dart';
import 'result_stamp.dart';
import 'wheel_face.dart';
import 'wheel_spinner.dart';

/// S2 Hub. Layout family Hub: vòng quay chiếm phần lớn màn, đúng một primary action.
/// 3 chạm tới bản đồ: Quay, chọn quán, Chỉ đường.
class SpinHubScreen extends ConsumerStatefulWidget {
  const SpinHubScreen({required this.onOpenUrgent, required this.onOpenDiscover, super.key});

  final VoidCallback onOpenUrgent;
  final VoidCallback onOpenDiscover;

  @override
  ConsumerState<SpinHubScreen> createState() => _SpinHubScreenState();
}

class _SpinHubScreenState extends ConsumerState<SpinHubScreen> {
  String? _openedSpinId;

  void _openMatches() {
    final flow = ref.read(spinFlowProvider);
    if (flow.matches == null) return;
    Navigator.of(context).push(
      MaterialPageRoute<void>(builder: (_) => const MatchListScreen()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final flow = ref.watch(spinFlowProvider);
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final motion = AngiMotion.of(context);

    // Kết quả đã có ⇒ mở bảng menu đúng một lần cho mỗi spin_id.
    ref.listen<SpinFlow>(spinFlowProvider, (previous, next) {
      if (next.phase == SpinPhase.ready && next.spin != null && _openedSpinId != next.spin!.spinId) {
        _openedSpinId = next.spin!.spinId;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) _openMatches();
        });
      }
    });

    final catalog = ref.watch(dishCatalogProvider).value ?? DishCatalog.empty;
    final anchor = ref.watch(anchorProvider);

    return SafeArea(
      bottom: false,
      child: Column(
        children: [
          DataQualityBanner(meta: flow.matches?.meta ?? ResponseMeta.fresh),
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(AngiScale.s5, AngiScale.s3, AngiScale.s5, AngiScale.s5),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _topBar(context, s, t, roles, anchor, flow),
                      const SizedBox(height: AngiScale.s6),
                      Text(
                        s.hubQuestion,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: roles.display.copyWith(color: t.ink),
                      ),
                      const SizedBox(height: AngiScale.s2),
                      Text(
                        flow.hasResult ? s.resultToday(flow.spin!.dish.displayLabel) : s.hubSub,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: roles.body.copyWith(color: t.muted),
                      ),
                      const SizedBox(height: AngiScale.s5),
                      _wheelZone(context, flow, motion, catalog, s, t),
                      const SizedBox(height: AngiScale.s5),
                      _filterSummary(context, flow, s, t, roles),
                      const SizedBox(height: AngiScale.s4),
                      _primary(context, flow, s, motion),
                      const SizedBox(height: AngiScale.s3),
                      _secondary(context, flow, s),
                      if (flow.phase == SpinPhase.failed) ...[
                        const SizedBox(height: AngiScale.s4),
                        _errorCard(context, flow, s, t, roles),
                      ],
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _topBar(
    BuildContext context,
    S s,
    AngiTokens t,
    AngiRoles roles,
    Anchor anchor,
    SpinFlow flow,
  ) {
    final label = anchor.displayLabel.isEmpty ? s.hubLocationMissing : anchor.displayLabel;
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(s.appTitle, style: roles.title.copyWith(color: t.ink)),
              const SizedBox(height: AngiScale.s1),
              InkWell(
                onTap: () => showLocationSheet(context),
                borderRadius: BorderRadius.circular(AngiScale.radiusSm),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: AngiScale.s1),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(AngiIcons.place, size: AngiIcons.sizeInline, color: t.muted),
                      const SizedBox(width: AngiScale.s1),
                      Flexible(
                        child: Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: roles.micro.copyWith(color: t.muted),
                        ),
                      ),
                      Icon(AngiIcons.chevronRight, size: AngiIcons.sizeInline, color: t.muted),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        StampChip(
          label: (strings) => strings.ctaUrgent,
          icon: AngiIcons.bolt,
          onTap: widget.onOpenUrgent,
        ),
      ],
    );
  }

  Widget _wheelZone(
    BuildContext context,
    SpinFlow flow,
    AngiMotion motion,
    DishCatalog catalog,
    S s,
    AngiTokens t,
  ) {
    final width = MediaQuery.sizeOf(context).width;
    final size = math.min(width - AngiScale.s8 * 2, 340.0);
    final spin = flow.spin;
    final showSpinner = spin != null && (flow.phase == SpinPhase.animating || flow.phase == SpinPhase.resolving);
    final showResult = spin != null && !showSpinner;

    return Center(
      child: SizedBox(
        width: size + AngiScale.s5,
        height: size + AngiScale.s5,
        child: Stack(
          alignment: Alignment.center,
          clipBehavior: Clip.none,
          children: [
            // "Đĩa" phía sau: mặt phẳng sunken, không đổ bóng (bóng chỉ dành cho stamp).
            Positioned(
              top: AngiScale.s3,
              child: Container(
                width: size + AngiScale.s2,
                height: size + AngiScale.s2,
                decoration: BoxDecoration(color: t.sunken, shape: BoxShape.circle),
              ),
            ),
            if (showSpinner)
              WheelSpinner(
                items: spin.animation.wheelItems,
                resultIndex: spin.animation.resultIndex,
                targetPosition: spin.animation.targetPosition,
                durationMs: spin.animation.durationMs,
                style: spin.animation.style,
                reduceMotion: spin.animation.reduceMotion || motion.reduceMotion,
                sound: spin.animation.sound,
                haptics: spin.animation.haptics,
                size: size,
                resolve: (dishId) {
                  final dish = catalog.of(dishId);
                  return WheelSegment(id: dishId, label: dish?.displayLabel ?? dishId, type: dish?.type);
                },
                onSettled: () => ref.read(spinFlowProvider.notifier).onWheelSettled(),
              )
            else if (showResult)
              ResultStamp(dish: spin.dish, maxSize: size * 0.72)
            else
              _IdleWheel(size: size, motion: motion),
            Positioned(
              top: AngiScale.s1,
              right: -AngiScale.s1,
              child: Transform.rotate(
                angle: AngiScale.stampTilt,
                child: StampBadge(
                  label: (strings) => strings.hubStamp,
                  fill: t.accent,
                  onFill: t.onAccent,
                  icon: AngiIcons.bolt,
                  tilt: false,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _filterSummary(BuildContext context, SpinFlow flow, S s, AngiTokens t, AngiRoles roles) {
    final count = flow.activeFilterCount;
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(AngiIcons.tune, size: AngiIcons.sizeInline, color: t.muted),
        const SizedBox(width: AngiScale.s2),
        Flexible(
          child: Text(
            count == 0 ? s.hubFilterNone : s.hubFilterSummary(count),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: roles.micro.copyWith(color: t.muted),
          ),
        ),
      ],
    );
  }

  Widget _primary(BuildContext context, SpinFlow flow, S s, AngiMotion motion) {
    final notifier = ref.read(spinFlowProvider.notifier);
    switch (flow.phase) {
      case SpinPhase.idle:
      case SpinPhase.requesting:
      case SpinPhase.animating:
      case SpinPhase.resolving:
        return StampButton(
          label: (strings) => strings.ctaSpin,
          loadingLabel: (strings) => strings.ctaSpinLoading,
          onPressed: flow.canSpin ? () => notifier.spinNow() : null,
          loading: flow.isBusy,
          countdownSeconds: flow.countdownSeconds,
          enabled: flow.canSpin,
        );
      case SpinPhase.ready:
        return StampButton(
          label: (strings) => strings.viewPlaces,
          onPressed: _openMatches,
        );
      case SpinPhase.failed:
        return StampButton(
          label: (strings) => strings.ctaRetry,
          onPressed: () => notifier.retry(),
        );
    }
  }

  Widget _secondary(BuildContext context, SpinFlow flow, S s) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        StampChip(
          label: (strings) => strings.ctaFilters,
          icon: AngiIcons.tune,
          onTap: () => showFilterSheet(context),
        ),
        const SizedBox(width: AngiScale.s3),
        if (flow.hasResult)
          StampChip(
            label: (strings) => strings.ctaSpinAgain,
            icon: AngiIcons.retry,
            onTap: () {
              _openedSpinId = null;
              ref.read(spinFlowProvider.notifier).spinNow();
            },
          )
        else
          StampChip(
            label: (strings) => strings.tabPlaces,
            icon: AngiIcons.place,
            onTap: widget.onOpenDiscover,
          ),
      ],
    );
  }

  Widget _errorCard(BuildContext context, SpinFlow flow, S s, AngiTokens t, AngiRoles roles) {
    final error = flow.error;
    final text = error == null ? s.errUnknown : ErrorMapper.toUi(s, error).headline;
    return StampCard(
      fill: t.warningFill,
      child: Row(
        children: [
          Icon(AngiIcons.warning, color: t.onFill, size: AngiIcons.size),
          const SizedBox(width: AngiScale.s3),
          Expanded(
            child: Text(text, style: roles.label.copyWith(color: t.onFill)),
          ),
        ],
      ),
    );
  }
}

/// Vòng quay lúc chưa quay: 8 nhóm món, một lần vào màn (không chạy vô hạn).
class _IdleWheel extends StatelessWidget {
  const _IdleWheel({required this.size, required this.motion});

  final double size;
  final AngiMotion motion;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final segments = [
      WheelSegment(id: 'noodle', label: s.typeNoodle, type: DishType.noodle),
      WheelSegment(id: 'rice', label: s.typeRice, type: DishType.rice),
      WheelSegment(id: 'bread', label: s.typeBread, type: DishType.bread),
      WheelSegment(id: 'sweet', label: s.typeSweet, type: DishType.sweet),
      WheelSegment(id: 'grill', label: s.typeGrill, type: DishType.grill),
      WheelSegment(id: 'salad', label: s.typeSalad, type: DishType.salad),
      WheelSegment(id: 'drink', label: s.typeDrink, type: DishType.drink),
      WheelSegment(id: 'snack', label: s.typeSnack, type: DishType.snack),
    ];

    final wheel = SizedBox(
      width: size,
      height: size,
      child: WheelFace(
        segments: segments,
        slotAngle: 2 * math.pi / segments.length,
        rotation: -math.pi / segments.length / 2,
      ),
    );

    if (!motion.animates) return wheel;
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: 1),
      duration: AngiScale.emphasis,
      curve: AngiScale.curveStamp,
      builder: (context, value, child) => Transform.rotate(
        angle: (1 - value) * -0.18,
        child: Transform.scale(scale: 0.9 + 0.1 * value, child: child),
      ),
      child: wheel,
    );
  }
}

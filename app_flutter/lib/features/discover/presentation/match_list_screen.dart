import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/matches.dart';
import '../../../core/api/models/meta.dart';
import '../../../core/api/models/place.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/angi_icons.dart';
import '../../../core/theme/angi_motion.dart';
import '../../../core/theme/angi_tokens.dart';
import '../../../shared/widgets/data_quality_banner.dart';
import '../../../shared/widgets/relax_empty_state.dart';
import '../../../shared/widgets/skeleton_row.dart';
import '../../place/presentation/place_detail_screen.dart';
import '../../spin/application/spin_flow.dart';
import 'result_row.dart';
import 'why_sheet.dart';

/// S4. Ba quán phù hợp nhất, layout Bảng menu. Không sort lại items (spec §Step 2).
class MatchListScreen extends ConsumerWidget {
  const MatchListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final flow = ref.watch(spinFlowProvider);
    final matches = flow.matches;
    final dish = flow.spin?.dish;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AngiIcons.chevronLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(s.matchDishLabel),
      ),
      body: SafeArea(
        top: false,
        child: Column(
          children: [
            DataQualityBanner(meta: matches?.meta ?? flow.spin?.meta ?? ResponseMeta.fresh),
            Expanded(
              child: flow.phase == SpinPhase.resolving
                  ? const Padding(
                      padding: EdgeInsets.all(AngiScale.s5),
                      child: SkeletonList(rows: 3),
                    )
                  : matches == null
                      ? const SizedBox.shrink()
                      : _content(context, ref, s, t, flow, matches, dish?.displayLabel ?? ''),
            ),
          ],
        ),
      ),
    );
  }

  Widget _content(
    BuildContext context,
    WidgetRef ref,
    S s,
    AngiTokens t,
    SpinFlow flow,
    MatchResponse matches,
    String dishName,
  ) {
    final notifier = ref.read(spinFlowProvider.notifier);
    return ListView(
      padding: EdgeInsets.zero,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AngiScale.s5, AngiScale.s4, AngiScale.s5, AngiScale.s4),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 56,
                height: 6,
                decoration: BoxDecoration(
                  color: t.hue(flow.spin?.dish.type),
                  borderRadius: BorderRadius.circular(AngiScale.radiusPill),
                ),
              ),
              const SizedBox(height: AngiScale.s3),
              Text(
                dishName,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AngiRoles.of(context).display.copyWith(color: t.ink),
              ),
              const SizedBox(height: AngiScale.s1),
              Text(
                matches.isEmpty ? s.emptyMatchesBody : s.matchCount(matches.items.length),
                style: AngiRoles.of(context).body.copyWith(color: t.muted),
              ),
              if (!matches.isEmpty) ...[
                const SizedBox(height: AngiScale.s1),
                Text(s.matchNote, style: AngiRoles.of(context).micro.copyWith(color: t.muted)),
              ],
            ],
          ),
        ),
        if (matches.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: AngiScale.s5),
            child: RelaxEmptyState(
              relaxation: matches.relaxation,
              substituteDishes: matches.substituteDishes,
              onRelax: notifier.applyRelaxation,
              onRetry: notifier.retry,
              onEnterAddress: () {},
            ),
          )
        else
          for (var i = 0; i < matches.items.length; i++)
            _StaggeredRow(
              index: i,
              child: ResultRow(
                place: matches.items[i],
                rank: i + 1,
                showWhy: matches.items[i].scoreBreakdown != null,
                onOpen: () => _openPlace(context, matches.items[i]),
                onWhy: () => _openWhy(context, matches.items[i]),
              ),
            ),
        const SizedBox(height: AngiScale.s8),
      ],
    );
  }

  void _openPlace(BuildContext context, Place place) {
    Navigator.of(context).push(
      MaterialPageRoute<void>(
        builder: (_) => PlaceDetailScreen(placeId: place.id, initial: place),
      ),
    );
  }

  void _openWhy(BuildContext context, Place place) {
    final breakdown = place.scoreBreakdown;
    if (breakdown == null) return;
    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      builder: (_) => WhySheet(breakdown: breakdown),
    );
  }
}

/// Vào list theo nhịp 40ms, tối đa 3 hàng (DESIGN.md §Motion).
class _StaggeredRow extends StatefulWidget {
  const _StaggeredRow({required this.index, required this.child});

  final int index;
  final Widget child;

  @override
  State<_StaggeredRow> createState() => _StaggeredRowState();
}

class _StaggeredRowState extends State<_StaggeredRow> {
  bool _shown = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_shown) return;
    if (!AngiMotion.of(context).animates || widget.index >= 3) {
      _shown = true;
      return;
    }
    Future<void>.delayed(AngiScale.staggerStep * widget.index, () {
      if (mounted) setState(() => _shown = true);
    });
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSlide(
      offset: _shown ? Offset.zero : const Offset(0, 0.08),
      duration: AngiScale.base,
      curve: AngiScale.curveStamp,
      child: AnimatedOpacity(
        opacity: _shown ? 1 : 0,
        duration: AngiScale.base,
        curve: AngiScale.curveStamp,
        child: widget.child,
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_mapper.dart';
import '../../../core/api/models/misc.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/angi_icons.dart';
import '../../../core/theme/angi_tokens.dart';
import '../../../shared/widgets/data_quality_banner.dart';
import '../../../shared/widgets/location_sheet.dart';
import '../../../shared/widgets/relax_empty_state.dart';
import '../../../shared/widgets/skeleton_row.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../app/application/app_providers.dart';
import '../../place/data/place_repository.dart';
import '../../place/presentation/place_detail_screen.dart';
import 'result_row.dart';

/// S9. Quán gần đây, layout Bảng menu, đồng bộ bộ lọc với bán kính đang chọn.
class DiscoverScreen extends ConsumerStatefulWidget {
  const DiscoverScreen({super.key});

  @override
  ConsumerState<DiscoverScreen> createState() => _DiscoverScreenState();
}

class _DiscoverScreenState extends ConsumerState<DiscoverScreen> {
  int? _radius;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final config = ref.watch(appConfigProvider);
    final radius = _radius ?? config.place.radiusDefaultM;
    final async = ref.watch(nearbyProvider(radius));
    final anchor = ref.watch(anchorProvider);

    final radii = <int>{
      500,
      1000,
      config.place.radiusDefaultM,
      3000,
      config.place.radiusMaxM,
    }.toList()..sort();

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(nearbyProvider(radius)),
        child: ListView(
          padding: const EdgeInsets.only(bottom: AngiScale.s11),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(AngiScale.s5, AngiScale.s4, AngiScale.s5, AngiScale.s3),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.discoverTitle, style: roles.display.copyWith(color: t.ink)),
                  const SizedBox(height: AngiScale.s1),
                  InkWell(
                    onTap: () => showLocationSheet(context),
                    borderRadius: BorderRadius.circular(AngiScale.radiusSm),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(AngiIcons.place, size: AngiIcons.sizeInline, color: t.muted),
                        const SizedBox(width: AngiScale.s1),
                        Flexible(
                          child: Text(
                            anchor.displayLabel.isEmpty ? s.hubLocationMissing : anchor.displayLabel,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: roles.micro.copyWith(color: t.muted),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: AngiScale.s4),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        for (final r in radii) ...[
                          StampChip(
                            label: (strings) => strings.discoverRadius(_radiusLabel(strings, r)),
                            selected: radius == r,
                            onTap: () => setState(() => _radius = r),
                          ),
                          const SizedBox(width: AngiScale.s2),
                        ],
                      ],
                    ),
                  ),
                ],
              ),
            ),
            async.when(
              loading: () => const Padding(
                padding: EdgeInsets.all(AngiScale.s5),
                child: SkeletonList(rows: 3),
              ),
              error: (error, _) {
                final message = error is ApiError ? ErrorMapper.toUi(s, error).headline : s.errUnknown;
                return Padding(
                  padding: const EdgeInsets.all(AngiScale.s5),
                  child: Text(message, style: roles.body.copyWith(color: t.dangerText)),
                );
              },
              data: (response) {
                if (response.items.isEmpty) {
                  return Padding(
                    padding: const EdgeInsets.all(AngiScale.s5),
                    child: RelaxEmptyState(
                      relaxation: response.relaxation,
                      substituteDishes: const [],
                      onRelax: (_) {},
                      onRetry: () => ref.invalidate(nearbyProvider(radius)),
                    ),
                  );
                }
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    DataQualityBanner(meta: response.meta),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(AngiScale.s5, AngiScale.s3, AngiScale.s5, AngiScale.s1),
                      child: Text(
                        s.matchCount(response.items.length),
                        style: roles.label.copyWith(color: t.muted),
                      ),
                    ),
                    for (var i = 0; i < response.items.length; i++)
                      ResultRow(
                        place: response.items[i],
                        rank: i + 1,
                        showWhy: response.items[i].scoreBreakdown != null,
                        onOpen: () => Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => PlaceDetailScreen(
                              placeId: response.items[i].id,
                              initial: response.items[i],
                            ),
                          ),
                        ),
                        onWhy: null,
                      ),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  static String _radiusLabel(S s, int radius) =>
      radius < 1000 ? s.distanceMeters(radius) : s.distanceKm((radius / 1000).toStringAsFixed(0));
}

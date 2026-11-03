import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/error_mapper.dart';
import '../../../core/api/models/dish.dart';
import '../../../core/api/models/misc.dart';
import '../../../core/api/models/place.dart';
import '../../../core/api/models/urgent.dart';
import '../../../core/i18n/angi_format.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/server_keys.dart';
import '../../../core/theme/angi_icons.dart';
import '../../../core/theme/angi_tokens.dart';
import '../../../shared/widgets/angi_thumb.dart';
import '../../../shared/widgets/data_quality_banner.dart';
import '../../../shared/widgets/open_status_chip.dart';
import '../../../shared/widgets/skeleton_row.dart';
import '../../../shared/widgets/stamp_badge.dart';
import '../../../shared/widgets/stamp_button.dart';
import '../../../shared/widgets/stamp_card.dart';
import '../../place/data/place_repository.dart';
import '../../place/presentation/place_detail_screen.dart';

/// S7. Đói gấp: một chạm, dưới 2 giây, layout Thẻ quyết định.
class UrgentScreen extends ConsumerWidget {
  const UrgentScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final async = ref.watch(urgentProvider);

    return SafeArea(
      bottom: false,
      child: RefreshIndicator(
        onRefresh: () async => ref.invalidate(urgentProvider),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(AngiScale.s5, AngiScale.s4, AngiScale.s5, AngiScale.s11),
          children: [
            Text(s.urgentHeading, style: roles.display.copyWith(color: t.ink)),
            const SizedBox(height: AngiScale.s1),
            Text(s.urgentOneTap, style: roles.body.copyWith(color: t.muted)),
            const SizedBox(height: AngiScale.s5),
            async.when(
              loading: () => const SkeletonRow(height: 180),
              error: (error, _) {
                final message = error is ApiError ? ErrorMapper.toUi(s, error).headline : s.errUnknown;
                return StampCard(
                  fill: t.warningFill,
                  child: Text(message, style: roles.label.copyWith(color: t.onFill)),
                );
              },
              data: (response) => _body(context, s, t, roles, response),
            ),
          ],
        ),
      ),
    );
  }

  Widget _body(BuildContext context, S s, AngiTokens t, AngiRoles roles, UrgentResponse response) {
    final place = response.place;
    if (place == null) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          StampCard(
            fill: t.surface,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(s.urgentNoneHeadline, style: roles.title.copyWith(color: t.ink)),
                const SizedBox(height: AngiScale.s2),
                Text(s.urgentNoneBody, style: roles.body.copyWith(color: t.muted)),
              ],
            ),
          ),
          if (response.alternatives.isNotEmpty) ...[
            const SizedBox(height: AngiScale.s6),
            _alternatives(context, s, t, roles, response.alternatives),
          ],
        ],
      );
    }

    final fallback = response.decision.fallbackDish;
    final hueName = place.cuisineTags.isEmpty ? place.name : place.cuisineTags.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        DataQualityBanner(meta: response.meta),
        StampCard(
          fill: t.surface,
          shadow: AngiScale.stamp3,
          padding: const EdgeInsets.all(AngiScale.s5),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  AngiThumb(
                    name: place.name,
                    hue: t.hue(TaxonomyTypeIndex.of(null, name: hueName)),
                    imageUrl: place.images.isEmpty ? null : place.images.first.url,
                    size: 64,
                  ),
                  const SizedBox(width: AngiScale.s4),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          place.name,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: roles.title.copyWith(color: t.ink),
                        ),
                        const SizedBox(height: AngiScale.s1),
                        Text(
                          place.address,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: roles.micro.copyWith(color: t.muted),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: AngiScale.s4),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AngiFormat.distance(s, place.distanceM),
                    style: roles.numericLg.copyWith(color: t.ink),
                  ),
                  const SizedBox(width: AngiScale.s2),
                  Padding(
                    padding: const EdgeInsets.only(bottom: AngiScale.s1),
                    child: Text(s.detailDistance, style: roles.micro.copyWith(color: t.muted)),
                  ),
                  const Spacer(),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      OpenStatusChip(openStatus: place.openStatus ?? response.openStatus),
                      const SizedBox(height: AngiScale.s1),
                      Text(
                        AngiFormat.price(s, place.avgPriceVnd),
                        style: roles.label.copyWith(color: t.ink),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: AngiScale.s3),
              Wrap(
                spacing: AngiScale.s2,
                runSpacing: AngiScale.s2,
                children: [
                  if (fallback != null)
                    StampBadge(
                      label: (strings) => strings.urgentNearbyMatch,
                      fill: t.surface,
                      onFill: t.ink,
                      outline: t.ink,
                      icon: AngiIcons.bestMatch,
                    ),
                  StampBadge(
                    label: (_) => s.ratingValue(place.ratingBayesian.toStringAsFixed(1)),
                    fill: t.accent,
                    onFill: t.onAccent,
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: AngiScale.s3),
        Row(
          children: [
            Expanded(
              child: Text(
                s.urgentDecision(
                  (response.decision.radiusMUsed / 1000).toStringAsFixed(1),
                  response.decision.candidatesConsidered,
                ),
                style: roles.micro.copyWith(color: t.muted),
              ),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).push(
                MaterialPageRoute<void>(
                  builder: (_) => PlaceDetailScreen(placeId: place.id, initial: place),
                ),
              ),
              child: Text(s.viewPlaces),
            ),
          ],
        ),
        const SizedBox(height: AngiScale.s2),
        StampButton(
          label: (strings) => strings.ctaNavigate,
          onPressed: () => _directions(context, place, s),
        ),
        if (response.alternatives.isNotEmpty) ...[
          const SizedBox(height: AngiScale.s6),
          _alternatives(context, s, t, roles, response.alternatives),
        ],
      ],
    );
  }

  Widget _alternatives(
    BuildContext context,
    S s,
    AngiTokens t,
    AngiRoles roles,
    List<UrgentAlternative> alternatives,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(s.alternativesHeading, style: roles.sectionLabel.copyWith(color: t.muted)),
        const SizedBox(height: AngiScale.s2),
        for (final alt in alternatives)
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: Text(alt.name),
            subtitle: Text(
              ServerKeys.text(s, alt.whyKey, alt.whyParams) ?? '',
              style: roles.micro.copyWith(color: t.muted),
            ),
            trailing: const Icon(AngiIcons.chevronRight),
            onTap: () => Navigator.of(context).push(
              MaterialPageRoute<void>(builder: (_) => PlaceDetailScreen(placeId: alt.id)),
            ),
          ),
      ],
    );
  }

  Future<void> _directions(BuildContext context, Place place, S s) async {
    final destination = '${place.geo.lat},${place.geo.lng}';
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': 'walking',
    });
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.errUnknown)));
    }
  }
}

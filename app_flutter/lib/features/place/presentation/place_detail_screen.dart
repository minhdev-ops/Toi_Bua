import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/api/error_mapper.dart';
import '../../../core/api/models/dish.dart';
import '../../../core/api/models/misc.dart';
import '../../../core/api/models/place.dart';
import '../../../core/i18n/angi_format.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/i18n/server_keys.dart';
import '../../../core/theme/angi_icons.dart';
import '../../../core/theme/angi_tokens.dart';
import '../../../shared/widgets/angi_thumb.dart';
import '../../../shared/widgets/open_status_chip.dart';
import '../../../shared/widgets/stamp_badge.dart';
import '../../../shared/widgets/stamp_button.dart';
import '../../../shared/widgets/stamp_card.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../discover/presentation/why_sheet.dart';
import '../../spin/application/spin_flow.dart';
import '../data/place_repository.dart';
import 'report_sheet.dart';

/// S6. Trang chi tiết quán (FR-PLC-05) + Chỉ đường (FR-NAV-01) + Tôi đã đến (FR-NAV-04).
class PlaceDetailScreen extends ConsumerStatefulWidget {
  const PlaceDetailScreen({required this.placeId, this.initial, super.key});

  final String placeId;
  final Place? initial;

  @override
  ConsumerState<PlaceDetailScreen> createState() => _PlaceDetailScreenState();
}

class _PlaceDetailScreenState extends ConsumerState<PlaceDetailScreen> {
  bool _saved = false;
  bool _arrived = false;
  int _cooldownS = 0;

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final async = ref.watch(placeDetailProvider(widget.placeId));
    final place = async.value ?? widget.initial;

    if (place == null) {
      final error = async.error;
      final message = async.hasError && error is ApiError ? ErrorMapper.toUi(s, error).headline : s.loading;
      return Scaffold(
        appBar: AppBar(leading: IconButton(icon: const Icon(AngiIcons.chevronLeft), onPressed: () => Navigator.of(context).maybePop())),
        body: Center(child: Text(message, style: AngiRoles.of(context).body.copyWith(color: t.muted))),
      );
    }

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(AngiIcons.chevronLeft),
          onPressed: () => Navigator.of(context).maybePop(),
        ),
        title: Text(place.name, maxLines: 1, overflow: TextOverflow.ellipsis),
      ),
      body: ListView(
        padding: const EdgeInsets.only(bottom: AngiScale.s11),
        children: [
          _hero(context, place, s, t),
          if (place.why != null) _whyBlock(context, place, s, t),
          if (place.images.isNotEmpty) _photos(context, place, s, t),
          _hours(context, place, s, t),
          _menu(context, place, s, t),
          _amenities(context, place, s, t),
          if (place.reportSummary != null) _reportInfo(context, place, s, t),
          if (place.similarPlaces.isNotEmpty) _similar(context, place, s, t),
        ],
      ),
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          padding: const EdgeInsets.fromLTRB(AngiScale.s5, AngiScale.s3, AngiScale.s5, AngiScale.s4),
          decoration: BoxDecoration(
            color: t.background,
            border: Border(top: BorderSide(color: t.line, width: AngiScale.divider)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                children: [
                  StampChip(
                    label: (strings) => _arrived ? strings.ctaArrivedDone : strings.ctaArrived,
                    icon: _arrived ? AngiIcons.check : AngiIcons.directions,
                    selected: _arrived,
                    onTap: _arrived ? null : () => _markArrived(place),
                  ),
                  const SizedBox(width: AngiScale.s2),
                  StampChip(
                    label: (strings) => _saved ? strings.ctaSaved : strings.ctaSave,
                    icon: _saved ? AngiIcons.saved : AngiIcons.save,
                    selected: _saved,
                    onTap: () {
                      setState(() => _saved = true);
                      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.ctaSaved)));
                    },
                  ),
                  const SizedBox(width: AngiScale.s2),
                  StampChip(
                    label: (strings) => _cooldownS > 0 ? strings.reportCooldown(_cooldownS) : strings.ctaReport,
                    icon: AngiIcons.report,
                    onTap: _cooldownS > 0 ? null : () => _report(place),
                  ),
                ],
              ),
              const SizedBox(height: AngiScale.s3),
              StampButton(
                label: (strings) => strings.ctaNavigate,
                onPressed: () => _directions(place, s),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _hero(BuildContext context, Place place, S s, AngiTokens t) {
    final roles = AngiRoles.of(context);
    final hue = t.hue(TaxonomyTypeIndex.of(null, name: place.highlightTypeSeed ?? place.name));
    return Padding(
      padding: const EdgeInsets.fromLTRB(AngiScale.s5, AngiScale.s4, AngiScale.s5, AngiScale.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              AngiThumb(
                name: place.name,
                hue: hue,
                imageUrl: place.images.isEmpty ? null : place.images.first.url,
                size: 84,
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
                      style: roles.display.copyWith(color: t.ink, fontSize: 30),
                    ),
                    const SizedBox(height: AngiScale.s1),
                    Text(
                      place.address,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: roles.body.copyWith(color: t.muted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: AngiScale.s4),
          Wrap(
            spacing: AngiScale.s3,
            runSpacing: AngiScale.s4,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              OpenStatusChip(openStatus: place.openStatus),
              for (final badge in place.badges.take(2))
                if (ServerKeys.badge(s, badge) != null)
                  StampBadge(
                    label: (_) => ServerKeys.badge(s, badge)!,
                    fill: t.surface,
                    onFill: t.ink,
                    outline: t.ink,
                    icon: AngiIcons.check,
                  ),
            ],
          ),
          const SizedBox(height: AngiScale.s4),
          Row(
            children: [
              _stat(context, AngiFormat.distance(s, place.distanceM), s.detailDistance),
              const SizedBox(width: AngiScale.s5),
              _stat(context, AngiFormat.price(s, place.avgPriceVnd), s.detailPrice),
              const SizedBox(width: AngiScale.s5),
              _stat(
                context,
                s.ratingValue(place.ratingBayesian.toStringAsFixed(1)),
                s.detailReviews(place.reviewCount),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _stat(BuildContext context, String value, String label) {
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(value, style: roles.numeric.copyWith(color: t.ink, fontSize: 22)),
          Text(label, style: roles.micro.copyWith(color: t.muted), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _whyBlock(BuildContext context, Place place, S s, AngiTokens t) {
    final text = ServerKeys.text(s, place.why!.key, place.why!.params);
    if (text == null) return const SizedBox.shrink();
    final roles = AngiRoles.of(context);
    return Padding(
      padding: const EdgeInsets.fromLTRB(AngiScale.s5, 0, AngiScale.s5, AngiScale.s5),
      child: StampCard(
        fill: t.surface,
        shadow: AngiScale.stamp2,
        child: Row(
          children: [
            Icon(AngiIcons.why, color: t.infoText, size: AngiIcons.size),
            const SizedBox(width: AngiScale.s3),
            Expanded(child: Text(text, style: roles.body.copyWith(color: t.ink))),
            if (place.scoreBreakdown != null)
              TextButton(
                onPressed: () => showModalBottomSheet<void>(
                  context: context,
                  isScrollControlled: true,
                  useSafeArea: true,
                  builder: (_) => WhySheet(breakdown: place.scoreBreakdown!),
                ),
                child: Text(s.whyShort),
              ),
          ],
        ),
      ),
    );
  }

  Widget _photos(BuildContext context, Place place, S s, AngiTokens t) {
    return _section(
      context,
      s.detailPhotos,
      SizedBox(
        height: 150,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          padding: const EdgeInsets.symmetric(horizontal: AngiScale.s5),
          itemCount: place.images.length,
          separatorBuilder: (_, _) => const SizedBox(width: AngiScale.s3),
          itemBuilder: (context, index) {
            final image = place.images[index];
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(AngiScale.radiusSm),
                  child: Image.network(
                    image.url,
                    width: 200,
                    height: 112,
                    fit: BoxFit.cover,
                    errorBuilder: (_, _, _) => Container(
                      width: 200,
                      height: 112,
                      color: t.sunken,
                      child: Icon(AngiIcons.camera, color: t.muted),
                    ),
                  ),
                ),
                const SizedBox(height: AngiScale.s1),
                SizedBox(
                  width: 200,
                  child: Text(
                    s.detailCredit(image.credit),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AngiRoles.of(context).micro.copyWith(color: t.muted),
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _hours(BuildContext context, Place place, S s, AngiTokens t) {
    if (place.hoursByDow.isEmpty) return const SizedBox.shrink();
    final now = DateTime.now();
    final rows = [...place.hoursByDow]..sort((a, b) => a.dow.compareTo(b.dow));
    return _section(
      context,
      s.detailHours,
      Column(children: [for (final hour in rows) _hourRow(context, hour, now, s, t)]),
    );
  }

  Widget _hourRow(BuildContext context, PlaceHour hour, DateTime now, S s, AngiTokens t) {
    final roles = AngiRoles.of(context);
    final today = hour.dow == now.weekday;
    final day = now.add(Duration(days: hour.dow - now.weekday));
    final label = DateFormat.EEEE(s.localeName).format(day);
    final opens = hour.opensAt ?? '--:--';
    final closes = hour.closesAt ?? '--:--';
    final value = hour.isClosed ? s.detailClosedDay : '$opens – $closes';
    return Container(
      padding: const EdgeInsets.symmetric(vertical: AngiScale.s2, horizontal: AngiScale.s5),
      decoration: BoxDecoration(
        color: today ? t.sunken : Colors.transparent,
        border: Border(left: BorderSide(color: today ? t.accent : Colors.transparent, width: 6)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: roles.label.copyWith(
                color: today ? t.ink : t.muted,
                fontWeight: today ? FontWeight.w700 : FontWeight.w600,
              ),
            ),
          ),
          Text(value, style: roles.label.copyWith(color: today ? t.ink : t.muted)),
        ],
      ),
    );
  }

  Widget _menu(BuildContext context, Place place, S s, AngiTokens t) {
    final menu = place.menu;
    if (menu == null || menu.dishes.isEmpty) return const SizedBox.shrink();
    final roles = AngiRoles.of(context);
    return _section(
      context,
      s.detailMenu,
      Column(
        children: [
          for (final entry in menu.dishes.take(6))
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: AngiScale.s5, vertical: AngiScale.s2),
              child: Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        Flexible(
                          child: Text(
                            entry.name,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: roles.body.copyWith(color: t.ink),
                          ),
                        ),
                        if (entry.popular) ...[
                          const SizedBox(width: AngiScale.s2),
                          Icon(AngiIcons.star, size: 14, color: t.accentText),
                        ],
                      ],
                    ),
                  ),
                  Text(
                    AngiFormat.price(s, entry.priceVnd),
                    style: roles.numeric.copyWith(color: t.accentText, fontSize: 18),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _amenities(BuildContext context, Place place, S s, AngiTokens t) {
    final amenities = place.amenities;
    if (amenities == null) return const SizedBox.shrink();
    final items = <List<Object>>[
      [amenities.parking, AngiIcons.parking, s.amenityParking],
      [amenities.ac, AngiIcons.ac, s.amenityAc],
      [amenities.groupFriendly, AngiIcons.group, s.amenityGroupFriendly],
      [amenities.takeaway, AngiIcons.takeaway, s.amenityTakeaway],
      [amenities.wifi, AngiIcons.wifi, s.amenityWifi],
    ].where((item) => item[0] as bool).toList(growable: false);
    if (items.isEmpty) return const SizedBox.shrink();

    return _section(
      context,
      s.detailAmenities,
      Padding(
        padding: const EdgeInsets.symmetric(horizontal: AngiScale.s5),
        child: Wrap(
          spacing: AngiScale.s2,
          runSpacing: AngiScale.s2,
          children: [
            for (final item in items)
              StampBadge(
                label: (_) => item[2] as String,
                fill: t.surface,
                onFill: t.ink,
                outline: t.ink,
                icon: item[1] as IconData,
                tilt: false,
              ),
          ],
        ),
      ),
    );
  }

  Widget _reportInfo(BuildContext context, Place place, S s, AngiTokens t) {
    final report = place.reportSummary!;
    return Padding(
      padding: const EdgeInsets.fromLTRB(AngiScale.s5, AngiScale.s3, AngiScale.s5, AngiScale.s5),
      child: Row(
        children: [
          Icon(AngiIcons.report, size: AngiIcons.sizeInline, color: t.muted),
          const SizedBox(width: AngiScale.s2),
          Expanded(
            child: Text(
              s.detailReportCount(report.count30d, report.pending),
              style: AngiRoles.of(context).micro.copyWith(color: t.muted),
            ),
          ),
        ],
      ),
    );
  }

  Widget _similar(BuildContext context, Place place, S s, AngiTokens t) {
    return _section(
      context,
      s.detailSimilar,
      Column(
        children: [
          for (final similar in place.similarPlaces)
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: AngiScale.s5),
              title: Text(similar.name),
              subtitle: Text(AngiFormat.distance(s, similar.distanceM)),
              trailing: const Icon(AngiIcons.chevronRight),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute<void>(builder: (_) => PlaceDetailScreen(placeId: similar.id)),
              ),
            ),
        ],
      ),
    );
  }

  Widget _section(BuildContext context, String title, Widget child) {
    final t = AngiTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AngiScale.s5),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(AngiScale.s5, AngiScale.s3, AngiScale.s5, AngiScale.s3),
            child: Text(title, style: AngiRoles.of(context).sectionLabel.copyWith(color: t.muted)),
          ),
          child,
        ],
      ),
    );
  }

  Future<void> _directions(Place place, S s) async {
    final mode = switch (place.travelMode) {
      'bike' => 'bicycling',
      'car' => 'driving',
      _ => 'walking',
    };
    final destination = '${place.geo.lat},${place.geo.lng}';
    final uri = Uri.https('www.google.com', '/maps/dir/', {
      'api': '1',
      'destination': destination,
      'travelmode': mode,
    });
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(s.errUnknown)));
    }
  }

  Future<void> _markArrived(Place place) async {
    final flow = ref.read(spinFlowProvider);
    try {
      final result = await ref.read(placeRepositoryProvider).visit(
            placeId: place.id,
            dishId: flow.spin?.dish.id,
            spinId: flow.spin?.spinId,
          );
      if (!mounted) return;
      setState(() => _arrived = true);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).visitSaved)));
      if (result.askReview) {
        final prompt = ServerKeys.text(S.of(context), result.reviewPromptKey, const {});
        if (prompt != null) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(prompt)));
        }
      }
    } on ApiError catch (error) {
      if (!mounted) return;
      final ui = ErrorMapper.toUi(S.of(context), error);
      if (ui.slot == ErrorSlot.replayAsSuccess) {
        setState(() => _arrived = true);
        return;
      }
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(ui.headline)));
    }
  }

  Future<void> _report(Place place) async {
    final result = await showReportSheet(context, placeId: place.id);
    if (!mounted || result == null) return;
    setState(() => _cooldownS = result.cooldownS);
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(S.of(context).ctaReportSent)));
  }
}

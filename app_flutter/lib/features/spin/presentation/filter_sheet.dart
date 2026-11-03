import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/models/spin.dart';
import '../../../core/i18n/angi_format.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/angi_icons.dart';
import '../../../core/theme/angi_tokens.dart';
import '../../../shared/widgets/stamp_button.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../../app/application/app_providers.dart';
import '../application/spin_flow.dart';

/// S3 FilterSheet. Nhóm tối đa 4 field (DESIGN.md cognitive load), chip là control duy nhất
/// ngoài 2 slider. Diet đã lưu **không** xuất hiện ở đây để tắt (FR-ROU-03).
Future<void> showFilterSheet(BuildContext context) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => const FractionallySizedBox(
      heightFactor: 0.92,
      child: FilterSheet(),
    ),
  );
}

class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  late final Set<String> _meals;
  late final Set<String> _types;
  late final Set<String> _regions;
  late final Set<String> _moods;
  late int _budget;
  late bool _budgetTouched;
  late int? _priceMax;
  late String _temp;
  late int _party;
  late int _antiRepeat;
  late bool _antiRepeatTouched;
  String? _lockedType;

  static const int _budgetMin = 10000;
  static const int _budgetMax = 200000;
  static const int _budgetStep = 5000;

  @override
  void initState() {
    super.initState();
    final request = ref.read(spinFlowProvider).request;
    final f = request.filters;
    _meals = {...?f?.meal};
    _types = {...?f?.type};
    _regions = {...?f?.region};
    _moods = {...?f?.mood};
    _budget = f?.budgetVnd ?? 50000;
    _budgetTouched = f?.budgetVnd != null;
    _priceMax = f?.priceLevelMax;
    _temp = f?.temp ?? 'any';
    _party = f?.partySize ?? 1;
    _antiRepeat = request.antiRepeat?.days ?? ref.read(appConfigProvider).spin.antiRepeatDaysDefault;
    _antiRepeatTouched = request.antiRepeat != null;
    _lockedType = request.locked?.type;
  }

  void _toggle(Set<String> set, String value) {
    setState(() {
      if (!set.remove(value)) set.add(value);
    });
  }

  void _apply() {
    final current = ref.read(spinFlowProvider).request;
    final filters = SpinFilters(
      meal: _meals.isEmpty ? null : _meals.toList(growable: false),
      budgetVnd: _budgetTouched ? _budget : null,
      priceLevelMax: _priceMax,
      type: _types.isEmpty ? null : _types.toList(growable: false),
      region: _regions.isEmpty ? null : _regions.toList(growable: false),
      temp: _temp == 'any' ? null : _temp,
      mood: _moods.isEmpty ? null : _moods.toList(growable: false),
      partySize: _party > 1 ? _party : null,
    );
    final hasFilters = !filters.isEmpty;
    ref.read(spinFlowProvider.notifier).updateRequest(
          SpinRequest(
            filters: hasFilters ? filters : null,
            locked: _lockedType == null ? null : SpinLocked(type: _lockedType),
            diet: current.diet,
            excludeDishIds: current.excludeDishIds,
            antiRepeat: _antiRepeatTouched ? AntiRepeatRequest(days: _antiRepeat) : current.antiRepeat,
            wheelId: current.wheelId,
            travelMode: current.travelMode,
            contextOverrides: current.contextOverrides,
            clientSeed: current.clientSeed,
            networkState: current.networkState,
          ),
        );
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _meals.clear();
      _types.clear();
      _regions.clear();
      _moods.clear();
      _budget = 50000;
      _budgetTouched = false;
      _priceMax = null;
      _temp = 'any';
      _party = 1;
      _antiRepeat = ref.read(appConfigProvider).spin.antiRepeatDaysDefault;
      _antiRepeatTouched = false;
      _lockedType = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final s = S.of(context);
    final t = AngiTokens.of(context);
    final roles = AngiRoles.of(context);
    final flow = ref.watch(spinFlowProvider);
    final pool = flow.spin?.pool;

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(AngiScale.s6, 0, AngiScale.s6, AngiScale.s3),
          child: Row(
            children: [
              Expanded(child: Text(s.filterTitle, style: roles.title.copyWith(color: t.ink))),
              TextButton(onPressed: _reset, child: Text(s.filterReset)),
            ],
          ),
        ),
        Expanded(
          child: ListView(
            padding: const EdgeInsets.fromLTRB(AngiScale.s6, 0, AngiScale.s6, AngiScale.s8),
            children: [
              _group(s.filterGroupMeal, [
                Wrap(
                  spacing: AngiScale.s3,
                  runSpacing: AngiScale.s3,
                  children: [
                    for (final meal in const ['breakfast', 'lunch', 'dinner', 'late_night'])
                      StampChip(
                        label: (strings) => _mealLabel(strings, meal),
                        selected: _meals.contains(meal),
                        onTap: () => _toggle(_meals, meal),
                      ),
                  ],
                ),
              ]),
              _group(s.filterGroupMoney, [
                _budgetBlock(s, t, roles),
                const SizedBox(height: AngiScale.s4),
                Wrap(
                  spacing: AngiScale.s3,
                  runSpacing: AngiScale.s3,
                  children: [
                    for (var level = 1; level <= 4; level++)
                      StampChip(
                        label: (strings) => _priceLabel(strings, level),
                        selected: _priceMax == level,
                        onTap: () => setState(() => _priceMax = _priceMax == level ? null : level),
                      ),
                  ],
                ),
              ]),
              _group(s.filterGroupTypeRegion, [
                Wrap(
                  spacing: AngiScale.s3,
                  runSpacing: AngiScale.s3,
                  children: [
                    for (final type in DishType.values)
                      StampChip(
                        label: (strings) => _typeLabel(strings, type),
                        hue: t.hues[type],
                        icon: _typeIcon(type),
                        selected: _types.contains(type.name),
                        onTap: () => _toggle(_types, type.name),
                      ),
                  ],
                ),
                const SizedBox(height: AngiScale.s4),
                Wrap(
                  spacing: AngiScale.s3,
                  runSpacing: AngiScale.s3,
                  children: [
                    for (final region in const ['north', 'central', 'south', 'all'])
                      StampChip(
                        label: (strings) => _regionLabel(strings, region),
                        selected: _regions.contains(region),
                        onTap: () => _toggle(_regions, region),
                      ),
                  ],
                ),
                const SizedBox(height: AngiScale.s4),
                Wrap(
                  spacing: AngiScale.s3,
                  runSpacing: AngiScale.s3,
                  children: [
                    for (final temp in const ['hot', 'warm', 'cold', 'any'])
                      StampChip(
                        label: (strings) => _tempLabel(strings, temp),
                        selected: _temp == temp,
                        onTap: () => setState(() => _temp = temp),
                      ),
                  ],
                ),
                if (_types.length == 1) ...[
                  const SizedBox(height: AngiScale.s5),
                  Text(s.filterLockHint, style: roles.micro.copyWith(color: t.muted)),
                  const SizedBox(height: AngiScale.s3),
                  StampChip(
                    label: (strings) => _lockedType == null
                        ? strings.filterLock(_typeLabel(strings, DishType.values.byName(_types.first)))
                        : strings.filterUnlock,
                    icon: _lockedType == null ? AngiIcons.lock : AngiIcons.lockOpen,
                    selected: _lockedType != null,
                    onTap: () => setState(() => _lockedType = _lockedType == null ? _types.first : null),
                  ),
                ],
              ]),
              _group(s.filterGroupMoodParty, [
                Wrap(
                  spacing: AngiScale.s3,
                  runSpacing: AngiScale.s3,
                  children: [
                    for (final mood in const ['comfort', 'light', 'greedy', 'fresh', 'local_specialty', 'quick'])
                      StampChip(
                        label: (strings) => _moodLabel(strings, mood),
                        selected: _moods.contains(mood),
                        onTap: () => _toggle(_moods, mood),
                      ),
                  ],
                ),
                const SizedBox(height: AngiScale.s5),
                _sliderLabel(roles, t, s.filterPartySize, '$_party'),
                Slider(
                  value: _party.toDouble(),
                  min: 1,
                  max: 12,
                  divisions: 11,
                  onChanged: (value) => setState(() => _party = value.round()),
                ),
              ]),
              _group(s.filterAntiRepeat, [
                Align(
                  alignment: Alignment.centerRight,
                  child: Text(
                    _antiRepeat == 0 ? s.filterDaysOff : s.filterDaysN(_antiRepeat),
                    style: roles.numeric.copyWith(color: t.accentText, fontSize: 18),
                  ),
                ),
                Slider(
                  value: _antiRepeat.toDouble(),
                  min: 0,
                  max: 30,
                  divisions: 30,
                  onChanged: (value) => setState(() {
                    _antiRepeat = value.round();
                    _antiRepeatTouched = true;
                  }),
                ),
              ]),
              const SizedBox(height: AngiScale.s3),
              Container(
                padding: const EdgeInsets.all(AngiScale.s4),
                decoration: BoxDecoration(
                  color: t.sunken,
                  borderRadius: BorderRadius.circular(AngiScale.radiusSm),
                  border: Border.all(color: t.ink, width: AngiScale.outline),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(s.filterDietTitle, style: roles.sectionLabel.copyWith(color: t.ink)),
                    const SizedBox(height: AngiScale.s2),
                    Text(s.filterDietLockedHint, style: roles.micro.copyWith(color: t.muted)),
                  ],
                ),
              ),
              if (pool != null) ...[
                const SizedBox(height: AngiScale.s4),
                Text(
                  s.filterPoolLine(pool.sizeInitial, pool.sizeFinal),
                  style: roles.label.copyWith(color: t.muted),
                ),
                const SizedBox(height: AngiScale.s1),
                Text(
                  s.filterPoolRemoved(
                    pool.removed.dietHard,
                    pool.removed.excluded,
                    pool.removed.locked,
                    pool.removed.filters,
                    pool.removed.antiRepeat,
                  ),
                  style: roles.micro.copyWith(color: t.muted),
                ),
              ],
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(AngiScale.s6, AngiScale.s3, AngiScale.s6, AngiScale.s6),
          child: StampButton(label: (strings) => strings.ctaApply, onPressed: _apply),
        ),
      ],
    );
  }

  Widget _group(String title, List<Widget> children) {
    final t = AngiTokens.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: AngiScale.s6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AngiRoles.of(context).sectionLabel.copyWith(color: t.muted)),
          const SizedBox(height: AngiScale.s3),
          ...children,
        ],
      ),
    );
  }

  Widget _budgetBlock(S s, AngiTokens t, AngiRoles roles) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sliderLabel(roles, t, s.filterBudget, AngiFormat.price(s, _budget)),
        Slider(
          value: _budget.toDouble(),
          min: _budgetMin.toDouble(),
          max: _budgetMax.toDouble(),
          divisions: (_budgetMax - _budgetMin) ~/ _budgetStep,
          onChanged: (value) => setState(() {
            _budget = (value / _budgetStep).round() * _budgetStep;
            _budgetTouched = true;
          }),
        ),
      ],
    );
  }

  Widget _sliderLabel(AngiRoles roles, AngiTokens t, String label, String value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: roles.label.copyWith(color: t.ink)),
        Text(value, style: roles.numeric.copyWith(color: t.accentText, fontSize: 18)),
      ],
    );
  }

  static IconData _typeIcon(DishType type) => switch (type) {
        DishType.noodle => Icons.ramen_dining,
        DishType.rice => Icons.rice_bowl,
        DishType.bread => Icons.bakery_dining,
        DishType.sweet => Icons.icecream,
        DishType.grill => Icons.local_fire_department,
        DishType.salad => Icons.eco,
        DishType.drink => Icons.local_cafe,
        DishType.snack => Icons.cookie,
      };

  static String _mealLabel(S s, String meal) => switch (meal) {
        'breakfast' => s.mealBreakfast,
        'lunch' => s.mealLunch,
        'dinner' => s.mealDinner,
        _ => s.mealLateNight,
      };

  static String _regionLabel(S s, String region) => switch (region) {
        'north' => s.regionNorth,
        'central' => s.regionCentral,
        'south' => s.regionSouth,
        _ => s.regionAll,
      };

  static String _tempLabel(S s, String temp) => switch (temp) {
        'hot' => s.tempHot,
        'warm' => s.tempWarm,
        'cold' => s.tempCold,
        _ => s.tempAny,
      };

  static String _moodLabel(S s, String mood) => switch (mood) {
        'comfort' => s.moodComfort,
        'light' => s.moodLight,
        'greedy' => s.moodGreedy,
        'fresh' => s.moodFresh,
        'local_specialty' => s.moodLocalSpecialty,
        _ => s.moodQuick,
      };

  static String _typeLabel(S s, DishType type) => switch (type) {
        DishType.noodle => s.typeNoodle,
        DishType.rice => s.typeRice,
        DishType.bread => s.typeBread,
        DishType.sweet => s.typeSweet,
        DishType.grill => s.typeGrill,
        DishType.salad => s.typeSalad,
        DishType.drink => s.typeDrink,
        DishType.snack => s.typeSnack,
      };

  static String _priceLabel(S s, int level) => switch (level) {
        1 => s.priceLevel1,
        2 => s.priceLevel2,
        3 => s.priceLevel3,
        _ => s.priceLevel4,
      };
}

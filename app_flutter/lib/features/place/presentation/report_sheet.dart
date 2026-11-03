import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/api/error_mapper.dart';
import '../../../core/api/models/misc.dart';
import '../../../core/i18n/app_localizations.dart';
import '../../../core/theme/angi_tokens.dart';
import '../../../shared/widgets/stamp_button.dart';
import '../../../shared/widgets/stamp_chip.dart';
import '../data/place_repository.dart';

Future<ReportResult?> showReportSheet(BuildContext context, {required String placeId}) {
  return showModalBottomSheet<ReportResult>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    builder: (_) => ReportSheet(placeId: placeId),
  );
}

/// S8. Báo sai thông tin (FR-PLC-07). Mọi POST ghi đều có idempotency key.
class ReportSheet extends ConsumerStatefulWidget {
  const ReportSheet({required this.placeId, super.key});

  final String placeId;

  @override
  ConsumerState<ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends ConsumerState<ReportSheet> {
  static const List<String> _kinds = [
    'closed',
    'wrong_hours',
    'wrong_price',
    'wrong_location',
    'wrong_name',
    'duplicate',
    'other',
  ];

  final TextEditingController _detail = TextEditingController();
  String? _kind;
  bool _sending = false;
  String? _error;

  @override
  void dispose() {
    _detail.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final kind = _kind;
    if (kind == null || _sending) return;
    final s = S.of(context);
    setState(() {
      _sending = true;
      _error = null;
    });
    try {
      final result = await ref.read(placeRepositoryProvider).report(
            widget.placeId,
            kind: kind,
            detail: _detail.text,
          );
      if (mounted) Navigator.of(context).pop(result);
    } on ApiError catch (error) {
      if (!mounted) return;
      final ui = ErrorMapper.toUi(s, error);
      if (ui.slot == ErrorSlot.replayAsSuccess) {
        Navigator.of(context).pop(
          ReportResult(reportId: '', status: 'duplicate', duplicateOf: widget.placeId),
        );
        return;
      }
      setState(() {
        _sending = false;
        _error = ui.headline;
      });
    }
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
          Text(s.reportSheetTitle, style: roles.title.copyWith(color: t.ink)),
          const SizedBox(height: AngiScale.s5),
          Text(s.reportKindLabel, style: roles.sectionLabel.copyWith(color: t.muted)),
          const SizedBox(height: AngiScale.s3),
          Wrap(
            spacing: AngiScale.s2,
            runSpacing: AngiScale.s2,
            children: [
              for (final kind in _kinds)
                StampChip(
                  label: (strings) => _kindLabel(strings, kind),
                  selected: _kind == kind,
                  onTap: () => setState(() => _kind = kind),
                ),
            ],
          ),
          const SizedBox(height: AngiScale.s5),
          TextField(
            controller: _detail,
            maxLines: 3,
            maxLength: 500,
            style: roles.body.copyWith(color: t.ink),
            decoration: InputDecoration(
              hintText: s.reportDetailHint,
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
          if (_error != null) ...[
            const SizedBox(height: AngiScale.s2),
            Text(_error!, style: roles.label.copyWith(color: t.dangerText)),
          ],
          const SizedBox(height: AngiScale.s4),
          StampButton(
            label: (strings) => strings.reportSubmit,
            loading: _sending,
            enabled: _kind != null,
            onPressed: _submit,
          ),
        ],
      ),
    );
  }

  static String _kindLabel(S s, String kind) => switch (kind) {
        'closed' => s.reportKindClosed,
        'wrong_hours' => s.reportKindWrongHours,
        'wrong_price' => s.reportKindWrongPrice,
        'wrong_location' => s.reportKindWrongLocation,
        'wrong_name' => s.reportKindWrongName,
        'duplicate' => s.reportKindDuplicate,
        _ => s.reportKindOther,
      };
}

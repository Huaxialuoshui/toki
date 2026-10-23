import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../application/planning/daily_planning_service.dart';
import '../../application/planning/planning_context.dart';
import '../../core/errors/planning_exception.dart';
import '../../core/extensions/l10n_extension.dart';
import '../../infrastructure/clock_provider.dart';
import '../../l10n/generated/app_localizations.dart';
import '../../shared/widgets/glass_card.dart';

enum _EnergyLevel { low, normal, high }

Future<GeneratedPlanDraft?> showPlanGenerationDialog(
  BuildContext context, {
  DateTime? day,
}) {
  return showDialog<GeneratedPlanDraft>(
    context: context,
    barrierDismissible: false,
    builder: (BuildContext dialogContext) => PlanGenerationDialog(day: day),
  );
}

class PlanGenerationDialog extends ConsumerStatefulWidget {
  const PlanGenerationDialog({super.key, this.day});

  final DateTime? day;

  @override
  ConsumerState<PlanGenerationDialog> createState() =>
      _PlanGenerationDialogState();
}

class _PlanGenerationDialogState extends ConsumerState<PlanGenerationDialog> {
  final TextEditingController _goal = TextEditingController();
  final TextEditingController _notes = TextEditingController();
  _EnergyLevel _energy = _EnergyLevel.normal;
  bool _busy = false;
  String? _error;

  @override
  void dispose() {
    _goal.dispose();
    _notes.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final l10n = context.l10n;
    final theme = Theme.of(context);
    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: GlassCard(
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              Row(
                children: <Widget>[
                  Expanded(
                    child: Text(
                      l10n.planGenerationTitle,
                      style: theme.textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close),
                    tooltip: l10n.planApplyCancel,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _goal,
                autofocus: true,
                minLines: 2,
                maxLines: 3,
                decoration: InputDecoration(labelText: l10n.planGoalField),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _notes,
                minLines: 2,
                maxLines: 4,
                decoration: InputDecoration(labelText: l10n.planNotesField),
              ),
              const SizedBox(height: 14),
              DropdownButtonFormField<_EnergyLevel>(
                value: _energy,
                decoration: InputDecoration(labelText: l10n.planEnergy),
                items: <DropdownMenuItem<_EnergyLevel>>[
                  DropdownMenuItem<_EnergyLevel>(
                    value: _EnergyLevel.low,
                    child: Text(l10n.planEnergyLow),
                  ),
                  DropdownMenuItem<_EnergyLevel>(
                    value: _EnergyLevel.normal,
                    child: Text(l10n.planEnergyNormal),
                  ),
                  DropdownMenuItem<_EnergyLevel>(
                    value: _EnergyLevel.high,
                    child: Text(l10n.planEnergyHigh),
                  ),
                ],
                onChanged: _busy
                    ? null
                    : (_EnergyLevel? value) => setState(
                          () => _energy = value ?? _EnergyLevel.normal,
                        ),
              ),
              if (_busy) ...<Widget>[
                const SizedBox(height: 16),
                Row(
                  children: <Widget>[
                    const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 10),
                    Text(l10n.planGenerating),
                  ],
                ),
              ],
              if (_error != null) ...<Widget>[
                const SizedBox(height: 12),
                Text(
                  _error!,
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.error,
                  ),
                ),
              ],
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: <Widget>[
                  TextButton(
                    onPressed: _busy ? null : () => Navigator.of(context).pop(),
                    child: Text(l10n.planApplyCancel),
                  ),
                  const SizedBox(width: 8),
                  FilledButton.icon(
                    onPressed: _busy ? null : _generate,
                    icon: const Icon(Icons.auto_awesome, size: 18),
                    label: Text(l10n.planGenerate),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _generate() async {
    final l10n = context.l10n;
    final navigator = Navigator.of(context);
    final day = widget.day ?? ref.read(clockProvider).now();
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final result = await ref.read(dailyPlanningServiceProvider).generateDraft(
            PlanningRequest(
              day: day,
              goalText: _goal.text.trim().isEmpty ? null : _goal.text.trim(),
              notes: _notes.text.trim().isEmpty ? null : _notes.text.trim(),
              energy: switch (_energy) {
                _EnergyLevel.low => 'low',
                _EnergyLevel.normal => 'normal',
                _EnergyLevel.high => 'high',
              },
            ),
          );
      if (!mounted) return;
      navigator.pop(result);
    } on PlanningException catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = _errorText(l10n, error);
      });
    } on Object catch (error) {
      if (!mounted) return;
      setState(() {
        _busy = false;
        _error = '${l10n.planGenerateFailed}：$error';
      });
    }
  }

  static String _errorText(
    AppLocalizations l10n,
    PlanningException error,
  ) {
    return switch (error.code) {
      PlanningErrorCode.noProvider => l10n.planNoProvider,
      PlanningErrorCode.cancelled => l10n.planApplyCancel,
      PlanningErrorCode.parseFailed ||
      PlanningErrorCode.validationFailed =>
        l10n.planGenerateFailed,
      PlanningErrorCode.planStale => l10n.planStale,
      PlanningErrorCode.planConflict => l10n.planConflict,
      PlanningErrorCode.taskMissing => l10n.taskMissing,
      _ => '${l10n.planGenerateFailed}：${error.message ?? error.code.name}',
    };
  }
}

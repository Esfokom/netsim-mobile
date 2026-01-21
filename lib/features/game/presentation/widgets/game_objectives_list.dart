import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/scenario_condition.dart';

/// Reusable widget for displaying scenario objectives/conditions
/// Shows objectives list with pass/fail indicators
class GameObjectivesList extends StatelessWidget {
  final List<ScenarioCondition> conditions;
  final Map<String, bool>? results;
  final bool showStatus;

  const GameObjectivesList({
    super.key,
    required this.conditions,
    this.results,
    this.showStatus = false,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              Icons.flag,
              size: 16,
              color: Theme.of(context).colorScheme.primary,
            ),
            const SizedBox(width: 8),
            Text(
              'Objectives (${conditions.length})',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        ...conditions.map(
          (condition) =>
              _buildObjectiveItem(context, condition, results?[condition.id]),
        ),
      ],
    );
  }

  Widget _buildObjectiveItem(
    BuildContext context,
    ScenarioCondition condition,
    bool? passed,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: _getBackgroundColor(passed),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _getBorderColor(passed), width: 1),
      ),
      child: Row(
        children: [
          if (showStatus && passed != null)
            Icon(
              passed ? Icons.check_circle : Icons.cancel,
              size: 16,
              color: passed ? Colors.green : Colors.red,
            )
          else
            Icon(Icons.circle_outlined, size: 16, color: Colors.grey.shade600),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              condition.description,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Color _getBackgroundColor(bool? passed) {
    if (passed == null) return Colors.grey.withValues(alpha: 0.1);
    return passed
        ? Colors.green.withValues(alpha: 0.1)
        : Colors.red.withValues(alpha: 0.1);
  }

  Color _getBorderColor(bool? passed) {
    if (passed == null) return Colors.grey.withValues(alpha: 0.3);
    return passed
        ? Colors.green.withValues(alpha: 0.3)
        : Colors.red.withValues(alpha: 0.3);
  }
}

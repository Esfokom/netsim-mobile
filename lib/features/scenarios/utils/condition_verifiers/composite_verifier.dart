import 'package:netsim_mobile/features/scenarios/domain/entities/scenario_condition.dart';
import 'package:netsim_mobile/features/canvas/presentation/providers/canvas_provider.dart';

/// Verify composite conditions (multiple sub-conditions)
class CompositeVerifier {
  /// Verify a composite condition
  static bool verify({
    required ScenarioCondition condition,
    required CanvasState canvasState,
    required Function(SubCondition, CanvasState) verifySubCondition,
  }) {
    if (condition.subConditions == null || condition.subConditions!.isEmpty) {
      return false;
    }

    // Verify each sub-condition
    final results = condition.subConditions!.map((subCondition) {
      return verifySubCondition(subCondition, canvasState);
    }).toList();

    // Apply composite logic
    switch (condition.compositeLogic ?? CompositeLogic.and) {
      case CompositeLogic.and:
        // All sub-conditions must be true
        return results.every((result) => result);

      case CompositeLogic.or:
        // At least one sub-condition must be true
        return results.any((result) => result);
    }
  }

  /// Convert SubCondition to ScenarioCondition for verification
  static ScenarioCondition subConditionToScenarioCondition(
    SubCondition subCondition,
  ) {
    // Extract parameters and create full condition
    return ScenarioCondition(
      id: subCondition.id,
      description: '',
      type: subCondition.type,
      targetDeviceID: subCondition.parameters['targetDeviceID'] as String?,
      property: subCondition.parameters['property'] as String?,
      operator: _parseOperator(subCondition.parameters['operator']),
      expectedValue: subCondition.parameters['expectedValue'] as String?,
      interfaceName: subCondition.parameters['interfaceName'] as String?,
      targetIpForCheck: subCondition.parameters['targetIpForCheck'] as String?,
      targetNetworkForCheck:
          subCondition.parameters['targetNetworkForCheck'] as String?,
      targetDeviceIdForLink:
          subCondition.parameters['targetDeviceIdForLink'] as String?,
    );
  }

  /// Parse operator from string/dynamic
  static PropertyOperator? _parseOperator(dynamic op) {
    if (op == null) return null;
    final opStr = op.toString().toLowerCase();
    return PropertyOperator.values.firstWhere(
      (e) => e.name.toLowerCase() == opStr,
      orElse: () => PropertyOperator.equals,
    );
  }
}

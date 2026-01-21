import 'package:netsim_mobile/features/devices/domain/interfaces/device_property.dart';
import 'package:netsim_mobile/features/scenarios/domain/entities/scenario_condition.dart';

/// Helper to get property data type from DeviceProperty
PropertyDataType getPropertyDataType(DeviceProperty property) {
  if (property is BooleanProperty) {
    return PropertyDataType.boolean;
  } else if (property is IntegerProperty) {
    return PropertyDataType.integer;
  } else if (property is IpAddressProperty) {
    return PropertyDataType.ipAddress;
  } else {
    // StringProperty, MacAddressProperty, SelectionProperty, StatusProperty
    return PropertyDataType.string;
  }
}

/// Helper to get actual property value as string for comparison
String getPropertyValueAsString(DeviceProperty property) {
  if (property is BooleanProperty) {
    return property.value.toString();
  } else if (property is IntegerProperty) {
    return property.value.toString();
  } else {
    // All other types have String values
    return property.value.toString();
  }
}

/// Helper to verify if a property matches a condition
bool verifyPropertyCondition({
  required DeviceProperty property,
  required PropertyOperator operator,
  required String expectedValue,
  required PropertyDataType dataType,
}) {
  switch (dataType) {
    case PropertyDataType.boolean:
      if (property is! BooleanProperty) return false;
      final actualValue = property.value;
      final expected = expectedValue.toLowerCase() == 'true';

      switch (operator) {
        case PropertyOperator.equals:
          return actualValue == expected;
        case PropertyOperator.notEquals:
          return actualValue != expected;
        default:
          return false;
      }

    case PropertyDataType.integer:
      if (property is! IntegerProperty) return false;
      final actualValue = property.value;
      final expected = int.tryParse(expectedValue);
      if (expected == null) return false;

      switch (operator) {
        case PropertyOperator.equals:
          return actualValue == expected;
        case PropertyOperator.notEquals:
          return actualValue != expected;
        case PropertyOperator.greaterThan:
          return actualValue > expected;
        case PropertyOperator.lessThan:
          return actualValue < expected;
        default:
          return false;
      }

    case PropertyDataType.string:
    case PropertyDataType.ipAddress:
      final actualValue = getPropertyValueAsString(property);

      switch (operator) {
        case PropertyOperator.equals:
          return actualValue == expectedValue;
        case PropertyOperator.notEquals:
          return actualValue != expectedValue;
        case PropertyOperator.contains:
          return actualValue.contains(expectedValue);
        default:
          return false;
      }
  }
}

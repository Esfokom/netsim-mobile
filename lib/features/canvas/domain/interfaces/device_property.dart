import 'package:flutter/material.dart';

/// Base property that all device properties extend from
abstract class DeviceProperty<T> {
  final String id;
  final String label;
  final bool isReadOnly;
  T value;

  DeviceProperty({
    required this.id,
    required this.label,
    required this.value,
    this.isReadOnly = false,
  });

  /// Widget to display this property in the UI
  Widget buildDisplayWidget();

  /// Widget to edit this property (if not read-only)
  Widget? buildEditWidget(Function(T) onChanged);
}

/// String property
class StringProperty extends DeviceProperty<String> {
  StringProperty({
    required super.id,
    required super.label,
    required super.value,
    super.isReadOnly,
  });

  @override
  Widget buildDisplayWidget() {
    return ListTile(title: Text(label), subtitle: Text(value), dense: true);
  }

  @override
  Widget? buildEditWidget(Function(String) onChanged) {
    if (isReadOnly) return null;
    return TextField(
      decoration: InputDecoration(labelText: label),
      controller: TextEditingController(text: value),
      onChanged: onChanged,
    );
  }
}

/// IP Address property
class IpAddressProperty extends DeviceProperty<String> {
  IpAddressProperty({
    required super.id,
    required super.label,
    required super.value,
    super.isReadOnly,
  });

  @override
  Widget buildDisplayWidget() {
    return ListTile(
      leading: const Icon(Icons.settings_ethernet),
      title: Text(label),
      subtitle: Text(value.isEmpty ? 'Not configured' : value),
      dense: true,
    );
  }

  @override
  Widget? buildEditWidget(Function(String) onChanged) {
    if (isReadOnly) return null;
    return TextField(
      decoration: InputDecoration(labelText: label, hintText: '192.168.1.1'),
      controller: TextEditingController(text: value),
      keyboardType: TextInputType.number,
      onChanged: onChanged,
    );
  }
}

/// MAC Address property (always read-only)
class MacAddressProperty extends DeviceProperty<String> {
  MacAddressProperty({
    required super.id,
    required super.label,
    required super.value,
  }) : super(isReadOnly: true);

  @override
  Widget buildDisplayWidget() {
    return ListTile(
      leading: const Icon(Icons.fingerprint),
      title: Text(label),
      subtitle: Text(value),
      dense: true,
    );
  }

  @override
  Widget? buildEditWidget(Function(String) onChanged) => null;
}

/// Boolean property (switch/toggle)
class BooleanProperty extends DeviceProperty<bool> {
  BooleanProperty({
    required super.id,
    required super.label,
    required super.value,
    super.isReadOnly,
  });

  @override
  Widget buildDisplayWidget() {
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: isReadOnly ? null : (val) {},
      dense: true,
    );
  }

  @override
  Widget? buildEditWidget(Function(bool) onChanged) {
    if (isReadOnly) return null;
    return SwitchListTile(
      title: Text(label),
      value: value,
      onChanged: onChanged,
    );
  }
}

/// Enum/Selection property
class SelectionProperty extends DeviceProperty<String> {
  final List<String> options;

  SelectionProperty({
    required super.id,
    required super.label,
    required super.value,
    required this.options,
    super.isReadOnly,
  });

  @override
  Widget buildDisplayWidget() {
    return ListTile(
      title: Text(label),
      subtitle: Text(value),
      trailing: isReadOnly ? null : const Icon(Icons.arrow_drop_down),
      dense: true,
    );
  }

  @override
  Widget? buildEditWidget(Function(String) onChanged) {
    if (isReadOnly) return null;
    return DropdownButtonFormField<String>(
      decoration: InputDecoration(labelText: label),
      value: value,
      items: options.map((option) {
        return DropdownMenuItem(value: option, child: Text(option));
      }).toList(),
      onChanged: (val) {
        if (val != null) onChanged(val);
      },
    );
  }
}

/// Status indicator property (colored)
class StatusProperty extends DeviceProperty<String> {
  final Color color;

  StatusProperty({
    required super.id,
    required super.label,
    required super.value,
    required this.color,
  }) : super(isReadOnly: true);

  @override
  Widget buildDisplayWidget() {
    return ListTile(
      leading: Icon(Icons.circle, color: color, size: 12),
      title: Text(label),
      subtitle: Text(value),
      dense: true,
    );
  }

  @override
  Widget? buildEditWidget(Function(String) onChanged) => null;
}

/// Integer property
class IntegerProperty extends DeviceProperty<int> {
  final int? min;
  final int? max;

  IntegerProperty({
    required super.id,
    required super.label,
    required super.value,
    super.isReadOnly,
    this.min,
    this.max,
  });

  @override
  Widget buildDisplayWidget() {
    return ListTile(
      title: Text(label),
      subtitle: Text(value.toString()),
      dense: true,
    );
  }

  @override
  Widget? buildEditWidget(Function(int) onChanged) {
    if (isReadOnly) return null;
    return TextField(
      decoration: InputDecoration(labelText: label),
      controller: TextEditingController(text: value.toString()),
      keyboardType: TextInputType.number,
      onChanged: (val) {
        final intVal = int.tryParse(val);
        if (intVal != null) onChanged(intVal);
      },
    );
  }
}

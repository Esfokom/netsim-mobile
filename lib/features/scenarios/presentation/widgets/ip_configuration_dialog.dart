import 'package:flutter/material.dart';
import 'package:netsim_mobile/features/devices/domain/entities/end_device.dart';
import 'package:netsim_mobile/features/devices/domain/entities/network_device.dart';
import 'package:netsim_mobile/core/utils/ip_validator.dart';

/// Dialog for configuring IP address settings on an End Device
class IpConfigurationDialog extends StatefulWidget {
  final EndDevice device;
  final List<NetworkDevice> allDevices;
  final Function(String ip, String subnet, String gateway) onSave;

  const IpConfigurationDialog({
    super.key,
    required this.device,
    required this.allDevices,
    required this.onSave,
  });

  @override
  State<IpConfigurationDialog> createState() => _IpConfigurationDialogState();
}

class _IpConfigurationDialogState extends State<IpConfigurationDialog> {
  late TextEditingController _ipController;
  late TextEditingController _subnetController;
  late TextEditingController _gatewayController;

  String? _ipError;
  String? _subnetError;
  String? _gatewayError;

  @override
  void initState() {
    super.initState();
    final iface = widget.device.defaultInterface;
    _ipController = TextEditingController(text: iface.ipAddress ?? '');
    _subnetController = TextEditingController(
      text: iface.subnetMask ?? '255.255.255.0',
    );
    _gatewayController = TextEditingController(
      text: iface.defaultGateway ?? '',
    );
  }

  @override
  void dispose() {
    _ipController.dispose();
    _subnetController.dispose();
    _gatewayController.dispose();
    super.dispose();
  }

  /// Validate IP address with duplicate checking
  String? _validateIpAddress(String value) {
    if (value.isEmpty) return 'IP address is required';

    // Use existing IpValidator
    final error = IpValidator.getValidationError(value);
    if (error != null) return error;

    // Check for duplicate IP (excluding current device)
    final duplicate = IpValidator.isDuplicateIp(
      value,
      widget.device.deviceId,
      widget.allDevices,
    );

    if (duplicate) {
      return 'IP address already in use by another device';
    }

    return null;
  }

  /// Validate subnet mask
  String? _validateSubnetMask(String value) {
    if (value.isEmpty) return 'Subnet mask is required';

    return IpValidator.validateSubnetMask(value);
  }

  /// Validate gateway (optional but must be valid and in subnet if provided)
  String? _validateGateway(String value) {
    if (value.isEmpty) return null; // Gateway is optional

    final error = IpValidator.getValidationError(value);
    if (error != null) return error;

    // Check if gateway is in same subnet
    final ipAddress = _ipController.text;
    final subnetMask = _subnetController.text;

    if (ipAddress.isNotEmpty &&
        subnetMask.isNotEmpty &&
        IpValidator.isValidIpv4(ipAddress) &&
        IpValidator.isValidIpv4(subnetMask)) {
      if (!IpValidator.isGatewayInSubnet(value, ipAddress, subnetMask)) {
        return 'Gateway must be in same subnet as IP address';
      }
    }

    return null;
  }

  /// Save configuration
  void _save() {
    setState(() {
      _ipError = _validateIpAddress(_ipController.text);
      _subnetError = _validateSubnetMask(_subnetController.text);
      _gatewayError = _validateGateway(_gatewayController.text);
    });

    if (_ipError == null && _subnetError == null && _gatewayError == null) {
      widget.onSave(
        _ipController.text,
        _subnetController.text,
        _gatewayController.text,
      );
      Navigator.pop(context, true);

      // Show success snackbar
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('IP configuration updated successfully'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: Row(
        children: [
          const Icon(Icons.settings_ethernet, size: 24),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Configure IP - ${widget.device.hostname}',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
      content: SingleChildScrollView(
        child: SizedBox(
          width: MediaQuery.of(context).size.width * 0.8,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // IP Address Field
              _buildIpField(
                controller: _ipController,
                label: 'IP Address',
                hint: '192.168.1.10',
                error: _ipError,
                icon: Icons.computer,
                onChanged: (value) {
                  setState(() {
                    _ipError = _validateIpAddress(value);
                  });
                },
              ),
              const SizedBox(height: 16),

              // Subnet Mask Field
              _buildIpField(
                controller: _subnetController,
                label: 'Subnet Mask',
                hint: '255.255.255.0',
                error: _subnetError,
                icon: Icons.network_check,
                onChanged: (value) {
                  setState(() {
                    _subnetError = _validateSubnetMask(value);
                    // Re-validate gateway when subnet changes
                    if (_gatewayController.text.isNotEmpty) {
                      _gatewayError = _validateGateway(_gatewayController.text);
                    }
                  });
                },
              ),
              const SizedBox(height: 16),

              // Default Gateway Field (optional)
              _buildIpField(
                controller: _gatewayController,
                label: 'Default Gateway (Optional)',
                hint: '192.168.1.1',
                error: _gatewayError,
                icon: Icons.router,
                onChanged: (value) {
                  setState(() {
                    _gatewayError = _validateGateway(value);
                  });
                },
              ),

              // Informational note
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.info_outline,
                      size: 20,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Routing table will be automatically updated with directly connected routes.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.blue.shade700,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _save,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue,
            foregroundColor: Colors.white,
          ),
          child: const Text('Save'),
        ),
      ],
    );
  }

  Widget _buildIpField({
    required TextEditingController controller,
    required String label,
    required String hint,
    String? error,
    required IconData icon,
    required Function(String) onChanged,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          decoration: InputDecoration(
            hintText: hint,
            errorText: error,
            border: const OutlineInputBorder(),
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 12,
              vertical: 12,
            ),
            prefixIcon: Icon(icon, size: 20),
            errorMaxLines: 2,
          ),
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          onChanged: onChanged,
        ),
      ],
    );
  }
}

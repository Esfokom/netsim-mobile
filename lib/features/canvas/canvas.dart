// Canvas feature exports

// Domain Layer - Entities
export 'domain/entities/network_device.dart';
export 'domain/entities/end_device.dart';
export 'domain/entities/server_device.dart';
export 'domain/entities/switch_device.dart';
export 'domain/entities/router_device.dart';
export 'domain/entities/firewall_device.dart';
export 'domain/entities/wireless_access_point.dart';

// Domain Layer - Interfaces
export 'domain/interfaces/device_capability.dart';
export 'domain/interfaces/device_property.dart';

// Domain Layer - Factories
export 'domain/factories/device_factory.dart';

// Data Layer (hide old DeviceStatus to avoid conflict with new one)
export 'data/models/canvas_device.dart'
    hide DeviceStatus, DeviceStatusExtension;
export 'data/models/device_link.dart';

// Presentation Layer
export 'presentation/providers/canvas_provider.dart';
export 'presentation/widgets/network_canvas.dart';
export 'presentation/widgets/canvas_device_widget.dart';
export 'presentation/widgets/links_painter.dart';
export 'presentation/widgets/device_details_panel.dart';

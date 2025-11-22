/// Represents a single entry in the routing table
class RoutingEntry {
  /// Destination network address (e.g., "192.168.1.0")
  final String destinationNetwork;

  /// Subnet mask (e.g., "255.255.255.0")
  final String subnetMask;

  /// Gateway IP address (null means directly connected)
  final String? gateway;

  /// Interface to use for this route (e.g., "eth0")
  final String interfaceName;

  /// Metric (priority/cost) - lower is better
  final int metric;

  /// Is this a default route (0.0.0.0/0.0.0.0)?
  bool get isDefaultRoute =>
      destinationNetwork == '0.0.0.0' && subnetMask == '0.0.0.0';

  RoutingEntry({
    required this.destinationNetwork,
    required this.subnetMask,
    this.gateway,
    required this.interfaceName,
    this.metric = 0,
  });

  /// Calculate prefix length from subnet mask
  int get prefixLength {
    try {
      final parts = subnetMask.split('.').map(int.parse).toList();
      if (parts.length != 4) return 0;

      int bits = 0;
      for (final part in parts) {
        bits += part.toRadixString(2).replaceAll('0', '').length;
      }
      return bits;
    } catch (e) {
      return 0;
    }
  }

  /// Check if this route matches the given destination IP
  bool matches(String destIp) {
    try {
      final destParts = destIp.split('.').map(int.parse).toList();
      final networkParts = destinationNetwork
          .split('.')
          .map(int.parse)
          .toList();
      final maskParts = subnetMask.split('.').map(int.parse).toList();

      if (destParts.length != 4 ||
          networkParts.length != 4 ||
          maskParts.length != 4) {
        return false;
      }

      // Check if destination matches network when masked
      for (int i = 0; i < 4; i++) {
        if ((destParts[i] & maskParts[i]) != networkParts[i]) {
          return false;
        }
      }
      return true;
    } catch (e) {
      return false;
    }
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {
      'destinationNetwork': destinationNetwork,
      'subnetMask': subnetMask,
      'gateway': gateway,
      'interfaceName': interfaceName,
      'metric': metric,
    };
  }

  /// Create from JSON
  factory RoutingEntry.fromJson(Map<String, dynamic> json) {
    return RoutingEntry(
      destinationNetwork: json['destinationNetwork'] as String,
      subnetMask: json['subnetMask'] as String,
      gateway: json['gateway'] as String?,
      interfaceName: json['interfaceName'] as String,
      metric: json['metric'] as int? ?? 0,
    );
  }

  @override
  String toString() {
    final gatewayStr = gateway ?? 'directly connected';
    return 'Route: $destinationNetwork/$subnetMask via $gatewayStr on $interfaceName (metric: $metric)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is RoutingEntry &&
        other.destinationNetwork == destinationNetwork &&
        other.subnetMask == subnetMask &&
        other.interfaceName == interfaceName;
  }

  @override
  int get hashCode =>
      destinationNetwork.hashCode ^
      subnetMask.hashCode ^
      interfaceName.hashCode;
}

/// Manages routing table for a device
/// Implements longest prefix match algorithm for routing decisions
class RoutingTable {
  final List<RoutingEntry> _entries;

  RoutingTable({List<RoutingEntry>? entries}) : _entries = entries ?? [];

  /// Get all routing entries
  List<RoutingEntry> get entries => List.unmodifiable(_entries);

  /// Add a routing entry
  void addRoute(RoutingEntry entry) {
    // Remove existing route to same destination on same interface
    _entries.removeWhere(
      (e) =>
          e.destinationNetwork == entry.destinationNetwork &&
          e.subnetMask == entry.subnetMask &&
          e.interfaceName == entry.interfaceName,
    );

    _entries.add(entry);
    _sortEntries();

    // Route added: $entry
  }

  /// Remove a routing entry
  void removeRoute(String destinationNetwork, String subnetMask) {
    final countBefore = _entries.length;
    _entries.removeWhere(
      (e) =>
          e.destinationNetwork == destinationNetwork &&
          e.subnetMask == subnetMask,
    );
    final removed = countBefore - _entries.length;

    if (removed > 0) {
      // Removed $removed route(s) to $destinationNetwork/$subnetMask
    }
  }

  /// Remove all routes for a specific interface
  void removeRoutesForInterface(String interfaceName) {
    final countBefore = _entries.length;
    _entries.removeWhere((e) => e.interfaceName == interfaceName);
    final removed = countBefore - _entries.length;

    if (removed > 0) {
      // Removed $removed route(s) for interface $interfaceName
    }
  }

  /// Clear all routing entries
  void clear() {
    _entries.clear();
    // Cleared all routes
  }

  /// Find the best matching route for a destination IP using longest prefix match
  /// This is the core routing algorithm
  RoutingEntry? longestPrefixMatch(String destIp) {
    // Looking up route for $destIp

    // Find all matching routes
    final matchingRoutes = _entries
        .where((route) => route.matches(destIp))
        .toList();

    if (matchingRoutes.isEmpty) {
      // No route found for $destIp
      return null;
    }

    // Sort by prefix length (most specific first), then by metric
    matchingRoutes.sort((a, b) {
      final prefixCompare = b.prefixLength.compareTo(a.prefixLength);
      if (prefixCompare != 0) return prefixCompare;
      return a.metric.compareTo(b.metric);
    });

    final bestRoute = matchingRoutes.first;
    // Best route for $destIp: ${bestRoute.destinationNetwork}/${bestRoute.prefixLength} via ${bestRoute.gateway ?? "direct"} on ${bestRoute.interfaceName}

    return bestRoute;
  }

  /// Get default route (0.0.0.0/0.0.0.0)
  RoutingEntry? getDefaultRoute() {
    try {
      return _entries.firstWhere((e) => e.isDefaultRoute);
    } catch (e) {
      return null;
    }
  }

  /// Check if a route exists for a destination
  bool hasRouteFor(String destIp) {
    return longestPrefixMatch(destIp) != null;
  }

  /// Add a directly connected network route (no gateway)
  void addDirectlyConnectedRoute({
    required String network,
    required String subnetMask,
    required String interfaceName,
  }) {
    addRoute(
      RoutingEntry(
        destinationNetwork: network,
        subnetMask: subnetMask,
        gateway: null,
        interfaceName: interfaceName,
        metric: 0,
      ),
    );
  }

  /// Add a default route (0.0.0.0/0.0.0.0)
  void addDefaultRoute({
    required String gateway,
    required String interfaceName,
    int metric = 1,
  }) {
    addRoute(
      RoutingEntry(
        destinationNetwork: '0.0.0.0',
        subnetMask: '0.0.0.0',
        gateway: gateway,
        interfaceName: interfaceName,
        metric: metric,
      ),
    );
  }

  /// Sort entries by specificity (most specific first)
  void _sortEntries() {
    _entries.sort((a, b) {
      final prefixCompare = b.prefixLength.compareTo(a.prefixLength);
      if (prefixCompare != 0) return prefixCompare;
      return a.metric.compareTo(b.metric);
    });
  }

  /// Get routing table as formatted string (for display)
  String toDisplayString() {
    if (_entries.isEmpty) {
      return 'Routing table is empty';
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'Destination        Subnet Mask        Gateway           Interface   Metric',
    );
    buffer.writeln(
      '----------------   ----------------   ----------------  ----------  ------',
    );

    for (final entry in _entries) {
      final dest = entry.destinationNetwork.padRight(18);
      final mask = entry.subnetMask.padRight(18);
      final gw = (entry.gateway ?? 'On-link').padRight(17);
      final iface = entry.interfaceName.padRight(11);
      final metric = entry.metric.toString();

      buffer.writeln('$dest $mask $gw $iface $metric');
    }

    return buffer.toString();
  }

  /// Convert to JSON for serialization
  Map<String, dynamic> toJson() {
    return {'entries': _entries.map((e) => e.toJson()).toList()};
  }

  /// Create from JSON
  factory RoutingTable.fromJson(Map<String, dynamic> json) {
    final entries = (json['entries'] as List<dynamic>?)
        ?.map((e) => RoutingEntry.fromJson(e as Map<String, dynamic>))
        .toList();
    return RoutingTable(entries: entries);
  }

  @override
  String toString() {
    return 'RoutingTable(${_entries.length} entries)';
  }
}

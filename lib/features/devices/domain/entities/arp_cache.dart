/// Represents a single entry in the ARP cache
class ArpEntry {
  /// IP address
  final String ipAddress;

  /// MAC address
  final String macAddress;

  /// Is this a static entry (manually configured)?
  final bool isStatic;

  /// When was this entry learned (null for static entries)
  final DateTime? timestamp;

  /// Which interface learned this entry
  final String interfaceName;

  /// How long until this entry expires (seconds, null for static)
  final int? ttl;

  ArpEntry({
    required this.ipAddress,
    required this.macAddress,
    required this.interfaceName,
    this.isStatic = false,
    DateTime? timestamp,
    this.ttl,
  }) : timestamp = isStatic ? null : (timestamp ?? DateTime.now());

  /// Check if this entry has expired
  bool get isExpired {
    if (isStatic) return false;
    if (timestamp == null || ttl == null) return false;

    final age = DateTime.now().difference(timestamp!).inSeconds;
    return age > ttl!;
  }

  /// Get age of this entry in seconds
  int get ageSeconds {
    if (timestamp == null) return 0;
    return DateTime.now().difference(timestamp!).inSeconds;
  }

  /// Get remaining TTL in seconds
  int? get remainingTtl {
    if (isStatic || ttl == null) return null;
    final remaining = ttl! - ageSeconds;
    return remaining > 0 ? remaining : 0;
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'ipAddress': ipAddress,
      'macAddress': macAddress,
      'interfaceName': interfaceName,
      'isStatic': isStatic,
      'timestamp': timestamp?.toIso8601String(),
      'ttl': ttl,
    };
  }

  /// Create from JSON
  factory ArpEntry.fromJson(Map<String, dynamic> json) {
    return ArpEntry(
      ipAddress: json['ipAddress'] as String,
      macAddress: json['macAddress'] as String,
      interfaceName: json['interfaceName'] as String,
      isStatic: json['isStatic'] as bool? ?? false,
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'] as String)
          : null,
      ttl: json['ttl'] as int?,
    );
  }

  /// Legacy format for backward compatibility (simple map)
  Map<String, String> toLegacyMap() {
    return {'ip': ipAddress, 'mac': macAddress};
  }

  @override
  String toString() {
    final type = isStatic ? 'static' : 'dynamic';
    final ttlStr = remainingTtl != null ? ' (TTL: ${remainingTtl}s)' : '';
    return 'ARP: $ipAddress -> $macAddress [$type, $interfaceName]$ttlStr';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ArpEntry &&
        other.ipAddress == ipAddress &&
        other.interfaceName == interfaceName;
  }

  @override
  int get hashCode => ipAddress.hashCode ^ interfaceName.hashCode;
}

/// ARP Cache manager
/// Maintains IP-to-MAC address mappings with support for static and dynamic entries
class ArpCache {
  final Map<String, ArpEntry> _entries; // Key: IP address
  final int defaultTtl; // Default TTL for dynamic entries (seconds)

  ArpCache({
    Map<String, ArpEntry>? entries,
    this.defaultTtl = 300, // 5 minutes default
  }) : _entries = entries ?? {};

  /// Get all entries (including expired)
  List<ArpEntry> get allEntries => _entries.values.toList();

  /// Get only valid (non-expired) entries
  List<ArpEntry> get validEntries =>
      _entries.values.where((e) => !e.isExpired).toList();

  /// Get only dynamic entries
  List<ArpEntry> get dynamicEntries =>
      validEntries.where((e) => !e.isStatic).toList();

  /// Get only static entries
  List<ArpEntry> get staticEntries =>
      validEntries.where((e) => e.isStatic).toList();

  /// Lookup MAC address for an IP address
  String? lookup(String ipAddress) {
    final entry = _entries[ipAddress];

    if (entry == null) {
      // No ARP entry for $ipAddress
      return null;
    }

    if (entry.isExpired) {
      // ARP entry for $ipAddress expired
      _entries.remove(ipAddress);
      return null;
    }

    // ARP hit: $ipAddress -> ${entry.macAddress}
    return entry.macAddress;
  }

  /// Add a static ARP entry (permanent, manually configured)
  void addStatic(String ipAddress, String macAddress, String interfaceName) {
    _entries[ipAddress] = ArpEntry(
      ipAddress: ipAddress,
      macAddress: macAddress,
      interfaceName: interfaceName,
      isStatic: true,
    );
  }

  /// Add a dynamic ARP entry (learned from ARP reply)
  void addDynamic(
    String ipAddress,
    String macAddress,
    String interfaceName, {
    int? ttl,
  }) {
    // Don't override static entries with dynamic ones
    if (_entries.containsKey(ipAddress) && _entries[ipAddress]!.isStatic) {
      return;
    }

    _entries[ipAddress] = ArpEntry(
      ipAddress: ipAddress,
      macAddress: macAddress,
      interfaceName: interfaceName,
      isStatic: false,
      timestamp: DateTime.now(),
      ttl: ttl ?? defaultTtl,
    );
  }

  /// Remove a specific entry
  void removeEntry(String ipAddress) {
    _entries.remove(ipAddress);
  }

  /// Remove all dynamic entries
  void clearDynamic() {
    _entries.removeWhere((_, entry) => !entry.isStatic);
  }

  /// Remove all entries (including static)
  void clearAll() {
    _entries.clear();
  }

  /// Remove expired entries
  void removeExpired() {
    _entries.removeWhere((_, entry) => entry.isExpired);
  }

  /// Check if IP address has valid ARP entry
  bool hasValidEntry(String ipAddress) {
    final entry = _entries[ipAddress];
    return entry != null && !entry.isExpired;
  }

  /// Get entries for a specific interface
  List<ArpEntry> getEntriesForInterface(String interfaceName) {
    return validEntries.where((e) => e.interfaceName == interfaceName).toList();
  }

  /// Clear entries for a specific interface
  void clearInterface(String interfaceName) {
    _entries.removeWhere((_, entry) => entry.interfaceName == interfaceName);
  }

  /// Get ARP cache as legacy format (for backward compatibility)
  List<Map<String, String>> toLegacyFormat() {
    return validEntries.map((e) => e.toLegacyMap()).toList();
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'entries': _entries.values.map((e) => e.toJson()).toList(),
      'defaultTtl': defaultTtl,
    };
  }

  /// Create from JSON
  factory ArpCache.fromJson(Map<String, dynamic> json) {
    final entries = <String, ArpEntry>{};
    final entriesList = json['entries'] as List<dynamic>?;

    if (entriesList != null) {
      for (final entryJson in entriesList) {
        final entry = ArpEntry.fromJson(entryJson as Map<String, dynamic>);
        entries[entry.ipAddress] = entry;
      }
    }

    return ArpCache(
      entries: entries,
      defaultTtl: json['defaultTtl'] as int? ?? 300,
    );
  }

  /// Get formatted display string
  String toDisplayString() {
    final entries = validEntries;

    if (entries.isEmpty) {
      return 'ARP cache is empty';
    }

    final buffer = StringBuffer();
    buffer.writeln(
      'IP Address        MAC Address         Type      Interface   Age/TTL',
    );
    buffer.writeln(
      '----------------  -----------------   -------   ----------  -------',
    );

    for (final entry in entries) {
      final ip = entry.ipAddress.padRight(17);
      final mac = entry.macAddress.padRight(19);
      final type = entry.isStatic ? 'static ' : 'dynamic';
      final iface = entry.interfaceName.padRight(11);
      final age = entry.isStatic
          ? 'permanent'
          : '${entry.ageSeconds}s/${entry.ttl}s';

      buffer.writeln('$ip $mac $type $iface $age');
    }

    return buffer.toString();
  }

  @override
  String toString() {
    final valid = validEntries.length;
    final total = _entries.length;
    final expired = total - valid;
    return 'ArpCache($valid valid, $expired expired)';
  }
}

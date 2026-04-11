class Incident {
  static const int defaultRadiusM = 20;

  /// Marker category used by the map UI.
  /// - 'traffic'
  /// - 'incident'
  final String category;

  /// Human label shown in tooltip, e.g. "Heavy" or "Accident".
  final String type;

  /// Marker location.
  ///
  /// In the new normalized schema these are the coordinates of the related `zones`
  /// row (so multiple traffic/incidents in the same zone will share a location).
  final double lat;
  final double lon;

  /// Used for Valhalla `exclude_locations.radius`.
  final int radiusM;

  // Optional metadata (used for UI details + dashboard grouping)
  final int? zoneId;
  final String? zoneName;
  final String? status; // traffic_status OR incident_status
  final String? description;
  final String? recordId; // traffic_id OR incident_id as string
  final DateTime? reportedAt;

  const Incident({
    required this.category,
    required this.type,
    required this.lat,
    required this.lon,
    required this.radiusM,
    this.zoneId,
    this.zoneName,
    this.status,
    this.description,
    this.recordId,
    this.reportedAt,
  });

  factory Incident.fromMap(Map<String, dynamic> map) {
    double toDouble(dynamic v) {
      if (v is num) return v.toDouble();
      return double.parse(v.toString());
    }

    int toInt(dynamic v, {int fallback = defaultRadiusM}) {
      if (v == null) return fallback;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString()) ?? fallback;
    }

    int? toIntOrNull(dynamic v) {
      if (v == null) return null;
      if (v is int) return v;
      if (v is num) return v.toInt();
      return int.tryParse(v.toString());
    }

    DateTime? toDateTimeOrNull(dynamic v) {
      if (v == null) return null;
      return DateTime.tryParse(v.toString());
    }

    return Incident(
      category: (map['category'] ?? 'incident').toString(),
      type: (map['type'] ?? 'unknown').toString(),
      lat: toDouble(map['lat'] ?? map['latitude']),
      lon: toDouble(map['lon'] ?? map['lng'] ?? map['longitude']),
      radiusM: toInt(map['radius_m'] ?? map['radiusM'] ?? map['radius']),
      zoneId: toIntOrNull(map['zone_id'] ?? map['zoneId']),
      zoneName: (map['zone_name'] ?? map['district_name'] ?? map['zoneName'])
          ?.toString(),
      status: (map['status'] ?? map['traffic_status'] ?? map['incident_status'])
          ?.toString(),
      description: (map['description'])?.toString(),
      recordId: (map['record_id'] ?? map['recordId'] ?? map['id'])?.toString(),
      reportedAt: toDateTimeOrNull(map['reported_at'] ?? map['reportedAt']),
    );
  }

  Map<String, dynamic> toValhallaExcludeLocation() {
    return {
      'lat': lat,
      'lon': lon,
      // Used as Valhalla candidate-search radius for mapping the point to the road.
      'radius': radiusM,
    };
  }
}

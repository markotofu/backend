import 'package:supabase_flutter/supabase_flutter.dart';

import 'incident.dart';

class IncidentService {
  final SupabaseClient _supabase = Supabase.instance.client;

  /// New schema: fetch active/unresolved traffic + incidents and convert them into map markers.
  ///
  /// If the new tables do not exist yet, this falls back to the old `public.incidents`
  /// table (lat/lon + is_active) so the map still works in older databases.
  Future<List<Incident>> fetchActiveHazards() async {
    try {
      final trafficRows = await _supabase
          .from('traffic')
          .select(
            'traffic_id, traffic_status, cancelled_at, description, reported_at, zones (zone_id, district_name, latitude, longitude)',
          )
          .isFilter('cancelled_at', null);

      final incidentRows = await _supabase
          .from('incidents')
          .select(
            'incident_id, incident_type, incident_status, deleted_at, description, reported_at, zones (zone_id, district_name, latitude, longitude)',
          )
          .isFilter('deleted_at', null)
          .inFilter('incident_status', ['Reported', 'In Progress']);

      final hazards = <Incident>[];

      for (final r in (trafficRows as List)) {
        final row = r as Map<String, dynamic>;
        final zone = (row['zones'] as Map<String, dynamic>?);
        if (zone == null) continue;

        final status = (row['traffic_status'] ?? 'Traffic').toString();
        hazards.add(
          Incident(
            category: 'traffic',
            type: status,
            status: status,
            recordId: row['traffic_id']?.toString(),
            description: row['description']?.toString(),
            reportedAt: DateTime.tryParse(
              (row['reported_at'] ?? '').toString(),
            ),
            zoneId: (zone['zone_id'] as num?)?.toInt(),
            zoneName: zone['district_name']?.toString(),
            lat: (zone['latitude'] as num).toDouble(),
            lon: (zone['longitude'] as num).toDouble(),
            radiusM: Incident.defaultRadiusM,
          ),
        );
      }

      for (final r in (incidentRows as List)) {
        final row = r as Map<String, dynamic>;
        final zone = (row['zones'] as Map<String, dynamic>?);
        if (zone == null) continue;

        hazards.add(
          Incident(
            category: 'incident',
            type: (row['incident_type'] ?? 'Incident').toString(),
            status: (row['incident_status'] ?? 'Reported').toString(),
            recordId: row['incident_id']?.toString(),
            description: row['description']?.toString(),
            reportedAt: DateTime.tryParse(
              (row['reported_at'] ?? '').toString(),
            ),
            zoneId: (zone['zone_id'] as num?)?.toInt(),
            zoneName: zone['district_name']?.toString(),
            lat: (zone['latitude'] as num).toDouble(),
            lon: (zone['longitude'] as num).toDouble(),
            radiusM: Incident.defaultRadiusM,
          ),
        );
      }

      return hazards;
    } on PostgrestException catch (e) {
      // Fallback only when the new schema isn't installed.
      // 42P01 = undefined table.
      if (e.code != null && e.code != '42P01') rethrow;

      final rows = await _supabase
          .from('incidents')
          .select('type, lat, lon, radius_m, is_active')
          .eq('is_active', true);

      return (rows as List)
          .map(
            (e) => Incident.fromMap({
              ...(e as Map<String, dynamic>),
              'category': 'incident',
            }),
          )
          .toList(growable: false);
    }
  }

  /// Back-compat helper for older callers.
  Future<List<Incident>> fetchActiveIncidents() => fetchActiveHazards();
}

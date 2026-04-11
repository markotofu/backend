import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:latlong2/latlong.dart';

import 'incident.dart';
import 'routing_config.dart';

class ValhallaRoutingService {
  final String baseUrl;

  ValhallaRoutingService({String? baseUrl})
    : baseUrl = (baseUrl ?? RoutingConfig.valhallaBaseUrl).replaceAll(
        RegExp(r'/+$'),
        '',
      );

  Future<void> _assertHealthy(http.Client client) async {
    final uri = Uri.parse('$baseUrl/status');

    try {
      final res = await client
          .get(uri)
          .timeout(const Duration(seconds: 10));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception('HTTP ${res.statusCode}: ${res.body}');
      }
    } on TimeoutException {
      throw Exception('Timed out reaching Valhalla at $uri');
    } catch (e) {
      throw Exception(
        'Valhalla is not reachable/healthy at $uri.\n'
        'Start it with: cd Valhalla && docker compose up -d\n'
        'Then verify on host: curl.exe http://localhost:8002/status\n'
        'If host works but emulator fails, check Windows Firewall for port 8002.\n'
        'Details: $e',
      );
    }
  }

  Future<List<LatLng>> routeShortestAvoiding({
    required LatLng from,
    required LatLng to,
    List<Incident> exclude = const [],
  }) async {
    final payload = {
      'locations': [
        // Increase search radius so taps slightly off the road can still snap.
        {'lat': from.latitude, 'lon': from.longitude, 'radius': 200},
        {'lat': to.latitude, 'lon': to.longitude, 'radius': 200},
      ],
      'exclude_locations': exclude
          .map((e) => e.toValhallaExcludeLocation())
          .toList(),
      'costing': 'auto',
      'costing_options': {
        'auto': {
          // Pure distance-based (shortest) route.
          'shortest': true,
          // Improves optimality in edge cases (at some performance cost).
          'disable_hierarchy_pruning': true,
        },
      },
      // OSRM output makes parsing the line easier.
      'format': 'osrm',
      'shape_format': 'geojson',
    };

    final client = http.Client();
    try {
      await _assertHealthy(client);

      final uri = Uri.parse('$baseUrl/route');
      final res = await client
          .post(
            uri,
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode(payload),
          )
          .timeout(const Duration(seconds: 30));

      if (res.statusCode < 200 || res.statusCode >= 300) {
        throw Exception(
          'Valhalla route failed (${res.statusCode}): ${res.body}',
        );
      }

      final json = jsonDecode(res.body);

      // OSRM-format response: routes[0].geometry.coordinates = [[lon,lat], ...]
      final routes = (json is Map) ? (json['routes'] as List?) : null;
      if (routes == null || routes.isEmpty) {
        throw Exception('No route returned');
      }

      final geometry = (routes.first as Map)['geometry'];
      if (geometry is Map && geometry['coordinates'] is List) {
        final coords = geometry['coordinates'] as List;
        return coords
            .map((c) {
              final pair = c as List;
              final lon = (pair[0] as num).toDouble();
              final lat = (pair[1] as num).toDouble();
              return LatLng(lat, lon);
            })
            .toList(growable: false);
      }

      throw Exception('Unexpected Valhalla response format');
    } on TimeoutException catch (e) {
      throw Exception('Valhalla request timed out: $e');
    } finally {
      client.close();
    }
  }
}

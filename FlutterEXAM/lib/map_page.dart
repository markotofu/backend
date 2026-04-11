import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';

import 'incident.dart';
import 'incident_service.dart';
import 'valhalla_routing_service.dart';

class MapPage extends StatefulWidget {
  const MapPage({super.key});

  @override
  State<MapPage> createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  // Davao City area (rough bounds) – used to keep the UI and routing inputs
  // limited to Davao only.
  static const LatLng _davaoCenter = LatLng(7.0731, 125.6128);
  static final LatLngBounds _davaoBounds = LatLngBounds(
    const LatLng(6.88, 125.45),
    const LatLng(7.25, 125.75),
  );

  final _incidentService = IncidentService();
  final _routing = ValhallaRoutingService();

  LatLng? _a;
  LatLng? _b;
  bool _pickingA = true;

  bool _loading = true;
  bool _routingBusy = false;

  List<Incident> _incidents = const [];
  Incident? _selectedHazard;

  // Two route overlays:
  // - original (green): no excludes
  // - alternative (yellow): excludes hazards
  List<LatLng> _routeOriginal = const [];
  List<LatLng> _routeAlternative = const [];

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    setState(() {
      _loading = true;
    });

    try {
      final incidents = await _incidentService.fetchActiveHazards();
      if (!mounted) return;
      setState(() {
        _incidents = incidents;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(
        SnackBar(content: Text('Failed to load traffic/incidents: $e')),
      );
    }
  }

  void _onTap(LatLng p) {
    if (!_davaoBounds.contains(p)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please select a point within Davao City.')),
      );
      return;
    }

    setState(() {
      _selectedHazard = null;
      if (_pickingA) {
        _a = p;
        _pickingA = false;
      } else {
        _b = p;
      }
      _routeOriginal = const [];
      _routeAlternative = const [];
    });
  }

  Future<void> _buildRoute() async {
    final a = _a;
    final b = _b;
    if (a == null || b == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Pick Point A and Point B first.')),
      );
      return;
    }

    setState(() => _routingBusy = true);
    try {
      // Always compute original route (no excludes)
      final original = await _routing.routeShortestAvoiding(
        from: a,
        to: b,
        exclude: const [],
      );

      List<LatLng> alternative = const [];
      if (_incidents.isNotEmpty) {
        // Best-effort: alternative route avoiding hazards.
        try {
          alternative = await _routing.routeShortestAvoiding(
            from: a,
            to: b,
            exclude: _incidents,
          );
        } catch (e) {
          // Keep original visible even if alternative fails.
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Alternative route unavailable: $e')),
            );
          }
        }
      }

      if (!mounted) return;
      setState(() {
        _routeOriginal = original;
        _routeAlternative = alternative;
        _routingBusy = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _routingBusy = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Routing failed: $e')));
    }
  }

  void _clear() {
    setState(() {
      _a = null;
      _b = null;
      _pickingA = true;
      _routeOriginal = const [];
      _routeAlternative = const [];
    });
  }

  @override
  Widget build(BuildContext context) {

    final markers = <Marker>[
      for (final i in _incidents)
        Marker(
          point: LatLng(i.lat, i.lon),
          width: 40,
          height: 40,
          child: GestureDetector(
            onTap: () => setState(() => _selectedHazard = i),
            child: Tooltip(
              message: [
                '${i.category}: ${i.type}',
                if ((i.zoneName ?? '').isNotEmpty) 'Zone: ${i.zoneName}',
              ].join('\n'),
              child: Icon(
                i.category == 'traffic'
                    ? Icons.traffic
                    : Icons.warning_amber_rounded,
                color: i.category == 'traffic' ? Colors.orange : Colors.red,
              ),
            ),
          ),
        ),
      if (_a != null)
        Marker(
          point: _a!,
          width: 36,
          height: 36,
          child: const Icon(Icons.location_on, color: Colors.green),
        ),
      if (_b != null)
        Marker(
          point: _b!,
          width: 36,
          height: 36,
          child: const Icon(Icons.flag, color: Colors.blue),
        ),
    ];

    // Build the list without making Polyline const (points are dynamic).
    final effectivePolylines = <Polyline>[
      if (_routeOriginal.isNotEmpty)
        Polyline(
          points: _routeOriginal,
          strokeWidth: 4,
          color: Colors.green,
        ),
      if (_routeAlternative.isNotEmpty)
        Polyline(
          points: _routeAlternative,
          strokeWidth: 4,
          color: Colors.yellow.shade700,
        ),
    ];

    return Column(
      children: [
        Material(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 12,
              runSpacing: 8,
              children: [
                Chip(
                  label: Text(
                    _pickingA
                        ? 'Tap map to set Point A'
                        : 'Tap map to set Point B',
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _pickingA = true),
                  icon: const Icon(Icons.looks_one_outlined),
                  label: const Text('Pick A'),
                ),
                OutlinedButton.icon(
                  onPressed: () => setState(() => _pickingA = false),
                  icon: const Icon(Icons.looks_two_outlined),
                  label: const Text('Pick B'),
                ),
                OutlinedButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.clear),
                  label: const Text('Clear'),
                ),
                FilledButton.icon(
                  onPressed: _routingBusy ? null : _buildRoute,
                  icon: _routingBusy
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.alt_route),
                  label: const Text('Route'),
                ),
                IconButton(
                  tooltip: 'Refresh traffic/incidents',
                  onPressed: _loading ? null : _loadIncidents,
                  icon: const Icon(Icons.refresh),
                ),
                Text('Pins: ${_incidents.length}'),
              ],
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              FlutterMap(
                options: MapOptions(
                  initialCenter: _davaoCenter,
                  initialZoom: 12,
                  minZoom: 11,
                  maxZoom: 18,
                  cameraConstraint: CameraConstraint.contain(bounds: _davaoBounds),
                  interactionOptions: const InteractionOptions(
                    flags: InteractiveFlag.all & ~InteractiveFlag.rotate,
                  ),
                  onTap: (_, p) => _onTap(p),
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'flutter_exam',
                  ),
                  PolylineLayer(polylines: effectivePolylines),
                  MarkerLayer(markers: markers),
                ],
              ),
              if (_selectedHazard != null)
                Positioned(
                  left: 12,
                  right: 12,
                  bottom: 12,
                  child: _HazardInfoCard(
                    hazard: _selectedHazard!,
                    onClose: () => setState(() => _selectedHazard = null),
                  ),
                ),
            ],
          ),
        ),
      ],
    );
  }
}

class _HazardInfoCard extends StatelessWidget {
  final Incident hazard;
  final VoidCallback onClose;

  const _HazardInfoCard({required this.hazard, required this.onClose});

  @override
  Widget build(BuildContext context) {
    final title = hazard.category == 'traffic' ? 'Traffic' : 'Incident';
    final subtitleLines = <String>[];

    if ((hazard.zoneName ?? '').isNotEmpty) {
      subtitleLines.add('Zone: ${hazard.zoneName}');
    }
    if ((hazard.status ?? '').isNotEmpty && hazard.category == 'incident') {
      subtitleLines.add('Status: ${hazard.status}');
    }
    if ((hazard.description?.trim().isNotEmpty ?? false)) {
      subtitleLines.add(hazard.description!.trim());
    }

    return Card(
      elevation: 4,
      child: ListTile(
        leading: Icon(
          hazard.category == 'traffic'
              ? Icons.traffic
              : Icons.warning_amber_rounded,
          color: hazard.category == 'traffic' ? Colors.orange : Colors.red,
        ),
        title: Text('$title: ${hazard.type}'),
        subtitle: subtitleLines.isEmpty
            ? const Text('No details')
            : Text(subtitleLines.join('\n')),
        trailing: IconButton(
          tooltip: 'Close',
          onPressed: onClose,
          icon: const Icon(Icons.close),
        ),
      ),
    );
  }
}

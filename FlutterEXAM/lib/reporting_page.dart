import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:latlong2/latlong.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'incident.dart';
import 'incident_service.dart';

class ReportingPage extends StatefulWidget {
  const ReportingPage({super.key});

  @override
  State<ReportingPage> createState() => _ReportingPageState();
}

class _ReportingPageState extends State<ReportingPage> {
  // Keep consistent with MapPage.
  static const LatLng _davaoCenter = LatLng(7.0731, 125.6128);
  static final LatLngBounds _davaoBounds = LatLngBounds(
    const LatLng(6.88, 125.45),
    const LatLng(7.25, 125.75),
  );

  final _auth = AuthService();
  final _incidentService = IncidentService();
  final SupabaseClient _supabase = Supabase.instance.client;

  final _formKey = GlobalKey<FormState>();
  final _districtCtrl = TextEditingController();
  final _descriptionCtrl = TextEditingController();

  bool _loadingProfile = true;
  bool _loadingHazards = true;
  bool _submitting = false;

  String _role = 'User';
  String? _accountId;

  List<Incident> _hazards = const [];
  Incident? _selectedHazard;

  LatLng? _pin;

  String _reportKind = 'traffic'; // traffic | incident

  String _trafficStatus = 'Light';
  String _incidentType = 'Accident';

  @override
  void initState() {
    super.initState();
    _loadProfile();
    _loadHazards();
  }

  @override
  void dispose() {
    _districtCtrl.dispose();
    _descriptionCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    setState(() => _loadingProfile = true);
    final profile = await _auth.getUserProfile();
    if (!mounted) return;

    setState(() {
      _role = (profile?['role'] ?? 'User').toString();
      _accountId = (profile?['id'])?.toString();
      _loadingProfile = false;

      // Enforce role rule in UI.
      if (!_canReportIncidents) {
        _reportKind = 'traffic';
      }
    });
  }

  Future<void> _loadHazards() async {
    setState(() => _loadingHazards = true);
    try {
      final hazards = await _incidentService.fetchActiveHazards();
      if (!mounted) return;
      setState(() {
        _hazards = hazards;
        _loadingHazards = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loadingHazards = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load existing pins: $e')),
      );
    }
  }

  bool get _canReportIncidents => _role == 'ADMIN' || _role == 'CTTMO';

  void _onTap(LatLng p) {
    if (!_davaoBounds.contains(p)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please place the report pin within Davao City.'),
        ),
      );
      return;
    }

    setState(() {
      _selectedHazard = null;
      _pin = p;
    });
  }

  Future<int> _createZone({
    required String districtName,
    required LatLng pin,
  }) async {
    final row = await _supabase
        .from('zones')
        .insert({
          'district_name': districtName,
          'latitude': pin.latitude,
          'longitude': pin.longitude,
        })
        .select('zone_id')
        .single();

    return (row['zone_id'] as num).toInt();
  }

  Future<void> _submit() async {
    if (_loadingProfile) return;

    final pin = _pin;
    if (pin == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Tap on the map to drop a pin first.')),
      );
      return;
    }

    if (_reportKind == 'incident' && !_canReportIncidents) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Only CTTMO/ADMIN can report incidents.')),
      );
      return;
    }

    if (!(_formKey.currentState?.validate() ?? false)) return;

    final accountId = _accountId;
    if (accountId == null || accountId.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Missing account profile. Try signing out/in.'),
        ),
      );
      return;
    }

    setState(() => _submitting = true);
    try {
      final zoneId = await _createZone(
        districtName: _districtCtrl.text.trim(),
        pin: pin,
      );

      if (_reportKind == 'traffic') {
        final traffic = await _supabase
            .from('traffic')
            .insert({
              'zone_id': zoneId,
              'traffic_status': _trafficStatus,
              'description': _descriptionCtrl.text.trim().isEmpty
                  ? null
                  : _descriptionCtrl.text.trim(),
            })
            .select('traffic_id')
            .single();

        final trafficId = (traffic['traffic_id'] as num).toInt();

        // Best-effort log insert (policy requires updated_by = current account id)
        await _supabase.from('traffic_log').insert({
          'traffic_id': trafficId,
          'updated_by': accountId,
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Traffic report submitted.')),
        );
      } else {
        await _supabase.from('incidents').insert({
          'zone_id': zoneId,
          'incident_type': _incidentType,
          'incident_status': 'Reported',
          'description': _descriptionCtrl.text.trim().isEmpty
              ? null
              : _descriptionCtrl.text.trim(),
        });

        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Incident report submitted.')),
        );
      }

      if (!mounted) return;
      setState(() {
        _pin = null;
        _districtCtrl.clear();
        _descriptionCtrl.clear();
        _trafficStatus = 'Light';
        _incidentType = 'Accident';
        if (!_canReportIncidents) {
          _reportKind = 'traffic';
        }
      });

      // Refresh visible pins after submit.
      await _loadHazards();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Submit failed: $e')));
    } finally {
      if (mounted) setState(() => _submitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final pin = _pin;

    final kindOptions = <DropdownMenuItem<String>>[
      const DropdownMenuItem(value: 'traffic', child: Text('Traffic')),
      if (_canReportIncidents)
        const DropdownMenuItem(value: 'incident', child: Text('Incident')),
    ];

    return Column(
      children: [
        Material(
          elevation: 1,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    _loadingProfile
                        ? 'Loading account…'
                        : 'Role: $_role  •  Existing pins: ${_hazards.length}  •  Tap map to drop a report pin',
                  ),
                ),
                IconButton(
                  tooltip: 'Reload profile',
                  onPressed: _submitting ? null : _loadProfile,
                  icon: const Icon(Icons.person_outline),
                ),
                IconButton(
                  tooltip: 'Refresh pins',
                  onPressed: _submitting || _loadingHazards ? null : _loadHazards,
                  icon: const Icon(Icons.refresh),
                ),
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
                  MarkerLayer(
                    markers: [
                      for (final h in _hazards)
                        Marker(
                          point: LatLng(h.lat, h.lon),
                          width: 40,
                          height: 40,
                          child: GestureDetector(
                            onTap: () => setState(() => _selectedHazard = h),
                            child: Tooltip(
                              message: [
                                '${h.category}: ${h.type}',
                                if ((h.zoneName ?? '').isNotEmpty) 'Zone: ${h.zoneName}',
                              ].join('\n'),
                              child: Icon(
                                h.category == 'traffic'
                                    ? Icons.traffic
                                    : Icons.warning_amber_rounded,
                                color: h.category == 'traffic'
                                    ? Colors.orange
                                    : Colors.red,
                              ),
                            ),
                          ),
                        ),
                      if (pin != null)
                        Marker(
                          point: pin,
                          width: 40,
                          height: 40,
                          child: const Icon(Icons.place, color: Colors.purple),
                        ),
                    ],
                  ),
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
        Material(
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Row(
                    children: [
                      const Text('Report type:'),
                      const SizedBox(width: 12),
                      DropdownButton<String>(
                        value: _reportKind,
                        items: kindOptions,
                        onChanged: _submitting
                            ? null
                            : (v) {
                                if (v == null) return;
                                if (v == 'incident' && !_canReportIncidents)
                                  return;
                                setState(() => _reportKind = v);
                              },
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _districtCtrl,
                    decoration: const InputDecoration(
                      labelText: 'District / Zone name',
                      border: OutlineInputBorder(),
                    ),
                    validator: (v) {
                      final t = v?.trim() ?? '';
                      if (t.isEmpty) return 'Required';
                      return null;
                    },
                  ),
                  const SizedBox(height: 8),
                  if (_reportKind == 'traffic')
                    DropdownButtonFormField<String>(
                      value: _trafficStatus,
                      decoration: const InputDecoration(
                        labelText: 'Traffic status',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(value: 'Light', child: Text('Light')),
                        DropdownMenuItem(
                          value: 'Moderate',
                          child: Text('Moderate'),
                        ),
                        DropdownMenuItem(value: 'Heavy', child: Text('Heavy')),
                        DropdownMenuItem(
                          value: 'Blocked',
                          child: Text('Blocked'),
                        ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (v) =>
                                setState(() => _trafficStatus = v ?? 'Light'),
                    ),
                  if (_reportKind == 'incident')
                    DropdownButtonFormField<String>(
                      value: _incidentType,
                      decoration: const InputDecoration(
                        labelText: 'Incident type',
                        border: OutlineInputBorder(),
                      ),
                      items: const [
                        DropdownMenuItem(
                          value: 'Accident',
                          child: Text('Accident'),
                        ),
                        DropdownMenuItem(
                          value: 'Pedestrian Accident',
                          child: Text('Pedestrian Accident'),
                        ),
                        DropdownMenuItem(
                          value: 'Breakdown',
                          child: Text('Breakdown'),
                        ),
                        DropdownMenuItem(
                          value: 'Flooding',
                          child: Text('Flooding'),
                        ),
                        DropdownMenuItem(
                          value: 'Road Closure',
                          child: Text('Road Closure'),
                        ),
                        DropdownMenuItem(
                          value: 'Construction',
                          child: Text('Construction'),
                        ),
                        DropdownMenuItem(
                          value: 'Stalled Vehicle',
                          child: Text('Stalled Vehicle'),
                        ),
                      ],
                      onChanged: _submitting
                          ? null
                          : (v) =>
                                setState(() => _incidentType = v ?? 'Accident'),
                    ),
                  const SizedBox(height: 8),
                  TextFormField(
                    controller: _descriptionCtrl,
                    decoration: const InputDecoration(
                      labelText: 'Description (optional)',
                      border: OutlineInputBorder(),
                    ),
                    minLines: 1,
                    maxLines: 3,
                  ),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _submitting ? null : _submit,
                    icon: _submitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.send),
                    label: const Text('Submit report'),
                  ),
                ],
              ),
            ),
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

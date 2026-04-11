import 'package:flutter/material.dart';

import 'incident.dart';
import 'incident_service.dart';

class DashboardPage extends StatefulWidget {
  /// Increment this whenever the dashboard should reload.
  final int reloadToken;

  const DashboardPage({super.key, required this.reloadToken});

  @override
  State<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final _incidentService = IncidentService();

  late Future<List<Incident>> _future;

  @override
  void initState() {
    super.initState();
    _future = _incidentService.fetchActiveHazards();
  }

  @override
  void didUpdateWidget(covariant DashboardPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.reloadToken != widget.reloadToken) {
      _refresh();
    }
  }

  Future<void> _refresh() async {
    setState(() => _future = _incidentService.fetchActiveHazards());
    await _future;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<List<Incident>>(
      future: _future,
      builder: (context, snapshot) {
        final hazards = snapshot.data;

        if (snapshot.connectionState == ConnectionState.waiting &&
            hazards == null) {
          return const Center(child: CircularProgressIndicator());
        }

        if (snapshot.hasError) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text('Failed to load dashboard data:\n${snapshot.error}'),
                  const SizedBox(height: 12),
                  FilledButton.icon(
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                    label: const Text('Retry'),
                  ),
                ],
              ),
            ),
          );
        }

        final items = hazards ?? const <Incident>[];

        // Group by district/zone name (case-insensitive) so duplicate names like
        // "Sasa" collapse into one category even if they are separate zone rows.
        final groups = <String, _ZoneGroup>{};
        for (final h in items) {
          final rawName = (h.zoneName ?? '').trim();
          final normalizedName = rawName.isEmpty ? '' : rawName.toLowerCase();

          final key = normalizedName.isNotEmpty
              ? 'name:$normalizedName'
              : 'id:${h.zoneId ?? 'unknown'}';

          final displayName = rawName.isNotEmpty ? rawName : 'Unknown zone';

          final group = groups.putIfAbsent(
            key,
            () => _ZoneGroup(zoneName: displayName, lat: h.lat, lon: h.lon),
          );

          group.zoneIds.add(h.zoneId);
          group.locations.add('${h.lat.toStringAsFixed(6)},${h.lon.toStringAsFixed(6)}');

          if (h.category == 'traffic') {
            group.traffic.add(h);
          } else {
            group.incidents.add(h);
          }
        }

        final zoneList = groups.values.toList()
          ..sort(
            (a, b) =>
                a.zoneName.toLowerCase().compareTo(b.zoneName.toLowerCase()),
          );

        return RefreshIndicator(
          onRefresh: _refresh,
          child: ListView.builder(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.only(bottom: 12),
            itemCount: zoneList.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return ListTile(
                  title: const Text('Dashboard'),
                  subtitle: Text(
                    'Zones with active traffic/incidents: ${zoneList.length}  •  Pins: ${items.length}',
                  ),
                  trailing: IconButton(
                    tooltip: 'Refresh',
                    onPressed: _refresh,
                    icon: const Icon(Icons.refresh),
                  ),
                );
              }

              final z = zoneList[index - 1];
              final trafficCount = z.traffic.length;
              final incidentCount = z.incidents.length;

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: ExpansionTile(
                  title: Text(z.zoneName),
                  subtitle: Text(
                    'Traffic: $trafficCount  •  Incidents: $incidentCount',
                  ),
                  childrenPadding: const EdgeInsets.only(bottom: 12),
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          z.locations.length <= 1
                              ? 'Zone info: (${z.lat.toStringAsFixed(5)}, ${z.lon.toStringAsFixed(5)})'
                              : 'Zone info: ${z.locations.length} locations (showing one: ${z.lat.toStringAsFixed(5)}, ${z.lon.toStringAsFixed(5)})',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ),
                    ),
                    if (trafficCount > 0) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Text('Traffic reports'),
                      ),
                      for (final t in z.traffic)
                        ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.traffic,
                            color: Colors.orange,
                          ),
                          title: Text(t.status ?? t.type),
                          subtitle: Text(
                            (t.description?.trim().isNotEmpty ?? false)
                                ? t.description!.trim()
                                : 'No description',
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    if (incidentCount > 0) ...[
                      const Divider(),
                      const Padding(
                        padding: EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 6,
                        ),
                        child: Text('Incident reports'),
                      ),
                      for (final i in z.incidents)
                        ListTile(
                          dense: true,
                          leading: const Icon(
                            Icons.warning_amber_rounded,
                            color: Colors.red,
                          ),
                          title: Text(i.type),
                          subtitle: Text(
                            [
                              if ((i.status ?? '').isNotEmpty)
                                'Status: ${i.status}',
                              if ((i.description?.trim().isNotEmpty ?? false))
                                i.description!.trim(),
                            ].join('\n'),
                            maxLines: 3,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                    ],
                    if (trafficCount == 0 && incidentCount == 0)
                      const Padding(
                        padding: EdgeInsets.all(16),
                        child: Text('No active items.'),
                      ),
                  ],
                ),
              );
            },
          ),
        );
      },
    );
  }
}

class _ZoneGroup {
  final String zoneName;
  final double lat;
  final double lon;

  /// When multiple zone rows share the same name, we keep track of their ids and locations.
  final Set<int?> zoneIds = {};
  final Set<String> locations = {};

  final List<Incident> traffic = [];
  final List<Incident> incidents = [];

  _ZoneGroup({required this.zoneName, required this.lat, required this.lon});
}

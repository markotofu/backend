import 'package:flutter/material.dart';

import 'auth_service.dart';
import 'dashboard_page.dart';
import 'details_page.dart';
import 'login_screen.dart';
import 'map_page.dart';
import 'my_account_page.dart';
import 'reporting_page.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final _authService = AuthService();

  int _selectedIndex = 0;
  int _dashboardReloadToken = 0;
  bool _railExtended = true;

  String get _title {
    switch (_selectedIndex) {
      case 0:
        return 'Dashboard';
      case 1:
        return 'Map';
      case 2:
        return 'Reporting';
      case 3:
        return 'Details';
      case 4:
        return 'My Account';
      default:
        return 'App';
    }
  }

  Future<void> _signOut() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Sign Out'),
        content: const Text('Are you sure you want to sign out?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sign Out'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    try {
      await _authService.signOut();
      if (!mounted) return;
      Navigator.of(
        context,
      ).pushReplacement(MaterialPageRoute(builder: (_) => const LoginScreen()));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Sign out failed: $e')));
    }
  }

  Widget _currentPage() {
    return switch (_selectedIndex) {
      0 => DashboardPage(reloadToken: _dashboardReloadToken),
      1 => const MapPage(),
      2 => const ReportingPage(),
      3 => const DetailsPage(),
      4 => const MyAccountPage(),
      _ => DashboardPage(reloadToken: _dashboardReloadToken),
    };
  }

  void _select(int index) {
    setState(() {
      _selectedIndex = index;
      if (index == 0) {
        _dashboardReloadToken++;
      }
    });
  }

  Drawer _drawer() {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          DrawerHeader(
            child: Text(
              'Menu',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
          ),
          ListTile(
            leading: const Icon(Icons.dashboard_outlined),
            title: const Text('Dashboard'),
            selected: _selectedIndex == 0,
            onTap: () {
              Navigator.of(context).pop();
              _select(0);
            },
          ),
          ListTile(
            leading: const Icon(Icons.map_outlined),
            title: const Text('Map'),
            selected: _selectedIndex == 1,
            onTap: () {
              Navigator.of(context).pop();
              _select(1);
            },
          ),
          ListTile(
            leading: const Icon(Icons.campaign_outlined),
            title: const Text('Reporting'),
            selected: _selectedIndex == 2,
            onTap: () {
              Navigator.of(context).pop();
              _select(2);
            },
          ),
          ListTile(
            leading: const Icon(Icons.info_outline),
            title: const Text('Details'),
            selected: _selectedIndex == 3,
            onTap: () {
              Navigator.of(context).pop();
              _select(3);
            },
          ),
          ListTile(
            leading: const Icon(Icons.person_outline),
            title: const Text('My Account'),
            selected: _selectedIndex == 4,
            onTap: () {
              Navigator.of(context).pop();
              _select(4);
            },
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.logout),
            title: const Text('Sign out'),
            onTap: () {
              Navigator.of(context).pop();
              _signOut();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final useRail = constraints.maxWidth >= 900;

        final scaffold = Scaffold(
          appBar: AppBar(
            title: Text(_title),
            actions: [
              IconButton(
                icon: const Icon(Icons.logout),
                tooltip: 'Sign Out',
                onPressed: _signOut,
              ),
            ],
          ),
          drawer: useRail ? null : _drawer(),
          body: useRail
              ? Row(
                  children: [
                    NavigationRail(
                      extended: _railExtended,
                      leading: IconButton(
                        icon: Icon(
                          _railExtended
                              ? Icons.chevron_left
                              : Icons.chevron_right,
                        ),
                        tooltip: _railExtended ? 'Collapse' : 'Expand',
                        onPressed: () =>
                            setState(() => _railExtended = !_railExtended),
                      ),
                      selectedIndex: _selectedIndex,
                      onDestinationSelected: _select,
                      destinations: const [
                        NavigationRailDestination(
                          icon: Icon(Icons.dashboard_outlined),
                          label: Text('Dashboard'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.map_outlined),
                          label: Text('Map'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.campaign_outlined),
                          label: Text('Reporting'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.info_outline),
                          label: Text('Details'),
                        ),
                        NavigationRailDestination(
                          icon: Icon(Icons.person_outline),
                          label: Text('My Account'),
                        ),
                      ],
                    ),
                    const VerticalDivider(width: 1),
                    Expanded(child: _currentPage()),
                  ],
                )
              : _currentPage(),
        );

        return scaffold;
      },
    );
  }
}

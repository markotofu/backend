import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'auth_service.dart';
import 'theme_controller.dart';

class MyAccountPage extends StatefulWidget {
  const MyAccountPage({super.key});

  @override
  State<MyAccountPage> createState() => _MyAccountPageState();
}

class _MyAccountPageState extends State<MyAccountPage> {
  final _authService = AuthService();

  final _usernameController = TextEditingController();
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  Map<String, dynamic>? _account;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    setState(() => _loading = true);
    try {
      final data = await _authService.getUserProfile();
      if (!mounted) return;
      setState(() {
        _account = data;
        _usernameController.text = (data?['username'] ?? '').toString();
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _loading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to load account: $e')));
    }
  }

  String? _validateUsername(String input) {
    final v = input.trim();
    if (v.isEmpty) return 'Username is required';
    if (v.length < 3 || v.length > 30) {
      return 'Username must be 3–30 characters';
    }
    if (!RegExp(r'^[a-zA-Z0-9_.-]+$').hasMatch(v)) {
      return 'Only letters, numbers, underscore (_), dot (.), and hyphen (-) are allowed';
    }
    return null;
  }

  Future<void> _saveUsername() async {
    final username = _usernameController.text.trim();
    final err = _validateUsername(username);
    if (err != null) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(err)));
      return;
    }

    try {
      await _authService.updateUsername(username);
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Username updated')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update username: $e')));
    }
  }

  Future<void> _changePassword() async {
    final p1 = _newPasswordController.text;
    final p2 = _confirmPasswordController.text;

    if (p1.length < 6) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 6 characters')),
      );
      return;
    }
    if (p1 != p2) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Passwords do not match')));
      return;
    }

    try {
      await _authService.updatePassword(p1);
      if (!mounted) return;
      _newPasswordController.clear();
      _confirmPasswordController.clear();
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Password updated')));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Failed to update password: $e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;
    final themeController = ThemeControllerScope.of(context);

    if (_loading) {
      return const Center(child: CircularProgressIndicator());
    }

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Card(
            child: ListTile(
              leading: const Icon(Icons.person_outline),
              title: Text((_account?['username'] ?? 'User').toString()),
              subtitle: Text(user?.email ?? 'No email'),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                SwitchListTile(
                  title: const Text('Dark mode'),
                  subtitle: const Text('Saved on this device'),
                  value: themeController.isDark,
                  onChanged: (v) => themeController.setDark(v),
                  secondary: const Icon(Icons.dark_mode_outlined),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Change username',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _usernameController,
                    decoration: const InputDecoration(
                      labelText: 'Username',
                      hintText: 'letters, numbers, _ . -',
                      prefixIcon: Icon(Icons.alternate_email),
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _saveUsername,
                    child: const Text('Save username'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Change password',
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _newPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'New password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: _confirmPasswordController,
                    obscureText: true,
                    decoration: const InputDecoration(
                      labelText: 'Confirm new password',
                      border: OutlineInputBorder(),
                    ),
                  ),
                  const SizedBox(height: 12),
                  FilledButton(
                    onPressed: _changePassword,
                    child: const Text('Update password'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: Column(
              children: [
                ListTile(
                  leading: const Icon(Icons.badge_outlined),
                  title: const Text('Role'),
                  subtitle: Text((_account?['role'] ?? 'Unknown').toString()),
                ),
                ListTile(
                  leading: const Icon(Icons.toggle_on_outlined),
                  title: const Text('Active'),
                  subtitle: Text(
                    (_account?['isactive'] ??
                            _account?['isActive'] ??
                            'Unknown')
                        .toString(),
                  ),
                ),
                ListTile(
                  leading: const Icon(Icons.fingerprint),
                  title: const Text('Auth user id'),
                  subtitle: Text(user?.id ?? 'Unknown'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

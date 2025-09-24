import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../theme_provider.dart';

class AuthoritySettingsPage extends StatelessWidget {
  const AuthoritySettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        ListTile(
          leading: const Icon(Icons.person),
          title: const Text('Profile (Placeholder)'),
          subtitle: const Text('Update authority info later'),
          onTap: () {},
        ),
        Consumer<ThemeProvider>(
          builder: (context, theme, _) => SwitchListTile(
            value: theme.isDarkMode,
            onChanged: (_) => theme.toggleTheme(),
            title: const Text('Dark Mode'),
            secondary: const Icon(Icons.dark_mode),
          ),
        ),
        ListTile(
          leading: const Icon(Icons.switch_account),
          title: const Text('Switch to Driver Role'),
          onTap: () => Navigator.pushReplacementNamed(context, '/'),
        ),
        ListTile(
          leading: const Icon(Icons.logout),
            title: const Text('Logout'),
            onTap: () => Navigator.pushNamedAndRemoveUntil(context, '/', (r) => false),
        ),
        const SizedBox(height: 24),
        const Center(child: Text('Path Pilot Authority v0.1')),
      ],
    );
  }
}

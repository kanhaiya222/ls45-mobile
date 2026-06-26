import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../auth/state/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: user == null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      'Sign in to manage your bookings and travellers.',
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Sign in'),
                    ),
                    TextButton(
                      onPressed: () => context.go('/register'),
                      child: const Text('Create an account'),
                    ),
                  ],
                ),
              ),
            )
          : ListView(
              children: [
                const SizedBox(height: 8),
                ListTile(
                  leading: CircleAvatar(
                    child: Text(user.firstName.isNotEmpty ? user.firstName[0].toUpperCase() : '?'),
                  ),
                  title: Text(user.fullName),
                  subtitle: Text(user.email),
                ),
                const Divider(),
                ListTile(
                  leading: const Icon(Icons.confirmation_number_outlined),
                  title: const Text('My bookings'),
                  onTap: () => context.go('/account/bookings'),
                ),
                ListTile(
                  leading: const Icon(Icons.logout),
                  title: const Text('Log out'),
                  onTap: () => ref.read(authControllerProvider.notifier).logout(),
                ),
              ],
            ),
    );
  }
}

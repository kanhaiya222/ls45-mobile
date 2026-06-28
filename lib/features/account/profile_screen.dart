import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../shared/ui/app_ui.dart';
import '../auth/state/auth_controller.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authControllerProvider).value;

    return Scaffold(
      appBar: AppBar(title: const Text('Profile')),
      body: SafeArea(
        child: user == null ? _SignedOut() : _SignedIn(ref: ref, user: user),
      ),
    );
  }
}

class _SignedOut extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return ConstrainedBody(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.account_circle_outlined, size: 72, color: scheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Sign in to your account',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Manage your bookings, travellers and trip details.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: PrimaryButton(label: 'Sign in', onPressed: () => context.go('/login')),
            ),
            const SizedBox(height: 4),
            TextButton(
              onPressed: () => context.go('/register'),
              child: const Text('Create an account'),
            ),
          ],
        ),
      ),
    );
  }
}

class _SignedIn extends StatelessWidget {
  const _SignedIn({required this.ref, required this.user});

  final WidgetRef ref;
  final dynamic user;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final initial = (user.firstName as String).isNotEmpty
        ? (user.firstName as String)[0].toUpperCase()
        : '?';

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
      children: [
        ConstrainedBody(
          child: Column(
            children: [
              SectionCard(
                child: Row(
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            scheme.primary,
                            Color.alphaBlend(Colors.black.withValues(alpha: 0.18), scheme.primary),
                          ],
                        ),
                        shape: BoxShape.circle,
                      ),
                      child: Text(initial,
                          style: const TextStyle(color: Colors.white, fontSize: 24, fontWeight: FontWeight.w700)),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(user.fullName as String,
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
                          const SizedBox(height: 2),
                          Text(user.email as String, style: TextStyle(color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                padding: EdgeInsets.zero,
                child: _MenuTile(
                  icon: Icons.confirmation_number_outlined,
                  label: 'My bookings',
                  onTap: () => context.go('/account/bookings'),
                ),
              ),
              const SizedBox(height: 16),
              SectionCard(
                padding: EdgeInsets.zero,
                child: _MenuTile(
                  icon: Icons.logout_rounded,
                  label: 'Log out',
                  tone: scheme.error,
                  showChevron: false,
                  onTap: () => ref.read(authControllerProvider.notifier).logout(),
                ),
              ),
              const SizedBox(height: 24),
              Text('LS45 · v1.0.0',
                  style: TextStyle(color: scheme.onSurfaceVariant.withValues(alpha: 0.7), fontSize: 12)),
            ],
          ),
        ),
      ],
    );
  }
}

class _MenuTile extends StatelessWidget {
  const _MenuTile({
    required this.icon,
    required this.label,
    required this.onTap,
    this.tone,
    this.showChevron = true,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;
  final Color? tone;
  final bool showChevron;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color = tone ?? scheme.onSurface;
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(kRadiusLg),
      child: InkWell(
        borderRadius: BorderRadius.circular(kRadiusLg),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
          child: Row(
            children: [
              Icon(icon, color: color, size: 22),
              const SizedBox(width: 14),
              Expanded(child: Text(label, style: TextStyle(color: color, fontSize: 15, fontWeight: FontWeight.w600))),
              if (showChevron) Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }
}

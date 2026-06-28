import 'package:flutter/material.dart';

/// Branded header shared by the sign-in and create-account screens: a gradient brand mark, a clear
/// title and a one-line subtitle.
class AuthHeader extends StatelessWidget {
  const AuthHeader({super.key, required this.title, required this.subtitle});

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: 56,
          height: 56,
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                scheme.primary,
                Color.alphaBlend(Colors.black.withValues(alpha: 0.18), scheme.primary),
              ],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(color: scheme.primary.withValues(alpha: 0.35), blurRadius: 16, offset: const Offset(0, 6)),
            ],
          ),
          child: const Icon(Icons.spa_rounded, color: Colors.white, size: 30),
        ),
        const SizedBox(height: 20),
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 8),
        Text(
          subtitle,
          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 14.5, height: 1.4),
        ),
      ],
    );
  }
}

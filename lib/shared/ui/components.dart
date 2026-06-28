import 'package:flutter/material.dart';

import 'app_ui.dart';

/// Higher-level, reusable building blocks so every screen speaks the same visual language: one
/// primary button, one set of loading/empty/error states, one status pill, grouped cards, and
/// label/value rows. Re-exported from app_ui.dart, so screens import a single file.

/// Constrains content to a comfortable reading width and centres it — keeps forms and summaries
/// looking intentional on wide web/desktop windows instead of stretching edge to edge.
class ConstrainedBody extends StatelessWidget {
  const ConstrainedBody({super.key, required this.child, this.maxWidth = 480});

  final Widget child;
  final double maxWidth;

  @override
  Widget build(BuildContext context) {
    // Align (not Center) with heightFactor:1 so this is safe as a direct child of a ListView/scroll
    // view — it sizes its height to the child instead of trying to fill the unbounded scroll extent,
    // while still capping width and centring horizontally.
    return Align(
      alignment: Alignment.topCenter,
      heightFactor: 1,
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth),
        child: child,
      ),
    );
  }
}

/// The single full-width primary action used across the app, with a built-in busy state so callers
/// never re-implement the spinner/disable dance.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({
    super.key,
    required this.label,
    this.onPressed,
    this.busy = false,
    this.icon,
  });

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: _button(context),
    );
  }

  Widget _button(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? SizedBox(
              height: 20,
              width: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2.4,
                color: Theme.of(context).colorScheme.onPrimary,
              ),
            )
          : (icon == null
              ? Text(label)
              : Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [Icon(icon, size: 20), const SizedBox(width: 8), Text(label)],
                )),
    );
  }
}

/// Centred spinner with an optional caption — the one loading state.
class LoadingView extends StatelessWidget {
  const LoadingView({super.key, this.label});

  final String? label;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(),
          if (label != null) ...[
            const SizedBox(height: 16),
            Text(label!, style: TextStyle(color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// The one empty/error state: a friendly icon, a clear title, a supporting line and an optional
/// action. Replaces the ad-hoc Center/Column blocks that used to differ on every screen.
class StateView extends StatelessWidget {
  const StateView({
    super.key,
    required this.icon,
    required this.title,
    this.message,
    this.actionLabel,
    this.onAction,
    this.iconColor,
  });

  final IconData icon;
  final String title;
  final String? message;
  final String? actionLabel;
  final VoidCallback? onAction;
  final Color? iconColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: iconColor ?? scheme.primary.withValues(alpha: 0.55)),
            const SizedBox(height: 16),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            if (message != null) ...[
              const SizedBox(height: 6),
              Text(message!, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

/// Colour-coded status chip for bookings/departures. Greens for done, amber for pending, red for
/// cancelled/failed, neutral otherwise — and the raw enum is prettified ("PENDING_PAYMENT" →
/// "Pending payment").
class StatusPill extends StatelessWidget {
  const StatusPill(this.status, {super.key});

  final String status;

  @override
  Widget build(BuildContext context) {
    final dark = Theme.of(context).brightness == Brightness.dark;
    final c = _statusColor(status);
    final bg = c.withValues(alpha: dark ? 0.22 : 0.12);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 7, height: 7, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
          const SizedBox(width: 6),
          Text(
            prettifyStatus(status),
            style: TextStyle(color: c, fontSize: 12, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

Color _statusColor(String status) {
  switch (status.toUpperCase()) {
    case 'CONFIRMED':
    case 'PAID':
    case 'COMPLETED':
    case 'OPEN':
      return const Color(0xFF15803D);
    case 'PENDING_PAYMENT':
    case 'PENDING':
    case 'RESERVED':
    case 'ON_HOLD':
      return const Color(0xFFB45309);
    case 'CANCELLED':
    case 'EXPIRED':
    case 'FAILED':
    case 'CLOSED':
      return const Color(0xFFB91C1C);
    default:
      return const Color(0xFF475569);
  }
}

/// "PENDING_PAYMENT" -> "Pending payment".
String prettifyStatus(String status) {
  final lower = status.toLowerCase().replaceAll('_', ' ');
  return lower.isEmpty ? lower : '${lower[0].toUpperCase()}${lower.substring(1)}';
}

enum BannerTone { error, info, success }

/// Inline tinted banner for form errors / notices — clearer than bare red text.
class AppBanner extends StatelessWidget {
  const AppBanner({super.key, required this.message, this.tone = BannerTone.error, this.icon});

  final String message;
  final BannerTone tone;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final (color, fallbackIcon) = switch (tone) {
      BannerTone.error => (scheme.error, Icons.error_outline_rounded),
      BannerTone.info => (scheme.primary, Icons.info_outline_rounded),
      BannerTone.success => (const Color(0xFF15803D), Icons.check_circle_outline_rounded),
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon ?? fallbackIcon, size: 20, color: color),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: TextStyle(color: color, fontWeight: FontWeight.w500, height: 1.35)),
          ),
        ],
      ),
    );
  }
}

/// A grouped surface card with an optional heading — the standard container for a block of related
/// content (a price summary, a traveller form, a profile section).
class SectionCard extends StatelessWidget {
  const SectionCard({
    super.key,
    required this.child,
    this.title,
    this.padding = const EdgeInsets.all(16),
  });

  final Widget child;
  final String? title;
  final EdgeInsets padding;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(kRadiusLg),
        boxShadow: softShadow(context),
      ),
      padding: padding,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          if (title != null) ...[
            Text(
              title!,
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 14),
          ],
          child,
        ],
      ),
    );
  }
}

/// Sticky bottom action area with a soft top shadow + safe-area padding; content is width-constrained
/// to match the body on wide screens.
class BottomBar extends StatelessWidget {
  const BottomBar({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.fromLTRB(16, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: const [BoxShadow(color: Color(0x14101828), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: ConstrainedBody(child: child),
    );
  }
}

/// A label — value row for summaries and fact lists; emphasise for totals.
class SummaryRow extends StatelessWidget {
  const SummaryRow({
    super.key,
    required this.label,
    required this.value,
    this.emphasize = false,
    this.valueColor,
  });

  final String label;
  final String value;
  final bool emphasize;
  final Color? valueColor;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final labelStyle = TextStyle(
      color: emphasize ? scheme.onSurface : scheme.onSurfaceVariant,
      fontSize: emphasize ? 16 : 14.5,
      fontWeight: emphasize ? FontWeight.w700 : FontWeight.w500,
    );
    final valueStyle = TextStyle(
      color: valueColor ?? scheme.onSurface,
      fontSize: emphasize ? 18 : 14.5,
      fontWeight: emphasize ? FontWeight.w800 : FontWeight.w600,
    );
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(child: Text(label, style: labelStyle)),
          const SizedBox(width: 16),
          Text(value, style: valueStyle),
        ],
      ),
    );
  }
}

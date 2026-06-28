import 'package:flutter/material.dart';

export 'components.dart';

/// Shared visual language for the app — corner radii, soft shadows, entrance motion, shimmer
/// skeletons, fading network images, and small labelled chips / section headers. Pure Flutter (no
/// third-party packages) so it stays robust offline and on web. Higher-level building blocks
/// (PrimaryButton, StateView, StatusPill, SectionCard, …) live in components.dart and are re-exported.

const double kRadiusLg = 22;
const double kRadiusMd = 14;
const double kRadiusSm = 10;

/// A soft, layered card shadow tuned for light surfaces (subtle in dark mode).
List<BoxShadow> softShadow(BuildContext context) {
  final dark = Theme.of(context).brightness == Brightness.dark;
  if (dark) {
    return const [BoxShadow(color: Color(0x33000000), blurRadius: 16, offset: Offset(0, 6))];
  }
  return const [
    BoxShadow(color: Color(0x14101828), blurRadius: 18, offset: Offset(0, 8)),
    BoxShadow(color: Color(0x0A101828), blurRadius: 2, offset: Offset(0, 1)),
  ];
}

/// Fades + slides its child up on first build. Give later items a small [delay] for a staggered list.
class FadeSlideIn extends StatefulWidget {
  const FadeSlideIn({
    super.key,
    required this.child,
    this.delay = Duration.zero,
    this.offsetY = 22,
    this.duration = const Duration(milliseconds: 420),
  });

  final Widget child;
  final Duration delay;
  final double offsetY;
  final Duration duration;

  @override
  State<FadeSlideIn> createState() => _FadeSlideInState();
}

class _FadeSlideInState extends State<FadeSlideIn> with SingleTickerProviderStateMixin {
  late final AnimationController _c = AnimationController(vsync: this, duration: widget.duration);
  late final Animation<double> _t = CurvedAnimation(parent: _c, curve: Curves.easeOutCubic);

  @override
  void initState() {
    super.initState();
    if (widget.delay == Duration.zero) {
      _c.forward();
    } else {
      Future.delayed(widget.delay, () {
        if (mounted) _c.forward();
      });
    }
  }

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _t,
      builder: (context, child) => Opacity(
        opacity: _t.value.clamp(0, 1),
        child: Transform.translate(offset: Offset(0, (1 - _t.value) * widget.offsetY), child: child),
      ),
      child: widget.child,
    );
  }
}

/// Sweeps a light highlight across its (placeholder-coloured) children to signal loading.
class Shimmer extends StatefulWidget {
  const Shimmer({super.key, required this.child});

  final Widget child;

  @override
  State<Shimmer> createState() => _ShimmerState();
}

class _ShimmerState extends State<Shimmer> with SingleTickerProviderStateMixin {
  late final AnimationController _c =
      AnimationController(vsync: this, duration: const Duration(milliseconds: 1300))..repeat();

  @override
  void dispose() {
    _c.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final base = scheme.surfaceContainerHighest;
    final highlight = Color.alphaBlend(scheme.surface.withValues(alpha: 0.7), base);
    return AnimatedBuilder(
      animation: _c,
      builder: (context, child) {
        final v = _c.value * 1.6 - 0.3; // sweep from off-screen left to right
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) => LinearGradient(
            begin: Alignment.centerLeft,
            end: Alignment.centerRight,
            colors: [base, highlight, base],
            stops: [
              (v - 0.3).clamp(0.0, 1.0),
              v.clamp(0.0, 1.0),
              (v + 0.3).clamp(0.0, 1.0),
            ],
          ).createShader(bounds),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

/// A solid placeholder block used inside a [Shimmer].
class ShimmerBox extends StatelessWidget {
  const ShimmerBox({super.key, this.width, this.height = 14, this.radius = kRadiusSm});

  final double? width;
  final double height;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}

/// A network image that fades in once decoded and shows a tasteful branded placeholder while loading
/// or if it fails (so cards never render as empty grey boxes).
class NetworkImageFade extends StatelessWidget {
  const NetworkImageFade({super.key, required this.url, this.fit = BoxFit.cover});

  final String? url;
  final BoxFit fit;

  @override
  Widget build(BuildContext context) {
    if (url == null || url!.isEmpty) return _Placeholder();
    return Image.network(
      url!,
      fit: fit,
      gaplessPlayback: true,
      frameBuilder: (context, child, frame, wasSynchronouslyLoaded) {
        if (wasSynchronouslyLoaded) return child;
        return AnimatedOpacity(
          opacity: frame == null ? 0 : 1,
          duration: const Duration(milliseconds: 350),
          curve: Curves.easeOut,
          child: child,
        );
      },
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : _Placeholder(),
      errorBuilder: (_, __, ___) => _Placeholder(),
    );
  }
}

class _Placeholder extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Color.alphaBlend(scheme.primary.withValues(alpha: 0.18), scheme.surface),
            Color.alphaBlend(scheme.primary.withValues(alpha: 0.06), scheme.surface),
          ],
        ),
      ),
      child: Center(
        child: Icon(Icons.spa_outlined, size: 40, color: scheme.primary.withValues(alpha: 0.45)),
      ),
    );
  }
}

/// Dark-to-clear gradient laid over an image so overlaid white text stays legible.
BoxDecoration imageScrim({double opacity = 0.66}) => BoxDecoration(
      gradient: LinearGradient(
        begin: Alignment.bottomCenter,
        end: Alignment.topCenter,
        colors: [Colors.black.withValues(alpha: opacity), Colors.transparent],
        stops: const [0.0, 0.62],
      ),
    );

/// A compact icon + label pill used for duration, difficulty, location, seats, etc.
class InfoChip extends StatelessWidget {
  const InfoChip({super.key, required this.icon, required this.label, this.onSurfaceImage = false});

  final IconData icon;
  final String label;

  /// When laid over an image use white-on-translucent rather than the surface tint.
  final bool onSurfaceImage;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final fg = onSurfaceImage ? Colors.white : scheme.onSurfaceVariant;
    final bg = onSurfaceImage
        ? Colors.black.withValues(alpha: 0.32)
        : scheme.surfaceContainerHighest.withValues(alpha: 0.9);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(999)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: fg),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(color: fg, fontSize: 12, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Section title with a short accent bar — used down the detail page.
class SectionHeader extends StatelessWidget {
  const SectionHeader(this.title, {super.key, this.icon});

  final String title;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(top: 24, bottom: 12),
      child: Row(
        children: [
          Container(
            width: 4,
            height: 20,
            decoration: BoxDecoration(
              color: scheme.primary,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(width: 10),
          if (icon != null) ...[
            Icon(icon, size: 18, color: scheme.primary),
            const SizedBox(width: 6),
          ],
          Text(
            title,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

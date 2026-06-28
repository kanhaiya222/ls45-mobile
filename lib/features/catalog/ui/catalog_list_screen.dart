import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/ui/app_ui.dart';
import '../../appconfig/data/app_config_repository.dart';
import '../../appconfig/models/app_branding.dart';
import '../../auth/state/auth_controller.dart';
import '../models/catalog_models.dart';
import '../state/packages_controller.dart';

/// Home: the published wellness-package catalog with search + pagination.
class CatalogListScreen extends ConsumerStatefulWidget {
  const CatalogListScreen({super.key});

  @override
  ConsumerState<CatalogListScreen> createState() => _CatalogListScreenState();
}

class _CatalogListScreenState extends ConsumerState<CatalogListScreen> {
  final _search = TextEditingController();

  @override
  void dispose() {
    _search.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final packages = ref.watch(packagesControllerProvider);
    final signedIn = ref.watch(authControllerProvider).value != null;

    return Scaffold(
      body: RefreshIndicator(
        onRefresh: () => ref.read(packagesControllerProvider.notifier).refresh(),
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: _HeroHeader(
                signedIn: signedIn,
                onAuthTap: () => signedIn
                    ? ref.read(authControllerProvider.notifier).logout()
                    : context.go('/login'),
              ),
            ),
            SliverPersistentHeader(
              pinned: true,
              delegate: _SearchBarDelegate(
                controller: _search,
                onSubmit: (q) => ref.read(packagesControllerProvider.notifier).search(q),
              ),
            ),
            _body(packages),
          ],
        ),
      ),
    );
  }

  Widget _body(AsyncValue<List<PackageSummary>> packages) {
    return packages.when(
      loading: () => const SliverToBoxAdapter(child: _CatalogSkeleton()),
      error: (e, _) => SliverFillRemaining(
        hasScrollBody: false,
        child: _ErrorState(
          message: e is ApiException ? e.message : 'Could not load journeys.',
          onRetry: () => ref.read(packagesControllerProvider.notifier).refresh(),
        ),
      ),
      data: (items) => items.isEmpty
          ? const SliverFillRemaining(hasScrollBody: false, child: _EmptyState())
          : _PackageSliverList(items: items),
    );
  }
}

/// Brand gradient banner with a warm welcome + sign-in/out affordance.
class _HeroHeader extends StatelessWidget {
  const _HeroHeader({required this.signedIn, required this.onAuthTap});

  final bool signedIn;
  final VoidCallback onAuthTap;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 18, 16, 26),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            scheme.primary,
            Color.alphaBlend(Colors.black.withValues(alpha: 0.18), scheme.primary),
          ],
        ),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(28)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LS45 · WELLNESS',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 1.5,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Journeys for life\nafter 45',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    height: 1.15,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Small-group, doctor-informed retreats with fixed departures.',
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 13.5, height: 1.4),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          IconButton(
            tooltip: signedIn ? 'Log out' : 'Sign in',
            onPressed: onAuthTap,
            icon: Icon(signedIn ? Icons.logout_rounded : Icons.person_outline_rounded),
            style: IconButton.styleFrom(
              backgroundColor: Colors.white.withValues(alpha: 0.18),
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

/// Pinned, rounded search field that stays put as the catalogue scrolls.
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  _SearchBarDelegate({required this.controller, required this.onSubmit});

  final TextEditingController controller;
  final ValueChanged<String> onSubmit;

  // Generous fixed extent; the child fills it exactly (SizedBox.expand) so the declared extent always
  // matches what paints — otherwise the sliver throws "layoutExtent exceeds paintExtent".
  static const double _height = 80;

  @override
  double get minExtent => _height;
  @override
  double get maxExtent => _height;

  @override
  Widget build(BuildContext context, double shrinkOffset, bool overlapsContent) {
    return SizedBox.expand(
      child: ColoredBox(
        color: Theme.of(context).scaffoldBackgroundColor,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Center(
            child: TextField(
              controller: controller,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search journeys, places, themes…',
                prefixIcon: const Icon(Icons.search_rounded),
                suffixIcon: controller.text.isEmpty
                    ? null
                    : IconButton(
                        icon: const Icon(Icons.close_rounded, size: 20),
                        onPressed: () {
                          controller.clear();
                          onSubmit('');
                        },
                      ),
              ),
              onSubmitted: onSubmit,
            ),
          ),
        ),
      ),
    );
  }

  @override
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) => false;
}

class _PackageSliverList extends ConsumerWidget {
  const _PackageSliverList({required this.items});

  final List<PackageSummary> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(packagesControllerProvider.notifier);
    final hasMore = controller.hasMore;

    return SliverPadding(
      padding: const EdgeInsets.only(top: 4, bottom: 28),
      sliver: SliverList.builder(
        itemCount: items.length + (hasMore ? 1 : 0),
        itemBuilder: (context, index) {
          if (index >= items.length) {
            WidgetsBinding.instance.addPostFrameCallback((_) => controller.loadMore());
            return const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: CircularProgressIndicator()),
            );
          }
          return _PackageCard(
            package: items[index],
            // Stagger only the first screenful so later pages appear instantly.
            delay: Duration(milliseconds: index < 6 ? index * 55 : 0),
          );
        },
      ),
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package, this.delay = Duration.zero});

  final PackageSummary package;
  final Duration delay;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return FadeSlideIn(
      delay: delay,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: scheme.surface,
            borderRadius: BorderRadius.circular(kRadiusLg),
            boxShadow: softShadow(context),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(kRadiusLg),
            child: Material(
              color: Colors.transparent,
              child: InkWell(
                onTap: () => context.push('/packages/${package.slug}', extra: package),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Stack(
                      children: [
                        AspectRatio(
                          aspectRatio: 16 / 10,
                          child: Hero(
                            tag: 'pkg-${package.publicId}',
                            child: NetworkImageFade(url: package.heroImageUrl),
                          ),
                        ),
                        Positioned.fill(child: DecoratedBox(decoration: imageScrim())),
                        if (package.featured)
                          const Positioned(top: 12, right: 12, child: _FeaturedBadge()),
                        Positioned(
                          left: 16,
                          right: 16,
                          bottom: 14,
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (package.categoryName != null) ...[
                                _CategoryTag(package.categoryName!),
                                const SizedBox(height: 8),
                              ],
                              Text(
                                package.name,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 19,
                                  height: 1.15,
                                  fontWeight: FontWeight.w700,
                                  letterSpacing: -0.3,
                                  shadows: [Shadow(color: Color(0x66000000), blurRadius: 8)],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    Padding(
                      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
                      child: Row(
                        children: [
                          Expanded(
                            child: Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              children: [
                                InfoChip(
                                  icon: Icons.calendar_today_rounded,
                                  label: '${package.durationDays}D / ${package.durationNights}N',
                                ),
                                if (package.difficulty != null)
                                  InfoChip(
                                    icon: Icons.terrain_rounded,
                                    label: package.difficulty!,
                                  ),
                              ],
                            ),
                          ),
                          if (package.basePrice != null) _PriceTag(package: package),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _PriceTag extends ConsumerWidget {
  const _PriceTag({required this.package});

  final PackageSummary package;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final code = package.currency ?? ref.watch(currentBrandingProvider).currencyCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.end,
      mainAxisSize: MainAxisSize.min,
      children: [
        Text('from', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        Text(
          '${currencySymbolFor(code)}${package.basePrice!.round()}',
          style: TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: scheme.primary,
            letterSpacing: -0.3,
          ),
        ),
      ],
    );
  }
}

class _FeaturedBadge extends StatelessWidget {
  const _FeaturedBadge();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B),
        borderRadius: BorderRadius.circular(999),
        boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 6, offset: Offset(0, 2))],
      ),
      child: const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.star_rounded, size: 14, color: Colors.white),
          SizedBox(width: 4),
          Text('Featured',
              style: TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _CategoryTag extends StatelessWidget {
  const _CategoryTag(this.label);
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.22),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.5)),
      ),
      child: Text(
        label.toUpperCase(),
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.6,
        ),
      ),
    );
  }
}

class _CatalogSkeleton extends StatelessWidget {
  const _CatalogSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Column(
        children: List.generate(4, (_) => const _SkeletonCard()),
      ),
    );
  }
}

class _SkeletonCard extends StatelessWidget {
  const _SkeletonCard();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(kRadiusLg),
          boxShadow: softShadow(context),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusLg),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const AspectRatio(aspectRatio: 16 / 10, child: ShimmerBox(radius: 0, height: 999)),
              Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  children: const [
                    Expanded(child: ShimmerBox(width: 120, height: 26, radius: 999)),
                    SizedBox(width: 12),
                    ShimmerBox(width: 56, height: 30),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.travel_explore_rounded, size: 56, color: scheme.primary.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('No journeys yet',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
              'Nothing matches your search right now. Try a different keyword.',
              textAlign: TextAlign.center,
              style: TextStyle(color: scheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off_rounded, size: 56, color: scheme.error.withValues(alpha: 0.7)),
            const SizedBox(height: 16),
            Text('Something went wrong',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Try again'),
            ),
          ],
        ),
      ),
    );
  }
}

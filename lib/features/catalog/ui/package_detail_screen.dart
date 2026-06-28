import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
import '../../../shared/ui/app_ui.dart';
import '../../appconfig/data/app_config_repository.dart';
import '../../appconfig/models/app_branding.dart';
import '../models/catalog_models.dart';
import '../state/package_detail_controller.dart';

class PackageDetailScreen extends ConsumerStatefulWidget {
  const PackageDetailScreen({super.key, required this.slug, this.preview});

  final String slug;

  /// The list-card summary passed via route extra — lets the hero image + title paint instantly
  /// (and animate via Hero) while the full detail loads.
  final PackageSummary? preview;

  @override
  ConsumerState<PackageDetailScreen> createState() => _PackageDetailScreenState();
}

class _PackageDetailScreenState extends ConsumerState<PackageDetailScreen> {
  final _departuresKey = GlobalKey();

  void _scrollToDepartures() {
    final ctx = _departuresKey.currentContext;
    if (ctx != null) {
      Scrollable.ensureVisible(ctx,
          duration: const Duration(milliseconds: 450), curve: Curves.easeInOut, alignment: 0.05);
    }
  }

  @override
  Widget build(BuildContext context) {
    final async = ref.watch(packageDetailProvider(widget.slug));
    final bundle = async.value;
    final heroUrl = bundle?.detail.heroImageUrl ?? widget.preview?.heroImageUrl;
    final title = bundle?.detail.name ?? widget.preview?.name ?? 'Journey';
    final heroTag = 'pkg-${widget.preview?.publicId ?? widget.slug}';

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          _HeroAppBar(heroTag: heroTag, imageUrl: heroUrl, title: title),
          async.when(
            loading: () => const SliverToBoxAdapter(child: _DetailSkeleton()),
            error: (e, _) => SliverFillRemaining(
              hasScrollBody: false,
              child: _DetailError(
                message: e is ApiException ? e.message : 'Could not load this journey.',
                onRetry: () => ref.invalidate(packageDetailProvider(widget.slug)),
              ),
            ),
            data: (b) => SliverToBoxAdapter(
              child: _DetailBody(bundle: b, departuresKey: _departuresKey),
            ),
          ),
        ],
      ),
      bottomNavigationBar: bundle == null
          ? null
          : _BottomCta(bundle: bundle, onViewDepartures: _scrollToDepartures),
    );
  }
}

class _HeroAppBar extends StatelessWidget {
  const _HeroAppBar({required this.heroTag, required this.imageUrl, required this.title});

  final String heroTag;
  final String? imageUrl;
  final String title;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return SliverAppBar(
      pinned: true,
      expandedHeight: 300,
      backgroundColor: scheme.primary,
      foregroundColor: Colors.white,
      leading: Padding(
        padding: const EdgeInsets.all(8),
        child: CircleAvatar(
          backgroundColor: Colors.black.withValues(alpha: 0.32),
          child: IconButton(
            icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
            onPressed: () => Navigator.of(context).maybePop(),
          ),
        ),
      ),
      flexibleSpace: FlexibleSpaceBar(
        titlePadding: const EdgeInsets.only(left: 56, right: 16, bottom: 14),
        title: Text(
          title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.w700,
            fontSize: 16,
            shadows: [Shadow(color: Color(0x99000000), blurRadius: 8)],
          ),
        ),
        background: Stack(
          fit: StackFit.expand,
          children: [
            Hero(tag: heroTag, child: NetworkImageFade(url: imageUrl)),
            Positioned.fill(child: DecoratedBox(decoration: imageScrim(opacity: 0.55))),
          ],
        ),
      ),
    );
  }
}

class _DetailBody extends StatelessWidget {
  const _DetailBody({required this.bundle, required this.departuresKey});

  final PackageDetailBundle bundle;
  final GlobalKey departuresKey;

  @override
  Widget build(BuildContext context) {
    final d = bundle.detail;
    final text = Theme.of(context).textTheme;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          FadeSlideIn(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (d.categoryName != null) ...[
                  Text(
                    d.categoryName!.toUpperCase(),
                    style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                      letterSpacing: 1,
                    ),
                  ),
                  const SizedBox(height: 6),
                ],
                Text(d.name, style: text.headlineSmall),
                const SizedBox(height: 14),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    InfoChip(
                      icon: Icons.calendar_today_rounded,
                      label: '${d.durationDays}D / ${d.durationNights}N',
                    ),
                    if (d.difficulty != null)
                      InfoChip(icon: Icons.terrain_rounded, label: d.difficulty!),
                    if (d.meetingLocation != null)
                      InfoChip(icon: Icons.place_rounded, label: d.meetingLocation!),
                  ],
                ),
              ],
            ),
          ),
          if (d.shortDescription != null) ...[
            const SizedBox(height: 18),
            FadeSlideIn(delay: const Duration(milliseconds: 60), child: Text(d.shortDescription!, style: text.bodyLarge)),
          ],
          if (d.description != null) ...[
            const SizedBox(height: 10),
            Text(d.description!, style: text.bodyMedium),
          ],
          _Highlights(highlights: d.highlights),
          _BulletSection(title: "What's included", items: d.inclusions, icon: Icons.check_circle_rounded, iconColor: const Color(0xFF15803D)),
          _BulletSection(title: 'Not included', items: d.exclusions, icon: Icons.cancel_rounded, iconColor: const Color(0xFFB91C1C)),
          KeyedSubtree(key: departuresKey, child: _Departures(departures: bundle.departures)),
          _ItineraryView(itinerary: bundle.itinerary),
          _Faqs(faqs: bundle.faqs),
          _ShopThisJourney(products: d.taggedProducts),
        ],
      ),
    );
  }
}

/// "Shop this journey" — commerce products tagged to this package, cross-sold here.
class _ShopThisJourney extends ConsumerWidget {
  const _ShopThisJourney({required this.products});

  final List<TaggedProduct> products;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (products.isEmpty) return const SizedBox.shrink();
    final code = ref.watch(currentBrandingProvider).currencyCode;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Shop this journey', icon: Icons.shopping_bag_outlined),
        SizedBox(
          height: 198,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(vertical: 4),
            itemCount: products.length,
            separatorBuilder: (_, __) => const SizedBox(width: 12),
            itemBuilder: (_, i) => _TaggedProductCard(product: products[i], code: code),
          ),
        ),
      ],
    );
  }
}

class _TaggedProductCard extends StatelessWidget {
  const _TaggedProductCard({required this.product, required this.code});

  final TaggedProduct product;
  final String code;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final price = product.basePrice;
    return SizedBox(
      width: 150,
      child: DecoratedBox(
        decoration: BoxDecoration(
          color: scheme.surface,
          borderRadius: BorderRadius.circular(kRadiusMd),
          boxShadow: softShadow(context),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(kRadiusMd),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: product.slug == null ? null : () => context.push('/shop/${product.slug}'),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  AspectRatio(
                    aspectRatio: 1.2,
                    child: NetworkImageFade(url: product.thumbnailUrl ?? product.heroImageUrl),
                  ),
                  Padding(
                    padding: const EdgeInsets.fromLTRB(10, 8, 10, 10),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(product.name,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700, height: 1.2)),
                        const SizedBox(height: 4),
                        if (price != null)
                          Text('${currencySymbolFor(code)}${price.round()}',
                              style: TextStyle(fontSize: 13.5, fontWeight: FontWeight.w800, color: scheme.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _Highlights extends StatelessWidget {
  const _Highlights({required this.highlights});
  final List<String>? highlights;

  @override
  Widget build(BuildContext context) {
    if (highlights == null || highlights!.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Highlights', icon: Icons.auto_awesome_rounded),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: [
            for (final h in highlights!)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: scheme.primary.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(color: scheme.primary.withValues(alpha: 0.2)),
                ),
                child: Text(h,
                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 13)),
              ),
          ],
        ),
      ],
    );
  }
}

class _BulletSection extends StatelessWidget {
  const _BulletSection({
    required this.title,
    required this.items,
    required this.icon,
    required this.iconColor,
  });

  final String title;
  final List<String>? items;
  final IconData icon;
  final Color iconColor;

  @override
  Widget build(BuildContext context) {
    if (items == null || items!.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SectionHeader(title),
        for (final i in items!)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 5),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(icon, size: 18, color: iconColor),
                const SizedBox(width: 10),
                Expanded(child: Text(i, style: Theme.of(context).textTheme.bodyMedium)),
              ],
            ),
          ),
      ],
    );
  }
}

class _Departures extends StatelessWidget {
  const _Departures({required this.departures});
  final List<DepartureSummary> departures;

  @override
  Widget build(BuildContext context) {
    if (departures.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Upcoming departures', icon: Icons.event_available_rounded),
        for (final dep in departures) _DepartureCard(dep: dep),
      ],
    );
  }
}

class _DepartureCard extends ConsumerWidget {
  const _DepartureCard({required this.dep});
  final DepartureSummary dep;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final open = dep.status == 'OPEN';
    final fewLeft = dep.availableSeats > 0 && dep.availableSeats <= 4;
    final code = ref.watch(currentBrandingProvider).currencyCode;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: scheme.surface,
        borderRadius: BorderRadius.circular(kRadiusMd),
        border: Border.all(color: scheme.outlineVariant),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(kRadiusMd),
          onTap: open ? () => context.push('/book/${dep.publicId}') : null,
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${dep.startDate}  –  ${dep.endDate}',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          _StatusDot(open: open),
                          const SizedBox(width: 6),
                          Text(
                            open ? (fewLeft ? 'Only ${dep.availableSeats} seats left' : '${dep.availableSeats} seats left') : dep.status,
                            style: TextStyle(
                              color: fewLeft ? const Color(0xFFB45309) : scheme.onSurfaceVariant,
                              fontSize: 12.5,
                              fontWeight: fewLeft ? FontWeight.w700 : FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                if (dep.priceFrom != null)
                  Text('${currencySymbolFor(code)}${dep.priceFrom!.round()}',
                      style: TextStyle(
                          fontWeight: FontWeight.w800, fontSize: 16, color: scheme.primary)),
                if (open) ...[
                  const SizedBox(width: 6),
                  Icon(Icons.chevron_right_rounded, color: scheme.onSurfaceVariant),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StatusDot extends StatelessWidget {
  const _StatusDot({required this.open});
  final bool open;

  @override
  Widget build(BuildContext context) => Container(
        width: 8,
        height: 8,
        decoration: BoxDecoration(
          color: open ? const Color(0xFF16A34A) : Theme.of(context).colorScheme.outline,
          shape: BoxShape.circle,
        ),
      );
}

class _ItineraryView extends StatelessWidget {
  const _ItineraryView({required this.itinerary});
  final Itinerary? itinerary;

  @override
  Widget build(BuildContext context) {
    final days = itinerary?.days ?? const [];
    if (days.isEmpty) return const SizedBox.shrink();
    final scheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Day-by-day itinerary', icon: Icons.map_rounded),
        for (final day in days)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              leading: CircleAvatar(
                radius: 16,
                backgroundColor: scheme.primary.withValues(alpha: 0.12),
                child: Text('${day.dayNumber}',
                    style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
              ),
              title: Text(day.title ?? 'Day ${day.dayNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w600)),
              subtitle: day.location != null ? Text(day.location!) : null,
              childrenPadding: const EdgeInsets.only(left: 16, bottom: 12),
              children: [
                if (day.description != null)
                  Align(alignment: Alignment.centerLeft, child: Text(day.description!)),
                for (final act in day.activities)
                  Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (act.startTime != null)
                          Text('${act.startTime}  ',
                              style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w600, fontSize: 13))
                        else
                          Icon(Icons.fiber_manual_record, size: 8, color: scheme.primary),
                        Expanded(child: Text(act.title)),
                      ],
                    ),
                  ),
              ],
            ),
          ),
      ],
    );
  }
}

class _Faqs extends StatelessWidget {
  const _Faqs({required this.faqs});
  final List<Faq> faqs;

  @override
  Widget build(BuildContext context) {
    if (faqs.isEmpty) return const SizedBox.shrink();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SectionHeader('Frequently asked', icon: Icons.help_outline_rounded),
        for (final faq in faqs)
          Theme(
            data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
            child: ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(faq.question, style: const TextStyle(fontWeight: FontWeight.w600)),
              childrenPadding: const EdgeInsets.only(bottom: 14),
              children: [Align(alignment: Alignment.centerLeft, child: Text(faq.answer))],
            ),
          ),
      ],
    );
  }
}

/// Sticky bottom bar with the lead price + a jump-to-departures CTA.
class _BottomCta extends ConsumerWidget {
  const _BottomCta({required this.bundle, required this.onViewDepartures});

  final PackageDetailBundle bundle;
  final VoidCallback onViewDepartures;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final scheme = Theme.of(context).colorScheme;
    final d = bundle.detail;
    final hasDepartures = bundle.departures.isNotEmpty;
    final code = d.currencyCode ?? ref.watch(currentBrandingProvider).currencyCode;

    return Container(
      padding: EdgeInsets.fromLTRB(20, 12, 16, 12 + MediaQuery.of(context).padding.bottom),
      decoration: BoxDecoration(
        color: scheme.surface,
        boxShadow: const [BoxShadow(color: Color(0x14101828), blurRadius: 16, offset: Offset(0, -4))],
      ),
      child: Row(
        children: [
          if (d.basePrice != null)
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('from', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                Text(
                  '${currencySymbolFor(code)}${d.basePrice!.round()}',
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: scheme.onSurface),
                ),
                Text('per person', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
              ],
            ),
          const Spacer(),
          FilledButton.icon(
            onPressed: hasDepartures ? onViewDepartures : null,
            icon: const Icon(Icons.event_available_rounded, size: 20),
            label: Text(hasDepartures ? 'View departures' : 'Sold out'),
            style: FilledButton.styleFrom(minimumSize: const Size(0, 50)),
          ),
        ],
      ),
    );
  }
}

class _DetailSkeleton extends StatelessWidget {
  const _DetailSkeleton();

  @override
  Widget build(BuildContext context) {
    return Shimmer(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: const [
            ShimmerBox(width: 220, height: 26),
            SizedBox(height: 16),
            Row(children: [
              ShimmerBox(width: 90, height: 28, radius: 999),
              SizedBox(width: 8),
              ShimmerBox(width: 90, height: 28, radius: 999),
            ]),
            SizedBox(height: 24),
            ShimmerBox(height: 14),
            SizedBox(height: 10),
            ShimmerBox(height: 14),
            SizedBox(height: 10),
            ShimmerBox(width: 240, height: 14),
            SizedBox(height: 28),
            ShimmerBox(width: 160, height: 20),
            SizedBox(height: 14),
            ShimmerBox(height: 66, radius: kRadiusMd),
            SizedBox(height: 10),
            ShimmerBox(height: 66, radius: kRadiusMd),
          ],
        ),
      ),
    );
  }
}

class _DetailError extends StatelessWidget {
  const _DetailError({required this.message, required this.onRetry});

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
            Icon(Icons.cloud_off_rounded, size: 52, color: scheme.error.withValues(alpha: 0.7)),
            const SizedBox(height: 14),
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

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/network/api_exception.dart';
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
      appBar: AppBar(
        title: const Text('LS45 Wellness Journeys'),
        actions: [
          if (signedIn)
            IconButton(
              tooltip: 'Log out',
              icon: const Icon(Icons.logout),
              onPressed: () => ref.read(authControllerProvider.notifier).logout(),
            )
          else
            IconButton(
              tooltip: 'Sign in',
              icon: const Icon(Icons.person_outline),
              onPressed: () => context.go('/login'),
            ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
            child: TextField(
              controller: _search,
              textInputAction: TextInputAction.search,
              decoration: InputDecoration(
                hintText: 'Search journeys',
                prefixIcon: const Icon(Icons.search),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                isDense: true,
              ),
              onSubmitted: (q) => ref.read(packagesControllerProvider.notifier).search(q),
            ),
          ),
          Expanded(
            child: packages.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => _ErrorState(
                message: e is ApiException ? e.message : 'Could not load journeys.',
                onRetry: () => ref.read(packagesControllerProvider.notifier).refresh(),
              ),
              data: (items) => items.isEmpty
                  ? const _EmptyState()
                  : RefreshIndicator(
                      onRefresh: () => ref.read(packagesControllerProvider.notifier).refresh(),
                      child: _PackageList(items: items),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PackageList extends ConsumerWidget {
  const _PackageList({required this.items});

  final List<PackageSummary> items;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final controller = ref.read(packagesControllerProvider.notifier);
    final hasMore = controller.hasMore;

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length + (hasMore ? 1 : 0),
      itemBuilder: (context, index) {
        if (index >= items.length) {
          // Trigger the next page when the load-more tile scrolls into view.
          WidgetsBinding.instance.addPostFrameCallback((_) => controller.loadMore());
          return const Padding(
            padding: EdgeInsets.all(16),
            child: Center(child: CircularProgressIndicator()),
          );
        }
        return _PackageCard(package: items[index]);
      },
    );
  }
}

class _PackageCard extends StatelessWidget {
  const _PackageCard({required this.package});

  final PackageSummary package;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      margin: const EdgeInsets.only(bottom: 16),
      child: InkWell(
        onTap: () => context.push('/packages/${package.slug}'),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (package.heroImageUrl != null)
              AspectRatio(
                aspectRatio: 16 / 9,
                child: Image.network(
                  package.heroImageUrl!,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => const ColoredBox(color: Color(0xFFE5E7EB)),
                ),
              ),
            Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(package.name,
                            style: Theme.of(context).textTheme.titleMedium,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis),
                      ),
                      if (package.featured)
                        const Chip(
                          label: Text('Featured'),
                          visualDensity: VisualDensity.compact,
                        ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${package.durationDays}D / ${package.durationNights}N'
                    '${package.difficulty != null ? ' · ${package.difficulty}' : ''}',
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  if (package.basePrice != null) ...[
                    const SizedBox(height: 8),
                    Consumer(builder: (context, ref, _) {
                      final code = package.currency ?? ref.watch(currentBrandingProvider).currencyCode;
                      return Text('from ${currencySymbolFor(code)}${package.basePrice!.round()}',
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(fontWeight: FontWeight.bold));
                    }),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Center(
        child: Padding(
          padding: EdgeInsets.all(24),
          child: Text('No journeys match your search yet.', textAlign: TextAlign.center),
        ),
      );
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) => Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(message, textAlign: TextAlign.center),
              const SizedBox(height: 12),
              FilledButton(onPressed: onRetry, child: const Text('Retry')),
            ],
          ),
        ),
      );
}

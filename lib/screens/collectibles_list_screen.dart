import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collectibles_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/formatting.dart';
import 'collectible_detail_screen.dart';

class CollectiblesListScreen extends StatefulWidget {
  const CollectiblesListScreen({super.key});

  @override
  State<CollectiblesListScreen> createState() => _CollectiblesListScreenState();
}

class _CollectiblesListScreenState extends State<CollectiblesListScreen> {
  String? get _username => context.read<AuthProvider>().userName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CollectiblesProvider>().refresh(_username);
    });
  }

  Future<void> _openFilters() async {
    final provider = context.read<CollectiblesProvider>();
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setSheetState) {
            final scheme = Theme.of(ctx).colorScheme;
            return Padding(
              padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
              child: DraggableScrollableSheet(
                initialChildSize: 0.6,
                minChildSize: 0.3,
                maxChildSize: 0.9,
                expand: false,
                builder: (ctx, scrollController) {
                  return ListView(
                    controller: scrollController,
                    padding: const EdgeInsets.all(16),
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Filters', style: Theme.of(ctx).textTheme.titleMedium),
                          TextButton(
                            onPressed: () async {
                              await provider.clearFilters(_username);
                              setSheetState(() {});
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      if (!provider.repFilterLocked) ...[
                        const SizedBox(height: 12),
                        Text('SALES REP', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        Wrap(
                          spacing: 8,
                          runSpacing: 8,
                          children: provider.salesReps.map((r) {
                            final selected = provider.selectedSalesReps.contains(r);
                            return FilterChip(
                              label: Text(r),
                              selected: selected,
                              onSelected: (_) async {
                                await provider.toggleSalesRep(r, _username);
                                setSheetState(() {});
                              },
                            );
                          }).toList(),
                        ),
                      ],
                      const SizedBox(height: 16),
                      Text('LOCATION', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.locations.map((l) {
                          final selected = provider.selectedLocations.contains(l);
                          return FilterChip(
                            label: Text(l),
                            selected: selected,
                            onSelected: (_) async {
                              await provider.toggleLocation(l, _username);
                              setSheetState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                    ],
                  );
                },
              ),
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<CollectiblesProvider>();
    final scheme = Theme.of(context).colorScheme;
    final activeFilters = provider.selectedLocations.length + provider.selectedSalesReps.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Collectibles'),
        actions: [
          IconButton(
            icon: Badge(
              isLabelVisible: activeFilters > 0,
              label: Text('$activeFilters'),
              child: const Icon(Icons.filter_list_outlined),
            ),
            onPressed: _openFilters,
          ),
        ],
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              key: const Key('collectibleSearchField'),
              hintText: 'Search by clinic, contact, location, or rep…',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              onChanged: (v) {
                context.read<CollectiblesProvider>().setSearch(v);
                context.read<CollectiblesProvider>().refresh(_username);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${provider.customersWithBalanceAll} with balance · ${formatMoney(provider.totalOpenBalanceAll)} total'
                    '${provider.isTruncated ? ' · showing top ${provider.items.length} of ${provider.totalItems}' : ''}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(provider.errorMessage!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 13))),
                  ],
                ),
              ),
            ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<CollectiblesProvider>().refresh(_username),
                    child: _list(provider, scheme),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _list(CollectiblesProvider provider, ColorScheme scheme) {
    if (provider.items.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(Icons.payments_outlined, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('No clinics found.', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      key: const Key('collectiblesList'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: provider.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = provider.items[index];
        final owes = c.openBalance > 0.01;
        final overdue = c.overdueBalance > 0.01;

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => CollectibleDetailScreen(customer: c))),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Text(
                      (c.clinicName?.isNotEmpty ?? false) ? c.clinicName![0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.clinicName ?? '', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 2),
                        Text(
                          [c.location, c.salesRep, '${c.invoiceCount} invoice${c.invoiceCount == 1 ? '' : 's'}'].where((s) => s != null && s.isNotEmpty).join(' · '),
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(formatMoney(c.openBalance), style: TextStyle(fontWeight: FontWeight.w700, color: owes ? (overdue ? scheme.error : null) : null)),
                      if (overdue)
                        Text('Overdue', style: TextStyle(fontSize: 10, color: scheme.error, fontWeight: FontWeight.w600)),
                    ],
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

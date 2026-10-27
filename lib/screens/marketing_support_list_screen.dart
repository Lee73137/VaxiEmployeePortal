import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/marketing_support_provider.dart';
import '../providers/auth_provider.dart';
import '../utils/formatting.dart';
import 'marketing_support_detail_screen.dart';
import 'marketing_support_form_screen.dart';

const _statusFilters = ['', 'PENDING', 'PROCEED', 'DENIED', 'COMPLETED', 'NOT FULFILLED'];

Color statusColor(String status) {
  switch (status) {
    case 'PROCEED':
      return AppPalette.black;
    case 'DENIED':
      return AppPalette.red;
    case 'COMPLETED':
      return AppPalette.greenText;
    case 'NOT FULFILLED':
      return const Color(0xFF8E1B1B);
    default:
      return const Color(0xFF8A8A8A);
  }
}

class MarketingSupportListScreen extends StatefulWidget {
  const MarketingSupportListScreen({super.key});

  @override
  State<MarketingSupportListScreen> createState() => _MarketingSupportListScreenState();
}

class _MarketingSupportListScreenState extends State<MarketingSupportListScreen> {
  String? get _username => context.read<AuthProvider>().userName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MarketingSupportProvider>().refresh(_username);
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<MarketingSupportProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Marketing Support Requests')),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addRequestFab'),
        onPressed: () async {
          final createdId = await Navigator.of(context).push<int>(MaterialPageRoute(builder: (_) => const MarketingSupportFormScreen()));
          if (createdId != null && context.mounted) {
            context.read<MarketingSupportProvider>().refresh(_username);
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketingSupportDetailScreen(requestId: createdId)));
            if (context.mounted) context.read<MarketingSupportProvider>().refresh(_username);
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Request'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              key: const Key('marketingSupportSearchField'),
              hintText: 'Search by reference, clinic, or description…',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              onChanged: (v) {
                provider.setSearch(v);
                provider.refresh(_username);
              },
            ),
          ),
          SizedBox(
            height: 40,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              itemCount: _statusFilters.length,
              separatorBuilder: (_, _) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final value = _statusFilters[index];
                final selected = provider.statusFilter == value;
                return FilterChip(
                  label: Text(value.isEmpty ? 'All' : value),
                  selected: selected,
                  onSelected: (_) => provider.setStatusFilter(value, _username),
                );
              },
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
                    onRefresh: () => provider.refresh(_username),
                    child: _list(provider, scheme),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _list(MarketingSupportProvider provider, ColorScheme scheme) {
    if (provider.items.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(Icons.campaign_outlined, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('No requests found.', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      key: const Key('marketingSupportList'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: provider.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final r = provider.items[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () async {
              await Navigator.of(context).push(MaterialPageRoute(builder: (_) => MarketingSupportDetailScreen(requestId: r.requestId)));
              if (context.mounted) context.read<MarketingSupportProvider>().refresh(_username);
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(r.clinicName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 2),
                            Text(
                              '${r.referenceNo} · ${formatShortDate(r.requestDate)}${r.tsr.isNotEmpty ? ' · ${r.tsr}' : ''}',
                              style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(color: statusColor(r.status).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                        child: Text(r.status, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: statusColor(r.status))),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${r.requestType}${(r.description?.isNotEmpty ?? false) ? ' · ${r.description}' : ''}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

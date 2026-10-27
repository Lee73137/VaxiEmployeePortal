import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';
import 'inventory_detail_screen.dart';

class InventoryListScreen extends StatefulWidget {
  const InventoryListScreen({super.key});

  @override
  State<InventoryListScreen> createState() => _InventoryListScreenState();
}

class _InventoryListScreenState extends State<InventoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventoryProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final inventory = context.watch<InventoryProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Inventory')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              hintText: 'Search item code…',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              onChanged: (v) => context.read<InventoryProvider>().setSearch(v),
            ),
          ),
          if (inventory.lastSyncedAtPh != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 6, 16, 4),
              child: Row(
                children: [
                  Icon(Icons.sync, size: 14, color: scheme.onSurfaceVariant),
                  const SizedBox(width: 6),
                  Text(
                    'Last synced ${_formatDate(inventory.lastSyncedAtPh!)}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
          if (inventory.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(inventory.errorMessage!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 13))),
                  ],
                ),
              ),
            ),
          Expanded(
            child: inventory.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<InventoryProvider>().refresh(),
                    child: _InventoryList(items: inventory.items),
                  ),
          ),
        ],
      ),
    );
  }

  String _formatDate(DateTime d) {
    final now = DateTime.now();
    final diff = now.difference(d);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    return '${d.month}/${d.day}/${d.year}';
  }
}

class _InventoryList extends StatelessWidget {
  final List<InventoryItem> items;

  const _InventoryList({required this.items});

  Color _statusColor(ColorScheme scheme, String? status) {
    switch (status) {
      case 'Out of Stock':
        return scheme.errorContainer;
      case 'Low Stock':
        return scheme.tertiaryContainer;
      default:
        return scheme.surfaceContainerHighest;
    }
  }

  Color _statusTextColor(ColorScheme scheme, String? status) {
    switch (status) {
      case 'Out of Stock':
        return scheme.onErrorContainer;
      case 'Low Stock':
        return scheme.onTertiaryContainer;
      default:
        return scheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(Icons.inventory_2_outlined, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('No items found.', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 24),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final item = items[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => InventoryDetailScreen(itemcode: item.displayCode)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(item.displayCode, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          'On hand ${item.quantityOnHand}${item.uom != null && item.uom!.isNotEmpty ? ' ${item.uom}' : ''}',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${item.available}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: _statusColor(scheme, item.statusLabel),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          item.statusLabel ?? '',
                          style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: _statusTextColor(scheme, item.statusLabel)),
                        ),
                      ),
                    ],
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

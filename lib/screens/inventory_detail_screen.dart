import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/inventory_provider.dart';
import '../models/inventory_item.dart';

class InventoryDetailScreen extends StatefulWidget {
  final String itemcode;

  const InventoryDetailScreen({super.key, required this.itemcode});

  @override
  State<InventoryDetailScreen> createState() => _InventoryDetailScreenState();
}

class _InventoryDetailScreenState extends State<InventoryDetailScreen> {
  InventoryItem? _item;

  @override
  void initState() {
    super.initState();
    final matches = context.read<InventoryProvider>().items.where((i) => i.displayCode == widget.itemcode);
    _item = matches.isEmpty ? null : matches.first;
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final item = _item;

    return Scaffold(
      appBar: AppBar(title: Text(widget.itemcode)),
      body: item == null
          ? const Center(child: Text('Item not found'))
          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
              children: [
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Text('Available', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                            const Spacer(),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(20)),
                              child: Text(item.statusLabel ?? '', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: scheme.onTertiaryContainer)),
                            ),
                          ],
                        ),
                        Text('${item.available}', style: const TextStyle(fontSize: 40, fontWeight: FontWeight.bold)),
                        if (item.uom != null && item.uom!.isNotEmpty)
                          Text(item.uom!, style: TextStyle(color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 2.2,
                  children: [
                    _statTile(context, 'On Hand', item.quantityOnHand, null),
                    _statTile(context, 'Pending', item.pending, item.pending > 0 ? () => _showPending(context, forDr: false) : null),
                    _statTile(context, 'For DR', item.forDr, item.forDr > 0 ? () => _showPending(context, forDr: true) : null),
                    _statTile(context, 'Invoiced', item.invoice, null),
                    _statTile(context, 'Adjustment', item.adjustment, null),
                    _statTile(context, 'Returned', item.returned, null),
                  ],
                ),
                if (item.lotnumbers != null && item.lotnumbers!.trim().isNotEmpty) ...[
                  const SizedBox(height: 16),
                  Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Row(
                        children: [
                          Icon(Icons.numbers, size: 18, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('Lot Numbers', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                                Text(item.lotnumbers!),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
                const SizedBox(height: 20),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showDescription(context),
                        icon: const Icon(Icons.description_outlined),
                        label: const Text('Description'),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: () => _showAudit(context),
                        icon: const Icon(Icons.history),
                        label: const Text('Audit Trail'),
                      ),
                    ),
                  ],
                ),
              ],
            ),
    );
  }

  Widget _statTile(BuildContext context, String label, int value, VoidCallback? onTap) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                  Text('$value', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                ],
              ),
              if (onTap != null) Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant),
            ],
          ),
        ),
      ),
    );
  }

  void _showPending(BuildContext context, {required bool forDr}) {
    final provider = context.read<InventoryProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AsyncSheet(
        title: forDr ? 'For DR' : 'Pending',
        future: provider.api.pending(widget.itemcode, forDr: forDr),
        builder: (data) => _PendingList(data: data),
      ),
    );
  }

  void _showDescription(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AsyncSheet(
        title: 'Description',
        future: provider.api.description(widget.itemcode),
        builder: (desc) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
          child: Text(
            (desc == null || desc.trim().isEmpty) ? 'No description available.' : _stripHtml(desc),
          ),
        ),
      ),
    );
  }

  void _showAudit(BuildContext context) {
    final provider = context.read<InventoryProvider>();
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => _AsyncSheet(
        title: 'Audit Trail',
        future: provider.api.audit(widget.itemcode),
        builder: (entries) => _AuditList(entries: entries),
      ),
    );
  }

  String _stripHtml(String html) {
    return html.replaceAll(RegExp(r'<[^>]*>'), '').replaceAll(RegExp(r'\n\s*\n+'), '\n\n').trim();
  }
}

class _AsyncSheet<T> extends StatelessWidget {
  final String title;
  final Future<T> future;
  final Widget Function(T data) builder;

  const _AsyncSheet({required this.title, required this.future, required this.builder});

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
        child: ConstrainedBox(
          constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.75),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Text(title, style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                    const Spacer(),
                    IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(context)),
                  ],
                ),
              ),
              Flexible(
                child: FutureBuilder<T>(
                  future: future,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState != ConnectionState.done) {
                      return const Padding(
                        padding: EdgeInsets.all(32),
                        child: Center(child: CircularProgressIndicator()),
                      );
                    }
                    if (snapshot.hasError) {
                      return Padding(
                        padding: const EdgeInsets.all(20),
                        child: Text('Failed to load: ${snapshot.error}', style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      );
                    }
                    return SingleChildScrollView(child: builder(snapshot.data as T));
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PendingList extends StatelessWidget {
  final PendingBookingsResponse data;

  const _PendingList({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (data.entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No bookings.')),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final b in data.entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(b.clinicname ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                        Text('${b.sono ?? ''} · ${b.areaname ?? ''}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Text(
                    data.isForDr ? '${b.preparedcount ?? 0} for DR' : '${(b.quantity ?? 0) - (b.preparedcount ?? 0)} pending',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ),
          const Divider(),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
              Text(
                data.isForDr ? '${data.totalPrepared}' : '${data.totalRemaining}',
                style: const TextStyle(fontWeight: FontWeight.bold),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _AuditList extends StatelessWidget {
  final List<InventoryAuditEntry> entries;

  const _AuditList({required this.entries});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (entries.isEmpty) {
      return const Padding(
        padding: EdgeInsets.all(32),
        child: Center(child: Text('No audit history.')),
      );
    }

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          for (final e in entries)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          '${e.action ?? ''}  ${e.oldQuantityOnHand != null && e.oldQuantityOnHand != e.newQuantityOnHand ? '${e.oldQuantityOnHand} → ' : ''}${e.newQuantityOnHand}',
                          style: const TextStyle(fontWeight: FontWeight.w600),
                        ),
                        Text('by ${e.changedby ?? 'unknown'}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                  Text(
                    '${e.changedat.month}/${e.changedat.day}/${e.changedat.year}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

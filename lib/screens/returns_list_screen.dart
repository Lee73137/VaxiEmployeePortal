import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/returns_provider.dart';
import '../models/return_record.dart';
import '../utils/formatting.dart';
import 'return_create_screen.dart';

class ReturnsListScreen extends StatefulWidget {
  const ReturnsListScreen({super.key});

  @override
  State<ReturnsListScreen> createState() => _ReturnsListScreenState();
}

class _ReturnsListScreenState extends State<ReturnsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReturnsProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final returns = context.watch<ReturnsProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Returns')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          final created = await Navigator.of(context).push<bool>(
            MaterialPageRoute(builder: (_) => const ReturnCreateScreen()),
          );
          if (created == true && context.mounted) {
            context.read<ReturnsProvider>().refresh();
          }
        },
        icon: const Icon(Icons.add),
        label: const Text('New Return'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              hintText: 'Search by customer or invoice #…',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              onChanged: (v) => context.read<ReturnsProvider>().setSearch(v),
            ),
          ),
          if (returns.errorMessage != null)
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
                    Expanded(child: Text(returns.errorMessage!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 13))),
                  ],
                ),
              ),
            ),
          Expanded(
            child: returns.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<ReturnsProvider>().refresh(),
                    child: _ReturnsList(rows: returns.list?.items ?? []),
                  ),
          ),
          if (returns.list != null && returns.list!.totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: returns.list!.page > 1 ? () => context.read<ReturnsProvider>().goToPage(returns.list!.page - 1) : null,
                  ),
                  Text('Page ${returns.list!.page} of ${returns.list!.totalPages}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: returns.list!.page < returns.list!.totalPages ? () => context.read<ReturnsProvider>().goToPage(returns.list!.page + 1) : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

class _ReturnsList extends StatelessWidget {
  final List<ReturnRow> rows;

  const _ReturnsList({required this.rows});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (rows.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(Icons.assignment_return_outlined, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('No returns recorded yet.', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      itemCount: rows.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final row = rows[index];
        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () => _showDetails(context, row),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.returnRecord.customerfullname ?? '—', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        const SizedBox(height: 4),
                        Text(
                          '${row.returnRecord.refnumber ?? ''}${row.returnRecord.referenceid != null && row.returnRecord.referenceid!.isNotEmpty ? ' · Ref ${row.returnRecord.referenceid}' : ''}',
                          style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(formatShortDate(row.returnRecord.returndate), style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('${row.totalQuantity}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                      Text('${row.items.length} item${row.items.length == 1 ? '' : 's'}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 11)),
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

  void _showDetails(BuildContext context, ReturnRow row) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        final scheme = Theme.of(ctx).colorScheme;
        return SafeArea(
          child: ConstrainedBox(
            constraints: BoxConstraints(maxHeight: MediaQuery.of(ctx).size.height * 0.75),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                  child: Row(
                    children: [
                      Text('Return Items', style: Theme.of(ctx).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                      const Spacer(),
                      IconButton(icon: const Icon(Icons.close), onPressed: () => Navigator.pop(ctx)),
                    ],
                  ),
                ),
                Flexible(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(row.returnRecord.customerfullname ?? '—', style: const TextStyle(fontWeight: FontWeight.bold)),
                        Text('Invoice ${row.returnRecord.refnumber ?? ''}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                        if (row.returnRecord.referenceid != null && row.returnRecord.referenceid!.isNotEmpty)
                          Text('Reference: ${row.returnRecord.referenceid}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                        Text('Recorded by ${row.returnRecord.recordedby ?? ''}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                        const SizedBox(height: 16),
                        for (final item in row.items)
                          Padding(
                            padding: const EdgeInsets.only(bottom: 10),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(item.itemcode ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                                      Text(
                                        '${item.reasoncategory ?? ''}${item.lotnumber != null && item.lotnumber!.isNotEmpty ? ' · Lot ${item.lotnumber}' : ''}',
                                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                                      ),
                                    ],
                                  ),
                                ),
                                Text('${item.quantity} ${item.unitofmeasure ?? ''}', style: const TextStyle(fontWeight: FontWeight.w600)),
                              ],
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

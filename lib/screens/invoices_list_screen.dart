import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoices_provider.dart';
import '../models/invoice.dart';
import '../utils/formatting.dart';
import 'invoice_items_screen.dart';

class InvoicesListScreen extends StatefulWidget {
  const InvoicesListScreen({super.key});

  @override
  State<InvoicesListScreen> createState() => _InvoicesListScreenState();
}

class _InvoicesListScreenState extends State<InvoicesListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InvoicesProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final invoices = context.watch<InvoicesProvider>();

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Invoices'),
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Overdue'),
              Tab(text: 'Due Soon'),
            ],
          ),
        ),
        body: invoices.isLoading && invoices.dashboard == null
            ? const Center(child: CircularProgressIndicator())
            : invoices.errorMessage != null && invoices.dashboard == null
                ? Center(child: Text(invoices.errorMessage!))
                : TabBarView(
                    children: [
                      _InvoiceListTab(
                        list: invoices.dashboard?.overdue,
                        isOverdue: true,
                        onPageChanged: (p) => context.read<InvoicesProvider>().goToOverduePage(p),
                      ),
                      _InvoiceListTab(
                        list: invoices.dashboard?.dueSoon,
                        isOverdue: false,
                        onPageChanged: (p) => context.read<InvoicesProvider>().goToDueSoonPage(p),
                      ),
                    ],
                  ),
      ),
    );
  }
}

class _InvoiceListTab extends StatelessWidget {
  final InvoiceList? list;
  final bool isOverdue;
  final ValueChanged<int> onPageChanged;

  const _InvoiceListTab({required this.list, required this.isOverdue, required this.onPageChanged});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final items = list?.items ?? [];

    return Column(
      children: [
        if (list != null)
          Container(
            width: double.infinity,
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
            color: (isOverdue ? scheme.errorContainer : scheme.tertiaryContainer).withValues(alpha: 0.4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('${list!.totalItems} invoice${list!.totalItems == 1 ? '' : 's'}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                Text(formatMoney(list!.totalBalance), style: const TextStyle(fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        Expanded(
          child: items.isEmpty
              ? Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        isOverdue ? Icons.check_circle_outline : Icons.event_available_outlined,
                        size: 56,
                        color: scheme.onSurfaceVariant.withValues(alpha: 0.5),
                      ),
                      const SizedBox(height: 12),
                      Text(isOverdue ? 'No overdue invoices.' : 'Nothing due soon.', style: TextStyle(color: scheme.onSurfaceVariant)),
                    ],
                  ),
                )
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  itemCount: items.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final inv = items[index];
                    return Card(
                      child: InkWell(
                        borderRadius: BorderRadius.circular(18),
                        onTap: () {
                          Navigator.of(context).push(
                            MaterialPageRoute(builder: (_) => InvoiceItemsScreen(invoiceId: inv.qbextractedid)),
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
                                    Text(inv.customerfullname ?? '—', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                    const SizedBox(height: 4),
                                    Text('${inv.refnumber ?? ''} · Due ${formatShortDate(inv.duedate)}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(formatMoney(inv.balanceremaining), style: const TextStyle(fontWeight: FontWeight.bold)),
                                  const SizedBox(height: 4),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                                    decoration: BoxDecoration(
                                      color: (isOverdue ? scheme.errorContainer : scheme.tertiaryContainer),
                                      borderRadius: BorderRadius.circular(20),
                                    ),
                                    child: Text(
                                      isOverdue ? '${inv.daysOverdue}d overdue' : (inv.daysUntilDue == 0 ? 'Due today' : '${inv.daysUntilDue}d left'),
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: isOverdue ? scheme.onErrorContainer : scheme.onTertiaryContainer,
                                      ),
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
                ),
        ),
        if (list != null && list!.totalPages > 1)
          Padding(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: list!.page > 1 ? () => onPageChanged(list!.page - 1) : null,
                ),
                Text('Page ${list!.page} of ${list!.totalPages}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: list!.page < list!.totalPages ? () => onPageChanged(list!.page + 1) : null,
                ),
              ],
            ),
          ),
      ],
    );
  }
}

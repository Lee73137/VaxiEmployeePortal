import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/promo_invoices_provider.dart';
import '../utils/formatting.dart';
import 'invoice_items_screen.dart';

class PromoInvoicesScreen extends StatefulWidget {
  const PromoInvoicesScreen({super.key});

  @override
  State<PromoInvoicesScreen> createState() => _PromoInvoicesScreenState();
}

class _PromoInvoicesScreenState extends State<PromoInvoicesScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PromoInvoicesProvider>().ensureOptionsLoaded();
    });
  }

  Future<void> _pickDateRange() async {
    final provider = context.read<PromoInvoicesProvider>();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: provider.dateStart != null && provider.dateEnd != null
          ? DateTimeRange(start: provider.dateStart!, end: provider.dateEnd!)
          : null,
    );
    if (picked != null) {
      provider.setDateRange(picked.start, picked.end);
    }
  }

  Future<void> _openFilters() async {
    final provider = context.read<PromoInvoicesProvider>();
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
                initialChildSize: 0.75,
                minChildSize: 0.4,
                maxChildSize: 0.95,
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
                            onPressed: () {
                              provider.clearFilters();
                              setSheetState(() {});
                            },
                            child: const Text('Clear'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ListTile(
                        contentPadding: EdgeInsets.zero,
                        leading: const Icon(Icons.date_range_outlined),
                        title: Text(
                          provider.dateStart != null && provider.dateEnd != null
                              ? '${formatShortDate(provider.dateStart)} – ${formatShortDate(provider.dateEnd)}'
                              : 'Pick a date range',
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () async {
                          await _pickDateRange();
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String?>(
                        initialValue: provider.selectedSalesRep,
                        decoration: const InputDecoration(labelText: 'Sales Rep', prefixIcon: Icon(Icons.badge_outlined)),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('All')),
                          ...provider.salesRepOptions.map((r) => DropdownMenuItem<String?>(value: r, child: Text(r))),
                        ],
                        onChanged: (v) {
                          provider.setSalesRep(v);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String?>(
                        initialValue: provider.selectedStatus,
                        decoration: const InputDecoration(labelText: 'Status', prefixIcon: Icon(Icons.local_shipping_outlined)),
                        items: [
                          const DropdownMenuItem<String?>(value: null, child: Text('All')),
                          ...provider.statusOptions.map((s) => DropdownMenuItem<String?>(value: s, child: Text(s))),
                        ],
                        onChanged: (v) {
                          provider.setStatus(v);
                          setSheetState(() {});
                        },
                      ),
                      const SizedBox(height: 16),
                      Text('PROMO / CAMPAIGN', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 8),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: provider.promoOptions.map((p) {
                          final selected = provider.selectedPromos.contains(p);
                          return FilterChip(
                            label: Text(p),
                            selected: selected,
                            onSelected: (_) {
                              provider.togglePromo(p);
                              setSheetState(() {});
                            },
                          );
                        }).toList(),
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          provider.refresh();
                        },
                        child: const Text('Apply Filters'),
                      ),
                      const SizedBox(height: 8),
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
    final provider = context.watch<PromoInvoicesProvider>();
    final scheme = Theme.of(context).colorScheme;
    final activeFilters = provider.selectedPromos.length +
        (provider.selectedSalesRep != null ? 1 : 0) +
        (provider.selectedStatus != null ? 1 : 0) +
        (provider.dateStart != null ? 1 : 0);

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Promo Invoices'),
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
          bottom: const TabBar(
            tabs: [
              Tab(text: 'Invoices'),
              Tab(text: 'Sales Orders'),
            ],
          ),
        ),
        body: provider.isLoading
            ? const Center(child: CircularProgressIndicator())
            : !provider.hasAnyFilter
                ? _emptyFilterState(scheme)
                : TabBarView(
                    children: [
                      _invoicesTab(provider, scheme),
                      _bookingsTab(provider, scheme),
                    ],
                  ),
      ),
    );
  }

  Widget _emptyFilterState(ColorScheme scheme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.filter_alt_outlined, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 16),
            Text('Pick a promo, rep, date range, or status to see results.', textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant)),
            const SizedBox(height: 16),
            FilledButton.icon(onPressed: _openFilters, icon: const Icon(Icons.filter_list_outlined), label: const Text('Open Filters')),
          ],
        ),
      ),
    );
  }

  Widget _invoicesTab(PromoInvoicesProvider provider, ColorScheme scheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('${provider.invoices.length} invoice${provider.invoices.length == 1 ? '' : 's'}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
              Text(formatMoney(provider.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: provider.invoices.isEmpty
              ? Center(child: Text('No invoices match these filters.', style: TextStyle(color: scheme.onSurfaceVariant)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: provider.invoices.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final inv = provider.invoices[index];
                    return Card(
                      child: ListTile(
                        title: Text(inv.customerName ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${inv.refNumber ?? '—'} · ${formatShortDate(inv.txnDate)}${(inv.salesRep?.isNotEmpty ?? false) ? ' · ${inv.salesRep}' : ''}'),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatMoney(inv.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                            if (inv.status?.isNotEmpty ?? false)
                              Text(inv.status!, style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                          ],
                        ),
                        onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceItemsScreen(invoiceId: inv.qbExtractedId))),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _bookingsTab(PromoInvoicesProvider provider, ColorScheme scheme) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: Row(
            children: [
              Expanded(child: Text('${provider.bookingItems.length} line${provider.bookingItems.length == 1 ? '' : 's'} not yet prepared', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
              Text(formatMoney(provider.bookingTotalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        Expanded(
          child: provider.bookingItems.isEmpty
              ? Center(child: Text('No pending sales orders match these filters.', style: TextStyle(color: scheme.onSurfaceVariant)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: provider.bookingItems.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 8),
                  itemBuilder: (context, index) {
                    final b = provider.bookingItems[index];
                    return Card(
                      child: ListTile(
                        title: Text(b.itemCode ?? '—', maxLines: 1, overflow: TextOverflow.ellipsis),
                        subtitle: Text('${b.clinicName ?? '—'} · SO ${b.sono ?? '—'} · ${formatShortDate(b.dateOrder)}'),
                        trailing: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(formatMoney(b.lineTotal), style: const TextStyle(fontWeight: FontWeight.w600)),
                            Text('Qty ${b.quantity}', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}

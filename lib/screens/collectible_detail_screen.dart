import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/collectibles_provider.dart';
import '../models/collectible.dart';
import '../utils/formatting.dart';
import 'invoice_items_screen.dart';

class CollectibleDetailScreen extends StatefulWidget {
  final CollectibleCustomer customer;

  const CollectibleDetailScreen({super.key, required this.customer});

  @override
  State<CollectibleDetailScreen> createState() => _CollectibleDetailScreenState();
}

class _CollectibleDetailScreenState extends State<CollectibleDetailScreen> {
  List<CollectibleInvoice>? _invoices;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final invoices = await context.read<CollectiblesProvider>().api.invoices(widget.customer.clinicName ?? '');
      if (!mounted) return;
      setState(() => _invoices = invoices);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final c = widget.customer;

    return Scaffold(
      appBar: AppBar(title: Text(c.clinicName ?? 'Clinic')),
      body: RefreshIndicator(
        onRefresh: _load,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (c.contactName?.isNotEmpty ?? false) _infoRow(scheme, Icons.person_outline, c.contactName!),
                    if (c.contactNumber?.isNotEmpty ?? false) _infoRow(scheme, Icons.phone_outlined, c.contactNumber!),
                    if (c.address?.isNotEmpty ?? false) _infoRow(scheme, Icons.place_outlined, c.address!),
                    if (c.salesRep?.isNotEmpty ?? false) _infoRow(scheme, Icons.badge_outlined, c.salesRep!),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(child: _summaryTile(scheme, 'Overdue', formatMoney(c.overdueBalance), valueColor: c.overdueBalance > 0.01 ? scheme.error : null)),
                const SizedBox(width: 10),
                Expanded(child: _summaryTile(scheme, 'Not Due', formatMoney(c.notDueBalance))),
                const SizedBox(width: 10),
                Expanded(child: _summaryTile(scheme, 'Total', formatMoney(c.openBalance))),
              ],
            ),
            const SizedBox(height: 20),
            Text('UNPAID INVOICES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            if (_loading)
              const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
            else if (_error != null)
              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text(_error!, style: TextStyle(color: scheme.error)))
            else if (_invoices == null || _invoices!.isEmpty)
              Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('No unpaid invoices.', style: TextStyle(color: scheme.onSurfaceVariant)))
            else
              ..._invoices!.map((inv) => Card(
                    margin: const EdgeInsets.only(bottom: 8),
                    child: ListTile(
                      title: Text(inv.refNumber ?? '—'),
                      subtitle: Text('Due ${formatShortDate(inv.dueDate)}${inv.daysOverdue > 0 ? ' · ${inv.daysOverdue}d overdue' : ''}'),
                      trailing: Text(
                        formatMoney(inv.balanceRemaining),
                        style: TextStyle(fontWeight: FontWeight.w600, color: inv.daysOverdue > 0 ? scheme.error : null),
                      ),
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceItemsScreen(invoiceId: inv.qbExtractedId))),
                    ),
                  )),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(ColorScheme scheme, IconData icon, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 16, color: scheme.onSurfaceVariant),
          const SizedBox(width: 8),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }

  Widget _summaryTile(ColorScheme scheme, String label, String value, {Color? valueColor}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: valueColor), maxLines: 1, overflow: TextOverflow.ellipsis),
          ],
        ),
      ),
    );
  }
}

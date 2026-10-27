import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/invoices_provider.dart';
import '../models/invoice.dart';
import '../utils/formatting.dart';

class InvoiceItemsScreen extends StatefulWidget {
  final int invoiceId;

  const InvoiceItemsScreen({super.key, required this.invoiceId});

  @override
  State<InvoiceItemsScreen> createState() => _InvoiceItemsScreenState();
}

class _InvoiceItemsScreenState extends State<InvoiceItemsScreen> {
  InvoiceItemsResponse? _data;
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
      final data = await context.read<InvoicesProvider>().api.items(widget.invoiceId);
      setState(() => _data = data);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_data?.invoice.refnumber?.trim() ?? 'Invoice')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: scheme.error)))
              : _data == null
                  ? const Center(child: Text('Not found'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        Card(
                          child: Padding(
                            padding: const EdgeInsets.all(16),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(_data!.invoice.customerfullname ?? '—', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                                const SizedBox(height: 4),
                                Text('Due ${formatShortDate(_data!.invoice.duedate)} · ${_data!.invoice.salesrepreffullname ?? ''}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12)),
                                const SizedBox(height: 12),
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('Balance', style: TextStyle(color: scheme.onSurfaceVariant)),
                                    Text(formatMoney(_data!.invoice.balanceremaining), style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18)),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Text('ITEMS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        for (final item in _data!.items)
                          Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(item.itemreffullname ?? '—', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                                        Text('${item.quantity ?? 0} ${item.unitofmeasure ?? ''} × ${formatMoney(item.orrate)}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                                      ],
                                    ),
                                  ),
                                  Text(formatMoney(item.amount), style: const TextStyle(fontWeight: FontWeight.w600)),
                                ],
                              ),
                            ),
                          ),
                        const Divider(),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              const Text('Total', style: TextStyle(fontWeight: FontWeight.bold)),
                              Text(formatMoney(_data!.totalAmount), style: const TextStyle(fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                      ],
                    ),
    );
  }
}

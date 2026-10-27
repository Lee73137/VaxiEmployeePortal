import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/itineraries_provider.dart';
import '../models/itinerary.dart';
import '../utils/formatting.dart';
import 'invoice_items_screen.dart';

class ItineraryVisitScreen extends StatefulWidget {
  final int itineraryId;

  const ItineraryVisitScreen({super.key, required this.itineraryId});

  @override
  State<ItineraryVisitScreen> createState() => _ItineraryVisitScreenState();
}

class _ItineraryVisitScreenState extends State<ItineraryVisitScreen> {
  ItineraryVisit? _visit;
  bool _loading = true;
  String? _error;
  bool _saving = false;
  late TextEditingController _drDeliveryController;
  late TextEditingController _drDeliveryAmountController;
  late TextEditingController _collectedController;
  late TextEditingController _remarksController;

  @override
  void initState() {
    super.initState();
    _drDeliveryController = TextEditingController();
    _drDeliveryAmountController = TextEditingController();
    _collectedController = TextEditingController();
    _remarksController = TextEditingController();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final v = await context.read<ItinerariesProvider>().api.getVisit(widget.itineraryId);
      if (!mounted) return;
      setState(() {
        _visit = v;
        _drDeliveryController.text = v.drDelivery ?? '';
        _drDeliveryAmountController.text = v.drDeliveryAmount?.toString() ?? '';
        _collectedController.text = v.drCollectionAmountCollected?.toString() ?? '';
        _remarksController.text = v.visitRemarks ?? '';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  Future<void> _submitVisit() async {
    setState(() => _saving = true);
    try {
      await context.read<ItinerariesProvider>().api.submitVisit(
            widget.itineraryId,
            drDelivery: _drDeliveryController.text.trim().isEmpty ? null : _drDeliveryController.text.trim(),
            drDeliveryAmount: double.tryParse(_drDeliveryAmountController.text.trim()),
            drCollectionAmountCollected: double.tryParse(_collectedController.text.trim()),
            visitRemarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
          );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Visit saved.')));
      await _load();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not save visit: $e')));
    }
    if (mounted) setState(() => _saving = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_visit?.clinicName ?? 'Visit')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: TextStyle(color: scheme.error), textAlign: TextAlign.center)))
              : _visit == null
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
                                if (_visit!.clinicAddress?.isNotEmpty ?? false) ...[
                                  Row(children: [const Icon(Icons.place_outlined, size: 16), const SizedBox(width: 8), Expanded(child: Text(_visit!.clinicAddress!))]),
                                  const SizedBox(height: 6),
                                ],
                                if (_visit!.contactNumber?.isNotEmpty ?? false)
                                  Row(children: [const Icon(Icons.phone_outlined, size: 16), const SizedBox(width: 8), Text(_visit!.contactNumber!)]),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(color: scheme.tertiaryContainer, borderRadius: BorderRadius.circular(20)),
                                  child: Text(_visit!.statusLabel, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: scheme.onTertiaryContainer)),
                                ),
                              ],
                            ),
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Expanded(child: _summaryTile(scheme, 'Overdue', formatMoney(_visit!.totalOverdueBalance), valueColor: _visit!.totalOverdueBalance > 0.01 ? scheme.error : null)),
                            const SizedBox(width: 10),
                            Expanded(child: _summaryTile(scheme, 'Not Due', formatMoney(_visit!.totalNotDueBalance))),
                          ],
                        ),
                        const SizedBox(height: 16),
                        Text('UNPAID INVOICES', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        if (_visit!.unpaidInvoices.isEmpty)
                          Padding(padding: const EdgeInsets.symmetric(vertical: 12), child: Text('No unpaid invoices.', style: TextStyle(color: scheme.onSurfaceVariant)))
                        else
                          ..._visit!.unpaidInvoices.map((inv) => Card(
                                margin: const EdgeInsets.only(bottom: 8),
                                child: ListTile(
                                  dense: true,
                                  title: Text(inv.refNumber ?? '—'),
                                  subtitle: Text('Due ${formatShortDate(inv.dueDate)}${inv.isOverdue ? ' · Overdue' : ''}'),
                                  trailing: Text(formatMoney(inv.balanceRemaining), style: TextStyle(fontWeight: FontWeight.w600, color: inv.isOverdue ? scheme.error : null)),
                                  onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceItemsScreen(invoiceId: inv.qbExtractedId))),
                                ),
                              )),
                        const SizedBox(height: 20),
                        Text('CLOSE OUT VISIT', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
                        const SizedBox(height: 8),
                        TextField(controller: _drDeliveryController, decoration: const InputDecoration(labelText: 'DR - Delivery', prefixIcon: Icon(Icons.local_shipping_outlined))),
                        const SizedBox(height: 12),
                        TextField(controller: _drDeliveryAmountController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Delivery Amount', prefixIcon: Icon(Icons.payments_outlined))),
                        const SizedBox(height: 12),
                        TextField(controller: _collectedController, keyboardType: const TextInputType.numberWithOptions(decimal: true), decoration: const InputDecoration(labelText: 'Amount Collected', prefixIcon: Icon(Icons.payments_outlined))),
                        const SizedBox(height: 12),
                        TextField(controller: _remarksController, maxLines: 3, decoration: const InputDecoration(labelText: 'Visit Remarks', prefixIcon: Icon(Icons.notes_outlined))),
                        const SizedBox(height: 20),
                        FilledButton(
                          key: const Key('submitVisitButton'),
                          onPressed: _saving ? null : _submitVisit,
                          child: _saving
                              ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                              : const Text('Save Visit'),
                        ),
                      ],
                    ),
    );
  }

  Widget _summaryTile(ColorScheme scheme, String label, String value, {Color? valueColor}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: valueColor)),
          ],
        ),
      ),
    );
  }
}

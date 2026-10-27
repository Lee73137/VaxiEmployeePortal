import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/returns_provider.dart';
import '../api/api_client.dart';
import '../models/return_record.dart';

const _reasonOptions = ['Damaged', 'Expired', 'Wrong Item', 'Quality Issue', 'Other'];

class _LineState {
  final InvoiceItemForReturn item;
  bool selected = false;
  int quantity = 1;
  final TextEditingController lotController = TextEditingController();
  final TextEditingController notesController = TextEditingController();
  String reasonCategory = _reasonOptions.first;

  _LineState(this.item);
}

class ReturnCreateScreen extends StatefulWidget {
  const ReturnCreateScreen({super.key});

  @override
  State<ReturnCreateScreen> createState() => _ReturnCreateScreenState();
}

class _ReturnCreateScreenState extends State<ReturnCreateScreen> {
  final _referenceIdController = TextEditingController();
  final _invoiceSearchController = TextEditingController();

  List<InvoiceSearchResult> _searchResults = [];
  InvoiceSearchResult? _selectedInvoice;
  List<_LineState> _lines = [];
  bool _loadingItems = false;
  bool _submitting = false;
  String? _error;

  Future<void> _search(String term) async {
    if (term.trim().length < 2) {
      setState(() => _searchResults = []);
      return;
    }
    final results = await context.read<ReturnsProvider>().api.searchInvoices(term);
    if (mounted) setState(() => _searchResults = results);
  }

  Future<void> _selectInvoice(InvoiceSearchResult invoice) async {
    setState(() {
      _selectedInvoice = invoice;
      _searchResults = [];
      _loadingItems = true;
      _lines = [];
      _error = null;
    });
    try {
      final response = await context.read<ReturnsProvider>().api.invoiceItems(invoice.id);
      setState(() => _lines = response.items.map((i) => _LineState(i)).toList());
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loadingItems = false);
  }

  void _changeInvoice() {
    setState(() {
      _selectedInvoice = null;
      _lines = [];
      _invoiceSearchController.clear();
    });
  }

  bool get _canSubmit => _selectedInvoice != null && _lines.any((l) => l.selected && l.quantity > 0) && !_submitting;

  Future<void> _submit() async {
    setState(() {
      _submitting = true;
      _error = null;
    });

    final items = _lines.where((l) => l.selected && l.quantity > 0).map((l) => {
          'itemCode': l.item.itemcode,
          'unitOfMeasure': l.item.uom,
          'quantity': l.quantity,
          'lotNumber': l.lotController.text.trim(),
          'reasonCategory': l.reasonCategory,
          'notes': l.notesController.text.trim(),
        }).toList();

    try {
      await context.read<ReturnsProvider>().api.create(
            invoiceId: _selectedInvoice!.id,
            referenceId: _referenceIdController.text.trim().isEmpty ? null : _referenceIdController.text.trim(),
            items: items,
          );
      if (mounted) Navigator.of(context).pop(true);
    } on ApiException catch (e) {
      setState(() => _error = (e.body?['message'] as String?) ?? e.message);
    } catch (e) {
      setState(() => _error = e.toString());
    }

    if (mounted) setState(() => _submitting = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('New Return')),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          TextField(
            controller: _referenceIdController,
            decoration: const InputDecoration(
              labelText: 'Reference ID',
              hintText: 'Optional - e.g. RMA number or courier tracking #',
              prefixIcon: Icon(Icons.tag),
            ),
          ),
          const SizedBox(height: 16),
          Text('INVOICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          if (_selectedInvoice != null)
            Card(
              child: ListTile(
                title: Text(_selectedInvoice!.refnumber ?? ''),
                subtitle: Text('${_selectedInvoice!.customername ?? ''} · ${_selectedInvoice!.txndate ?? ''}'),
                trailing: TextButton(onPressed: _changeInvoice, child: const Text('Change')),
              ),
            )
          else ...[
            TextField(
              controller: _invoiceSearchController,
              decoration: const InputDecoration(hintText: 'Search by customer or invoice #…', prefixIcon: Icon(Icons.search)),
              onChanged: _search,
            ),
            if (_searchResults.isNotEmpty)
              Card(
                margin: const EdgeInsets.only(top: 8),
                child: Column(
                  children: _searchResults
                      .map((inv) => ListTile(
                            title: Text(inv.refnumber ?? ''),
                            subtitle: Text('${inv.customername ?? ''} · ${inv.txndate ?? ''}'),
                            trailing: Text('₱${inv.balance.toStringAsFixed(2)}'),
                            onTap: () => _selectInvoice(inv),
                          ))
                      .toList(),
                ),
              ),
          ],
          if (_loadingItems) ...[
            const SizedBox(height: 24),
            const Center(child: CircularProgressIndicator()),
          ],
          if (!_loadingItems && _lines.isNotEmpty) ...[
            const SizedBox(height: 20),
            Text('ITEMS ON THIS INVOICE', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            for (final line in _lines) _buildLineCard(context, line),
          ],
          if (_error != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(_error!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 13))),
                ],
              ),
            ),
          ],
          const SizedBox(height: 20),
          FilledButton(
            onPressed: _canSubmit ? _submit : null,
            child: _submitting
                ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                : const Text('Record Return'),
          ),
        ],
      ),
    );
  }

  Widget _buildLineCard(BuildContext context, _LineState line) {
    final scheme = Theme.of(context).colorScheme;
    final fullyReturned = line.item.remaining <= 0;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                if (!fullyReturned)
                  Checkbox(
                    value: line.selected,
                    onChanged: (v) => setState(() => line.selected = v ?? false),
                  ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(line.item.itemcode, style: const TextStyle(fontWeight: FontWeight.w600)),
                      Text(
                        fullyReturned
                            ? 'Fully returned already - nothing left to return.'
                            : '${line.item.quantity} ${line.item.uom ?? ''}${line.item.alreadyReturned > 0 ? ' (${line.item.alreadyReturned} already returned, ${line.item.remaining} left)' : ''}',
                        style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            if (line.selected && !fullyReturned) ...[
              const SizedBox(height: 8),
              Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.remove_circle_outline),
                    onPressed: line.quantity > 1 ? () => setState(() => line.quantity--) : null,
                  ),
                  Text('${line.quantity}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  IconButton(
                    icon: const Icon(Icons.add_circle_outline),
                    onPressed: line.quantity < line.item.remaining ? () => setState(() => line.quantity++) : null,
                  ),
                  const Spacer(),
                  DropdownButton<String>(
                    value: line.reasonCategory,
                    items: _reasonOptions.map((r) => DropdownMenuItem(value: r, child: Text(r, style: const TextStyle(fontSize: 13)))).toList(),
                    onChanged: (v) => setState(() => line.reasonCategory = v ?? line.reasonCategory),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              TextField(
                controller: line.lotController,
                decoration: InputDecoration(
                  isDense: true,
                  labelText: 'Lot Number',
                  hintText: line.item.knownLots.isNotEmpty ? line.item.knownLots.join(', ') : 'Optional',
                ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: line.notesController,
                decoration: const InputDecoration(isDense: true, labelText: 'Notes', hintText: 'Optional'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

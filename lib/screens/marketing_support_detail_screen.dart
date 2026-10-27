import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/marketing_support_provider.dart';
import '../providers/auth_provider.dart';
import '../models/marketing_support.dart';
import '../utils/formatting.dart';
import 'marketing_support_list_screen.dart' show statusColor;
import 'marketing_support_form_screen.dart';

class MarketingSupportDetailScreen extends StatefulWidget {
  final int requestId;

  const MarketingSupportDetailScreen({super.key, required this.requestId});

  @override
  State<MarketingSupportDetailScreen> createState() => _MarketingSupportDetailScreenState();
}

class _MarketingSupportDetailScreenState extends State<MarketingSupportDetailScreen> {
  MarketingSupportDetail? _detail;
  bool _loading = true;
  String? _error;

  String? get _username => context.read<AuthProvider>().userName;

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
      final detail = await context.read<MarketingSupportProvider>().api.get(widget.requestId, username: _username);
      if (!mounted) return;
      setState(() {
        _detail = detail;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e.toString();
        _loading = false;
      });
    }
  }

  Future<void> _edit() async {
    final updated = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => MarketingSupportFormScreen(existing: _detail)));
    if (updated == true) _load();
  }

  Future<void> _decide(String status) async {
    final reasonController = TextEditingController();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(status == 'PROCEED' ? 'Approve this request?' : 'Deny this request?'),
        content: TextField(
          controller: reasonController,
          decoration: const InputDecoration(labelText: 'Reason (optional)'),
          maxLines: 2,
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          FilledButton(onPressed: () => Navigator.pop(ctx, true), child: Text(status == 'PROCEED' ? 'Approve' : 'Deny')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    try {
      await context.read<MarketingSupportProvider>().api.decision(widget.requestId, _username, status, reasonController.text.trim().isEmpty ? null : reasonController.text.trim());
      if (mounted) _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _markFulfilled(String status) async {
    try {
      await context.read<MarketingSupportProvider>().api.markFulfilled(widget.requestId, _username, status);
      if (mounted) _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteRequest() async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete this request?'),
        content: const Text('This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: scheme.error), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<MarketingSupportProvider>().remove(widget.requestId, _username);
    if (ok && mounted) {
      Navigator.of(context).pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(context.read<MarketingSupportProvider>().errorMessage ?? 'Could not delete this request.')));
    }
  }

  Future<void> _showItemDialog({MarketingSupportItem? existing}) async {
    final itemCodeController = TextEditingController(text: existing?.itemCode ?? '');
    final qtyController = TextEditingController(text: existing != null ? existing.qty.toString() : '');
    List<String> suggestions = [];
    bool searching = false;

    final saved = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            Future<void> search(String term) async {
              if (term.trim().length < 2) {
                setDialogState(() => suggestions = []);
                return;
              }
              setDialogState(() => searching = true);
              try {
                final results = await context.read<MarketingSupportProvider>().api.searchItems(term.trim());
                setDialogState(() {
                  suggestions = results;
                  searching = false;
                });
              } catch (_) {
                setDialogState(() => searching = false);
              }
            }

            return AlertDialog(
              title: Text(existing == null ? 'Add Item' : 'Edit Item'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  TextField(
                    controller: itemCodeController,
                    decoration: InputDecoration(
                      labelText: 'Item Code',
                      suffixIcon: searching ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                    ),
                    onChanged: search,
                  ),
                  if (suggestions.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxHeight: 160),
                      child: ListView(
                        shrinkWrap: true,
                        children: suggestions.map((s) {
                          return ListTile(
                            dense: true,
                            title: Text(s, maxLines: 1, overflow: TextOverflow.ellipsis),
                            onTap: () {
                              itemCodeController.text = s;
                              setDialogState(() => suggestions = []);
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: qtyController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Quantity'),
                  ),
                ],
              ),
              actions: [
                TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Save')),
              ],
            );
          },
        );
      },
    );

    if (saved != true || !mounted) return;
    final itemCode = itemCodeController.text.trim();
    final qty = int.tryParse(qtyController.text.trim()) ?? 0;
    if (itemCode.isEmpty || qty <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Item code and a quantity greater than zero are required.')));
      return;
    }

    try {
      final api = context.read<MarketingSupportProvider>().api;
      if (existing == null) {
        await api.addItem(widget.requestId, itemCode, qty);
      } else {
        await api.updateItem(existing.requestDetailId, itemCode, qty);
      }
      if (mounted) _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  Future<void> _deleteItem(MarketingSupportItem item) async {
    try {
      await context.read<MarketingSupportProvider>().api.deleteItem(item.requestDetailId);
      if (mounted) _load();
    } catch (e) {
      if (mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('$e')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final detail = _detail;

    return Scaffold(
      appBar: AppBar(
        title: Text(detail?.referenceNo ?? 'Request'),
        actions: [
          if (detail != null) IconButton(icon: const Icon(Icons.edit_outlined), onPressed: _edit),
          if (detail != null && detail.canDelete) IconButton(icon: const Icon(Icons.delete_outline), onPressed: _deleteRequest),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(_error!, style: TextStyle(color: scheme.error))))
              : detail == null
                  ? const SizedBox.shrink()
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: [
                          Row(
                            children: [
                              Expanded(child: Text(detail.clinicName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(color: statusColor(detail.status).withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
                                child: Text(detail.status, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: statusColor(detail.status))),
                              ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text('${formatShortDate(detail.requestDate)}${detail.tsr.isNotEmpty ? ' · ${detail.tsr}' : ''}', style: TextStyle(color: scheme.onSurfaceVariant)),
                          const SizedBox(height: 16),
                          Card(
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  _field('Request Type', detail.requestType),
                                  _field('Description', detail.description),
                                  _field('Remarks', detail.remarks),
                                  _field('Location', detail.location),
                                  if (detail.status == 'DENIED' || detail.reason != null) _field('Reason', detail.reason),
                                  if (detail.dateApproved != null) _field('Date Approved', formatShortDate(detail.dateApproved)),
                                  if (detail.dateFulfilled != null) _field('Date Fulfilled', formatShortDate(detail.dateFulfilled)),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 16),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text('ITEMS', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
                              TextButton.icon(onPressed: () => _showItemDialog(), icon: const Icon(Icons.add, size: 18), label: const Text('Add Item')),
                            ],
                          ),
                          if (detail.items.isEmpty)
                            Padding(
                              padding: const EdgeInsets.symmetric(vertical: 12),
                              child: Text('No items added.', style: TextStyle(color: scheme.onSurfaceVariant)),
                            )
                          else
                            ...detail.items.map((i) => Card(
                                  margin: const EdgeInsets.only(bottom: 8),
                                  child: ListTile(
                                    title: Text(i.itemCode),
                                    subtitle: Text('Qty ${i.qty}'),
                                    trailing: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        IconButton(icon: const Icon(Icons.edit_outlined, size: 20), onPressed: () => _showItemDialog(existing: i)),
                                        IconButton(icon: const Icon(Icons.delete_outline, size: 20), onPressed: () => _deleteItem(i)),
                                      ],
                                    ),
                                  ),
                                )),
                          if (detail.canDecide) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _decide('DENIED'),
                                    style: OutlinedButton.styleFrom(foregroundColor: scheme.error),
                                    child: const Text('Deny'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(onPressed: () => _decide('PROCEED'), child: const Text('Approve')),
                                ),
                              ],
                            ),
                          ],
                          if (detail.canMarkFulfilled) ...[
                            const SizedBox(height: 16),
                            Row(
                              children: [
                                Expanded(
                                  child: OutlinedButton(
                                    onPressed: () => _markFulfilled('NOT FULFILLED'),
                                    child: const Text('Not Fulfilled'),
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: FilledButton(onPressed: () => _markFulfilled('COMPLETED'), child: const Text('Completed')),
                                ),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),
    );
  }

  Widget _field(String label, String? value) {
    if (value == null || value.trim().isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: Colors.grey)),
          const SizedBox(height: 2),
          Text(value),
        ],
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customers_provider.dart';
import '../models/customer.dart';
import 'customer_form_screen.dart';

class CustomerDetailScreen extends StatefulWidget {
  final int customerId;

  const CustomerDetailScreen({super.key, required this.customerId});

  @override
  State<CustomerDetailScreen> createState() => _CustomerDetailScreenState();
}

class _CustomerDetailScreenState extends State<CustomerDetailScreen> {
  Customer? _customer;
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
      final c = await context.read<CustomersProvider>().api.get(widget.customerId);
      setState(() => _customer = c);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  Future<void> _delete() async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete customer?'),
        content: Text('Delete "${_customer?.displayName}"? This can be undone by support if needed.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: scheme.error),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final customersProvider = context.read<CustomersProvider>();
    final ok = await customersProvider.remove(widget.customerId);
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_customer?.displayName ?? 'Customer'),
        actions: [
          if (_customer != null) ...[
            IconButton(
              key: const Key('editButton'),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final updated = await Navigator.of(context).push<Customer>(
                  MaterialPageRoute(builder: (_) => CustomerFormScreen(customer: _customer)),
                );
                if (updated != null) _load();
              },
            ),
            IconButton(
              key: const Key('deleteButton'),
              icon: const Icon(Icons.delete_outline),
              onPressed: _delete,
            ),
            const SizedBox(width: 4),
          ],
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: scheme.error)))
              : _customer == null
                  ? const Center(child: Text('Not found'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        _buildHeader(scheme),
                        const SizedBox(height: 20),
                        _sectionCard('Contact', [
                          _field(Icons.person_outline, 'Contact Person', _customer!.contact),
                          _field(Icons.phone_outlined, 'Phone', _customer!.phone),
                          _field(Icons.email_outlined, 'Email', _customer!.email),
                        ]),
                        _sectionCard('Address', [
                          _field(Icons.location_city_outlined, 'City', _customer!.city),
                          _field(Icons.place_outlined, 'Location', _customer!.location),
                        ]),
                        _sectionCard('Business', [
                          _field(Icons.apartment_outlined, 'Company', _customer!.companyname),
                          _field(Icons.payments_outlined, 'Balance', _customer!.balance?.toStringAsFixed(2)),
                        ]),
                        _sectionCard('Record', [
                          _field(Icons.person_add_outlined, 'Created By', _customer!.createdby),
                          _field(Icons.edit_note_outlined, 'Modified By', _customer!.modifiedby),
                        ]),
                      ],
                    ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    final isActive = _customer!.isactive == true;
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Text(
              _customer!.displayName.isNotEmpty ? _customer!.displayName[0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _customer!.displayName,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 6),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
            decoration: BoxDecoration(
              color: isActive ? scheme.tertiaryContainer : scheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              isActive ? 'Active' : 'Inactive',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isActive ? scheme.onTertiaryContainer : scheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _sectionCard(String title, List<Widget?> fields) {
    final visible = fields.whereType<Widget>().toList();
    if (visible.isEmpty) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Card(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title.toUpperCase(),
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w700,
                  letterSpacing: 0.6,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 8),
              ...visible,
            ],
          ),
        ),
      ),
    );
  }

  Widget? _field(IconData icon, String label, String? value) {
    if (value == null || value.isEmpty) return null;
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                Text(value, style: const TextStyle(fontSize: 15)),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

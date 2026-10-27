import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/customers_provider.dart';
import '../models/customer.dart';
import 'customer_detail_screen.dart';
import 'customer_form_screen.dart';

class CustomersListScreen extends StatefulWidget {
  const CustomersListScreen({super.key});

  @override
  State<CustomersListScreen> createState() => _CustomersListScreenState();
}

class _CustomersListScreenState extends State<CustomersListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<CustomersProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final customersProvider = context.watch<CustomersProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Customers'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addCustomerFab'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const CustomerFormScreen()),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Customer'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              key: const Key('searchField'),
              hintText: 'Search customers…',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              onChanged: (v) => context.read<CustomersProvider>().setSearch(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<String>(
                key: const Key('statusDropdown'),
                segments: const [
                  ButtonSegment(value: 'active', label: Text('Active'), icon: Icon(Icons.check_circle_outline, size: 16)),
                  ButtonSegment(value: 'inactive', label: Text('Inactive'), icon: Icon(Icons.pause_circle_outline, size: 16)),
                  ButtonSegment(value: 'all', label: Text('All'), icon: Icon(Icons.list, size: 16)),
                ],
                selected: {customersProvider.status},
                onSelectionChanged: (s) => context.read<CustomersProvider>().setStatus(s.first),
                showSelectedIcon: false,
              ),
            ),
          ),
          if (customersProvider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(customersProvider.errorMessage!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 13))),
                  ],
                ),
              ),
            ),
          Expanded(
            child: customersProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<CustomersProvider>().refresh(),
                    child: _CustomerList(customers: customersProvider.customers),
                  ),
          ),
        ],
      ),
    );
  }
}

class _CustomerList extends StatelessWidget {
  final List<Customer> customers;

  const _CustomerList({required this.customers});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (customers.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(Icons.people_outline, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('No customers found.', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      key: const Key('customersList'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: customers.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = customers[index];
        final isActive = c.isactive == true;

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => CustomerDetailScreen(customerId: c.customerid!)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 22,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Text(
                      c.displayName.isNotEmpty ? c.displayName[0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          c.displayName,
                          style: const TextStyle(fontWeight: FontWeight.w600),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        if ([c.location, c.city].any((s) => s != null && s.isNotEmpty)) ...[
                          const SizedBox(height: 2),
                          Text(
                            [c.location, c.city].where((s) => s != null && s.isNotEmpty).join(' · '),
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: isActive ? scheme.tertiaryContainer : scheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      isActive ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: isActive ? scheme.onTertiaryContainer : scheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                  const SizedBox(width: 4),
                  Icon(Icons.chevron_right, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}

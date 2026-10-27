import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clinic_history_provider.dart';
import '../models/clinic_history.dart';
import '../utils/formatting.dart';
import 'clinic_history_detail_screen.dart';

class ClinicHistoryListScreen extends StatefulWidget {
  const ClinicHistoryListScreen({super.key});

  @override
  State<ClinicHistoryListScreen> createState() => _ClinicHistoryListScreenState();
}

class _ClinicHistoryListScreenState extends State<ClinicHistoryListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicHistoryProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicHistoryProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Clinic History')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              key: const Key('clinicHistorySearchField'),
              hintText: 'Search by name, municipality, location, or rep…',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              onChanged: (v) => context.read<ClinicHistoryProvider>().setSearch(v),
            ),
          ),
          if (provider.errorMessage != null)
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
                    Expanded(child: Text(provider.errorMessage!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 13))),
                  ],
                ),
              ),
            ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<ClinicHistoryProvider>().refresh(),
                    child: _List(items: provider.items),
                  ),
          ),
        ],
      ),
    );
  }
}

class _List extends StatelessWidget {
  final List<ClinicHistoryListItem> items;

  const _List({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(Icons.history_outlined, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('No clinics found.', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      key: const Key('clinicHistoryList'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 32),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = items[index];
        final owes = c.openBalance > 0.01;

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ClinicHistoryDetailScreen(clinicId: c.clinicId)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Row(
                children: [
                  CircleAvatar(
                    radius: 20,
                    backgroundColor: scheme.primaryContainer,
                    foregroundColor: scheme.onPrimaryContainer,
                    child: Text(
                      (c.clinicName?.isNotEmpty ?? false) ? c.clinicName![0].toUpperCase() : '?',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(c.clinicName ?? '', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                        if ([c.clinicMunicipality, c.location, c.salesRep].any((s) => s != null && s.isNotEmpty)) ...[
                          const SizedBox(height: 2),
                          Text(
                            [c.clinicMunicipality, c.location, c.salesRep].where((s) => s != null && s.isNotEmpty).join(' · '),
                            style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text('Balance', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                      Text(
                        formatMoney(c.openBalance),
                        style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: owes ? scheme.error : null),
                      ),
                    ],
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

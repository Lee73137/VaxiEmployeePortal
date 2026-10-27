import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clinics_provider.dart';
import '../models/clinic.dart';
import '../utils/formatting.dart';
import 'clinic_detail_screen.dart';
import 'clinic_form_screen.dart';

class ClinicsListScreen extends StatefulWidget {
  const ClinicsListScreen({super.key});

  @override
  State<ClinicsListScreen> createState() => _ClinicsListScreenState();
}

class _ClinicsListScreenState extends State<ClinicsListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicsProvider>().refresh();
    });
  }

  @override
  Widget build(BuildContext context) {
    final clinicsProvider = context.watch<ClinicsProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Clinics'),
      ),
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addClinicFab'),
        onPressed: () async {
          await Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => const ClinicFormScreen()),
          );
          if (context.mounted) context.read<ClinicsProvider>().refresh();
        },
        icon: const Icon(Icons.add),
        label: const Text('Add Clinic'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: SearchBar(
              key: const Key('clinicSearchField'),
              hintText: 'Search by name, municipality, area, or contact…',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              onChanged: (v) => context.read<ClinicsProvider>().setSearch(v),
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: Align(
              alignment: Alignment.centerLeft,
              child: SegmentedButton<String>(
                key: const Key('statusFilter'),
                segments: const [
                  ButtonSegment(value: 'active', label: Text('Active'), icon: Icon(Icons.check_circle_outline, size: 16)),
                  ButtonSegment(value: 'inactive', label: Text('Inactive'), icon: Icon(Icons.pause_circle_outline, size: 16)),
                  ButtonSegment(value: 'all', label: Text('All'), icon: Icon(Icons.list, size: 16)),
                ],
                selected: {clinicsProvider.status},
                onSelectionChanged: (s) => context.read<ClinicsProvider>().setStatus(s.first),
                showSelectedIcon: false,
              ),
            ),
          ),
          if (clinicsProvider.errorMessage != null)
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
                    Expanded(child: Text(clinicsProvider.errorMessage!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 13))),
                  ],
                ),
              ),
            ),
          Expanded(
            child: clinicsProvider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<ClinicsProvider>().refresh(),
                    child: _ClinicList(clinics: clinicsProvider.clinics),
                  ),
          ),
        ],
      ),
    );
  }
}

class _ClinicList extends StatelessWidget {
  final List<Clinic> clinics;

  const _ClinicList({required this.clinics});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (clinics.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(Icons.local_hospital_outlined, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('No clinics found.', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      key: const Key('clinicsList'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: clinics.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final c = clinics[index];
        final isActive = c.isActive;
        final owesBalance = (c.openBalance ?? 0) > 0.01;

        return Card(
          child: InkWell(
            borderRadius: BorderRadius.circular(18),
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(builder: (_) => ClinicDetailScreen(clinicId: c.clinicId!)),
              );
            },
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
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
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    c.clinicName ?? '',
                                    style: const TextStyle(fontWeight: FontWeight.w600),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (c.areaCode?.isNotEmpty ?? false)
                                  Container(
                                    margin: const EdgeInsets.only(left: 6),
                                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                    decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                                    child: Text(c.areaCode!, style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                                  ),
                              ],
                            ),
                            if ([c.clinicMunicipality, c.contactPerson].any((s) => s != null && s.isNotEmpty)) ...[
                              const SizedBox(height: 2),
                              Text(
                                [c.clinicMunicipality, c.contactPerson].where((s) => s != null && s.isNotEmpty).join(' · '),
                                style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ],
                        ),
                      ),
                      Icon(Icons.chevron_right, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        child: _miniStat(scheme, 'Last Order', formatShortDate(c.lastOrderDate)),
                      ),
                      Expanded(
                        child: _miniStat(
                          scheme,
                          'Open Balance',
                          c.openBalance != null ? formatMoney(c.openBalance) : '—',
                          valueColor: owesBalance ? scheme.error : null,
                        ),
                      ),
                      Row(
                        children: [
                          Text(isActive ? 'Active' : 'Inactive', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                          Switch(
                            key: Key('activeSwitch_${c.clinicId}'),
                            value: isActive,
                            onChanged: (v) async {
                              final confirmed = await showDialog<bool>(
                                context: context,
                                builder: (ctx) => AlertDialog(
                                  title: Text(v ? 'Mark Active' : 'Mark Inactive'),
                                  content: Text('Mark "${c.clinicName}" as ${v ? 'Active' : 'Inactive'}?'),
                                  actions: [
                                    TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
                                    TextButton(onPressed: () => Navigator.pop(ctx, true), child: Text(v ? 'Mark Active' : 'Mark Inactive')),
                                  ],
                                ),
                              );
                              if (confirmed == true && context.mounted) {
                                await context.read<ClinicsProvider>().setActive(c.clinicId!, v);
                              }
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _miniStat(ColorScheme scheme, String label, String value, {Color? valueColor}) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
        Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600, color: valueColor)),
      ],
    );
  }
}

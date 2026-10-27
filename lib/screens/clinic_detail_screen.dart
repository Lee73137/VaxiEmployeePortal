import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clinics_provider.dart';
import '../models/clinic.dart';
import '../utils/formatting.dart';
import 'clinic_form_screen.dart';

class ClinicDetailScreen extends StatefulWidget {
  final int clinicId;

  const ClinicDetailScreen({super.key, required this.clinicId});

  @override
  State<ClinicDetailScreen> createState() => _ClinicDetailScreenState();
}

class _ClinicDetailScreenState extends State<ClinicDetailScreen> {
  Clinic? _clinic;
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
      final c = await context.read<ClinicsProvider>().api.get(widget.clinicId);
      setState(() => _clinic = c);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  Future<void> _toggleActive(bool nowActive) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(nowActive ? 'Mark Active' : 'Mark Inactive'),
        content: Text('Mark "${_clinic?.clinicName}" as ${nowActive ? 'Active' : 'Inactive'}?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(foregroundColor: scheme.primary),
            child: Text(nowActive ? 'Mark Active' : 'Mark Inactive'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final ok = await context.read<ClinicsProvider>().setActive(widget.clinicId, nowActive);
    if (ok) _load();
  }

  Future<void> _delete() async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete clinic?'),
        content: Text('Delete "${_clinic?.clinicName}"? This cannot be undone.'),
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

    final ok = await context.read<ClinicsProvider>().remove(widget.clinicId);
    if (ok && mounted) {
      Navigator.of(context).pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_clinic?.clinicName ?? 'Clinic'),
        actions: [
          if (_clinic != null) ...[
            IconButton(
              key: const Key('editButton'),
              icon: const Icon(Icons.edit_outlined),
              onPressed: () async {
                final updated = await Navigator.of(context).push<Clinic>(
                  MaterialPageRoute(builder: (_) => ClinicFormScreen(clinic: _clinic)),
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
              : _clinic == null
                  ? const Center(child: Text('Not found'))
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                      children: [
                        _buildHeader(scheme),
                        const SizedBox(height: 20),
                        _sectionCard('Location', [
                          _field(Icons.map_outlined, 'Area', _clinic!.areaCode),
                          _field(Icons.location_city_outlined, 'Municipality', _clinic!.clinicMunicipality),
                          _field(Icons.place_outlined, 'Address', _clinic!.clinicAddress),
                        ]),
                        _sectionCard('Contact', [
                          _field(Icons.person_outline, 'Contact Person', _clinic!.contactPerson),
                          _field(Icons.phone_outlined, 'Contact Number', _clinic!.contactNumber),
                        ]),
                        _sectionCard('Business', [
                          _field(Icons.badge_outlined, 'Sales Rep', _clinic!.repCode),
                          _field(Icons.schedule_outlined, 'Payment Terms', _clinic!.terms != null ? '${_clinic!.terms} days' : null),
                          _field(Icons.badge_outlined, 'TIN', _clinic!.tinNo),
                          _field(Icons.receipt_outlined, 'With SI', _clinic!.withSi == true ? 'Yes' : 'No'),
                          _field(Icons.event_outlined, 'Last Order', formatShortDate(_clinic!.lastOrderDate)),
                          _balanceField(scheme),
                        ]),
                        _sectionCard('Remarks', [
                          _field(Icons.notes_outlined, 'Remarks', _clinic!.clinicRemarks),
                        ]),
                        const SizedBox(height: 4),
                        Card(
                          child: SwitchListTile(
                            key: const Key('activeToggle'),
                            title: const Text('Active'),
                            subtitle: Text(
                              _clinic!.isActive ? 'This clinic is currently active' : 'This clinic is inactive',
                              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                            ),
                            value: _clinic!.isActive,
                            onChanged: _toggleActive,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                          ),
                        ),
                      ],
                    ),
    );
  }

  Widget _buildHeader(ColorScheme scheme) {
    final isActive = _clinic!.isActive;
    return Center(
      child: Column(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: scheme.primaryContainer,
            foregroundColor: scheme.onPrimaryContainer,
            child: Text(
              (_clinic!.clinicName?.isNotEmpty ?? false) ? _clinic!.clinicName![0].toUpperCase() : '?',
              style: const TextStyle(fontSize: 30, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _clinic!.clinicName ?? '',
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

  Widget? _balanceField(ColorScheme scheme) {
    final balance = _clinic!.openBalance;
    if (balance == null) return null;
    final isOwing = balance > 0.01;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.payments_outlined, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Open Balance', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                Text(
                  formatMoney(balance),
                  style: TextStyle(fontSize: 15, fontWeight: isOwing ? FontWeight.bold : FontWeight.normal, color: isOwing ? scheme.error : null),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

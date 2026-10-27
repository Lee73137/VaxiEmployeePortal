import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clinics_provider.dart';
import '../models/clinic.dart';

class ClinicFormScreen extends StatefulWidget {
  final Clinic? clinic;

  const ClinicFormScreen({super.key, this.clinic});

  @override
  State<ClinicFormScreen> createState() => _ClinicFormScreenState();
}

class _ClinicFormScreenState extends State<ClinicFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _nameController;
  late TextEditingController _municipalityController;
  late TextEditingController _addressController;
  late TextEditingController _contactPersonController;
  late TextEditingController _contactNumberController;
  late TextEditingController _remarksController;
  late TextEditingController _termsController;
  late TextEditingController _tinController;
  int? _areaId;
  int? _repId;
  bool _withSi = false;
  bool _saving = false;
  bool _loadingLookups = true;
  String? _error;
  List<ClinicArea> _areas = [];
  List<ClinicSalesRep> _reps = [];

  bool get _isEdit => widget.clinic != null;

  @override
  void initState() {
    super.initState();
    final c = widget.clinic;
    _nameController = TextEditingController(text: c?.clinicName ?? '');
    _municipalityController = TextEditingController(text: c?.clinicMunicipality ?? '');
    _addressController = TextEditingController(text: c?.clinicAddress ?? '');
    _contactPersonController = TextEditingController(text: c?.contactPerson ?? '');
    _contactNumberController = TextEditingController(text: c?.contactNumber ?? '');
    _remarksController = TextEditingController(text: c?.clinicRemarks ?? '');
    _termsController = TextEditingController(text: c?.terms?.toString() ?? '');
    _tinController = TextEditingController(text: c?.tinNo ?? '');
    _areaId = c?.areaId;
    _repId = c?.repId;
    _withSi = c?.withSi ?? false;
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final api = context.read<ClinicsProvider>().api;
    try {
      final areas = await api.areas();
      final reps = await api.salesReps();
      if (!mounted) return;
      setState(() {
        _areas = areas;
        _reps = reps;
        _loadingLookups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load Area/Rep options: $e';
        _loadingLookups = false;
      });
    }
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _saving = true;
      _error = null;
    });

    final clinic = widget.clinic ?? Clinic();
    clinic.clinicName = _nameController.text.trim();
    clinic.clinicMunicipality = _municipalityController.text.trim();
    clinic.clinicAddress = _addressController.text.trim();
    clinic.contactPerson = _contactPersonController.text.trim();
    clinic.contactNumber = _contactNumberController.text.trim();
    clinic.clinicRemarks = _remarksController.text.trim();
    clinic.terms = int.tryParse(_termsController.text.trim());
    clinic.tinNo = _tinController.text.trim();
    clinic.areaId = _areaId;
    clinic.repId = _repId;
    clinic.withSi = _withSi;

    final saved = await context.read<ClinicsProvider>().save(clinic);

    setState(() => _saving = false);

    if (saved != null && mounted) {
      Navigator.of(context).pop(saved);
    } else {
      setState(() => _error = context.read<ClinicsProvider>().errorMessage ?? 'Save failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(_isEdit ? 'Edit Clinic' : 'New Clinic'),
      ),
      body: _loadingLookups
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  TextFormField(
                    key: const Key('clinicNameField'),
                    controller: _nameController,
                    decoration: const InputDecoration(labelText: 'Clinic Name', prefixIcon: Icon(Icons.local_hospital_outlined)),
                    validator: (v) => (v == null || v.trim().isEmpty) ? 'Clinic name is required' : null,
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    key: const Key('areaField'),
                    initialValue: _areaId,
                    decoration: const InputDecoration(labelText: 'Area', prefixIcon: Icon(Icons.map_outlined)),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('— None —')),
                      ..._areas.map((a) => DropdownMenuItem<int?>(value: a.areaId, child: Text(a.label, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _areaId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _municipalityController,
                    decoration: const InputDecoration(labelText: 'Municipality', prefixIcon: Icon(Icons.location_city_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _addressController,
                    maxLines: 2,
                    decoration: const InputDecoration(labelText: 'Address', prefixIcon: Icon(Icons.place_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactPersonController,
                    decoration: const InputDecoration(labelText: 'Contact Person', prefixIcon: Icon(Icons.person_outline)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _contactNumberController,
                    keyboardType: TextInputType.phone,
                    decoration: const InputDecoration(labelText: 'Contact Number', prefixIcon: Icon(Icons.phone_outlined)),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    key: const Key('repField'),
                    initialValue: _repId,
                    decoration: const InputDecoration(labelText: 'Sales Rep', prefixIcon: Icon(Icons.badge_outlined)),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('— None —')),
                      ..._reps.map((r) => DropdownMenuItem<int?>(value: r.repId, child: Text(r.label, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _repId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _termsController,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(labelText: 'Payment Terms (days)', prefixIcon: Icon(Icons.schedule_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _tinController,
                    decoration: const InputDecoration(labelText: 'TIN', prefixIcon: Icon(Icons.badge_outlined)),
                  ),
                  const SizedBox(height: 12),
                  Card(
                    child: SwitchListTile(
                      title: const Text('With SI (Sales Invoice)'),
                      value: _withSi,
                      onChanged: (v) => setState(() => _withSi = v),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)),
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _remarksController,
                    maxLines: 3,
                    decoration: const InputDecoration(labelText: 'Remarks', prefixIcon: Icon(Icons.notes_outlined)),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 14),
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
                    key: const Key('saveButton'),
                    onPressed: _saving ? null : _submit,
                    child: _saving
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : Text(_isEdit ? 'Save Changes' : 'Create Clinic'),
                  ),
                ],
              ),
            ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/itineraries_provider.dart';
import '../providers/clinics_provider.dart';
import '../models/itinerary.dart';
import '../models/clinic.dart';

class ItineraryFormScreen extends StatefulWidget {
  final Itinerary? itinerary;

  const ItineraryFormScreen({super.key, this.itinerary});

  @override
  State<ItineraryFormScreen> createState() => _ItineraryFormScreenState();
}

class _ItineraryFormScreenState extends State<ItineraryFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _scheduleDate;
  late TextEditingController _clinicSearchController;
  late TextEditingController _drCollectionController;
  late TextEditingController _drCollectionAmountController;
  int? _repId;
  int? _clinicId;
  String? _purpose;
  bool _saving = false;
  bool _loadingLookups = true;
  String? _error;
  List<ClinicSalesRep> _reps = [];
  List<ItineraryActivity> _activities = [];
  List<ItineraryClinicOption> _clinicResults = [];
  bool _searchingClinics = false;

  bool get _isEdit => widget.itinerary != null;

  @override
  void initState() {
    super.initState();
    final i = widget.itinerary;
    _scheduleDate = i?.scheduleDate ?? DateTime.now();
    _clinicSearchController = TextEditingController(text: i?.clinicName ?? '');
    _drCollectionController = TextEditingController(text: i?.drCollection ?? '');
    _drCollectionAmountController = TextEditingController(text: i?.drCollectionAmount?.toString() ?? '');
    _repId = i?.repId;
    _clinicId = i?.clinicId;
    _purpose = i?.purpose;
    _loadLookups();
  }

  Future<void> _loadLookups() async {
    final itinApi = context.read<ItinerariesProvider>().api;
    final clinicsApi = context.read<ClinicsProvider>().api;
    try {
      final reps = await clinicsApi.salesReps();
      final activities = await itinApi.activities();
      if (!mounted) return;
      setState(() {
        _reps = reps;
        _activities = activities;
        _loadingLookups = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Could not load Rep/Purpose options: $e';
        _loadingLookups = false;
      });
    }
  }

  Future<void> _searchClinics(String term) async {
    if (term.trim().length < 2) {
      setState(() => _clinicResults = []);
      return;
    }
    setState(() => _searchingClinics = true);
    try {
      final results = await context.read<ItinerariesProvider>().api.searchClinics(term.trim());
      if (!mounted) return;
      setState(() {
        _clinicResults = results;
        _searchingClinics = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _searchingClinics = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _scheduleDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365)),
      lastDate: DateTime.now().add(const Duration(days: 365)),
    );
    if (picked != null) setState(() => _scheduleDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clinicId == null) {
      setState(() => _error = 'Please pick a clinic.');
      return;
    }
    if (_repId == null) {
      setState(() => _error = 'Please pick a sales rep.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final request = ItinerarySaveRequest(
      scheduleDate: _scheduleDate,
      repId: _repId!,
      clinicId: _clinicId!,
      purpose: _purpose,
      drCollection: _drCollectionController.text.trim().isEmpty ? null : _drCollectionController.text.trim(),
      drCollectionAmount: double.tryParse(_drCollectionAmountController.text.trim()),
    );

    final saved = await context.read<ItinerariesProvider>().save(request, itineraryId: widget.itinerary?.itineraryId);

    setState(() => _saving = false);

    if (saved != null && mounted) {
      Navigator.of(context).pop(saved);
    } else if (mounted) {
      setState(() => _error = context.read<ItinerariesProvider>().errorMessage ?? 'Save failed');
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Itinerary' : 'New Itinerary')),
      body: _loadingLookups
          ? const Center(child: CircularProgressIndicator())
          : Form(
              key: _formKey,
              child: ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                children: [
                  Card(
                    child: ListTile(
                      leading: const Icon(Icons.event_outlined),
                      title: const Text('Schedule Date'),
                      subtitle: Text('${_scheduleDate.year}-${_scheduleDate.month.toString().padLeft(2, '0')}-${_scheduleDate.day.toString().padLeft(2, '0')}'),
                      trailing: const Icon(Icons.chevron_right),
                      onTap: _pickDate,
                    ),
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int?>(
                    key: const Key('repField'),
                    initialValue: _repId,
                    decoration: const InputDecoration(labelText: 'Sales Rep', prefixIcon: Icon(Icons.badge_outlined)),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<int?>(value: null, child: Text('— Select —')),
                      ..._reps.map((r) => DropdownMenuItem<int?>(value: r.repId, child: Text(r.label, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _repId = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    key: const Key('clinicSearchField'),
                    controller: _clinicSearchController,
                    decoration: InputDecoration(
                      labelText: 'Clinic',
                      prefixIcon: const Icon(Icons.local_hospital_outlined),
                      suffixIcon: _searchingClinics ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))) : null,
                    ),
                    onChanged: (v) {
                      _clinicId = null;
                      _searchClinics(v);
                    },
                  ),
                  if (_clinicResults.isNotEmpty)
                    Card(
                      margin: const EdgeInsets.only(top: 4),
                      child: Column(
                        children: _clinicResults.map((c) {
                          return ListTile(
                            dense: true,
                            title: Text(c.name),
                            subtitle: (c.subtitle?.isNotEmpty ?? false) ? Text(c.subtitle!) : null,
                            onTap: () {
                              setState(() {
                                _clinicId = c.clinicId;
                                _clinicSearchController.text = c.name;
                                _clinicResults = [];
                              });
                            },
                          );
                        }).toList(),
                      ),
                    ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<String?>(
                    key: const Key('purposeField'),
                    initialValue: _purpose,
                    decoration: const InputDecoration(labelText: 'Purpose', prefixIcon: Icon(Icons.task_alt_outlined)),
                    isExpanded: true,
                    items: [
                      const DropdownMenuItem<String?>(value: null, child: Text('— Select —')),
                      ..._activities.map((a) => DropdownMenuItem<String?>(value: a.description, child: Text(a.description, overflow: TextOverflow.ellipsis))),
                    ],
                    onChanged: (v) => setState(() => _purpose = v),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _drCollectionController,
                    decoration: const InputDecoration(labelText: 'DR for Collection', prefixIcon: Icon(Icons.receipt_long_outlined)),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _drCollectionAmountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: const InputDecoration(labelText: 'Amount to Collect', prefixIcon: Icon(Icons.payments_outlined)),
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
                        : Text(_isEdit ? 'Save Changes' : 'Create Itinerary'),
                  ),
                ],
              ),
            ),
    );
  }
}

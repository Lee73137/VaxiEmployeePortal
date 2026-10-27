import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/marketing_support_provider.dart';
import '../providers/itineraries_provider.dart';
import '../providers/auth_provider.dart';
import '../models/marketing_support.dart';
import '../models/itinerary.dart' show ItineraryClinicOption;

// Create / edit the core request fields (clinic, date, description, type,
// remarks, location) - mirrors vaxiCSR's own Manage GET/POST. Status/
// decision fields are never touched here, only via the Decision/Mark
// Fulfilled actions on MarketingSupportDetailScreen. Reuses
// api/csritineraries/search-clinics for the clinic picker instead of
// duplicating it (same endpoint Itineraries' own form already uses).
class MarketingSupportFormScreen extends StatefulWidget {
  final MarketingSupportDetail? existing;

  const MarketingSupportFormScreen({super.key, this.existing});

  @override
  State<MarketingSupportFormScreen> createState() => _MarketingSupportFormScreenState();
}

class _MarketingSupportFormScreenState extends State<MarketingSupportFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late DateTime _requestDate;
  late TextEditingController _clinicSearchController;
  late TextEditingController _descriptionController;
  late TextEditingController _remarksController;
  late TextEditingController _locationController;
  int? _clinicId;
  String? _requestType;
  bool _saving = false;
  String? _error;
  List<ItineraryClinicOption> _clinicResults = [];
  bool _searchingClinics = false;

  bool get _isEdit => widget.existing != null;

  @override
  void initState() {
    super.initState();
    final e = widget.existing;
    _requestDate = e?.requestDate ?? DateTime.now();
    _clinicSearchController = TextEditingController(text: e?.clinicName ?? '');
    _descriptionController = TextEditingController(text: e?.description ?? '');
    _remarksController = TextEditingController(text: e?.remarks ?? '');
    _locationController = TextEditingController(text: e?.location ?? '');
    _clinicId = e?.clinicId;
    _requestType = e?.requestType;
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
      initialDate: _requestDate,
      firstDate: DateTime.now().subtract(const Duration(days: 365 * 3)),
      lastDate: DateTime.now().add(const Duration(days: 365 * 3)),
    );
    if (picked != null) setState(() => _requestDate = picked);
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;
    if (_clinicId == null) {
      setState(() => _error = 'Please pick a clinic.');
      return;
    }
    if (_requestType == null) {
      setState(() => _error = 'Please pick a request type.');
      return;
    }

    setState(() {
      _saving = true;
      _error = null;
    });

    final username = context.read<AuthProvider>().userName;
    final request = MarketingSupportSaveRequest(
      username: username,
      clinicId: _clinicId!,
      requestDate: _requestDate,
      description: _descriptionController.text.trim(),
      requestType: _requestType!,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      location: _locationController.text.trim().isEmpty ? null : _locationController.text.trim(),
    );

    final provider = context.read<MarketingSupportProvider>();
    if (_isEdit) {
      final ok = await provider.update(widget.existing!.requestId, request);
      setState(() => _saving = false);
      if (ok && mounted) {
        Navigator.of(context).pop(true);
      } else if (mounted) {
        setState(() => _error = provider.errorMessage ?? 'Save failed');
      }
    } else {
      final newId = await provider.create(request);
      setState(() => _saving = false);
      if (newId != null && mounted) {
        Navigator.of(context).pop(newId);
      } else if (mounted) {
        setState(() => _error = provider.errorMessage ?? 'Save failed');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_isEdit ? 'Edit Request' : 'New Marketing Support Request')),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
          children: [
            Card(
              child: ListTile(
                leading: const Icon(Icons.event_outlined),
                title: const Text('Request Date'),
                subtitle: Text('${_requestDate.year}-${_requestDate.month.toString().padLeft(2, '0')}-${_requestDate.day.toString().padLeft(2, '0')}'),
                trailing: const Icon(Icons.chevron_right),
                onTap: _pickDate,
              ),
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
              key: const Key('requestTypeField'),
              initialValue: _requestType,
              decoration: const InputDecoration(labelText: 'Request Type', prefixIcon: Icon(Icons.category_outlined)),
              isExpanded: true,
              items: [
                const DropdownMenuItem<String?>(value: null, child: Text('— Select —')),
                ...marketingSupportRequestTypes.map((t) => DropdownMenuItem<String?>(value: t, child: Text(t, overflow: TextOverflow.ellipsis))),
              ],
              onChanged: (v) => setState(() => _requestType = v),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _descriptionController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Description', prefixIcon: Icon(Icons.description_outlined)),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Description is required.' : null,
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _remarksController,
              maxLines: 2,
              decoration: const InputDecoration(labelText: 'Remarks (optional)', prefixIcon: Icon(Icons.notes_outlined)),
            ),
            const SizedBox(height: 12),
            TextFormField(
              controller: _locationController,
              decoration: const InputDecoration(labelText: 'Location (optional)', prefixIcon: Icon(Icons.place_outlined)),
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
                  : Text(_isEdit ? 'Save Changes' : 'Submit Request'),
            ),
          ],
        ),
      ),
    );
  }
}

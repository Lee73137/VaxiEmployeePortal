import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/clinic_booking.dart';
import '../offline/booking_offline.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_drafts_provider.dart';
import '../providers/clinic_bookings_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatting.dart';

const _color = AppPalette.black;

// New Booking - mirrors vaxiCSR's own Bookings/_CreateForm.cshtml: clinic
// search (with the clinic's unpaid balance), rep/promo/delivery pickers, and
// an item cart priced by the server's tier-breakdown + free-accessory rules.
//
// Works with no signal: lookups and pricing fall back to the offline pack
// (BookingDraftsProvider), and the booking can be saved on the phone, then
// edited, deleted or submitted later. Opening a saved booking ([draft])
// edits it in place.
class ClinicBookingFormScreen extends StatefulWidget {
  final BookingDraft? draft;

  const ClinicBookingFormScreen({super.key, this.draft});

  @override
  State<ClinicBookingFormScreen> createState() => _ClinicBookingFormScreenState();
}

class _ClinicBookingFormScreenState extends State<ClinicBookingFormScreen> {
  final _clinicSearchController = TextEditingController();
  final _remarksController = TextEditingController();

  late final String _draftId;
  late final DateTime _createdAt;

  BookingClinicOption? _clinic;
  List<BookingClinicOption> _clinicResults = [];
  bool _searchingClinics = false;
  UnpaidInvoicesResponse? _unpaidInvoices;
  bool _loadingUnpaid = false;
  bool _unpaidUnavailable = false;

  List<BookingRepOption> _reps = [];
  int? _repId;
  List<PromoOption> _promos = [];
  int _promoId = 0;
  String? _deliveryType;
  bool _loadingLookups = true;

  final List<DraftItem> _items = [];

  /// Set once any lookup had to fall back to the phone's offline copy.
  bool _offline = false;
  bool _saving = false;
  String? _error;

  String? get _username => context.read<AuthProvider>().userName;
  ClinicBookingsProvider get _bookings => context.read<ClinicBookingsProvider>();
  BookingDraftsProvider get _drafts => context.read<BookingDraftsProvider>();
  double get _total => _items.fold<double>(0, (s, i) => s + i.total);

  @override
  void initState() {
    super.initState();
    final d = widget.draft;
    _draftId = d?.id ?? newClientReference();
    _createdAt = d?.createdAt ?? DateTime.now();
    if (d != null) {
      _clinic = d.clinic;
      _clinicSearchController.text = d.clinic?.name ?? '';
      _repId = d.repId;
      _promoId = d.promoId;
      _deliveryType = d.deliveryType;
      _remarksController.text = d.remarks ?? '';
      _items.addAll(d.items);
    }
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadLookups());
  }

  @override
  void dispose() {
    _clinicSearchController.dispose();
    _remarksController.dispose();
    super.dispose();
  }

  Future<void> _loadLookups() async {
    await _drafts.load(_username);
    try {
      final reps = await _bookings.api.reps(username: _username);
      final promos = await _bookings.api.promos();
      if (!mounted) return;
      setState(() {
        _reps = reps;
        _promos = promos;
      });
    } catch (_) {
      final pack = _drafts.pack;
      if (!mounted) return;
      setState(() {
        _offline = true;
        _reps = pack?.reps ?? [];
        _promos = pack?.promos ?? [];
        if (pack == null) _error = 'No connection and nothing downloaded for offline use yet - connect once to download it.';
      });
    }
    if (!mounted) return;
    setState(() {
      if (_reps.length == 1) _repId = _reps.first.repId;
      if (_repId != null && !_reps.any((r) => r.repId == _repId)) _repId = null;
      if (_promoId != 0 && !_promos.any((p) => p.promoId == _promoId)) _promoId = 0;
      _loadingLookups = false;
    });
    if (_clinic != null) _loadUnpaid(_clinic!);
  }

  Future<void> _searchClinics(String term) async {
    if (term.trim().length < 2) {
      setState(() => _clinicResults = []);
      return;
    }
    setState(() => _searchingClinics = true);
    List<BookingClinicOption> results;
    try {
      results = await _bookings.api.searchClinics(term.trim(), username: _username);
    } catch (_) {
      _offline = true;
      results = _drafts.pack?.searchClinics(term) ?? [];
    }
    if (!mounted || _clinicSearchController.text.trim() != term.trim()) return;
    setState(() {
      _clinicResults = results;
      _searchingClinics = false;
    });
  }

  void _pickClinic(BookingClinicOption c) {
    FocusScope.of(context).unfocus();
    setState(() {
      _clinic = c;
      _clinicSearchController.text = c.name;
      _clinicResults = [];
    });
    _loadUnpaid(c);
  }

  Future<void> _loadUnpaid(BookingClinicOption c) async {
    setState(() {
      _unpaidInvoices = null;
      _unpaidUnavailable = false;
      _loadingUnpaid = true;
    });
    try {
      final unpaid = await _bookings.api.unpaidInvoices(c.name);
      if (!mounted) return;
      setState(() {
        _unpaidInvoices = unpaid;
        _loadingUnpaid = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loadingUnpaid = false;
        _unpaidUnavailable = true;
      });
    }
  }

  /// Prices [qty] of [code] through the server, or - with no signal - from
  /// the offline pack (re-checked online when the booking is submitted).
  Future<DraftItem> _price(String code, int qty) async {
    try {
      final lines = await _bookings.api.itemPreview(code, qty);
      return DraftItem(itemCode: code, quantity: qty, lines: lines);
    } catch (e) {
      if (!isOfflineError(e)) rethrow;
      final item = _drafts.pack?.item(code);
      if (item == null) throw 'No connection, and "$code" isn\'t in the offline item list.';
      setState(() => _offline = true);
      return DraftItem(itemCode: code, quantity: qty, lines: priceItemOffline(item, qty), pricedOffline: true);
    }
  }

  Future<void> _editItem({int? index}) async {
    final existing = index == null ? null : _items[index];
    final result = await showModalBottomSheet<DraftItem>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => _ItemSheet(
        initial: existing,
        search: (term) async {
          try {
            return await _bookings.api.searchItems(term);
          } catch (e) {
            final pack = _drafts.pack;
            if (pack == null || pack.items.isEmpty) {
              throw isOfflineError(e) ? 'No connection, and the offline item list hasn\'t been downloaded yet.' : '$e';
            }
            setState(() => _offline = true);
            return pack.searchItems(term);
          }
        },
        price: _price,
      ),
    );
    if (result == null || !mounted) return;
    if (result.quantity == 0) {
      if (index != null) _removeItem(index);
      return;
    }
    setState(() {
      // Adding an item that's already in the cart replaces it rather than
      // listing the same code twice.
      final existingIndex = index ?? _items.indexWhere((x) => x.itemCode == result.itemCode);
      if (existingIndex >= 0) {
        _items[existingIndex] = result;
      } else {
        _items.add(result);
      }
    });
  }

  Future<void> _removeItem(int index) async {
    final item = _items[index];
    setState(() => _items.removeAt(index));
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(
        content: Text('Removed ${item.itemCode}'),
        action: SnackBarAction(label: 'Undo', onPressed: () => setState(() => _items.insert(index.clamp(0, _items.length), item))),
      ));
  }

  BookingDraft _currentDraft() {
    final rep = _reps.where((r) => r.repId == _repId).firstOrNull;
    final promo = _promos.where((p) => p.promoId == _promoId).firstOrNull;
    return BookingDraft(
      id: _draftId,
      createdAt: _createdAt,
      updatedAt: DateTime.now(),
      clinic: _clinic,
      repId: _repId,
      repName: rep?.repName ?? widget.draft?.repName,
      promoId: _promoId,
      promoCode: promo?.promoCode,
      deliveryType: _deliveryType,
      remarks: _remarksController.text.trim().isEmpty ? null : _remarksController.text.trim(),
      items: List.of(_items),
    );
  }

  String? _validate() {
    if (_clinic == null || _clinic!.clinicId <= 0) return 'Please select a clinic from the list.';
    if (_repId == null) return 'Please select a sales rep.';
    if (_deliveryType == null) return 'Please select a delivery type.';
    if (_items.isEmpty) return 'Please add at least one item to the booking.';
    return null;
  }

  Future<void> _saveToPhone() async {
    if (_clinic == null && _items.isEmpty) {
      setState(() => _error = 'Pick a clinic or add an item before saving.');
      return;
    }
    await _drafts.saveDraft(_currentDraft());
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Kept on this phone as a draft. Open it in Clinic Bookings and tap Submit when ready.')),
    );
    Navigator.of(context).pop(false);
  }

  Future<void> _submit({bool confirmedPrices = false, BookingDraft? draftOverride}) async {
    final problem = _validate();
    if (problem != null) {
      setState(() => _error = problem);
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });

    final draft = draftOverride ?? _currentDraft();
    final outcome = await _drafts.submit(draft, username: _username, confirmedPrices: confirmedPrices);
    if (!mounted) return;
    setState(() => _saving = false);

    switch (outcome.status) {
      case DraftSubmitStatus.submitted:
        final r = outcome.response!;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.check_circle_rounded, color: AppPalette.greenText, size: 40),
            title: Text(r.alreadySubmitted ? 'Already submitted' : 'Booking submitted'),
            content: Text(
              r.alreadySubmitted
                  ? 'This booking for ${r.clinicName} had already reached the server${r.soNo != null ? ' (SO ${r.soNo})' : ''} - it wasn\'t sent twice.'
                  : r.routedToDavao
                      ? 'Booking created for ${r.clinicName} (${r.itemCount} line${r.itemCount == 1 ? '' : 's'}) - saved to the Davao database.'
                      : 'Booking created for ${r.clinicName} - SO ${r.soNo} generated (${r.itemCount} line${r.itemCount == 1 ? '' : 's'}).',
            ),
            actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
        if (mounted) Navigator.of(context).pop(true);
      case DraftSubmitStatus.priceChanged:
        final repriced = outcome.repriced!;
        setState(() {
          _items
            ..clear()
            ..addAll(repriced.items);
        });
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.price_change_rounded, color: _color, size: 36),
            title: const Text('Prices have changed'),
            content: Text(
              'This booking was priced at ${formatMoney(draft.total)}. With today\'s prices it\'s ${formatMoney(repriced.total)}.\n\nSubmit at the new total?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Review first')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
            ],
          ),
        );
        if (ok == true && mounted) await _submit(confirmedPrices: true, draftOverride: _currentDraft());
      case DraftSubmitStatus.offline:
        await _drafts.saveDraft(draft.copyWith(lastError: outcome.message, queued: true));
        if (!mounted) return;
        await showDialog<void>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.cloud_off_rounded, color: _color, size: 40),
            title: const Text('Will send when back online'),
            content: const Text(
              'There\'s no connection right now, so the booking is saved on this phone and will be sent automatically '
              'as soon as the app has signal again. Until then you can still edit or delete it in Clinic Bookings.',
            ),
            actions: [FilledButton(onPressed: () => Navigator.pop(ctx), child: const Text('OK'))],
          ),
        );
        if (mounted) Navigator.of(context).pop(false);
      case DraftSubmitStatus.failed:
        setState(() => _error = outcome.message);
    }
  }

  Future<void> _deleteSaved() async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete saved booking?'),
        content: const Text('It hasn\'t been submitted, so it will be gone for good.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            style: TextButton.styleFrom(foregroundColor: AppPalette.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
    if (ok != true || !mounted) return;
    await _drafts.deleteDraft(_draftId);
    if (mounted) Navigator.of(context).pop(false);
  }

  /// Item rows currently being re-priced after a quantity change.
  final Set<String> _repricing = {};
  final Map<String, int> _qtyTokens = {};

  /// Inline − / + on an item row: shows the new quantity at once, then
  /// re-prices it (server, or offline pack) and swaps in the priced lines.
  Future<void> _changeQty(int index, int qty) async {
    if (qty < 1) {
      _removeItem(index);
      return;
    }
    final code = _items[index].itemCode;
    final token = (_qtyTokens[code] ?? 0) + 1;
    _qtyTokens[code] = token;
    setState(() {
      _items[index] = DraftItem(itemCode: code, quantity: qty, lines: _items[index].lines, pricedOffline: _items[index].pricedOffline);
      _repricing.add(code);
    });
    try {
      final priced = await _price(code, qty);
      if (!mounted || _qtyTokens[code] != token) return;
      final i = _items.indexWhere((x) => x.itemCode == code);
      setState(() {
        if (i >= 0) _items[i] = priced;
        _repricing.remove(code);
      });
    } catch (e) {
      if (!mounted || _qtyTokens[code] != token) return;
      setState(() {
        _repricing.remove(code);
        _error = '$e';
      });
    }
  }

  bool get _clinicDone => _clinic != null && _clinic!.clinicId > 0;
  bool get _detailsDone => _repId != null && _deliveryType != null;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isSaved = widget.draft != null;
    final itemCount = _items.length;

    return Scaffold(
      backgroundColor: scheme.surface,
      body: SafeArea(
        bottom: false,
        child: Column(
          children: [
            // Clean top bar: back, title + status, offline pill, delete.
            Padding(
              padding: const EdgeInsets.fromLTRB(6, 6, 8, 4),
              child: Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.of(context).maybePop(),
                    icon: const Icon(Icons.arrow_back_rounded),
                  ),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(isSaved ? 'Saved booking' : 'New booking',
                            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                        Text(
                          isSaved ? 'On this phone · not submitted yet' : 'Clinic, details, then items',
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  if (_offline)
                    Container(
                      margin: const EdgeInsets.only(right: 4),
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(20)),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.cloud_off_rounded, size: 14, color: scheme.onSurfaceVariant),
                          const SizedBox(width: 4),
                          Text('Offline', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                        ],
                      ),
                    ),
                  if (isSaved)
                    IconButton(
                      tooltip: 'Delete saved booking',
                      onPressed: _deleteSaved,
                      icon: const Icon(Icons.delete_outline_rounded, color: AppPalette.red),
                    ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 2, 16, 8),
              child: _StepStrip(steps: [
                ('Clinic', _clinicDone),
                ('Details', _detailsDone),
                ('Items', itemCount > 0),
              ]),
            ),
            Expanded(
              child: _loadingLookups
                  ? const Center(child: CircularProgressIndicator())
                  : ListView(
                      padding: const EdgeInsets.fromLTRB(12, 4, 12, 16),
                      children: [
                        _section(number: 1, title: 'Clinic', done: _clinicDone, child: _clinicStep(scheme)),
                        const SizedBox(height: 10),
                        _section(number: 2, title: 'Details', done: _detailsDone, child: _detailsStep(scheme)),
                        const SizedBox(height: 10),
                        _section(
                          number: 3,
                          title: 'Items',
                          done: itemCount > 0,
                          trailing: FilledButton.icon(
                            style: FilledButton.styleFrom(
                              backgroundColor: AppPalette.red,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              minimumSize: const Size(0, 32),
                              visualDensity: VisualDensity.compact,
                            ),
                            onPressed: () => _editItem(),
                            icon: const Icon(Icons.add_rounded, size: 18),
                            label: const Text('Add'),
                          ),
                          child: _itemsStep(scheme),
                        ),
                        if (_error != null) ...[
                          const SizedBox(height: 10),
                          _note(AppPalette.red, Icons.error_outline_rounded, _error!),
                        ],
                      ],
                    ),
            ),
            if (!_loadingLookups) _cartBar(scheme),
          ],
        ),
      ),
    );
  }

  Widget _section({required int number, required String title, required bool done, required Widget child, Widget? trailing}) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.7)),
      ),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Row(
            children: [
              _StepDot(number: number, done: done),
              const SizedBox(width: 8),
              Expanded(child: Text(title, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800))),
              ?trailing,
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }

  // ---- Step 1: clinic -------------------------------------------------

  Widget _clinicStep(ColorScheme scheme) {
    final c = _clinic;
    if (c != null && c.clinicId > 0) {
      final b = Theme.of(context).brightness;
      final unpaid = _unpaidInvoices;
      return Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
            decoration: BoxDecoration(color: AppPalette.black, borderRadius: BorderRadius.circular(14)),
            child: Row(
              children: [
                _Monogram(text: c.name, background: AppPalette.red, foreground: Colors.white, size: 38),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(c.name, maxLines: 1, overflow: TextOverflow.ellipsis,
                          style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 14.5)),
                      Text(
                        [if (c.areaName.isNotEmpty) c.areaName, if (c.subtitle?.isNotEmpty ?? false) c.subtitle!].join(' · '),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                      ),
                    ],
                  ),
                ),
                TextButton(
                  style: TextButton.styleFrom(foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                  onPressed: () => setState(() {
                    _clinic = null;
                    _clinicSearchController.clear();
                    _unpaidInvoices = null;
                    _unpaidUnavailable = false;
                  }),
                  child: const Text('Change'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          if (_loadingUnpaid)
            const LinearProgressIndicator(minHeight: 2)
          else if (unpaid != null && unpaid.totalBalance > 0.01)
            _note(
              AppPalette.red,
              Icons.warning_amber_rounded,
              'Unpaid ${formatMoney(unpaid.totalBalance)} · ${unpaid.invoices.length} invoice${unpaid.invoices.length == 1 ? '' : 's'}',
            )
          else if (unpaid != null)
            _note(AppPalette.green, Icons.verified_rounded, 'No unpaid balance')
          else if (_unpaidUnavailable)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(color: AppPalette.tint(AppPalette.black, b), borderRadius: BorderRadius.circular(10)),
              child: Text('Unpaid balance can\'t be checked offline.', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ),
        ],
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          key: const Key('clinicSearchField'),
          controller: _clinicSearchController,
          decoration: InputDecoration(
            hintText: 'Search clinic name',
            isDense: true,
            prefixIcon: const Icon(Icons.search_rounded, size: 20),
            suffixIcon: _searchingClinics
                ? const Padding(padding: EdgeInsets.all(12), child: SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2)))
                : null,
          ),
          onChanged: (v) {
            setState(() {
              _clinic = null;
              _unpaidInvoices = null;
              _unpaidUnavailable = false;
            });
            _searchClinics(v);
          },
        ),
        if (_clinicResults.isNotEmpty) ...[
          const SizedBox(height: 6),
          for (final r in _clinicResults)
            InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _pickClinic(r),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
                child: Row(
                  children: [
                    _Monogram(text: r.name, background: AppPalette.tint(AppPalette.black, Theme.of(context).brightness), foreground: scheme.onSurface, size: 32),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(r.name, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5)),
                          Text(
                            [if (r.areaName.isNotEmpty) r.areaName, if (r.subtitle?.isNotEmpty ?? false) r.subtitle!].join(' · '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Icon(Icons.chevron_right_rounded, color: scheme.outline),
                  ],
                ),
              ),
            ),
        ] else if (_clinicSearchController.text.trim().length >= 2 && !_searchingClinics) ...[
          const SizedBox(height: 8),
          Text('No clinic matches that name.', style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant)),
        ],
      ],
    );
  }

  // ---- Step 2: details ------------------------------------------------

  static const _deliveryIcons = {
    'PICKUP': Icons.storefront_rounded,
    'CARGO': Icons.inventory_2_rounded,
    'DELIVERY': Icons.local_shipping_rounded,
    'LALAMOVE': Icons.two_wheeler_rounded,
  };

  Widget _detailsStep(ColorScheme scheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Row(
          key: const Key('deliveryTypeField'),
          children: [
            for (final d in bookingDeliveryTypes) ...[
              Expanded(
                child: _DeliveryTile(
                  label: d['label']!,
                  icon: _deliveryIcons[d['value']] ?? Icons.local_shipping_rounded,
                  selected: _deliveryType == d['value'],
                  onTap: () => setState(() => _deliveryType = d['value']),
                ),
              ),
              if (d != bookingDeliveryTypes.last) const SizedBox(width: 6),
            ],
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: DropdownButtonFormField<int?>(
                key: const Key('repField'),
                initialValue: _repId,
                isExpanded: true,
                isDense: true,
                decoration: const InputDecoration(labelText: 'Sales rep', isDense: true),
                items: [
                  const DropdownMenuItem<int?>(value: null, child: Text('Select')),
                  ..._reps.map((r) => DropdownMenuItem<int?>(value: r.repId, child: Text(r.repName, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: _reps.length == 1 ? null : (v) => setState(() => _repId = v),
              ),
            ),
            const SizedBox(width: 8),
            Expanded(
              child: DropdownButtonFormField<int>(
                key: const Key('promoField'),
                initialValue: _promoId,
                isExpanded: true,
                isDense: true,
                decoration: const InputDecoration(labelText: 'Promo', isDense: true),
                items: [
                  const DropdownMenuItem<int>(value: 0, child: Text('None')),
                  ..._promos.map((p) => DropdownMenuItem<int>(value: p.promoId, child: Text(p.promoCode, overflow: TextOverflow.ellipsis))),
                ],
                onChanged: (v) => setState(() => _promoId = v ?? 0),
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _remarksController,
          minLines: 1,
          maxLines: 3,
          decoration: const InputDecoration(
            hintText: 'Remarks (optional)',
            isDense: true,
            prefixIcon: Icon(Icons.sticky_note_2_outlined, size: 20),
          ),
        ),
      ],
    );
  }

  // ---- Step 3: items --------------------------------------------------

  Widget _itemsStep(ColorScheme scheme) {
    if (_items.isEmpty) {
      return InkWell(
        borderRadius: BorderRadius.circular(14),
        onTap: () => _editItem(),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant, width: 1.4),
          ),
          child: Column(
            children: [
              Icon(Icons.add_shopping_cart_rounded, color: scheme.onSurfaceVariant),
              const SizedBox(height: 4),
              Text('Tap to add the first item', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            ],
          ),
        ),
      );
    }
    return Column(
      children: [
        for (var i = 0; i < _items.length; i++) ...[
          if (i > 0) Divider(height: 14, color: scheme.outlineVariant.withValues(alpha: 0.6)),
          Dismissible(
            key: ValueKey('item-${_items[i].itemCode}'),
            direction: DismissDirection.endToStart,
            background: Container(
              alignment: Alignment.centerRight,
              padding: const EdgeInsets.only(right: 16),
              decoration: BoxDecoration(color: AppPalette.red, borderRadius: BorderRadius.circular(12)),
              child: const Icon(Icons.delete_outline_rounded, color: Colors.white),
            ),
            onDismissed: (_) => _removeItem(i),
            child: _ItemRow(
              item: _items[i],
              busy: _repricing.contains(_items[i].itemCode),
              onTap: () => _editItem(index: i),
              onQty: (q) => _changeQty(i, q),
            ),
          ),
        ],
        const SizedBox(height: 6),
        Text('Swipe an item left to remove it · tap it to change', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
      ],
    );
  }

  // ---- Bottom cart bar --------------------------------------------------

  Widget _cartBar(ColorScheme scheme) {
    final lines = _items.fold<int>(0, (s, i) => s + i.quantity);
    final offlinePriced = _items.any((i) => i.pricedOffline);
    return Container(
      margin: EdgeInsets.fromLTRB(10, 0, 10, MediaQuery.of(context).padding.bottom + 10),
      padding: const EdgeInsets.fromLTRB(16, 10, 8, 10),
      decoration: BoxDecoration(
        color: AppPalette.black,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [BoxShadow(color: Colors.black.withValues(alpha: 0.18), blurRadius: 16, offset: const Offset(0, 6))],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _items.isEmpty
                      ? 'No items yet'
                      : '${_items.length} item${_items.length == 1 ? '' : 's'} · $lines pcs${offlinePriced ? ' · offline price' : ''}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 11.5, fontWeight: FontWeight.w600),
                ),
                FittedBox(
                  fit: BoxFit.scaleDown,
                  alignment: Alignment.centerLeft,
                  child: Text(formatMoney(_total), style: const TextStyle(color: Colors.white, fontSize: 19, fontWeight: FontWeight.w800)),
                ),
              ],
            ),
          ),
          IconButton(
            key: const Key('saveToPhoneButton'),
            tooltip: 'Save to phone',
            onPressed: _saving ? null : _saveToPhone,
            style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.12)),
            icon: const Icon(Icons.save_alt_rounded, color: Colors.white),
          ),
          const SizedBox(width: 6),
          FilledButton.icon(
            key: const Key('submitButton'),
            style: FilledButton.styleFrom(
              backgroundColor: AppPalette.red,
              foregroundColor: Colors.white,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
            onPressed: _saving ? null : _submit,
            icon: _saving
                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2.2, color: Colors.white))
                : const Icon(Icons.send_rounded, size: 18),
            label: const Text('Submit'),
          ),
        ],
      ),
    );
  }

  Widget _note(Color color, IconData icon, String text) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(color: AppPalette.tint(color, b), borderRadius: BorderRadius.circular(10)),
      child: Row(
        children: [
          Icon(icon, color: AppPalette.onTint(color, b), size: 16),
          const SizedBox(width: 6),
          Expanded(child: Text(text, style: TextStyle(color: AppPalette.onTint(color, b), fontSize: 12.5, fontWeight: FontWeight.w700))),
        ],
      ),
    );
  }
}

/// "AG" for "AG_ALUSPRAY", "VPI" for "VPI_HEMASHIELD" - the supplier prefix
/// shown in an item's badge; the rest is the item's name.
(String, String) _splitCode(String code) {
  final i = code.indexOf('_');
  if (i > 0 && i <= 4) return (code.substring(0, i), code.substring(i + 1));
  final words = code.trim().split(RegExp(r'\s+'));
  return (words.first.substring(0, words.first.length.clamp(1, 2)).toUpperCase(), code);
}

/// Rounded square with initials / a short code.
class _Monogram extends StatelessWidget {
  final String text;
  final Color background;
  final Color foreground;
  final double size;

  const _Monogram({required this.text, required this.background, required this.foreground, this.size = 36});

  @override
  Widget build(BuildContext context) {
    final words = text.replaceAll(RegExp(r'[^A-Za-z0-9 ]'), ' ').trim().split(RegExp(r'\s+')).where((w) => w.isNotEmpty).toList();
    final initials = words.isEmpty ? '?' : (words.length == 1 ? words.first.substring(0, 1) : '${words[0][0]}${words[1][0]}').toUpperCase();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(color: background, borderRadius: BorderRadius.circular(size * 0.3)),
      alignment: Alignment.center,
      child: Text(initials, style: TextStyle(color: foreground, fontWeight: FontWeight.w800, fontSize: size * 0.36)),
    );
  }
}

/// The 1 · 2 · 3 progress strip under the title.
class _StepStrip extends StatelessWidget {
  final List<(String, bool)> steps;

  const _StepStrip({required this.steps});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        for (var i = 0; i < steps.length; i++) ...[
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                AnimatedContainer(
                  duration: const Duration(milliseconds: 250),
                  height: 4,
                  decoration: BoxDecoration(
                    color: steps[i].$2 ? AppPalette.green : scheme.outlineVariant,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  steps[i].$1,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: steps[i].$2 ? AppPalette.onTint(AppPalette.green, Theme.of(context).brightness) : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
          if (i < steps.length - 1) const SizedBox(width: 6),
        ],
      ],
    );
  }
}

class _StepDot extends StatelessWidget {
  final int number;
  final bool done;

  const _StepDot({required this.number, required this.done});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 22,
      height: 22,
      decoration: BoxDecoration(color: done ? AppPalette.green : AppPalette.black, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: done
          ? const Icon(Icons.check_rounded, size: 15, color: AppPalette.black)
          : Text('$number', style: const TextStyle(color: Colors.white, fontSize: 11.5, fontWeight: FontWeight.w800)),
    );
  }
}

class _DeliveryTile extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  const _DeliveryTile({required this.label, required this.icon, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Material(
      color: selected ? AppPalette.black : scheme.surfaceContainerHigh,
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 9),
          child: Column(
            children: [
              Icon(icon, size: 20, color: selected ? Colors.white : scheme.onSurfaceVariant),
              const SizedBox(height: 3),
              FittedBox(
                fit: BoxFit.scaleDown,
                child: Text(label,
                    style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: selected ? Colors.white : scheme.onSurfaceVariant)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// − qty + pill used on item rows and in the item sheet.
class _QtyStepper extends StatelessWidget {
  final int value;
  final ValueChanged<int> onChanged;
  final bool large;

  const _QtyStepper({required this.value, required this.onChanged, this.large = false});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final h = large ? 44.0 : 32.0;
    Widget btn(IconData icon, int next) => SizedBox(
          width: h,
          height: h,
          child: IconButton(
            padding: EdgeInsets.zero,
            iconSize: large ? 22 : 17,
            onPressed: () => onChanged(next),
            icon: Icon(icon),
          ),
        );
    return Container(
      height: h,
      decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(h / 2)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          btn(value <= 1 ? Icons.delete_outline_rounded : Icons.remove_rounded, value - 1),
          ConstrainedBox(
            constraints: BoxConstraints(minWidth: large ? 44 : 28),
            child: Text('$value',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: large ? 18 : 14, fontWeight: FontWeight.w800, fontFeatures: const [FontFeature.tabularFigures()])),
          ),
          btn(Icons.add_rounded, value + 1),
        ],
      ),
    );
  }
}

/// One cart row: code badge, name, unit price + free goods, inline stepper,
/// line total.
class _ItemRow extends StatelessWidget {
  final DraftItem item;
  final bool busy;
  final VoidCallback onTap;
  final ValueChanged<int> onQty;

  const _ItemRow({required this.item, required this.busy, required this.onTap, required this.onQty});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final b = Theme.of(context).brightness;
    final (prefix, name) = _splitCode(item.itemCode);
    final paid = item.lines.where((l) => !l.isFree).toList();
    final free = item.lines.where((l) => l.isFree).toList();
    final unit = paid.isEmpty ? null : paid.first.unitPrice;

    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(color: AppPalette.tint(AppPalette.black, b), borderRadius: BorderRadius.circular(11)),
              alignment: Alignment.center,
              child: FittedBox(
                fit: BoxFit.scaleDown,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: Text(prefix, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 12, color: scheme.onSurface)),
                ),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
                  const SizedBox(height: 2),
                  Text(
                    [
                      if (unit != null) '${formatMoney(unit)} each',
                      if (paid.map((l) => l.unitPrice).toSet().length > 1) 'mixed tiers',
                      if (item.pricedOffline) 'offline price',
                    ].join(' · '),
                    style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant),
                  ),
                  if (free.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        for (final f in free)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                            decoration: BoxDecoration(color: AppPalette.tint(AppPalette.green, b), borderRadius: BorderRadius.circular(6)),
                            child: Text(
                              '+${f.quantity} free${f.itemCode == item.itemCode ? '' : ' ${_splitCode(f.itemCode).$2}'}',
                              style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppPalette.onTint(AppPalette.green, b)),
                            ),
                          ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _QtyStepper(value: item.quantity, onChanged: onQty),
                const SizedBox(height: 6),
                busy
                    ? const SizedBox(width: 14, height: 14, child: CircularProgressIndicator(strokeWidth: 2))
                    : Text(formatMoney(item.total), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13.5)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

/// Bottom sheet to add or edit one item: search the code, set the quantity
/// with a stepper, see the live price breakdown, then add/update. Being a
/// scrolling sheet (not a fixed dialog) it never overflows when the
/// keyboard opens or the text size is large.
class _ItemSheet extends StatefulWidget {
  final DraftItem? initial;
  final Future<List<String>> Function(String term) search;
  final Future<DraftItem> Function(String code, int qty) price;

  const _ItemSheet({required this.initial, required this.search, required this.price});

  @override
  State<_ItemSheet> createState() => _ItemSheetState();
}

class _ItemSheetState extends State<_ItemSheet> {
  late final TextEditingController _code;
  late final TextEditingController _qty;
  /// Every bookable item code, loaded when the sheet opens and filtered
  /// locally as the user types. Null until loaded.
  List<String>? _all;
  bool _loadingList = true;
  String? _listError;
  String? _chosen;
  DraftItem? _preview;
  bool _busy = false;
  String? _error;
  int _previewToken = 0;

  @override
  void initState() {
    super.initState();
    _code = TextEditingController(text: widget.initial?.itemCode ?? '');
    _qty = TextEditingController(text: widget.initial == null ? '1' : '${widget.initial!.quantity}');
    _chosen = widget.initial?.itemCode;
    _preview = widget.initial;
    _loadList();
  }

  @override
  void dispose() {
    _code.dispose();
    _qty.dispose();
    super.dispose();
  }

  Future<void> _loadList() async {
    setState(() {
      _loadingList = true;
      _listError = null;
    });
    try {
      final items = await widget.search('');
      if (!mounted) return;
      setState(() {
        _all = items;
        _loadingList = false;
        // An older server returns nothing for an empty search - fall back to
        // searching as the user types.
        _searchAsYouType = items.isEmpty;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _all = [];
        _loadingList = false;
        _listError = '$e';
      });
    }
  }

  int get _qtyValue => int.tryParse(_qty.text.trim()) ?? 0;

  /// What the list shows: everything, or the codes containing the typed text.
  List<String> get _matches {
    final all = _all ?? const <String>[];
    return all.where((c) => searchMatches(c, _code.text)).toList();
  }

  /// True when the full list couldn't be loaded up front, so results come
  /// from a server search per typed term (2+ letters) instead.
  bool _searchAsYouType = false;
  int _searchToken = 0;

  Future<void> _onCodeChanged(String v) async {
    setState(() {
      _chosen = null;
      _preview = null;
    });
    if (!_searchAsYouType) return;
    final term = v.trim();
    if (term.length < 2) {
      setState(() => _all = []);
      return;
    }
    final token = ++_searchToken;
    setState(() => _loadingList = true);
    try {
      var results = await widget.search(term);
      // An older server matches the text literally, so "petshield" misses
      // "PET SHIELD". Widen to the first 3 letters and let [_matches] apply
      // the space-insensitive filter locally.
      final norm = normalizeForSearch(term);
      if (results.isEmpty && norm.length >= 3) {
        results = await widget.search(norm.substring(0, 3));
      }
      if (!mounted || token != _searchToken) return;
      setState(() {
        _all = results;
        _loadingList = false;
        _listError = null;
      });
    } catch (e) {
      if (!mounted || token != _searchToken) return;
      setState(() {
        _all = [];
        _loadingList = false;
        _listError = '$e';
      });
    }
  }

  void _choose(String code) {
    _code.text = code;
    setState(() => _chosen = code);
    FocusScope.of(context).unfocus();
    _refreshPreview();
  }

  void _setQty(int q) {
    if (q < 1) q = 1;
    _qty.text = '$q';
    _refreshPreview();
  }

  Future<void> _refreshPreview() async {
    final code = _chosen;
    final qty = _qtyValue;
    if (code == null || qty <= 0) {
      setState(() => _preview = null);
      return;
    }
    final token = ++_previewToken;
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      final p = await widget.price(code, qty);
      if (!mounted || token != _previewToken) return;
      setState(() {
        _preview = p;
        _busy = false;
      });
    } catch (e) {
      if (!mounted || token != _previewToken) return;
      setState(() {
        _busy = false;
        _error = '$e';
      });
    }
  }

  @override
  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final b = Theme.of(context).brightness;
    final editing = widget.initial != null;
    final chosen = _chosen;

    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(editing ? 'Edit item' : 'Add item', style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (chosen == null) ...[
              TextField(
                controller: _code,
                decoration: InputDecoration(
                  hintText: 'Search items (e.g. petshield)',
                  isDense: true,
                  prefixIcon: const Icon(Icons.search_rounded, size: 20),
                  suffixIcon: _code.text.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.close_rounded, size: 18),
                          onPressed: () {
                            _code.clear();
                            _onCodeChanged('');
                          },
                        )
                      : null,
                ),
                onChanged: _onCodeChanged,
              ),
              const SizedBox(height: 8),
              SizedBox(
                height: 300,
                child: _loadingList
                    ? const Center(child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2.4)))
                    : _listError != null && (_all?.isEmpty ?? true)
                        ? Center(
                            child: Column(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.cloud_off_rounded, color: scheme.onSurfaceVariant),
                                const SizedBox(height: 6),
                                Text(_listError!, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                                TextButton.icon(onPressed: _loadList, icon: const Icon(Icons.refresh_rounded, size: 18), label: const Text('Retry')),
                              ],
                            ),
                          )
                        : _matches.isEmpty
                            ? Center(
                                child: Text(
                                  _searchAsYouType && _code.text.trim().length < 2
                                      ? 'Type at least 2 letters to search items'
                                      : 'No item matches "${_code.text.trim()}"',
                                  style: TextStyle(color: scheme.onSurfaceVariant),
                                ),
                              )
                            : ListView.separated(
                                padding: EdgeInsets.zero,
                                itemCount: _matches.length,
                                separatorBuilder: (_, _) => Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
                                itemBuilder: (context, i) {
                                  final code = _matches[i];
                                  final (prefix, name) = _splitCode(code);
                                  return InkWell(
                                    onTap: () => _choose(code),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(vertical: 7, horizontal: 2),
                                      child: Row(
                                        children: [
                                          Container(
                                            width: 34,
                                            height: 34,
                                            decoration: BoxDecoration(color: AppPalette.tint(AppPalette.black, b), borderRadius: BorderRadius.circular(9)),
                                            alignment: Alignment.center,
                                            child: FittedBox(
                                              fit: BoxFit.scaleDown,
                                              child: Padding(
                                                padding: const EdgeInsets.all(3),
                                                child: Text(prefix, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 11)),
                                              ),
                                            ),
                                          ),
                                          const SizedBox(width: 10),
                                          Expanded(
                                            child: Text(name, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                                          ),
                                          Container(
                                            width: 28,
                                            height: 28,
                                            decoration: const BoxDecoration(color: AppPalette.red, shape: BoxShape.circle),
                                            child: const Icon(Icons.add_rounded, size: 18, color: Colors.white),
                                          ),
                                        ],
                                      ),
                                    ),
                                  );
                                },
                              ),
              ),
              if (!_loadingList && (_all?.isNotEmpty ?? false))
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text('${_matches.length} of ${_all!.length} items', style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                ),
            ] else ...[
              // The picked item, its quantity and live price.
              Container(
                padding: const EdgeInsets.fromLTRB(12, 10, 4, 10),
                decoration: BoxDecoration(color: AppPalette.black, borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(_splitCode(chosen).$1, style: TextStyle(color: Colors.white.withValues(alpha: 0.6), fontSize: 11, fontWeight: FontWeight.w800)),
                          Text(_splitCode(chosen).$2, style: const TextStyle(color: Colors.white, fontSize: 15, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                    if (!editing)
                      TextButton(
                        style: TextButton.styleFrom(foregroundColor: Colors.white, visualDensity: VisualDensity.compact),
                        onPressed: () => setState(() {
                          _chosen = null;
                          _preview = null;
                          _code.clear();
                        }),
                        child: const Text('Change'),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 14),
              Center(child: _QtyStepper(value: _qtyValue < 1 ? 1 : _qtyValue, onChanged: _setQty, large: true)),
              const SizedBox(height: 10),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 6,
                runSpacing: 6,
                children: [
                  for (final q in const [1, 5, 10, 25, 50, 100])
                    ChoiceChip(
                      label: Text('$q'),
                      showCheckmark: false,
                      selected: _qtyValue == q,
                      selectedColor: AppPalette.tint(AppPalette.black, b),
                      visualDensity: VisualDensity.compact,
                      onSelected: (_) => _setQty(q),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              if (_busy)
                const Padding(padding: EdgeInsets.symmetric(vertical: 14), child: Center(child: CircularProgressIndicator()))
              else if (_preview != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: scheme.surfaceContainerHigh, borderRadius: BorderRadius.circular(14)),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      for (final l in _preview!.lines)
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 2),
                          child: Row(
                            children: [
                              Icon(l.isFree ? Icons.card_giftcard_rounded : Icons.sell_outlined,
                                  size: 15, color: l.isFree ? AppPalette.greenText : scheme.onSurfaceVariant),
                              const SizedBox(width: 6),
                              Expanded(
                                child: Text(
                                  l.isFree
                                      ? '${l.quantity} × ${l.itemCode == chosen ? 'free' : '${_splitCode(l.itemCode).$2} free'}'
                                      : '${l.quantity} × ${formatMoney(l.unitPrice)}',
                                  style: TextStyle(fontSize: 12.5, color: l.isFree ? AppPalette.greenText : scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
                                ),
                              ),
                              Text(l.isFree ? '—' : formatMoney(l.total), style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
                            ],
                          ),
                        ),
                      if (_preview!.pricedOffline)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text('Offline price - re-checked when submitted.', style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                        ),
                    ],
                  ),
                ),
              if (_error != null) ...[
                const SizedBox(height: 8),
                Text(_error!, style: const TextStyle(color: AppPalette.red, fontWeight: FontWeight.w600)),
              ],
              const SizedBox(height: 14),
              FilledButton(
                style: FilledButton.styleFrom(backgroundColor: AppPalette.red, foregroundColor: Colors.white),
                onPressed: _preview == null || _busy ? null : () => Navigator.of(context).pop(_preview),
                child: Text(
                  _preview == null
                      ? (editing ? 'Update item' : 'Add to booking')
                      : '${editing ? 'Update' : 'Add'} · ${formatMoney(_preview!.total)}',
                ),
              ),
              if (editing)
                TextButton.icon(
                  style: TextButton.styleFrom(foregroundColor: AppPalette.red),
                  // Quantity 0 tells the form to remove this item.
                  onPressed: () => Navigator.of(context).pop(DraftItem(itemCode: chosen, quantity: 0, lines: const [])),
                  icon: const Icon(Icons.delete_outline_rounded, size: 18),
                  label: const Text('Remove item'),
                ),
            ],
          ],
        ),
      ),
    );
  }
}

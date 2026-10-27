import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clinic_bookings_provider.dart';
import '../providers/auth_provider.dart';
import '../models/clinic_booking.dart';
import '../offline/booking_offline.dart';
import '../providers/booking_drafts_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatting.dart';
import '../widgets/module_widgets.dart';
import 'clinic_booking_form_screen.dart';

Color bookingStatusColor(String statusName) {
  switch (statusName) {
    case 'For Preparation':
      return AppPalette.black;
    case 'For Discounting':
      return AppPalette.red;
    case 'Waiting for Delivery':
      return AppPalette.greenText;
    case 'On-Hold':
      return const Color(0xFF8A8A8A);
    case 'To Davao':
      return const Color(0xFF555555);
    case 'Void':
    case 'Cancelled':
      return AppPalette.red;
    case 'Delivered':
      return AppPalette.greenText;
    default:
      return const Color(0xFF8A8A8A);
  }
}

class ClinicBookingsListScreen extends StatefulWidget {
  const ClinicBookingsListScreen({super.key});

  @override
  State<ClinicBookingsListScreen> createState() => _ClinicBookingsListScreenState();
}

class _ClinicBookingsListScreenState extends State<ClinicBookingsListScreen> {
  String? get _username => context.read<AuthProvider>().userName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingDraftsProvider>().load(_username);
      context.read<ClinicBookingsProvider>().refresh(_username);
    });
  }

  Future<void> _pickDateRange() async {
    final provider = context.read<ClinicBookingsProvider>();
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2018),
      lastDate: now.add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: provider.dateFrom, end: provider.dateTo),
    );
    if (picked != null) {
      provider.setDateRange(picked.start, picked.end, _username);
    }
  }

  Future<void> _showPriceCorrections(BookingOrder order) async {
    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          expand: false,
          builder: (ctx, scrollController) {
            return FutureBuilder<List<PriceCorrection>>(
              future: context.read<ClinicBookingsProvider>().api.priceCorrections(order.referenceNo),
              builder: (ctx, snapshot) {
                final scheme = Theme.of(ctx).colorScheme;
                return ListView(
                  controller: scrollController,
                  padding: const EdgeInsets.all(16),
                  children: [
                    Text('PRICE CORRECTIONS', style: Theme.of(ctx).textTheme.titleMedium),
                    const SizedBox(height: 12),
                    if (snapshot.connectionState == ConnectionState.waiting)
                      const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
                    else if (snapshot.hasError)
                      Text('${snapshot.error}', style: TextStyle(color: scheme.error))
                    else if ((snapshot.data?.isEmpty ?? true))
                      Text('No corrections.', style: TextStyle(color: scheme.onSurfaceVariant))
                    else
                      ...snapshot.data!.map((c) => Card(
                            margin: const EdgeInsets.only(bottom: 8),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(c.itemName, style: const TextStyle(fontWeight: FontWeight.w600)),
                                  const SizedBox(height: 4),
                                  Text('Qty ${c.submittedQuantity} · ${formatMoney(c.submittedUnitPrice)} → ${formatMoney(c.correctedUnitPrice)}'),
                                  if (c.reason != null && c.reason!.isNotEmpty) ...[
                                    const SizedBox(height: 4),
                                    Text(c.reason!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                                  ],
                                ],
                              ),
                            ),
                          )),
                  ],
                );
              },
            );
          },
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicBookingsProvider>();
    final drafts = context.watch<BookingDraftsProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addBookingFab'),
        backgroundColor: AppPalette.black,
        onPressed: () => _openForm(),
        icon: const Icon(Icons.add_rounded),
        label: const Text('New Booking'),
      ),
      body: Column(
        children: [
          ModuleHero(
            title: 'Clinic Bookings',
            subtitle: 'Orders waiting for delivery, plus bookings saved on this phone',
            icon: Icons.local_shipping_rounded,
            color: AppPalette.black,
            bottom: Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                GestureDetector(
                  onTap: _pickDateRange,
                  child: HeroFilterChips(labels: ['${formatShortDate(provider.dateFrom)} – ${formatShortDate(provider.dateTo)}  ✎']),
                ),
                if (drafts.drafts.isNotEmpty)
                  HeroFilterChips(labels: ['${drafts.drafts.length} saved on phone']),
              ],
            ),
          ),
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppPalette.tint(AppPalette.red, Theme.of(context).brightness),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.cloud_off_rounded, color: AppPalette.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        drafts.drafts.isEmpty ? provider.errorMessage! : 'Couldn\'t load bookings from the server. Your saved bookings are below.',
                        style: const TextStyle(color: AppPalette.red, fontSize: 13, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          Expanded(
            child: provider.isLoading && drafts.drafts.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => provider.refresh(_username),
                    child: _list(provider, drafts, scheme),
                  ),
          ),
        ],
      ),
    );
  }

  Future<void> _openForm({BookingDraft? draft}) async {
    final created = await Navigator.of(context).push<bool>(MaterialPageRoute(builder: (_) => ClinicBookingFormScreen(draft: draft)));
    if (created == true && mounted) context.read<ClinicBookingsProvider>().refresh(_username);
  }

  Future<void> _submitDraft(BookingDraft d, {bool confirmed = false}) async {
    final drafts = context.read<BookingDraftsProvider>();
    final outcome = await drafts.submit(d, username: _username, confirmedPrices: confirmed);
    if (!mounted) return;
    switch (outcome.status) {
      case DraftSubmitStatus.submitted:
        final r = outcome.response!;
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(r.alreadySubmitted
              ? '${r.clinicName}: already on the server - not sent twice.'
              : '${r.clinicName}: submitted${r.soNo != null ? ' - SO ${r.soNo}' : ''}.'),
        ));
        context.read<ClinicBookingsProvider>().refresh(_username);
      case DraftSubmitStatus.priceChanged:
        final ok = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            icon: const Icon(Icons.price_change_rounded, color: AppPalette.black, size: 36),
            title: const Text('Prices have changed'),
            content: Text(
              '${d.clinic?.name ?? 'This booking'} was saved at ${formatMoney(d.total)}. '
              'With today\'s prices it\'s ${formatMoney(outcome.repriced!.total)}.\n\nSubmit at the new total?',
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Not now')),
              FilledButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Submit')),
            ],
          ),
        );
        if (ok == true && mounted) await _submitDraft(outcome.repriced!, confirmed: true);
      case DraftSubmitStatus.offline:
      case DraftSubmitStatus.failed:
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(outcome.message ?? 'Could not submit.')));
    }
  }

  Future<void> _submitAll() async {
    final drafts = context.read<BookingDraftsProvider>();
    for (final d in List.of(drafts.drafts)) {
      if (_draftProblem(d) != null) continue;
      await _submitDraft(d);
      if (!mounted) return;
    }
  }

  Future<void> _deleteDraft(BookingDraft d) async {
    final ok = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete saved booking?'),
        content: Text('${d.clinic?.name ?? 'This booking'} hasn\'t been submitted, so it will be gone for good.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(style: TextButton.styleFrom(foregroundColor: AppPalette.red), onPressed: () => Navigator.pop(ctx, true), child: const Text('Delete')),
        ],
      ),
    );
    if (ok == true && mounted) await context.read<BookingDraftsProvider>().deleteDraft(d.id);
  }

  String? _draftProblem(BookingDraft d) => BookingDraftsProvider.problemOf(d);

  Widget _pill(IconData icon, String text, Color color, Brightness b) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        decoration: BoxDecoration(color: AppPalette.tint(color, b), borderRadius: BorderRadius.circular(8)),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 13, color: AppPalette.onTint(color, b)),
            const SizedBox(width: 4),
            Flexible(
              child: Text(text, style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w700, color: AppPalette.onTint(color, b))),
            ),
          ],
        ),
      );

  Widget _list(ClinicBookingsProvider provider, BookingDraftsProvider drafts, ColorScheme scheme) {
    final children = <Widget>[];

    if (drafts.drafts.isNotEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 4, 0, 8),
        child: Row(
          children: [
            const Icon(Icons.phone_android_rounded, size: 18, color: AppPalette.black),
            const SizedBox(width: 6),
            Expanded(
              child: Text('Saved on this phone · not submitted', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: scheme.onSurface)),
            ),
            if (drafts.drafts.length > 1)
              TextButton.icon(onPressed: _submitAll, icon: const Icon(Icons.cloud_upload_rounded, size: 18), label: const Text('Submit all')),
          ],
        ),
      ));
      for (final d in drafts.drafts) {
        children.add(Padding(padding: const EdgeInsets.only(bottom: 10), child: _draftCard(d, drafts, scheme)));
      }
      children.add(const SizedBox(height: 10));
      children.add(Padding(
        padding: const EdgeInsets.fromLTRB(4, 0, 0, 8),
        child: Text('Submitted', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 14, color: scheme.onSurface)),
      ));
    }

    if (provider.items.isEmpty) {
      children.add(Padding(
        padding: const EdgeInsets.all(36),
        child: Column(
          children: [
            Icon(Icons.local_shipping_outlined, size: 52, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
            const SizedBox(height: 12),
            Text('No bookings in this range.', style: TextStyle(color: scheme.onSurfaceVariant)),
          ],
        ),
      ));
    } else {
      for (final o in provider.items) {
        children.add(Padding(padding: const EdgeInsets.only(bottom: 8), child: _orderCard(o, scheme)));
      }
    }

    return ListView(
      key: const Key('clinicBookingsList'),
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 96),
      children: children,
    );
  }

  Widget _draftCard(BookingDraft d, BookingDraftsProvider drafts, ColorScheme scheme) {
    final b = Theme.of(context).brightness;
    final problem = _draftProblem(d);
    final busy = drafts.submitting.contains(d.id);

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () => _openForm(draft: d),
        child: Container(
          decoration: const BoxDecoration(border: Border(left: BorderSide(color: AppPalette.black, width: 5))),
          padding: const EdgeInsets.fromLTRB(14, 12, 8, 6),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(d.clinic?.name ?? 'No clinic picked yet',
                        maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                  ),
                  const SizedBox(width: 8),
                  Text(formatMoney(d.total), style: const TextStyle(fontWeight: FontWeight.w800)),
                  const SizedBox(width: 6),
                ],
              ),
              const SizedBox(height: 3),
              Text(
                '${d.items.length} item${d.items.length == 1 ? '' : 's'}'
                '${d.repName != null ? ' · ${d.repName}' : ''}'
                ' · saved ${BookingDraftsProvider.formatWhen(d.updatedAt)}',
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
              ),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _pill(
                    d.queued ? Icons.cloud_sync_rounded : Icons.edit_note_rounded,
                    d.queued ? 'Sends automatically when online' : 'Draft - tap Submit when ready',
                    d.queued ? AppPalette.green : AppPalette.red,
                    b,
                  ),
                  if (problem != null)
                    _pill(Icons.error_outline_rounded, problem, AppPalette.red, b)
                  else if (d.lastError != null && !d.queued)
                    _pill(Icons.error_outline_rounded, d.lastError!, AppPalette.red, b),
                ],
              ),
              Row(
                children: [
                  TextButton.icon(onPressed: () => _openForm(draft: d), icon: const Icon(Icons.edit_rounded, size: 18), label: const Text('Edit')),
                  TextButton.icon(
                    onPressed: () => _deleteDraft(d),
                    style: TextButton.styleFrom(foregroundColor: AppPalette.red),
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete'),
                  ),
                  const Spacer(),
                  FilledButton.tonalIcon(
                    onPressed: problem != null || busy ? null : () => _submitDraft(d),
                    icon: busy
                        ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                        : const Icon(Icons.cloud_upload_rounded, size: 18),
                    label: const Text('Submit'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _orderCard(BookingOrder o, ColorScheme scheme) {
    final statusColor = bookingStatusColor(o.statusName);
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        shape: const Border(),
        title: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(o.clinicName, style: const TextStyle(fontWeight: FontWeight.w700), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    '${o.soNo.isNotEmpty ? o.soNo : "No SO#"} · ${formatShortDate(o.dateOrder)}${o.repName.isNotEmpty ? ' · ${o.repName}' : ''}',
                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(20)),
              child: Text(o.statusName, style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w700, color: statusColor)),
            ),
          ],
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 0, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (o.totalOverdue > 0.01)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text('Overdue: ${formatMoney(o.totalOverdue)} (${o.maxDaysOverdue}d)',
                        style: TextStyle(color: scheme.error, fontWeight: FontWeight.w600, fontSize: 12)),
                  ),
                if (o.hasPriceCorrection)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: TextButton.icon(
                      onPressed: () => _showPriceCorrections(o),
                      icon: const Icon(Icons.info_outline, size: 16),
                      label: const Text('Price corrected - view details'),
                      style: TextButton.styleFrom(padding: EdgeInsets.zero, minimumSize: const Size(0, 32), alignment: Alignment.centerLeft),
                    ),
                  ),
                ...o.lines.map((l) => Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Row(
                        children: [
                          Expanded(child: Text(l.itemCode, style: const TextStyle(fontSize: 13), maxLines: 2, overflow: TextOverflow.ellipsis)),
                          const SizedBox(width: 8),
                          Text('x${l.quantity}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                          const SizedBox(width: 10),
                          Text(formatMoney(l.unitTotal), textAlign: TextAlign.right, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
                        ],
                      ),
                    )),
                const Divider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text('Total', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                    Text(formatMoney(o.grandTotal), style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                if (o.remarks.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text(o.remarks, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontStyle: FontStyle.italic)),
                ],
              ],
            ),
          ),
        ],
      ),
    );
  }
}

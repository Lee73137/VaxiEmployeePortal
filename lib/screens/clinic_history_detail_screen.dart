import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/app_theme.dart';
import '../providers/clinic_history_provider.dart';
import '../models/clinic_history.dart';
import '../utils/formatting.dart';
import 'invoice_items_screen.dart';

class ClinicHistoryDetailScreen extends StatefulWidget {
  final int clinicId;

  const ClinicHistoryDetailScreen({super.key, required this.clinicId});

  @override
  State<ClinicHistoryDetailScreen> createState() => _ClinicHistoryDetailScreenState();
}

class _ClinicHistoryDetailScreenState extends State<ClinicHistoryDetailScreen> {
  ClinicHistoryDetail? _data;
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
      final data = await context.read<ClinicHistoryProvider>().api.get(widget.clinicId);
      setState(() => _data = data);
    } catch (e) {
      setState(() => _error = e.toString());
    }
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: Text(_data?.clinicName ?? 'Clinic History')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(child: Text(_error!, style: TextStyle(color: scheme.error)))
              : _data == null
                  ? const Center(child: Text('Not found'))
                  : RefreshIndicator(
                      onRefresh: _load,
                      child: ListView(
                        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
                        children: [
                          if ((_data!.clinicMunicipality?.isNotEmpty ?? false) || (_data!.clinicAddress?.isNotEmpty ?? false))
                            Padding(
                              padding: const EdgeInsets.only(bottom: 16),
                              child: Text(
                                [_data!.clinicMunicipality, _data!.clinicAddress].where((s) => s != null && s.isNotEmpty).join(' · '),
                                style: TextStyle(color: scheme.onSurfaceVariant),
                              ),
                            ),
                          GridView.count(
                            crossAxisCount: 2,
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            mainAxisSpacing: 10,
                            crossAxisSpacing: 10,
                            childAspectRatio: 1.8,
                            children: [
                              _summaryTile(scheme, 'Total Invoiced', formatMoney(_data!.totalInvoiced), '${_data!.invoices.length} invoice${_data!.invoices.length == 1 ? '' : 's'}'),
                              _summaryTile(scheme, 'Open Balance', formatMoney(_data!.openBalance), 'Total unpaid'),
                              _summaryTile(scheme, 'Total Due', formatMoney(_data!.totalDue), 'Past due date', valueColor: _data!.totalDue > 0.01 ? scheme.error : null),
                              _summaryTile(scheme, 'Total Undue', formatMoney(_data!.totalUndue), 'Not yet due'),
                            ],
                          ),
                          const SizedBox(height: 20),
                          _sectionHeader(scheme, 'Invoices', _data!.invoices.length),
                          const SizedBox(height: 8),
                          if (_data!.invoices.isEmpty)
                            _emptyRow(scheme, 'No invoices found for this clinic.')
                          else
                            ..._data!.invoices.map((inv) => _invoiceCard(context, scheme, inv)),
                          const SizedBox(height: 20),
                          _sectionHeader(scheme, 'Bookings', _data!.bookings.length),
                          const SizedBox(height: 8),
                          if (_data!.bookings.isEmpty)
                            _emptyRow(scheme, 'No bookings found for this clinic.')
                          else
                            ..._data!.bookings.map((b) => _bookingCard(scheme, b)),
                        ],
                      ),
                    ),
    );
  }

  Widget _summaryTile(ColorScheme scheme, String label, String value, String sub, {Color? valueColor}) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Text(value, style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: valueColor)),
            const SizedBox(height: 2),
            Text(sub, style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(ColorScheme scheme, String title, int count) {
    return Row(
      children: [
        Text(title.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
        const SizedBox(width: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
          decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
          child: Text('$count', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
        ),
      ],
    );
  }

  Widget _emptyRow(ColorScheme scheme, String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16),
      child: Center(child: Text(text, style: TextStyle(color: scheme.onSurfaceVariant))),
    );
  }

  Widget _invoiceCard(BuildContext context, ColorScheme scheme, ClinicHistoryInvoice inv) {
    final isPaid = inv.balanceRemaining <= 0;
    final isOverdue = !isPaid && (inv.dueDate?.isBefore(DateTime.now()) ?? false);
    final statusLabel = isPaid ? 'Paid' : (isOverdue ? 'Overdue' : 'Unpaid');
    final statusColor = isPaid ? AppPalette.greenText : (isOverdue ? scheme.error : AppPalette.black);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(builder: (_) => InvoiceItemsScreen(invoiceId: inv.qbExtractedId)),
          );
        },
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
          child: Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(inv.refNumber ?? '—', style: const TextStyle(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 2),
                    Text(
                      '${formatShortDate(inv.txnDate)}${(inv.shipMethod?.isNotEmpty ?? false) ? ' · ${inv.shipMethod}' : ''}',
                      style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(formatMoney(inv.balanceRemaining), style: const TextStyle(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                        decoration: BoxDecoration(color: statusColor.withValues(alpha: 0.15), borderRadius: BorderRadius.circular(8)),
                        child: Text(statusLabel, style: TextStyle(fontSize: 10, color: statusColor, fontWeight: FontWeight.w600)),
                      ),
                      if (inv.isReturned) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                          decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                          child: Text('Returned', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
              Icon(Icons.chevron_right, size: 18, color: scheme.onSurfaceVariant.withValues(alpha: 0.6)),
            ],
          ),
        ),
      ),
    );
  }

  Widget _bookingCard(ColorScheme scheme, ClinicHistoryBooking b) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(b.itemCode ?? '—', style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    'SO ${b.sono ?? '—'} · ${formatShortDate(b.dateOrder)}${(b.repName?.isNotEmpty ?? false) ? ' · ${b.repName}' : ''}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text('Qty ${b.quantity ?? 0}', style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 2),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                  child: Text(b.statusName ?? 'Unknown', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

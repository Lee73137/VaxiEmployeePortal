import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sales_pivot.dart';
import '../providers/sales_pivot_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatting.dart';
import '../widgets/module_widgets.dart';
import '../widgets/report_table.dart';
import 'invoice_items_screen.dart';

const _color = AppPalette.red;

/// Sales Pivot Report - same table as vaxiCSR's: one row per clinic with
/// Sales Rep, Location, one column per month in the range and a row Total,
/// plus the Grand Total row. Tap a clinic for its invoices in the range,
/// then an invoice for its items (vaxiCSR's two modals).
class SalesPivotScreen extends StatefulWidget {
  const SalesPivotScreen({super.key});

  @override
  State<SalesPivotScreen> createState() => _SalesPivotScreenState();
}

class _SalesPivotScreenState extends State<SalesPivotScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesPivotProvider>().ensureOptionsLoaded();
    });
  }

  void _openFilters() {
    final p = context.read<SalesPivotProvider>();
    if (p.startDate == null || p.endDate == null) {
      final now = DateTime.now();
      p.setDateRange(DateTime(now.year, 1, 1), DateTime(now.year, now.month, now.day));
    }
    showFilterSheet(
      context,
      color: _color,
      title: 'Filters',
      onReset: () {
        p.clearFilters();
        final now = DateTime.now();
        p.setDateRange(DateTime(now.year, 1, 1), DateTime(now.year, now.month, now.day));
      },
      onApply: p.refresh,
      sections: (ctx, setSheetState) => [
        FilterSection(
          label: 'Date range',
          hint: 'One column per month in this range.',
          child: DateRangeFields(
            from: p.startDate,
            to: p.endDate,
            color: _color,
            onFrom: (d) => setSheetState(() => p.setDateRange(d, p.endDate!.isBefore(d) ? d : p.endDate!)),
            onTo: (d) => setSheetState(() => p.setDateRange(p.startDate!.isAfter(d) ? d : p.startDate!, d)),
          ),
        ),
        FilterSection(
          label: 'Sales Rep(s)',
          hint: 'Leave empty for all reps.',
          child: SearchableMultiSelect(
            options: p.repOptions,
            selected: p.selectedReps,
            onToggle: (r) => setSheetState(() => p.toggleRep(r)),
            hint: 'Search sales rep…',
            color: _color,
          ),
        ),
        FilterSection(
          label: 'Consistency',
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Theme.of(ctx).colorScheme.outlineVariant.withValues(alpha: 0.6)),
            ),
            child: SwitchListTile(
              value: p.onlyEveryMonth,
              activeThumbColor: _color,
              onChanged: (v) => setSheetState(() => p.setOnlyEveryMonth(v)),
              title: const Text('Only clinics that bought every month', style: TextStyle(fontWeight: FontWeight.w700, fontSize: 14)),
              subtitle: const Text('Drop any clinic with a gap'),
            ),
          ),
        ),
      ],
    );
  }

  Future<void> _showClinicInvoices(SalesPivotRow row) async {
    final p = context.read<SalesPivotProvider>();
    if (p.startDate == null || p.endDate == null) return;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.7,
        minChildSize: 0.4,
        maxChildSize: 0.95,
        expand: false,
        builder: (ctx, scroll) => FutureBuilder<List<SalesPivotInvoice>>(
          future: p.api.clinicInvoices(row.clinicName, p.startDate!, p.endDate!),
          builder: (ctx, snap) {
            final scheme = Theme.of(ctx).colorScheme;
            final invoices = snap.data ?? const [];
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Row(
                  children: [
                    const IconWellSmall(icon: Icons.receipt_long_rounded, color: _color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(row.clinicName, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                          Text(
                            '${formatShortDate(p.startDate)} – ${formatShortDate(p.endDate)} · ${formatMoney(row.rowTotal)}',
                            style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 32), child: Center(child: CircularProgressIndicator()))
                else if (snap.hasError)
                  Text('${snap.error}', style: TextStyle(color: scheme.error))
                else if (invoices.isEmpty)
                  Text('No invoices in this range.', style: TextStyle(color: scheme.onSurfaceVariant))
                else
                  Card(
                    child: Column(
                      children: [
                        for (var i = 0; i < invoices.length; i++) ...[
                          if (i > 0) Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.4)),
                          ListTile(
                            title: Text(invoices[i].refNumber?.trim() ?? '—', style: const TextStyle(fontWeight: FontWeight.w700)),
                            subtitle: Text(formatShortDate(invoices[i].txnDate)),
                            trailing: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              crossAxisAlignment: CrossAxisAlignment.end,
                              children: [
                                Text(formatMoney(invoices[i].subtotal), style: const TextStyle(fontWeight: FontWeight.w800)),
                                if (invoices[i].balanceRemaining > 0)
                                  Text('Bal ${formatMoney(invoices[i].balanceRemaining)}',
                                      style: const TextStyle(fontSize: 11.5, color: AppPalette.red, fontWeight: FontWeight.w700)),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(ctx).pop();
                              Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceItemsScreen(invoiceId: invoices[i].qbExtractedId)));
                            },
                          ),
                        ],
                      ],
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SalesPivotProvider>();
    final active = p.selectedReps.length + (p.onlyEveryMonth ? 1 : 0);

    return Scaffold(
      body: Column(
        children: [
          ModuleHero(
            title: 'Sales Pivot Report',
            subtitle: 'Each clinic\'s sales per month across a date range, with row and grand totals',
            icon: Icons.pivot_table_chart_rounded,
            color: _color,
            actions: [HeroPillButton(icon: Icons.tune_rounded, label: 'Filters', color: _color, badge: active, onPressed: _openFilters)],
            bottom: p.generated && p.startDate != null
                ? HeroFilterChips(labels: [
                    '${formatShortDate(p.startDate)} – ${formatShortDate(p.endDate)}',
                    p.selectedReps.isEmpty ? 'All reps' : '${p.selectedReps.length} rep${p.selectedReps.length == 1 ? '' : 's'}',
                    if (p.onlyEveryMonth) 'Bought every month',
                  ])
                : null,
          ),
          Expanded(child: _body(p)),
        ],
      ),
    );
  }

  Widget _body(SalesPivotProvider p) {
    if (p.isLoading) return const Center(child: CircularProgressIndicator());
    if (p.errorMessage != null) {
      return EmptyStateCard(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load the report',
        message: p.errorMessage!,
        color: AppPalette.red,
        action: FilledButton(onPressed: p.refresh, child: const Text('Try again')),
      );
    }
    if (!p.generated) {
      return EmptyStateCard(
        icon: Icons.date_range_rounded,
        title: 'Generate the report',
        message: 'Pick a Start Date and End Date, then tap "Generate Report".',
        color: _color,
        action: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: _color),
          onPressed: _openFilters,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Choose dates'),
        ),
      );
    }
    if (p.rows.isEmpty) {
      return EmptyStateCard(icon: Icons.bar_chart_rounded, title: 'No results', message: 'No invoices found for this date range.', color: _color);
    }

    final columns = <ReportColumn>[
      const ReportColumn(86, numeric: false),
      const ReportColumn(124, numeric: false),
      for (var i = 0; i < p.months.length; i++) ReportColumn(132, dividerBefore: i == 0),
      const ReportColumn(140, dividerBefore: true),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        children: [
          ReportToolbar(
            summary: '${p.rows.length} clinic${p.rows.length == 1 ? '' : 's'} · ${p.months.length} month${p.months.length == 1 ? '' : 's'}'
                '${p.onlyEveryMonth ? ' · bought every month' : ''} · tap a clinic for its invoices',
          ),
          Expanded(
            child: ReportTable(
              accent: _color,
              frozenColumns: const [ReportColumn(176, numeric: false)],
              frozenHeaders: const ['Clinic'],
              columns: columns,
              headerRows: [
                [
                  const ReportHeaderCell('Sales Rep'),
                  const ReportHeaderCell('Location'),
                  for (final m in p.months) ReportHeaderCell(m.label),
                  const ReportHeaderCell('Total'),
                ],
              ],
              rowCount: p.rows.length,
              rowBuilder: (i) {
                final r = p.rows[i];
                return ReportRow(
                  onTap: () => _showClinicInvoices(r),
                  frozen: [ReportCell(r.clinicName, bold: true)],
                  cells: [
                    ReportCell(r.salesRep ?? '—', muted: true),
                    ReportCell(r.location ?? '—', muted: true),
                    for (final a in r.monthlyAmounts) ReportCell(tableMoney(a), muted: a == 0),
                    ReportCell(formatMoney(r.rowTotal), bold: true),
                  ],
                );
              },
              footer: ReportRow(
                frozen: const [ReportCell('Grand Total')],
                cells: [
                  const ReportCell(''),
                  const ReportCell(''),
                  for (final a in p.grandTotalsByMonth) ReportCell(formatMoney(a)),
                  ReportCell(formatMoney(p.grandTotal)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

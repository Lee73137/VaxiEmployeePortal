import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/performance.dart';
import '../providers/auth_provider.dart';
import '../providers/performance_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatting.dart';
import '../widgets/module_widgets.dart';
import '../widgets/report_table.dart';
import '../widgets/sales_trend_chart.dart';

const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _color = AppPalette.red;

// vaxiCSR's cell legend: Sales / Actual Visit / Virtual Visit.
const _saleColor = AppPalette.greenText;
const _actualColor = AppPalette.black;
const _virtualColor = AppPalette.red;

/// Performance Monitoring - vaxiCSR's page split over two tabs: Overview
/// (the four summary tiles + Monthly Sales Trend chart: one "Total" line
/// when no rep is picked, otherwise a line per rep with its target bars)
/// and Clinic Performance (Clinic, Location, TSR, Jan-Dec as
/// "sales / actual / virtual", Grand Total; tap a month for visit remarks).
class PerformanceScreen extends StatefulWidget {
  final int initialTab;

  const PerformanceScreen({super.key, this.initialTab = 0});

  @override
  State<PerformanceScreen> createState() => _PerformanceScreenState();
}

class _PerformanceScreenState extends State<PerformanceScreen> {
  String? get _username => context.read<AuthProvider>().userName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PerformanceProvider>().ensureOptionsLoaded(_username);
    });
  }

  void _openFilters() {
    final p = context.read<PerformanceProvider>();
    showFilterSheet(
      context,
      color: _color,
      title: 'Filters',
      onReset: p.clearFilters,
      onApply: () => p.refresh(_username, generate: true),
      sections: (ctx, setSheetState) => [
        FilterSection(
          label: 'Year',
          child: Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              for (final y in (p.yearOptions.isEmpty ? [DateTime.now().year] : p.yearOptions))
                ChoiceChip(
                  label: Text('$y'),
                  selected: p.year == y,
                  showCheckmark: false,
                  selectedColor: AppPalette.tint(_color, Theme.of(ctx).brightness),
                  labelStyle: TextStyle(fontWeight: FontWeight.w800, color: p.year == y ? AppPalette.onTint(_color, Theme.of(ctx).brightness) : null),
                  onSelected: (_) => setSheetState(() => p.setYear(y)),
                ),
            ],
          ),
        ),
        FilterSection(
          label: 'Sales Rep',
          hint: p.repFilterLocked ? 'Your account is locked to your own rep.' : 'Leave empty for all reps (one combined "Total" line on the chart).',
          child: p.repFilterLocked
              ? const SizedBox.shrink()
              : SearchableMultiSelect(
                  options: p.repOptions,
                  selected: p.selectedReps,
                  onToggle: (r) => setSheetState(() => p.toggleRep(r)),
                  hint: 'Search sales rep…',
                  color: _color,
                ),
        ),
        FilterSection(
          label: 'Location',
          hint: 'Leave empty for all locations.',
          child: SearchableMultiSelect(
            options: p.locationOptions,
            selected: p.selectedLocations,
            onToggle: (l) => setSheetState(() => p.toggleLocation(l)),
            hint: 'Search locations…',
            color: _color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<PerformanceProvider>();
    final active = p.selectedReps.length + p.selectedLocations.length;

    return DefaultTabController(
      length: 2,
      initialIndex: widget.initialTab,
      child: Scaffold(
        body: Column(
          children: [
            ModuleHero(
              title: 'Performance Monitoring',
              subtitle: 'Monthly sales and clinic visits per rep, against target',
              icon: Icons.speed_rounded,
              color: _color,
              actions: [HeroPillButton(icon: Icons.tune_rounded, label: 'Filters', color: _color, badge: active, onPressed: _openFilters)],
              bottom: p.generated
                  ? HeroFilterChips(labels: [
                      '${p.year}',
                      p.repFilterLocked
                          ? 'Own rep only'
                          : (p.selectedReps.isEmpty ? 'All reps' : p.selectedReps.join(', ')),
                      p.selectedLocations.isEmpty ? 'All locations' : '${p.selectedLocations.length} location${p.selectedLocations.length == 1 ? '' : 's'}',
                    ])
                  : null,
            ),
            Expanded(child: _body(p)),
          ],
        ),
      ),
    );
  }

  Widget _body(PerformanceProvider p) {
    if (p.isLoading) return const Center(child: CircularProgressIndicator());
    if (p.errorMessage != null) {
      return EmptyStateCard(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load the report',
        message: p.errorMessage!,
        color: AppPalette.red,
        action: FilledButton(onPressed: () => p.refresh(_username, generate: p.generated), child: const Text('Try again')),
      );
    }
    if (!p.generated) {
      return EmptyStateCard(
        icon: Icons.speed_rounded,
        title: 'Generate the report',
        message: 'Pick a year (and optionally a Sales Rep / Location), then tap "Generate Report".',
        color: _color,
        action: FilledButton.icon(
          style: FilledButton.styleFrom(backgroundColor: _color),
          onPressed: _openFilters,
          icon: const Icon(Icons.tune_rounded),
          label: const Text('Choose filters'),
        ),
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        TabBar(
          labelColor: _color,
          indicatorColor: _color,
          unselectedLabelColor: scheme.onSurfaceVariant,
          tabs: [
            const Tab(text: 'Overview'),
            Tab(text: 'Clinic Performance (${p.rows.length})'),
          ],
        ),
        Expanded(child: TabBarView(children: [_overview(p), _table(p)])),
      ],
    );
  }

  List<TrendSeries> _series(PerformanceProvider p) {
    final pickedReps = p.repFilterLocked || p.selectedReps.isNotEmpty;
    if (!pickedReps) {
      return [TrendSeries(name: 'Total', values: p.monthlySalesTotals, color: trendPalette[0])];
    }
    final names = p.monthlySalesByRep.keys.toList()..sort();
    return [
      for (var i = 0; i < names.length; i++)
        TrendSeries(
          name: names[i],
          values: p.monthlySalesByRep[names[i]]!,
          color: trendPalette[i % trendPalette.length],
          target: p.targetMonthByRep[names[i]],
        ),
    ];
  }

  Widget _overview(PerformanceProvider p) {
    final scheme = Theme.of(context).colorScheme;
    return ListView(
      padding: const EdgeInsets.fromLTRB(14, 16, 14, 24),
      children: [
        Row(
          children: [
            Expanded(child: _Tile(label: 'Total Sales', value: formatMoney(p.totalSales), icon: Icons.payments_rounded, color: _saleColor)),
            const SizedBox(width: 10),
            Expanded(
              child: _Tile(
                label: 'Visits (actual / virtual)',
                value: '${_n(p.totalActualVisits)} / ${_n(p.totalVirtualVisits)}',
                icon: Icons.directions_walk_rounded,
                color: _actualColor,
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(child: _Tile(label: 'Visit Coverage', value: '${p.coveragePercent}%', icon: Icons.radar_rounded, color: AppPalette.black)),
            const SizedBox(width: 10),
            Expanded(child: _Tile(label: 'Clinics Monitored', value: _n(p.clinicCount), icon: Icons.local_hospital_rounded, color: AppPalette.green)),
          ],
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Expanded(child: Text('Monthly Sales Trend', style: TextStyle(fontSize: 15.5, fontWeight: FontWeight.w800))),
                    Text('${p.year}', style: TextStyle(fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                  ],
                ),
                const SizedBox(height: 14),
                SalesTrendChart(series: _series(p)),
                const SizedBox(height: 6),
                Row(
                  children: [
                    Icon(Icons.zoom_in_rounded, size: 15, color: scheme.onSurfaceVariant),
                    const SizedBox(width: 4),
                    Text('Tap the chart to view it larger', style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _table(PerformanceProvider p) {
    if (p.rows.isEmpty) {
      return const EmptyStateCard(icon: Icons.local_hospital_rounded, title: 'No clinics', message: 'No clinics match these filters.', color: _color);
    }
    final scheme = Theme.of(context).colorScheme;

    Widget legendDot(Color c, String l) => Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 9, height: 9, decoration: BoxDecoration(color: c, shape: BoxShape.circle)),
            const SizedBox(width: 5),
            Text(l, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700)),
          ],
        );

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(4, 0, 4, 10),
            child: Row(
              children: [
                legendDot(_saleColor, 'Sales'),
                const SizedBox(width: 14),
                legendDot(_actualColor, 'Actual visit'),
                const SizedBox(width: 14),
                legendDot(_virtualColor, 'Virtual visit'),
                const Spacer(),
                Text('Tap a month', style: TextStyle(fontSize: 11.5, color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
          Expanded(
            child: ReportTable(
              accent: _color,
              frozenColumns: const [ReportColumn(176, numeric: false)],
              frozenHeaders: const ['Clinic Name'],
              columns: [
                const ReportColumn(124, numeric: false),
                const ReportColumn(66, numeric: false),
                for (var m = 0; m < 12; m++) ReportColumn(132, dividerBefore: m == 0),
                const ReportColumn(140, dividerBefore: true),
              ],
              headerRows: [
                [
                  const ReportHeaderCell('Location'),
                  const ReportHeaderCell('TSR'),
                  for (final m in _monthNames) ReportHeaderCell(m),
                  const ReportHeaderCell('Grand Total'),
                ],
              ],
              rowCount: p.rows.length,
              rowBuilder: (i) {
                final r = p.rows[i];
                return ReportRow(
                  frozen: [ReportCell(r.clinicName, bold: true)],
                  cells: [
                    ReportCell(r.location ?? '—', muted: true),
                    ReportCell(r.repCode ?? '—', muted: true),
                    for (var m = 0; m < 12; m++) _monthCell(r, m),
                    ReportCell(formatMoney(r.grandTotal), bold: true),
                  ],
                );
              },
              footer: ReportRow(
                frozen: const [ReportCell('Grand Total')],
                cells: [
                  const ReportCell(''),
                  const ReportCell(''),
                  for (var m = 0; m < 12; m++)
                    ReportCell(m < p.monthlySalesTotals.length && p.monthlySalesTotals[m] != 0 ? formatMoney(p.monthlySalesTotals[m]) : ''),
                  ReportCell(formatMoney(p.totalSales)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  ReportCell _monthCell(PerformanceRow r, int m) {
    if (m >= r.months.length) return const ReportCell('');
    final c = r.months[m];
    if (c.sale == null && c.actualVisits == 0 && c.virtualVisits == 0) return const ReportCell('');
    const style = TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, fontFeatures: [FontFeature.tabularFigures()]);
    final parts = <TextSpan>[
      if (c.sale != null) TextSpan(text: _n(c.sale!.round()), style: style.copyWith(color: _saleColor)),
      if (c.actualVisits > 0) ...[
        if (c.sale != null) const TextSpan(text: ' / '),
        TextSpan(text: '${c.actualVisits}', style: style.copyWith(color: _actualColor)),
      ],
      if (c.virtualVisits > 0) ...[
        if (c.sale != null || c.actualVisits > 0) const TextSpan(text: ' / '),
        TextSpan(text: '${c.virtualVisits}', style: style.copyWith(color: _virtualColor)),
      ],
    ];
    return ReportCell(
      '',
      child: Text.rich(TextSpan(children: parts), maxLines: 1, overflow: TextOverflow.ellipsis),
      onTap: () => _showRemarks(r, m),
    );
  }

  Future<void> _showRemarks(PerformanceRow row, int monthIndex) async {
    final p = context.read<PerformanceProvider>();
    if (row.repCode == null || row.repCode!.isEmpty) return;
    final scheme = Theme.of(context).colorScheme;

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: scheme.surfaceContainer,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.6,
        minChildSize: 0.3,
        maxChildSize: 0.9,
        expand: false,
        builder: (ctx, scroll) => FutureBuilder<List<ClinicVisitRemark>>(
          future: p.api.clinicRemarks(repCode: row.repCode!, clinicName: row.clinicName, month: monthIndex + 1, year: p.year),
          builder: (ctx, snap) {
            final remarks = snap.data ?? const [];
            final cell = monthIndex < row.months.length ? row.months[monthIndex] : null;
            return ListView(
              controller: scroll,
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
              children: [
                Row(
                  children: [
                    const IconWellSmall(icon: Icons.chat_rounded, color: _color),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Visit Remarks', style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
                          Text('${row.clinicName} — ${_monthNames[monthIndex]} ${p.year}',
                              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800)),
                        ],
                      ),
                    ),
                  ],
                ),
                if (cell != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      _Chip(label: 'Sales', value: cell.sale == null ? '—' : formatMoney(cell.sale), color: _saleColor),
                      const SizedBox(width: 8),
                      _Chip(label: 'Actual', value: '${cell.actualVisits}', color: _actualColor),
                      const SizedBox(width: 8),
                      _Chip(label: 'Virtual', value: '${cell.virtualVisits}', color: _virtualColor),
                    ],
                  ),
                ],
                const SizedBox(height: 16),
                if (snap.connectionState == ConnectionState.waiting)
                  const Padding(padding: EdgeInsets.symmetric(vertical: 24), child: Center(child: CircularProgressIndicator()))
                else if (snap.hasError)
                  Text('${snap.error}', style: TextStyle(color: scheme.error))
                else if (remarks.isEmpty)
                  Text('No visit remarks on file for this month.', style: TextStyle(color: scheme.onSurfaceVariant))
                else
                  for (final r in remarks)
                    Card(
                      margin: const EdgeInsets.only(bottom: 10),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                const Icon(Icons.schedule_rounded, size: 15, color: _actualColor),
                                const SizedBox(width: 5),
                                Text(formatShortDate(r.arrivalTime), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 13)),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(r.remarks?.isNotEmpty == true ? r.remarks! : '(no remarks entered)', style: const TextStyle(height: 1.4)),
                          ],
                        ),
                      ),
                    ),
              ],
            );
          },
        ),
      ),
    );
  }
}

String _n(int v) {
  final s = v.abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

class _Tile extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;

  const _Tile({required this.label, required this.value, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      clipBehavior: Clip.antiAlias,
      child: Container(
        decoration: BoxDecoration(border: Border(top: BorderSide(color: color, width: 4))),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            IconWellSmall(icon: icon, color: color),
            const SizedBox(height: 10),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
            ),
            const SizedBox(height: 2),
            Text(label, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
          ],
        ),
      ),
    );
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _Chip({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(color: AppPalette.tint(color, b), borderRadius: BorderRadius.circular(12)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppPalette.onTint(color, b))),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

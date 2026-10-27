import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/sales_summary.dart';
import '../providers/sales_summary_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/module_widgets.dart';
import '../widgets/report_table.dart';

const _monthNames = ['Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun', 'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec'];
const _color = AppPalette.red;

/// Sales Summary (Monthly) - same table as vaxiCSR's page: customers grouped
/// by Sales Rep + Location under collapsible group rows (with group totals),
/// Jan-Dec with one sub-column per compared year, and a Grand Total row.
/// The phone pins one column (vaxiCSR pins three): group rows carry the
/// "Rep - Location" label there, detail rows the customer - the web table
/// leaves Rep/Location blank on detail rows anyway.
class SalesSummaryScreen extends StatefulWidget {
  const SalesSummaryScreen({super.key});

  @override
  State<SalesSummaryScreen> createState() => _SalesSummaryScreenState();
}

class _Group {
  final String rep;
  final String location;
  final List<SalesSummaryRow> rows;

  _Group(this.rep, this.location, this.rows);
}

class _SalesSummaryScreenState extends State<SalesSummaryScreen> {
  final Set<int> _expanded = {};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<SalesSummaryProvider>().ensureOptionsLoaded();
    });
  }

  List<_Group> _groups(List<SalesSummaryRow> rows) {
    final groups = <_Group>[];
    for (final r in rows) {
      final rep = r.salesRep ?? '';
      final loc = r.location ?? '';
      if (groups.isEmpty || groups.last.rep != rep || groups.last.location != loc) {
        groups.add(_Group(rep, loc, []));
      }
      groups.last.rows.add(r);
    }
    return groups;
  }

  void _openFilters() {
    final p = context.read<SalesSummaryProvider>();
    showFilterSheet(
      context,
      color: _color,
      title: 'Filters',
      onReset: () {
        p.clearFilters();
        p.setYear(DateTime.now().year);
      },
      onApply: () {
        _expanded.clear();
        p.refresh(generate: true);
      },
      sections: (ctx, setSheetState) {
        final y = p.year;
        final shown = [y - 1, y, if (y + 1 <= DateTime.now().year) y + 1];
        return [
          FilterSection(
            label: 'Year',
            hint: 'Shows ${shown.join(' / ')}',
            child: YearStepper(year: p.year, color: _color, onChanged: (v) => setSheetState(() => p.setYear(v))),
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
            label: 'Location(s)',
            hint: 'Leave empty for all locations.',
            child: SearchableMultiSelect(
              options: p.locationOptions,
              selected: p.selectedLocations,
              onToggle: (l) => setSheetState(() => p.toggleLocation(l)),
              hint: 'Search locations…',
              color: _color,
            ),
          ),
        ];
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<SalesSummaryProvider>();
    final active = p.selectedReps.length + p.selectedLocations.length;
    final yearsLabel = p.years.isEmpty ? '${p.year - 1} / ${p.year}' : p.years.join(' / ');

    return Scaffold(
      body: Column(
        children: [
          ModuleHero(
            title: 'Sales Summary',
            subtitle: 'Every customer\'s sales by month, comparing $yearsLabel side by side - grouped by Sales Rep and Location',
            icon: Icons.calendar_month_rounded,
            color: _color,
            actions: [HeroPillButton(icon: Icons.tune_rounded, label: 'Filters', color: _color, badge: active, onPressed: _openFilters)],
            bottom: p.generated
                ? HeroFilterChips(labels: [
                    'Year ${p.year}',
                    p.selectedReps.isEmpty ? 'All reps' : '${p.selectedReps.length} rep${p.selectedReps.length == 1 ? '' : 's'}',
                    p.selectedLocations.isEmpty ? 'All locations' : '${p.selectedLocations.length} location${p.selectedLocations.length == 1 ? '' : 's'}',
                  ])
                : null,
          ),
          Expanded(child: _body(p)),
        ],
      ),
    );
  }

  Widget _body(SalesSummaryProvider p) {
    if (p.isLoading) return const Center(child: CircularProgressIndicator());
    if (p.errorMessage != null) {
      return EmptyStateCard(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load the report',
        message: p.errorMessage!,
        color: AppPalette.red,
        action: FilledButton(onPressed: () => p.refresh(generate: p.generated), child: const Text('Try again')),
      );
    }
    if (!p.generated) {
      return EmptyStateCard(
        icon: Icons.calendar_month_rounded,
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
    if (p.rows.isEmpty) {
      return EmptyStateCard(icon: Icons.bar_chart_rounded, title: 'No results', message: 'No customers match the current filters.', color: _color);
    }

    final groups = _groups(p.rows);
    final years = p.years;

    // Flatten into what's on screen: every group row, plus its customers when expanded.
    final items = <Object>[];
    for (var gi = 0; gi < groups.length; gi++) {
      items.add(gi);
      if (_expanded.contains(gi)) items.addAll(groups[gi].rows);
    }

    double amount(SalesSummaryRow r, int y, int m) {
      for (final ya in r.monthlySalesByYear) {
        if (ya.year == y) return m < ya.monthlyAmounts.length ? ya.monthlyAmounts[m] : 0;
      }
      return 0;
    }

    final columns = <ReportColumn>[
      for (var m = 0; m < 12; m++)
        for (var yi = 0; yi < years.length; yi++) ReportColumn(132, dividerBefore: yi == 0),
    ];

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 14, 12, 12),
      child: Column(
        children: [
          ReportToolbar(
            summary: '${groups.length} group${groups.length == 1 ? '' : 's'} · ${p.rows.length} customer${p.rows.length == 1 ? '' : 's'}',
            actions: [
              TextButton.icon(
                onPressed: () => setState(() => _expanded.addAll(List.generate(groups.length, (i) => i))),
                icon: const Icon(Icons.unfold_more_rounded, size: 18),
                label: const Text('Expand all'),
              ),
              TextButton.icon(
                onPressed: () => setState(_expanded.clear),
                icon: const Icon(Icons.unfold_less_rounded, size: 18),
                label: const Text('Collapse'),
              ),
            ],
          ),
          Expanded(
            child: ReportTable(
              accent: _color,
              frozenColumns: const [ReportColumn(196, numeric: false)],
              frozenHeaders: const ['Customer'],
              columns: columns,
              headerRows: [
                [for (final m in _monthNames) ReportHeaderCell(m, span: years.length)],
                if (years.length > 1) [for (var m = 0; m < 12; m++) for (final y in years) ReportHeaderCell('$y')],
              ],
              rowCount: items.length,
              rowBuilder: (i) {
                final item = items[i];
                if (item is int) {
                  final g = groups[item];
                  final open = _expanded.contains(item);
                  return ReportRow(
                    kind: ReportRowKind.group,
                    expanded: open,
                    onTap: () => setState(() => open ? _expanded.remove(item) : _expanded.add(item)),
                    frozen: [
                      ReportCell(
                        '${g.rep.isEmpty ? '—' : g.rep} · ${g.location} (${g.rows.length})',
                        leading: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(open ? Icons.expand_more_rounded : Icons.chevron_right_rounded, size: 18, color: _color),
                            const SizedBox(width: 2),
                            _RepAvatar(rep: g.rep),
                          ],
                        ),
                      ),
                    ],
                    cells: [
                      for (var m = 0; m < 12; m++)
                        for (final y in years) ReportCell(tableMoney(g.rows.fold(0.0, (s, r) => s + amount(r, y, m)))),
                    ],
                  );
                }
                final r = item as SalesSummaryRow;
                return ReportRow(
                  frozen: [ReportCell(r.customerName)],
                  cells: [
                    for (var m = 0; m < 12; m++)
                      for (final y in years) ReportCell(tableMoney(amount(r, y, m)), muted: amount(r, y, m) == 0),
                  ],
                );
              },
              footer: ReportRow(
                frozen: const [ReportCell('Grand Total')],
                cells: [
                  for (var m = 0; m < 12; m++)
                    for (final y in years)
                      ReportCell(formatMoneyFor(p.grandTotalsByYear, y, m)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

String formatMoneyFor(List<SalesSummaryYearAmounts> totals, int year, int month) {
  for (final t in totals) {
    if (t.year == year) return tableMoney(month < t.monthlyAmounts.length ? t.monthlyAmounts[month] : 0);
  }
  return tableMoney(0);
}

class _RepAvatar extends StatelessWidget {
  final String rep;

  const _RepAvatar({required this.rep});

  @override
  Widget build(BuildContext context) {
    final initial = rep.trim().isEmpty ? '?' : rep.trim().substring(0, 1).toUpperCase();
    return Container(
      width: 22,
      height: 22,
      decoration: const BoxDecoration(color: _color, shape: BoxShape.circle),
      alignment: Alignment.center,
      child: Text(initial, style: const TextStyle(color: Colors.white, fontSize: 10.5, fontWeight: FontWeight.w800)),
    );
  }
}

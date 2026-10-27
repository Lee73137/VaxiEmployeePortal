import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/product_sales.dart';
import '../providers/auth_provider.dart';
import '../providers/product_sales_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatting.dart';
import '../widgets/module_widgets.dart';
import '../widgets/report_table.dart';
import 'invoice_items_screen.dart';

const _color = AppPalette.red;
const _vaxishApp = 'VAXISHAPP';
const _vaxihub = 'VAXIHUB';

/// Product Sales Report - vaxiCSR's page: the four summary tiles (Total
/// Sales, Uncollected, VaxiShApp, VaxiHub) and its five tabs - All Items,
/// then Per Customer / Per Item for each channel. OTHERS opens its line
/// items; a customer opens their invoices with each invoice's items.
class ProductSalesScreen extends StatefulWidget {
  /// Which of the five tabs opens first (0 = All Items).
  final int initialTab;

  const ProductSalesScreen({super.key, this.initialTab = 0});

  @override
  State<ProductSalesScreen> createState() => _ProductSalesScreenState();
}

class _ProductSalesScreenState extends State<ProductSalesScreen> {
  String? get _username => context.read<AuthProvider>().userName;

  void _openFilters() {
    final p = context.read<ProductSalesProvider>();
    if (p.dateFrom == null || p.dateTo == null) {
      final now = DateTime.now();
      p.setDateRange(DateTime(now.year, now.month, 1), DateTime(now.year, now.month, now.day));
    }
    showFilterSheet(
      context,
      color: _color,
      title: 'Filters',
      onReset: p.clearFilters,
      onApply: () => p.refresh(_username, generate: true),
      sections: (ctx, setSheetState) => [
        FilterSection(
          label: 'Date range',
          child: DateRangeFields(
            from: p.dateFrom,
            to: p.dateTo,
            color: _color,
            onFrom: (d) => setSheetState(() => p.setDateRange(d, p.dateTo!.isBefore(d) ? d : p.dateTo!)),
            onTo: (d) => setSheetState(() => p.setDateRange(p.dateFrom!.isAfter(d) ? d : p.dateFrom!, d)),
          ),
        ),
        FilterSection(
          label: 'Filter by Sales Agent',
          hint: p.repFilterLocked
              ? 'Your account is locked to your own rep.'
              : (p.repOptions.isEmpty ? 'Generate once to load the agent list. Leave empty for all.' : 'Leave empty for all agents.'),
          child: p.repFilterLocked
              ? const SizedBox.shrink()
              : SearchableMultiSelect(
                  options: p.repOptions,
                  selected: p.selectedReps,
                  onToggle: (r) => setSheetState(() => p.toggleRep(r)),
                  hint: 'Search sales agent…',
                  color: _color,
                ),
        ),
        FilterSection(
          label: 'Filter by Product Prefix',
          hint: p.prefixOptions.isEmpty ? 'Generate once to load the prefix list. Leave empty for all.' : 'Leave empty for all prefixes.',
          child: SearchableMultiSelect(
            options: p.prefixOptions,
            selected: p.selectedPrefixes,
            onToggle: (x) => setSheetState(() => p.togglePrefix(x)),
            hint: 'Search prefix (e.g. MV_)…',
            color: _color,
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final p = context.watch<ProductSalesProvider>();
    final active = p.selectedReps.length + p.selectedPrefixes.length;

    return DefaultTabController(
      length: 5,
      initialIndex: widget.initialTab,
      child: Scaffold(
        body: Column(
          children: [
            ModuleHero(
              title: 'Product Sales Report',
              subtitle: 'Item-level sales split by VaxiShApp and VaxiHub',
              icon: Icons.bar_chart_rounded,
              color: _color,
              actions: [HeroPillButton(icon: Icons.tune_rounded, label: 'Filters', color: _color, badge: active, onPressed: _openFilters)],
              bottom: p.generated && p.dateFrom != null
                  ? HeroFilterChips(labels: [
                      '${formatShortDate(p.dateFrom)} – ${formatShortDate(p.dateTo)}',
                      p.repFilterLocked
                          ? 'Own rep only'
                          : (p.selectedReps.isEmpty ? 'All agents' : '${p.selectedReps.length} agent${p.selectedReps.length == 1 ? '' : 's'}'),
                      p.selectedPrefixes.isEmpty ? 'All prefixes' : '${p.selectedPrefixes.length} prefix${p.selectedPrefixes.length == 1 ? '' : 'es'}',
                    ])
                  : null,
            ),
            Expanded(child: _body(p)),
          ],
        ),
      ),
    );
  }

  Widget _body(ProductSalesProvider p) {
    if (p.isLoading) return const Center(child: CircularProgressIndicator());
    if (p.errorMessage != null) {
      return EmptyStateCard(
        icon: Icons.cloud_off_rounded,
        title: 'Couldn\'t load the report',
        message: p.errorMessage!,
        color: AppPalette.red,
        action: FilledButton(onPressed: () => p.refresh(_username, generate: true), child: const Text('Try again')),
      );
    }
    if (!p.generated) {
      return EmptyStateCard(
        icon: Icons.bar_chart_rounded,
        title: 'Generate the report',
        message: 'Pick a date range, then tap "Generate Report" to see item-level sales.',
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
      return EmptyStateCard(
        icon: Icons.bar_chart_rounded,
        title: 'No sales found',
        message: 'No sales found for these filters between ${formatShortDate(p.dateFrom)} and ${formatShortDate(p.dateTo)}.',
        color: _color,
      );
    }

    final scheme = Theme.of(context).colorScheme;
    return Column(
      children: [
        SizedBox(
          height: 108,
          child: ListView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 14, 12, 4),
            children: [
              _SummaryTile(label: 'Total Sales', value: formatMoney(p.totalSales), sub: '${formatShortDate(p.dateFrom)} – ${formatShortDate(p.dateTo)}', color: _color),
              _SummaryTile(label: 'Uncollected Amount', value: formatMoney(p.uncollectedAmount), sub: 'Across selected sales agents', color: AppPalette.black),
              _SummaryTile(label: 'VaxiShApp Sales', value: formatMoney(p.vaxishAppSales), sub: 'Invoices tagged "APP PROMO"', color: AppPalette.green),
              _SummaryTile(label: 'VaxiHub Sales', value: formatMoney(p.vaxihubSales), sub: 'Every other invoice', color: AppPalette.red),
            ],
          ),
        ),
        TabBar(
          isScrollable: true,
          tabAlignment: TabAlignment.start,
          labelColor: _color,
          indicatorColor: _color,
          unselectedLabelColor: scheme.onSurfaceVariant,
          tabs: const [
            Tab(text: 'All Items'),
            Tab(text: 'VaxiShApp · Per Customer'),
            Tab(text: 'VaxiShApp · Per Item'),
            Tab(text: 'VaxiHub · Per Customer'),
            Tab(text: 'VaxiHub · Per Item'),
          ],
        ),
        Expanded(
          child: TabBarView(
            children: [
              _itemTab(p.rows, 'Item Sales', othersTappable: true, grandTotal: p.totalSales),
              _customerTab(p.vaxishAppCustomerRows, 'VaxiShApp Sales · Per Customer', _vaxishApp),
              _itemTab(p.vaxishAppItemRows, 'VaxiShApp Sales · Per Item'),
              _customerTab(p.vaxihubCustomerRows, 'VaxiHub Sales · Per Customer', _vaxihub),
              _itemTab(p.vaxihubItemRows, 'VaxiHub Sales · Per Item'),
            ],
          ),
        ),
      ],
    );
  }

  Widget _itemTab(List<ProductSalesRow> rows, String title, {bool othersTappable = false, double? grandTotal}) {
    if (rows.isEmpty) {
      return const EmptyStateCard(icon: Icons.inventory_2_rounded, title: 'No sales', message: 'No sales found for these filters.', color: _color);
    }
    int sum(int Function(ProductSalesRow) f) => rows.fold<int>(0, (s, r) => s + f(r));
    String n(int v) => _count(v);

    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          ReportToolbar(summary: '$title · ${_count(rows.length)} item${rows.length == 1 ? '' : 's'}${othersTappable ? ' · tap OTHERS for its lines' : ''}'),
          Expanded(
            child: ReportTable(
              accent: _color,
              frozenColumns: const [ReportColumn(188, numeric: false)],
              frozenHeaders: const ['Item Code'],
              columns: const [ReportColumn(92), ReportColumn(80), ReportColumn(104), ReportColumn(140)],
              headerRows: const [
                [ReportHeaderCell('Quantity'), ReportHeaderCell('Free'), ReportHeaderCell('Total Items'), ReportHeaderCell('Amount')],
              ],
              rowCount: rows.length,
              rowBuilder: (i) {
                final r = rows[i];
                final isOthers = othersTappable && r.itemCode == 'OTHERS';
                return ReportRow(
                  onTap: isOthers ? _showOthers : null,
                  frozen: [
                    ReportCell(
                      r.itemCode,
                      bold: true,
                      leading: isOthers ? const Icon(Icons.open_in_new_rounded, size: 15, color: _color) : null,
                    ),
                  ],
                  cells: [
                    ReportCell(n(r.quantity)),
                    ReportCell(n(r.free), muted: r.free == 0),
                    ReportCell(n(r.totalItems)),
                    ReportCell(formatMoney(r.amount), bold: true),
                  ],
                );
              },
              footer: ReportRow(
                frozen: const [ReportCell('Grand Total')],
                cells: [
                  ReportCell(n(sum((r) => r.quantity))),
                  ReportCell(n(sum((r) => r.free))),
                  ReportCell(n(sum((r) => r.totalItems))),
                  ReportCell(formatMoney(grandTotal ?? rows.fold<double>(0.0, (s, r) => s + r.amount))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _customerTab(List<ProductSalesCustomerRow> rows, String title, String channel) {
    if (rows.isEmpty) {
      return const EmptyStateCard(icon: Icons.people_alt_rounded, title: 'No sales', message: 'No sales found for these filters.', color: _color);
    }
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
      child: Column(
        children: [
          ReportToolbar(summary: '$title · ${_count(rows.length)} customer${rows.length == 1 ? '' : 's'} · tap one for invoices'),
          Expanded(
            child: ReportTable(
              accent: _color,
              frozenColumns: const [ReportColumn(180, numeric: false)],
              frozenHeaders: const ['Customer Name'],
              columns: const [ReportColumn(134, numeric: false), ReportColumn(92), ReportColumn(140)],
              headerRows: const [
                [ReportHeaderCell('Location'), ReportHeaderCell('Quantity'), ReportHeaderCell('Amount')],
              ],
              rowCount: rows.length,
              rowBuilder: (i) {
                final r = rows[i];
                return ReportRow(
                  onTap: () => _showCustomerInvoices(r, channel),
                  frozen: [ReportCell(r.customerName, bold: true)],
                  cells: [
                    ReportCell(r.location.isEmpty ? '—' : r.location, muted: true),
                    ReportCell(_count(r.quantity)),
                    ReportCell(formatMoney(r.amount), bold: true),
                  ],
                );
              },
              footer: ReportRow(
                frozen: const [ReportCell('Grand Total')],
                cells: [
                  const ReportCell(''),
                  ReportCell(_count(rows.fold<int>(0, (s, r) => s + r.quantity))),
                  ReportCell(formatMoney(rows.fold<double>(0.0, (s, r) => s + r.amount))),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _showOthers() async {
    final p = context.read<ProductSalesProvider>();
    if (p.dateFrom == null || p.dateTo == null) return;
    await _sheet(
      title: 'Other Products',
      subtitle: 'Line items grouped into OTHERS · ${formatShortDate(p.dateFrom)} – ${formatShortDate(p.dateTo)}',
      icon: Icons.category_rounded,
      body: (ctx) => FutureBuilder<List<OtherProductRow>>(
        future: p.api.others(dateFrom: p.dateFrom!, dateTo: p.dateTo!, reps: p.selectedReps.toList()),
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final rows = snap.data ?? const [];
          if (rows.isEmpty) return const Center(child: Text('No line items.'));
          return ReportTable(
            accent: _color,
            frozenColumns: const [ReportColumn(168, numeric: false)],
            frozenHeaders: const ['Item Code'],
            columns: const [
              ReportColumn(70, numeric: false),
              ReportColumn(96, numeric: false),
              ReportColumn(108, numeric: false),
              ReportColumn(66),
              ReportColumn(62),
              ReportColumn(124),
              ReportColumn(124),
              ReportColumn(124),
            ],
            headerRows: const [
              [
                ReportHeaderCell('TSR'),
                ReportHeaderCell('Invoice #'),
                ReportHeaderCell('Date'),
                ReportHeaderCell('Qty'),
                ReportHeaderCell('Free'),
                ReportHeaderCell('Amount'),
                ReportHeaderCell('Balance'),
                ReportHeaderCell('Collected'),
              ],
            ],
            rowCount: rows.length,
            rowBuilder: (i) {
              final r = rows[i];
              return ReportRow(
                frozen: [ReportCell(r.itemCode, bold: true)],
                cells: [
                  ReportCell(r.tsrCode ?? '—', muted: true),
                  ReportCell(r.refNumber ?? '—'),
                  ReportCell(formatShortDate(r.txnDate), muted: true),
                  ReportCell(_count(r.quantity)),
                  ReportCell(_count(r.free), muted: r.free == 0),
                  ReportCell(formatMoney(r.amount), bold: true),
                  ReportCell(tableMoney(r.balanceRemaining), muted: r.balanceRemaining == 0),
                  ReportCell(formatMoney(r.collectedAmount)),
                ],
              );
            },
            footer: ReportRow(
              frozen: const [ReportCell('Total')],
              cells: [
                const ReportCell(''),
                const ReportCell(''),
                const ReportCell(''),
                ReportCell(_count(rows.fold<int>(0, (s, r) => s + r.quantity))),
                ReportCell(_count(rows.fold<int>(0, (s, r) => s + r.free))),
                ReportCell(formatMoney(rows.fold<double>(0.0, (s, r) => s + r.amount))),
                ReportCell(formatMoney(rows.fold<double>(0.0, (s, r) => s + r.balanceRemaining))),
                ReportCell(formatMoney(rows.fold<double>(0.0, (s, r) => s + r.collectedAmount))),
              ],
            ),
          );
        },
      ),
    );
  }

  Future<void> _showCustomerInvoices(ProductSalesCustomerRow row, String channel) async {
    final p = context.read<ProductSalesProvider>();
    if (p.dateFrom == null || p.dateTo == null) return;
    final future = p.api.customerInvoices(
      dateFrom: p.dateFrom!,
      dateTo: p.dateTo!,
      customerName: row.customerName,
      channel: channel,
      username: _username,
      reps: p.selectedReps.toList(),
      prefixes: p.selectedPrefixes.toList(),
    );
    await _sheet(
      title: row.customerName,
      subtitle: '${channel == _vaxishApp ? 'VaxiShApp' : 'VaxiHub'} · ${row.location.isEmpty ? 'No location' : row.location}',
      icon: Icons.storefront_rounded,
      body: (ctx) => FutureBuilder<List<ProductSalesCustomerInvoice>>(
        future: future,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
          if (snap.hasError) return Center(child: Text('${snap.error}'));
          final invoices = snap.data ?? const [];
          if (invoices.isEmpty) return const Center(child: Text('No invoices.'));
          final total = invoices.fold<double>(0.0, (s, i) => s + i.subtotal);
          final outstanding = invoices.fold<double>(0.0, (s, i) => s + i.balanceRemaining);
          return ListView(
            padding: EdgeInsets.zero,
            children: [
              Row(
                children: [
                  _MiniStat(label: 'Invoices', value: '${invoices.length}', color: _color),
                  const SizedBox(width: 8),
                  _MiniStat(label: 'Total', value: formatMoney(total), color: AppPalette.green),
                  const SizedBox(width: 8),
                  _MiniStat(label: 'Outstanding', value: formatMoney(outstanding), color: outstanding > 0 ? AppPalette.red : AppPalette.green),
                ],
              ),
              const SizedBox(height: 14),
              for (final inv in invoices) _InvoiceCard(invoice: inv),
            ],
          );
        },
      ),
    );
  }

  Future<void> _sheet({required String title, required String subtitle, required IconData icon, required WidgetBuilder body}) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: Theme.of(context).colorScheme.surface,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
      builder: (ctx) => SizedBox(
        height: MediaQuery.of(ctx).size.height * 0.85,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconWellSmall(icon: icon, color: _color),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(title, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
                        Text(subtitle, style: TextStyle(fontSize: 12.5, color: Theme.of(ctx).colorScheme.onSurfaceVariant)),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Expanded(child: body(ctx)),
            ],
          ),
        ),
      ),
    );
  }
}

String _count(int v) {
  final s = v.abs().toString();
  final b = StringBuffer(v < 0 ? '-' : '');
  for (var i = 0; i < s.length; i++) {
    if (i > 0 && (s.length - i) % 3 == 0) b.write(',');
    b.write(s[i]);
  }
  return b.toString();
}

class _SummaryTile extends StatelessWidget {
  final String label;
  final String value;
  final String sub;
  final Color color;

  const _SummaryTile({required this.label, required this.value, required this.sub, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: 200,
      margin: const EdgeInsets.only(right: 10),
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          Container(width: 5, color: color),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(label.toUpperCase(), style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: AppPalette.onTint(color, Theme.of(context).brightness))),
                  const SizedBox(height: 3),
                  FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(value, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.3)),
                  ),
                  Text(sub, maxLines: 1, overflow: TextOverflow.ellipsis, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniStat extends StatelessWidget {
  final String label;
  final String value;
  final Color color;

  const _MiniStat({required this.label, required this.value, required this.color});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
        decoration: BoxDecoration(color: AppPalette.tint(color, b), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppPalette.onTint(color, b))),
            FittedBox(
              fit: BoxFit.scaleDown,
              alignment: Alignment.centerLeft,
              child: Text(value, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w800)),
            ),
          ],
        ),
      ),
    );
  }
}

class _InvoiceCard extends StatelessWidget {
  final ProductSalesCustomerInvoice invoice;

  const _InvoiceCard({required this.invoice});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final paid = invoice.balanceRemaining <= 0.009;
    final b = Theme.of(context).brightness;
    final statusColor = paid ? AppPalette.green : AppPalette.red;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: invoice.qbExtractedId == 0
                ? null
                : () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => InvoiceItemsScreen(invoiceId: invoice.qbExtractedId))),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 10),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Invoice ${invoice.refNumber ?? '—'}', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                        Text(
                          '${formatShortDate(invoice.txnDate)}${(invoice.tsrCode?.isNotEmpty ?? false) ? ' · ${invoice.tsrCode}' : ''}',
                          style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                    decoration: BoxDecoration(color: AppPalette.tint(statusColor, b), borderRadius: BorderRadius.circular(20)),
                    child: Text(paid ? 'Paid' : 'Bal ${formatMoney(invoice.balanceRemaining)}',
                        style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w800, color: AppPalette.onTint(statusColor, b))),
                  ),
                ],
              ),
            ),
          ),
          Container(
            color: scheme.surfaceContainerHigh,
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            child: Row(
              children: [
                Expanded(child: _h('ITEM', scheme)),
                SizedBox(width: 48, child: _h('QTY', scheme, end: true)),
                SizedBox(width: 44, child: _h('FREE', scheme, end: true)),
                SizedBox(width: 100, child: _h('AMOUNT', scheme, end: true)),
              ],
            ),
          ),
          for (final it in invoice.items)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
              child: Row(
                children: [
                  Expanded(child: Text(it.itemCode, maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600))),
                  SizedBox(width: 48, child: Text(_count(it.quantity), textAlign: TextAlign.end, style: const TextStyle(fontSize: 12.5))),
                  SizedBox(width: 44, child: Text(_count(it.free), textAlign: TextAlign.end, style: TextStyle(fontSize: 12.5, color: scheme.onSurfaceVariant))),
                  SizedBox(width: 100, child: Text(formatMoney(it.amount), textAlign: TextAlign.end, style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700))),
                ],
              ),
            ),
          Divider(height: 1, color: scheme.outlineVariant.withValues(alpha: 0.5)),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 9, 14, 11),
            child: Row(
              children: [
                _foot('Subtotal', formatMoney(invoice.subtotal), scheme),
                _foot('Collected', formatMoney(invoice.collectedAmount), scheme),
                _foot('Balance', formatMoney(invoice.balanceRemaining), scheme, color: paid ? null : AppPalette.red),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _h(String s, ColorScheme scheme, {bool end = false}) => Text(
        s,
        textAlign: end ? TextAlign.end : TextAlign.start,
        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: scheme.onSurfaceVariant),
      );

  Widget _foot(String label, String value, ColorScheme scheme, {Color? color}) => Expanded(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800, color: color)),
          ],
        ),
      );
}

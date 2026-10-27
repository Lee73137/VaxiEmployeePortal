import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:printing/printing.dart';
import '../providers/forecast_provider.dart';
import '../models/forecast.dart';
import '../utils/forecast_pdf.dart';

class ForecastScreen extends StatefulWidget {
  const ForecastScreen({super.key});

  @override
  State<ForecastScreen> createState() => _ForecastScreenState();
}

class _ForecastScreenState extends State<ForecastScreen> {
  static const _horizonOptions = [30, 60, 90, 180];

  @override
  Widget build(BuildContext context) {
    final forecast = context.watch<ForecastProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sales Forecast'),
        actions: [
          if (forecast.generated && forecast.rows.isNotEmpty)
            IconButton(
              key: const Key('exportPdfButton'),
              tooltip: 'Print / Export PDF',
              icon: const Icon(Icons.print_outlined),
              onPressed: () => Printing.layoutPdf(
                onLayout: (format) => buildForecastPdf(forecast.rows),
                name: 'vaxicsr-forecast-po-report.pdf',
              ),
            ),
          const SizedBox(width: 4),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('FILTERS', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, letterSpacing: 0.6, color: scheme.onSurfaceVariant)),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(child: _dateField(context, 'From', forecast.query.historicalStart, (d) => setState(() => forecast.query.historicalStart = d))),
                      const SizedBox(width: 10),
                      Expanded(child: _dateField(context, 'To', forecast.query.historicalEnd, (d) => setState(() => forecast.query.historicalEnd = d))),
                    ],
                  ),
                  const SizedBox(height: 12),
                  DropdownButtonFormField<int>(
                    initialValue: forecast.query.horizonDays,
                    decoration: const InputDecoration(labelText: 'Forecast Horizon'),
                    items: _horizonOptions.map((h) => DropdownMenuItem(value: h, child: Text(h == 180 ? 'Next 6 months' : 'Next $h days'))).toList(),
                    onChanged: (v) => setState(() => forecast.query.horizonDays = v ?? 30),
                  ),
                  const SizedBox(height: 12),
                  _ChipPicker(
                    label: 'Location(s)',
                    hint: 'Search locations…',
                    selected: forecast.query.locations,
                    search: forecast.api.searchLocations,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _ChipPicker(
                    label: 'Product(s)',
                    hint: 'Search item code…',
                    selected: forecast.query.itemCodes,
                    search: forecast.api.searchProducts,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 12),
                  _ChipPicker(
                    label: 'Supplier(s)',
                    hint: 'Search supplier…',
                    selected: forecast.query.suppliers,
                    search: forecast.api.searchSuppliers,
                    onChanged: () => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  Text('Seasonality Weight: ${forecast.query.seasonalityWeight}%', style: const TextStyle(fontSize: 13)),
                  Slider(
                    value: forecast.query.seasonalityWeight.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${forecast.query.seasonalityWeight}%',
                    onChanged: (v) => setState(() => forecast.query.seasonalityWeight = v.round()),
                  ),
                  Text('Trend Weight: ${forecast.query.trendWeight}%', style: const TextStyle(fontSize: 13)),
                  Slider(
                    value: forecast.query.trendWeight.toDouble(),
                    min: 0,
                    max: 100,
                    divisions: 20,
                    label: '${forecast.query.trendWeight}%',
                    onChanged: (v) => setState(() => forecast.query.trendWeight = v.round()),
                  ),
                  const SizedBox(height: 4),
                  TextFormField(
                    initialValue: forecast.query.safetyBufferPercent.toString(),
                    decoration: const InputDecoration(labelText: 'Safety Buffer %'),
                    keyboardType: TextInputType.number,
                    onChanged: (v) => forecast.query.safetyBufferPercent = int.tryParse(v) ?? forecast.query.safetyBufferPercent,
                  ),
                  const SizedBox(height: 16),
                  FilledButton(
                    onPressed: forecast.isLoading ? null : () => context.read<ForecastProvider>().generate(),
                    child: forecast.isLoading
                        ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white))
                        : const Text('Generate Forecast'),
                  ),
                ],
              ),
            ),
          ),
          if (forecast.errorMessage != null) ...[
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
              child: Row(
                children: [
                  Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 18),
                  const SizedBox(width: 8),
                  Expanded(child: Text(forecast.errorMessage!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 13))),
                ],
              ),
            ),
          ],
          if (forecast.generated) ...[
            const SizedBox(height: 20),
            Row(
              children: [
                Expanded(
                  child: Text(
                    '${forecast.rows.length} item${forecast.rows.length == 1 ? '' : 's'} · sorted by suggested PO qty',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ),
                if (forecast.rows.isNotEmpty)
                  OutlinedButton.icon(
                    onPressed: () => Printing.layoutPdf(
                      onLayout: (format) => buildForecastPdf(forecast.rows),
                      name: 'vaxicsr-forecast-po-report.pdf',
                    ),
                    icon: const Icon(Icons.picture_as_pdf_outlined, size: 18),
                    label: const Text('Export PO Report'),
                  ),
              ],
            ),
            const SizedBox(height: 8),
            if (forecast.rows.isEmpty)
              Padding(
                padding: const EdgeInsets.all(32),
                child: Center(
                  child: Column(
                    children: [
                      Icon(Icons.query_stats_outlined, size: 48, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                      const SizedBox(height: 12),
                      Text('No sales history found for this range/filters.', style: TextStyle(color: scheme.onSurfaceVariant), textAlign: TextAlign.center),
                    ],
                  ),
                ),
              )
            else
              for (final row in forecast.rows) _forecastRowCard(context, row),
          ],
        ],
      ),
    );
  }

  Widget _dateField(BuildContext context, String label, DateTime? value, ValueChanged<DateTime?> onPicked) {
    return InkWell(
      onTap: () async {
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? DateTime.now(),
          firstDate: DateTime(2015),
          lastDate: DateTime.now(),
        );
        if (picked != null) onPicked(picked);
      },
      child: InputDecorator(
        decoration: InputDecoration(labelText: label),
        child: Text(value == null ? '(default)' : '${value.month}/${value.day}/${value.year}'),
      ),
    );
  }

  Widget _forecastRowCard(BuildContext context, ForecastRow row) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(row.itemCode, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      Text('Avg ${row.avgMonthlySales}/mo · ${row.uom ?? ''}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text('${row.suggestedPoQty}', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 20, color: scheme.primary)),
                    Text('Suggested PO', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 12,
              runSpacing: 4,
              children: [
                _statChip('On Hand', '${row.onHand}', scheme),
                _statChip('Pending', '${row.pending}', scheme),
                _statChip('Available', '${row.available}', scheme),
                _statChip('Trend', '${row.trendRatePercent > 0 ? '+' : ''}${row.trendRatePercent}%', scheme),
                if (row.limitedHistory) _statChip('Limited history', '', scheme, warn: true),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _statChip(String label, String value, ColorScheme scheme, {bool warn = false}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: warn ? scheme.tertiaryContainer : scheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        value.isEmpty ? label : '$label $value',
        style: TextStyle(fontSize: 11, color: warn ? scheme.onTertiaryContainer : scheme.onSurfaceVariant, fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _ChipPicker extends StatefulWidget {
  final String label;
  final String hint;
  final List<String> selected;
  final Future<List<String>> Function(String term) search;
  final VoidCallback onChanged;

  const _ChipPicker({required this.label, required this.hint, required this.selected, required this.search, required this.onChanged});

  @override
  State<_ChipPicker> createState() => _ChipPickerState();
}

class _ChipPickerState extends State<_ChipPicker> {
  final _controller = TextEditingController();
  List<String> _results = [];
  Timer? _debounce;

  void _onTextChanged(String term) {
    _debounce?.cancel();
    if (term.trim().length < 2) {
      setState(() => _results = []);
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 250), () async {
      final results = await widget.search(term);
      if (mounted) setState(() => _results = results);
    });
  }

  @override
  void dispose() {
    _debounce?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(widget.label, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 4),
        if (widget.selected.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(bottom: 6),
            child: Wrap(
              spacing: 6,
              runSpacing: 6,
              children: widget.selected
                  .map((v) => Chip(
                        label: Text(v, style: const TextStyle(fontSize: 12)),
                        onDeleted: () {
                          widget.selected.remove(v);
                          widget.onChanged();
                        },
                      ))
                  .toList(),
            ),
          ),
        TextField(
          controller: _controller,
          decoration: InputDecoration(hintText: widget.hint, isDense: true, prefixIcon: const Icon(Icons.search, size: 18)),
          onChanged: _onTextChanged,
        ),
        if (_results.isNotEmpty)
          Container(
            margin: const EdgeInsets.only(top: 4),
            constraints: const BoxConstraints(maxHeight: 180),
            decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(10)),
            child: ListView(
              shrinkWrap: true,
              children: _results
                  .map((r) => ListTile(
                        dense: true,
                        title: Text(r, style: const TextStyle(fontSize: 13)),
                        onTap: () {
                          if (!widget.selected.contains(r)) widget.selected.add(r);
                          _controller.clear();
                          setState(() => _results = []);
                          widget.onChanged();
                        },
                      ))
                  .toList(),
            ),
          ),
      ],
    );
  }
}

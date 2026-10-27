import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// One cell of a [ReportTable] row. [span] lets a cell cover several
/// adjacent columns (vaxiCSR's colspan - e.g. a group header's merged
/// "Rep - Location" cell, or the "Grand Total" label).
class ReportCell {
  final String text;
  final int span;
  final bool bold;
  final bool muted;
  final Widget? leading;

  /// Replaces [text] with custom content (e.g. multi-coloured figures).
  final Widget? child;

  /// Makes just this cell tappable (vaxiCSR's per-cell drill-downs).
  final VoidCallback? onTap;

  const ReportCell(this.text, {this.span = 1, this.bold = false, this.muted = false, this.leading, this.child, this.onTap});
}

enum ReportRowKind { group, detail }

class ReportRow {
  final ReportRowKind kind;
  final List<ReportCell> frozen;
  final List<ReportCell> cells;
  final VoidCallback? onTap;

  /// Group rows only: whether its detail rows are currently showing.
  final bool expanded;

  const ReportRow({
    required this.frozen,
    required this.cells,
    this.kind = ReportRowKind.detail,
    this.onTap,
    this.expanded = false,
  });
}

class ReportColumn {
  final double width;
  final bool numeric;

  /// Draws the heavier left border vaxiCSR puts before each month block.
  final bool dividerBefore;

  const ReportColumn(this.width, {this.numeric = true, this.dividerBefore = false});
}

/// A header cell spanning [span] scrollable columns.
class ReportHeaderCell {
  final String label;
  final int span;

  const ReportHeaderCell(this.label, {this.span = 1});
}

/// vaxiCSR-style wide report table for a phone: the header rows stay pinned
/// on top, the [frozenColumns] (Rep / Location / Customer...) stay pinned on
/// the left, and the [footer] (Grand Total) stays pinned at the bottom while
/// the rest scrolls both ways - the same sticky behaviour as the web tables.
/// Body rows are built lazily, so thousands of rows stay smooth.
class ReportTable extends StatefulWidget {
  final List<ReportColumn> frozenColumns;
  final List<String> frozenHeaders;
  final List<ReportColumn> columns;

  /// One or two header rows over the scrollable columns; each row's spans
  /// must add up to columns.length.
  final List<List<ReportHeaderCell>> headerRows;
  final int rowCount;
  final ReportRow Function(int index) rowBuilder;
  final ReportRow? footer;
  final Color accent;

  const ReportTable({
    super.key,
    required this.frozenColumns,
    required this.frozenHeaders,
    required this.columns,
    required this.headerRows,
    required this.rowCount,
    required this.rowBuilder,
    this.footer,
    this.accent = AppPalette.red,
  });

  static const rowHeight = 40.0;
  static const headerRowHeight = 32.0;

  @override
  State<ReportTable> createState() => _ReportTableState();
}

class _ReportTableState extends State<ReportTable> {
  final _vFrozen = ScrollController();
  final _vMain = ScrollController();
  final _hHeader = ScrollController();
  final _hMain = ScrollController();
  final _hFooter = ScrollController();
  late final _vSync = _ScrollSync([_vFrozen, _vMain]);
  late final _hSync = _ScrollSync([_hHeader, _hMain, _hFooter]);

  @override
  void dispose() {
    _vSync.dispose();
    _hSync.dispose();
    for (final c in [_vFrozen, _vMain, _hHeader, _hMain, _hFooter]) {
      c.dispose();
    }
    super.dispose();
  }

  double get _frozenWidth => widget.frozenColumns.fold(0.0, (s, c) => s + c.width);
  double get _scrollWidth => widget.columns.fold(0.0, (s, c) => s + c.width);

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final b = Theme.of(context).brightness;
    final border = BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.45));
    final headerHeight = ReportTable.headerRowHeight * widget.headerRows.length;
    final headerBg = scheme.surfaceContainerHigh;

    Widget headerText(String s, {TextAlign align = TextAlign.left}) => Text(
          s.toUpperCase(),
          textAlign: align,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, letterSpacing: 0.5, color: scheme.onSurfaceVariant),
        );

    final frozenHeader = Container(
      width: _frozenWidth + 1, // +1 for the right divider
      height: headerHeight,
      decoration: BoxDecoration(color: headerBg, border: Border(bottom: border, right: BorderSide(color: scheme.outlineVariant))),
      child: Row(
        children: [
          for (var i = 0; i < widget.frozenColumns.length; i++)
            Container(
              width: widget.frozenColumns[i].width,
              padding: const EdgeInsets.symmetric(horizontal: 10),
              alignment: Alignment.centerLeft,
              child: headerText(widget.frozenHeaders[i]),
            ),
        ],
      ),
    );

    final scrollHeader = SizedBox(
      width: _scrollWidth,
      height: headerHeight,
      child: Column(
        children: [
          for (final row in widget.headerRows)
            Container(
              height: ReportTable.headerRowHeight,
              decoration: BoxDecoration(color: headerBg, border: Border(bottom: border)),
              child: Row(children: _spanCells(row, widget.columns, (cell, width, firstCol) {
                final col = widget.columns[firstCol];
                return Container(
                  width: width,
                  padding: const EdgeInsets.symmetric(horizontal: 10),
                  alignment: cell.span > 1 ? Alignment.center : (col.numeric ? Alignment.centerRight : Alignment.centerLeft),
                  decoration: BoxDecoration(
                    border: col.dividerBefore ? Border(left: BorderSide(color: scheme.outlineVariant, width: 1.5)) : null,
                  ),
                  child: headerText(cell.label),
                );
              }, (c) => c.span)),
            ),
        ],
      ),
    );

    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainer,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.45)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        children: [
          Row(
            children: [
              frozenHeader,
              Expanded(
                child: SingleChildScrollView(
                  controller: _hHeader,
                  scrollDirection: Axis.horizontal,
                  child: scrollHeader,
                ),
              ),
            ],
          ),
          Expanded(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Container(
                  width: _frozenWidth + 1, // +1 for the right divider
                  decoration: BoxDecoration(border: Border(right: BorderSide(color: scheme.outlineVariant))),
                  child: ListView.builder(
                    controller: _vFrozen,
                    itemExtent: ReportTable.rowHeight,
                    itemCount: widget.rowCount,
                    itemBuilder: (context, i) => _buildRow(widget.rowBuilder(i), frozen: true, scheme: scheme, b: b, border: border),
                  ),
                ),
                Expanded(
                  child: Scrollbar(
                    controller: _hMain,
                    child: SingleChildScrollView(
                      controller: _hMain,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: _scrollWidth,
                        child: ListView.builder(
                          controller: _vMain,
                          itemExtent: ReportTable.rowHeight,
                          itemCount: widget.rowCount,
                          itemBuilder: (context, i) => _buildRow(widget.rowBuilder(i), frozen: false, scheme: scheme, b: b, border: border),
                        ),
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (widget.footer != null)
            Container(
              decoration: BoxDecoration(border: Border(top: BorderSide(color: scheme.outlineVariant, width: 1.5))),
              child: Row(
                children: [
                  Container(
                    width: _frozenWidth + 1, // +1 for the right divider
                    decoration: BoxDecoration(border: Border(right: BorderSide(color: scheme.outlineVariant))),
                    child: _buildRow(widget.footer!, frozen: true, scheme: scheme, b: b, border: border, isFooter: true),
                  ),
                  Expanded(
                    child: SingleChildScrollView(
                      controller: _hFooter,
                      scrollDirection: Axis.horizontal,
                      child: SizedBox(
                        width: _scrollWidth,
                        child: _buildRow(widget.footer!, frozen: false, scheme: scheme, b: b, border: border, isFooter: true),
                      ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildRow(
    ReportRow row, {
    required bool frozen,
    required ColorScheme scheme,
    required Brightness b,
    required BorderSide border,
    bool isFooter = false,
  }) {
    final isGroup = row.kind == ReportRowKind.group;
    final accent = widget.accent;
    final cols = frozen ? widget.frozenColumns : widget.columns;
    final cells = frozen ? row.frozen : row.cells;

    final Color bg = isFooter
        ? scheme.surfaceContainerHigh
        : isGroup
            ? Color.alphaBlend(AppPalette.tint(accent, b), scheme.surfaceContainer)
            : scheme.surfaceContainer;

    final content = Container(
      height: ReportTable.rowHeight,
      decoration: BoxDecoration(
        color: bg,
        border: Border(
          bottom: border,
          left: frozen && isGroup ? BorderSide(color: accent, width: 4) : BorderSide.none,
        ),
      ),
      child: Row(
        children: _spanCells(cells, cols, (cell, width, firstCol) {
          final col = cols[firstCol];
          final strong = cell.bold || isGroup || isFooter;
          final box = Container(
            width: width - (frozen && isGroup && firstCol == 0 ? 4 : 0),
            padding: const EdgeInsets.symmetric(horizontal: 10),
            alignment: col.numeric && cell.span == 1 ? Alignment.centerRight : Alignment.centerLeft,
            decoration: BoxDecoration(
              border: col.dividerBefore ? Border(left: BorderSide(color: scheme.outlineVariant.withValues(alpha: 0.8), width: 1.5)) : null,
            ),
            child: Row(
              mainAxisAlignment: col.numeric && cell.span == 1 ? MainAxisAlignment.end : MainAxisAlignment.start,
              children: [
                if (cell.leading != null) ...[cell.leading!, const SizedBox(width: 8)],
                Flexible(
                  child: cell.child ??
                      Text(
                        cell.text,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: isFooter ? FontWeight.w800 : (strong ? FontWeight.w700 : FontWeight.w500),
                          fontFeatures: const [FontFeature.tabularFigures()],
                          color: cell.muted ? scheme.onSurfaceVariant : scheme.onSurface,
                        ),
                      ),
                ),
              ],
            ),
          );
          if (cell.onTap == null) return box;
          return Material(color: Colors.transparent, child: InkWell(onTap: cell.onTap, child: box));
        }, (c) => c.span),
      ),
    );

    if (row.onTap == null) return content;
    return Material(color: Colors.transparent, child: InkWell(onTap: row.onTap, child: content));
  }

  /// Lays [cells] out over [cols], each covering `spanOf(cell)` columns.
  List<Widget> _spanCells<T>(
    List<T> cells,
    List<ReportColumn> cols,
    Widget Function(T cell, double width, int firstCol) build,
    int Function(T) spanOf,
  ) {
    final out = <Widget>[];
    var col = 0;
    for (final cell in cells) {
      if (col >= cols.length) break;
      final span = spanOf(cell);
      var w = 0.0;
      for (var k = col; k < col + span && k < cols.length; k++) {
        w += cols[k].width;
      }
      out.add(build(cell, w, col));
      col += span;
    }
    return out;
  }
}

/// Keeps several scroll controllers at the same offset (pinned header,
/// frozen columns and footer follow the body).
class _ScrollSync {
  final List<ScrollController> controllers;
  final _listeners = <ScrollController, VoidCallback>{};
  bool _syncing = false;

  _ScrollSync(this.controllers) {
    for (final c in controllers) {
      void listener() {
        if (_syncing || !c.hasClients) return;
        _syncing = true;
        for (final other in controllers) {
          if (!identical(other, c) && other.hasClients && other.offset != c.offset) {
            final max = other.position.maxScrollExtent;
            other.jumpTo(c.offset.clamp(0.0, max));
          }
        }
        _syncing = false;
      }

      _listeners[c] = listener;
      c.addListener(listener);
    }
  }

  void dispose() {
    _listeners.forEach((c, l) => c.removeListener(l));
  }
}

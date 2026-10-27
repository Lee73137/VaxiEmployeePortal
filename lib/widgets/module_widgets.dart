import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../utils/formatting.dart';

/// Gradient page header for a module screen, in its group's colour - the
/// mobile counterpart of vaxiCSR's page "hero" banners (icon, title, one-line
/// description, decorative circles).
class ModuleHero extends StatelessWidget {
  final String title;
  final String subtitle;
  final IconData icon;
  final Color color;
  final List<Widget> actions;
  final Widget? bottom;

  const ModuleHero({
    super.key,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.color,
    this.actions = const [],
    this.bottom,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = Navigator.of(context).canPop();
    return Container(
      decoration: BoxDecoration(
        gradient: AppPalette.accentGradient(color),
        borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
      ),
      padding: EdgeInsets.fromLTRB(8, MediaQuery.of(context).padding.top + 6, 12, 12),
      clipBehavior: Clip.antiAlias,
      // One compact row - back, icon, title, actions - so the header doesn't
      // eat the screen; the subtitle and filter chips sit just under it.
      child: Stack(
        clipBehavior: Clip.none,
        children: [
          Positioned(right: -30, top: -40, child: _circle(120)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  if (canPop)
                    IconButton(
                      visualDensity: VisualDensity.compact,
                      onPressed: () => Navigator.of(context).maybePop(),
                      icon: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 20),
                      style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.16)),
                    )
                  else
                    const SizedBox(width: 4),
                  const SizedBox(width: 6),
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(10)),
                    child: Icon(icon, color: Colors.white, size: 18),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Colors.white, fontSize: 17, fontWeight: FontWeight.w800, letterSpacing: -0.3),
                    ),
                  ),
                  ...actions,
                ],
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(6, 6, 6, 0),
                child: Text(
                  subtitle,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(color: Colors.white.withValues(alpha: 0.82), fontSize: 12, height: 1.3),
                ),
              ),
              if (bottom != null) ...[const SizedBox(height: 10), Padding(padding: const EdgeInsets.symmetric(horizontal: 6), child: bottom!)],
            ],
          ),
        ],
      ),
    );
  }

  Widget _circle(double size) => IgnorePointer(
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(shape: BoxShape.circle, color: Colors.white.withValues(alpha: 0.08)),
        ),
      );
}

/// White pill button used on the coloured hero (e.g. "Filters").
class HeroPillButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final VoidCallback onPressed;
  final Color color;
  final int? badge;

  const HeroPillButton({super.key, required this.icon, required this.label, required this.onPressed, required this.color, this.badge});

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(30),
      elevation: 0,
      child: InkWell(
        borderRadius: BorderRadius.circular(30),
        onTap: onPressed,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 6),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 18, color: color),
              const SizedBox(width: 6),
              Text(label, style: TextStyle(color: color, fontWeight: FontWeight.w800, fontSize: 12)),
              if (badge != null && badge! > 0) ...[
                const SizedBox(width: 6),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 1),
                  decoration: BoxDecoration(color: color, borderRadius: BorderRadius.circular(10)),
                  child: Text('$badge', style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w800)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// Chips summarising the active filters, shown on the hero under the title.
class HeroFilterChips extends StatelessWidget {
  final List<String> labels;

  const HeroFilterChips({super.key, required this.labels});

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: [
        for (final l in labels)
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: Colors.white.withValues(alpha: 0.22)),
            ),
            child: Text(l, style: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.w700)),
          ),
      ],
    );
  }
}

/// Bottom-sheet filter panel - vaxiCSR's "Filters" card: titled sections,
/// then "Generate Report" / "Reset" buttons.
Future<void> showFilterSheet(
  BuildContext context, {
  required Color color,
  required String title,
  required List<Widget> Function(BuildContext ctx, void Function(VoidCallback) setSheetState) sections,
  required VoidCallback onApply,
  VoidCallback? onReset,
  String applyLabel = 'Generate Report',
}) {
  return showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    showDragHandle: true,
    backgroundColor: Theme.of(context).colorScheme.surfaceContainer,
    shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(28))),
    builder: (ctx) => StatefulBuilder(
      builder: (ctx, setSheetState) => Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.of(ctx).viewInsets.bottom),
        child: DraggableScrollableSheet(
          initialChildSize: 0.8,
          minChildSize: 0.45,
          maxChildSize: 0.95,
          expand: false,
          builder: (ctx, scroll) => Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 8),
                child: Row(
                  children: [
                    IconWellSmall(icon: Icons.tune_rounded, color: color),
                    const SizedBox(width: 12),
                    Expanded(child: Text(title, style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w800))),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  controller: scroll,
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  children: sections(ctx, setSheetState),
                ),
              ),
              Container(
                padding: EdgeInsets.fromLTRB(20, 12, 20, MediaQuery.of(ctx).padding.bottom + 14),
                decoration: BoxDecoration(
                  border: Border(top: BorderSide(color: Theme.of(ctx).colorScheme.outlineVariant.withValues(alpha: 0.5))),
                ),
                child: Row(
                  children: [
                    if (onReset != null) ...[
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () {
                            onReset();
                            setSheetState(() {});
                          },
                          child: const Text('Reset'),
                        ),
                      ),
                      const SizedBox(width: 12),
                    ],
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(backgroundColor: color, foregroundColor: Colors.white),
                        onPressed: () {
                          Navigator.of(ctx).pop();
                          onApply();
                        },
                        icon: const Icon(Icons.bolt_rounded),
                        label: Text(applyLabel),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}

class IconWellSmall extends StatelessWidget {
  final IconData icon;
  final Color color;

  const IconWellSmall({super.key, required this.icon, required this.color});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      width: 32,
      height: 32,
      decoration: BoxDecoration(color: AppPalette.tint(color, b), borderRadius: BorderRadius.circular(12)),
      child: Icon(icon, size: 17, color: AppPalette.onTint(color, b)),
    );
  }
}

/// A labelled block inside the filter sheet (vaxiCSR's "LABEL-CAPS" + hint).
class FilterSection extends StatelessWidget {
  final String label;
  final String? hint;
  final Widget child;

  const FilterSection({super.key, required this.label, required this.child, this.hint});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label.toUpperCase(), style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, letterSpacing: 0.7, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          child,
          if (hint != null) ...[
            const SizedBox(height: 6),
            Text(hint!, style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ],
        ],
      ),
    );
  }
}

/// vaxiCSR's searchable multi-picker: type to search, tap results to add
/// them as removable chips. Empty selection means "all".
class SearchableMultiSelect extends StatefulWidget {
  final List<String> options;
  final Set<String> selected;
  final ValueChanged<String> onToggle;
  final String hint;
  final Color color;

  const SearchableMultiSelect({
    super.key,
    required this.options,
    required this.selected,
    required this.onToggle,
    required this.hint,
    required this.color,
  });

  @override
  State<SearchableMultiSelect> createState() => _SearchableMultiSelectState();
}

class _SearchableMultiSelectState extends State<SearchableMultiSelect> {
  final _controller = TextEditingController();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final b = Theme.of(context).brightness;
    final term = _controller.text.trim().toLowerCase();
    final matches = widget.options
        .where((o) => !widget.selected.contains(o) && (term.isEmpty || o.toLowerCase().contains(term)))
        .take(term.isEmpty ? 8 : 30)
        .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (widget.selected.isNotEmpty) ...[
          Wrap(
            spacing: 6,
            runSpacing: 6,
            children: [
              for (final s in widget.selected)
                InputChip(
                  label: Text(s),
                  labelStyle: TextStyle(color: AppPalette.onTint(widget.color, b), fontWeight: FontWeight.w700, fontSize: 12.5),
                  backgroundColor: AppPalette.tint(widget.color, b),
                  deleteIconColor: AppPalette.onTint(widget.color, b),
                  onDeleted: () => setState(() => widget.onToggle(s)),
                ),
            ],
          ),
          const SizedBox(height: 10),
        ],
        TextField(
          controller: _controller,
          onChanged: (_) => setState(() {}),
          decoration: InputDecoration(
            hintText: widget.hint,
            prefixIcon: const Icon(Icons.search_rounded),
            isDense: true,
          ),
        ),
        const SizedBox(height: 6),
        Container(
          constraints: const BoxConstraints(maxHeight: 220),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.5)),
          ),
          child: matches.isEmpty
              ? Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(term.isEmpty ? 'All options selected' : 'No matches', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13)),
                )
              : ListView(
                  shrinkWrap: true,
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  children: [
                    for (final m in matches)
                      ListTile(
                        dense: true,
                        visualDensity: const VisualDensity(vertical: -2),
                        leading: Icon(Icons.add_circle_outline_rounded, size: 20, color: widget.color),
                        title: Text(m, style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w600)),
                        onTap: () => setState(() => widget.onToggle(m)),
                      ),
                  ],
                ),
        ),
      ],
    );
  }
}

/// "‹ 2026 ›" year stepper for the filter sheet.
class YearStepper extends StatelessWidget {
  final int year;
  final ValueChanged<int> onChanged;
  final Color color;

  const YearStepper({super.key, required this.year, required this.onChanged, required this.color});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      decoration: BoxDecoration(color: AppPalette.tint(color, b), borderRadius: BorderRadius.circular(16)),
      child: Row(
        children: [
          IconButton(onPressed: () => onChanged(year - 1), icon: Icon(Icons.chevron_left_rounded, color: AppPalette.onTint(color, b))),
          Expanded(
            child: Text('$year', textAlign: TextAlign.center, style: TextStyle(fontSize: 20, fontWeight: FontWeight.w800, color: AppPalette.onTint(color, b))),
          ),
          IconButton(
            onPressed: year >= DateTime.now().year ? null : () => onChanged(year + 1),
            icon: Icon(Icons.chevron_right_rounded, color: AppPalette.onTint(color, b)),
          ),
        ],
      ),
    );
  }
}

/// Two tappable date boxes ("From" / "To") that open the date picker.
class DateRangeFields extends StatelessWidget {
  final DateTime? from;
  final DateTime? to;
  final ValueChanged<DateTime> onFrom;
  final ValueChanged<DateTime> onTo;
  final Color color;

  const DateRangeFields({super.key, required this.from, required this.to, required this.onFrom, required this.onTo, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _box(context, 'From', from, onFrom)),
        const SizedBox(width: 10),
        Expanded(child: _box(context, 'To', to, onTo)),
      ],
    );
  }

  Widget _box(BuildContext context, String label, DateTime? value, ValueChanged<DateTime> onPicked) {
    final scheme = Theme.of(context).colorScheme;
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: context,
          initialDate: value ?? now,
          firstDate: DateTime(2015),
          lastDate: DateTime(now.year + 1, 12, 31),
        );
        if (picked != null) onPicked(picked);
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainer,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: scheme.outlineVariant.withValues(alpha: 0.6)),
        ),
        child: Row(
          children: [
            Icon(Icons.event_rounded, size: 20, color: color),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label, style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant, fontWeight: FontWeight.w700)),
                  Text(value == null ? 'Pick a date' : formatShortDate(value), style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Centered illustration + message for "nothing yet" / "no results" states.
class EmptyStateCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String message;
  final Color color;
  final Widget? action;

  const EmptyStateCard({super.key, required this.icon, required this.title, required this.message, required this.color, this.action});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final b = Theme.of(context).brightness;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 62,
              height: 62,
              decoration: BoxDecoration(color: AppPalette.tint(color, b), shape: BoxShape.circle),
              child: Icon(icon, size: 30, color: AppPalette.onTint(color, b)),
            ),
            const SizedBox(height: 12),
            Text(title, textAlign: TextAlign.center, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800)),
            const SizedBox(height: 6),
            Text(message, textAlign: TextAlign.center, style: TextStyle(color: scheme.onSurfaceVariant, height: 1.4)),
            if (action != null) ...[const SizedBox(height: 12), action!],
          ],
        ),
      ),
    );
  }
}

/// Thin summary line above a report table ("12 groups · 340 customers").
class ReportToolbar extends StatelessWidget {
  final String summary;
  final List<Widget> actions;

  const ReportToolbar({super.key, required this.summary, this.actions = const []});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 0, 0, 10),
      child: Row(
        children: [
          Expanded(child: Text(summary, style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant))),
          ...actions,
        ],
      ),
    );
  }
}

/// Compact peso amount for tight table cells: "—" for zero like vaxiCSR.
String tableMoney(double v) => v == 0 ? '—' : formatMoney(v);

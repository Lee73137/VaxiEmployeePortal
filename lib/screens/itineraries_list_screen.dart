import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/itineraries_provider.dart';
import '../providers/auth_provider.dart';
import '../models/itinerary.dart';
import '../theme/app_theme.dart';
import '../utils/formatting.dart';
import '../widgets/module_widgets.dart';
import 'itinerary_form_screen.dart';
import 'itinerary_visit_screen.dart';

class ItinerariesListScreen extends StatefulWidget {
  const ItinerariesListScreen({super.key});

  @override
  State<ItinerariesListScreen> createState() => _ItinerariesListScreenState();
}

class _ItinerariesListScreenState extends State<ItinerariesListScreen> {
  final Set<int> _selectedForApproval = {};

  String? get _username => context.read<AuthProvider>().userName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ItinerariesProvider>().refresh(_username);
    });
  }

  Future<void> _delete(Itinerary itinerary) async {
    final scheme = Theme.of(context).colorScheme;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete itinerary?'),
        content: Text('Delete the visit to "${itinerary.clinicName}"? This cannot be undone.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), style: TextButton.styleFrom(foregroundColor: scheme.error), child: const Text('Delete')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    final provider = context.read<ItinerariesProvider>();
    final ok = await provider.remove(itinerary.itineraryId, _username);
    if (ok && mounted) {
      await provider.refresh(_username);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Could not delete this itinerary.')));
    }
  }

  Future<void> _approve(Itinerary itinerary) async {
    final provider = context.read<ItinerariesProvider>();
    final ok = await provider.approve(itinerary.itineraryId, _username);
    if (ok && mounted) {
      await provider.refresh(_username);
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Could not approve this itinerary.')));
    }
  }

  Future<void> _approveSelected() async {
    if (_selectedForApproval.isEmpty) return;
    final provider = context.read<ItinerariesProvider>();
    final count = await provider.approveAll(_selectedForApproval.toList(), _username);
    if (!mounted) return;
    setState(() => _selectedForApproval.clear());
    if (count != null) {
      await provider.refresh(_username);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Approved $count itinerary(ies).')));
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Could not approve selected itineraries.')));
    }
  }


  Future<void> _setRange(DateTime from, DateTime to) =>
      context.read<ItinerariesProvider>().setDateRange(from, to, _username);

  Future<void> _pickCustomRange() async {
    final p = context.read<ItinerariesProvider>();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2018),
      lastDate: DateTime.now().add(const Duration(days: 365)),
      initialDateRange: DateTimeRange(start: p.dateFrom, end: p.dateTo),
    );
    if (picked != null) await _setRange(picked.start, picked.end);
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ItinerariesProvider>();
    final scheme = Theme.of(context).colorScheme;
    final b = Theme.of(context).brightness;
    final today = _day(DateTime.now());
    final presets = <_Preset>[
      _Preset('Today', today, today),
      _Preset('This week', today.subtract(Duration(days: today.weekday - 1)), today.add(Duration(days: 7 - today.weekday))),
      _Preset('Last 7 days', today.subtract(const Duration(days: 6)), today),
      _Preset('This month', DateTime(today.year, today.month, 1), DateTime(today.year, today.month + 1, 0)),
      _Preset('Next 7 days', today, today.add(const Duration(days: 6))),
    ];
    final from = _day(provider.dateFrom);
    final to = _day(provider.dateTo);
    final activePreset = presets.where((p) => p.from == from && p.to == to).firstOrNull;
    final counts = <String, int>{
      for (final s in ['Pending', 'Approved', 'Completed']) s: provider.items.where((i) => i.statusLabel == s).length,
    };

    return Scaffold(
      floatingActionButton: FloatingActionButton.extended(
        key: const Key('addItineraryFab'),
        backgroundColor: _color,
        onPressed: () async {
          final saved = await Navigator.of(context).push<Itinerary>(MaterialPageRoute(builder: (_) => const ItineraryFormScreen()));
          if (saved != null && context.mounted) context.read<ItinerariesProvider>().refresh(_username);
        },
        icon: const Icon(Icons.add_location_alt_rounded),
        label: const Text('New Visit'),
      ),
      body: Column(
        children: [
          ModuleHero(
            title: 'Itineraries',
            subtitle: 'Plan, approve and log clinic visits',
            icon: Icons.map_rounded,
            color: _color,
            actions: [
              if (provider.canApprove && _selectedForApproval.isNotEmpty)
                HeroPillButton(
                  icon: Icons.done_all_rounded,
                  label: 'Approve (${_selectedForApproval.length})',
                  color: _color,
                  onPressed: _approveSelected,
                ),
            ],
            bottom: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.event_rounded, color: Colors.white, size: 18),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        from == to ? formatShortDate(from) : '${formatShortDate(from)} – ${formatShortDate(to)}',
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 15),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    _StatusCount(label: 'Pending', count: counts['Pending']!, color: Colors.white),
                    const SizedBox(width: 8),
                    _StatusCount(label: 'Approved', count: counts['Approved']!, color: AppPalette.redSoft),
                    const SizedBox(width: 8),
                    _StatusCount(label: 'Completed', count: counts['Completed']!, color: AppPalette.green),
                  ],
                ),
              ],
            ),
          ),
          SizedBox(
            height: 56,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              children: [
                for (final p in presets) ...[
                  ChoiceChip(
                    label: Text(p.label),
                    selected: identical(activePreset, p),
                    showCheckmark: false,
                    selectedColor: AppPalette.tint(_color, b),
                    labelStyle: TextStyle(
                      fontWeight: FontWeight.w700,
                      color: identical(activePreset, p) ? AppPalette.onTint(_color, b) : scheme.onSurfaceVariant,
                    ),
                    onSelected: (_) => _setRange(p.from, p.to),
                  ),
                  const SizedBox(width: 8),
                ],
                ActionChip(
                  avatar: Icon(Icons.date_range_rounded, size: 18, color: activePreset == null ? AppPalette.onTint(_color, b) : null),
                  backgroundColor: activePreset == null ? AppPalette.tint(_color, b) : null,
                  label: Text('Custom range', style: TextStyle(fontWeight: FontWeight.w700, color: activePreset == null ? AppPalette.onTint(_color, b) : null)),
                  onPressed: _pickCustomRange,
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    key: const Key('itinerarySearchField'),
                    onChanged: (v) => context.read<ItinerariesProvider>().setSearch(v),
                    decoration: const InputDecoration(
                      hintText: 'Search clinic, purpose or rep…',
                      prefixIcon: Icon(Icons.search_rounded),
                      isDense: true,
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                FilterChip(
                  key: const Key('pendingOnlyChip'),
                  label: const Text('Pending only'),
                  selected: provider.pendingOnly,
                  selectedColor: AppPalette.tint(_color, b),
                  onSelected: (v) => context.read<ItinerariesProvider>().setPendingOnly(v, _username),
                ),
              ],
            ),
          ),
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: AppPalette.tint(AppPalette.red, b), borderRadius: BorderRadius.circular(14)),
                child: Row(
                  children: [
                    const Icon(Icons.error_outline, color: AppPalette.red, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(provider.errorMessage!, style: const TextStyle(color: AppPalette.red, fontSize: 13, fontWeight: FontWeight.w600))),
                  ],
                ),
              ),
            ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<ItinerariesProvider>().refresh(_username),
                    child: _filteredList(provider, scheme),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _filteredList(ItinerariesProvider provider, ColorScheme scheme) {
    final term = provider.search.trim().toLowerCase();
    final items = term.isEmpty
        ? provider.items
        : provider.items.where((i) {
            return (i.clinicName?.toLowerCase().contains(term) ?? false) ||
                (i.purpose?.toLowerCase().contains(term) ?? false) ||
                (i.repName?.toLowerCase().contains(term) ?? false);
          }).toList();

    if (items.isEmpty) {
      return ListView(
        children: const [
          SizedBox(height: 24),
          EmptyStateCard(
            icon: Icons.map_rounded,
            title: 'No visits in this range',
            message: 'Pick another date range above, or tap "New Visit" to plan one.',
            color: _color,
          ),
        ],
      );
    }

    // A header before each day's visits, in the order the API returns them.
    final entries = <Object>[];
    DateTime? lastDay;
    for (final i in items) {
      final d = _day(i.scheduleDate);
      if (lastDay != d) {
        entries.add(d);
        lastDay = d;
      }
      entries.add(i);
    }

    return ListView.builder(
      key: const Key('itinerariesList'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 96),
      itemCount: entries.length,
      itemBuilder: (context, index) {
        final e = entries[index];
        if (e is DateTime) {
          final n = items.where((i) => _day(i.scheduleDate) == e).length;
          return Padding(
            padding: const EdgeInsets.fromLTRB(4, 10, 4, 6),
            child: Row(
              children: [
                Text(_dayLabel(e), style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5)),
                const SizedBox(width: 8),
                Text('$n visit${n == 1 ? '' : 's'}', style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5, fontWeight: FontWeight.w600)),
              ],
            ),
          );
        }
        return Padding(padding: const EdgeInsets.only(bottom: 6), child: _visitCard(e as Itinerary, provider, scheme));
      },
    );
  }

  Widget _visitCard(Itinerary i, ItinerariesProvider provider, ColorScheme scheme) {
    final b = Theme.of(context).brightness;
    final statusColor = switch (i.statusLabel) {
      'Completed' => AppPalette.green,
      'Approved' => AppPalette.red,
      _ => AppPalette.black,
    };
    final isPending = i.approved != true;
    final selected = _selectedForApproval.contains(i.itineraryId);
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: () async {
          if (i.approved == true) {
            await Navigator.of(context).push(MaterialPageRoute(builder: (_) => ItineraryVisitScreen(itineraryId: i.itineraryId)));
            if (mounted) context.read<ItinerariesProvider>().refresh(_username);
          } else {
            final saved = await Navigator.of(context).push<Itinerary>(MaterialPageRoute(builder: (_) => ItineraryFormScreen(itinerary: i)));
            if (saved != null && mounted) context.read<ItinerariesProvider>().refresh(_username);
          }
        },
        child: IntrinsicHeight(
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Container(width: 5, color: statusColor),
              Padding(
                padding: const EdgeInsets.fromLTRB(10, 10, 2, 10),
                child: Container(
                  width: 42,
                  decoration: BoxDecoration(color: AppPalette.tint(statusColor, b), borderRadius: BorderRadius.circular(14)),
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('${i.scheduleDate.day}',
                          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppPalette.onTint(statusColor, b), height: 1)),
                      const SizedBox(height: 3),
                      Text(months[i.scheduleDate.month - 1],
                          style: TextStyle(fontSize: 10.5, fontWeight: FontWeight.w800, color: AppPalette.onTint(statusColor, b))),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 10, 6),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(i.clinicName ?? '',
                                style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 14.5), maxLines: 1, overflow: TextOverflow.ellipsis),
                          ),
                          const SizedBox(width: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 4),
                            decoration: BoxDecoration(color: AppPalette.tint(statusColor, b), borderRadius: BorderRadius.circular(20)),
                            child: Text(i.statusLabel,
                                style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: AppPalette.onTint(statusColor, b))),
                          ),
                          if (provider.canApprove)
                            IconButton(
                              tooltip: 'Delete',
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                              onPressed: () => _delete(i),
                              icon: const Icon(Icons.delete_outline_rounded, size: 19, color: AppPalette.red),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 10,
                        runSpacing: 2,
                        children: [
                          if (i.repName?.isNotEmpty ?? false) _meta(Icons.person_rounded, i.repName!, scheme),
                          if (i.areaName?.isNotEmpty ?? false) _meta(Icons.place_rounded, i.areaName!, scheme),
                          if (i.purpose?.isNotEmpty ?? false) _meta(Icons.flag_rounded, i.purpose!, scheme),
                        ],
                      ),
                      if (i.totalOverdueBalance > 0.01) ...[
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(color: AppPalette.tint(AppPalette.red, b), borderRadius: BorderRadius.circular(8)),
                          child: Text('Overdue ${formatMoney(i.totalOverdueBalance)}',
                              style: const TextStyle(fontSize: 11.5, color: AppPalette.red, fontWeight: FontWeight.w800)),
                        ),
                      ],
                      // Only pending visits need a second row (select + Approve);
                      // Delete sits next to the status above.
                      if (provider.canApprove && isPending)
                        Row(
                          children: [
                            Checkbox(
                              value: selected,
                              activeColor: _color,
                              visualDensity: VisualDensity.compact,
                              onChanged: (v) => setState(() {
                                if (v == true) {
                                  _selectedForApproval.add(i.itineraryId);
                                } else {
                                  _selectedForApproval.remove(i.itineraryId);
                                }
                              }),
                            ),
                            const Spacer(),
                            TextButton.icon(
                              onPressed: () => _approve(i),
                              icon: const Icon(Icons.check_circle_outline_rounded, size: 18),
                              label: const Text('Approve'),
                              style: TextButton.styleFrom(foregroundColor: AppPalette.greenText, visualDensity: VisualDensity.compact),
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _meta(IconData icon, String text, ColorScheme scheme) => Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: scheme.onSurfaceVariant),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12.5)),
        ],
      );
}

const _color = AppPalette.black;

DateTime _day(DateTime d) => DateTime(d.year, d.month, d.day);

String _dayLabel(DateTime d) {
  final today = _day(DateTime.now());
  if (d == today) return 'Today';
  if (d == today.subtract(const Duration(days: 1))) return 'Yesterday';
  if (d == today.add(const Duration(days: 1))) return 'Tomorrow';
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  return '${days[d.weekday - 1]}, ${formatShortDate(d)}';
}

class _Preset {
  final String label;
  final DateTime from;
  final DateTime to;

  _Preset(this.label, this.from, this.to);
}

class _StatusCount extends StatelessWidget {
  final String label;
  final int count;
  final Color color;

  const _StatusCount({required this.label, required this.count, required this.color});

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(14)),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('$count', style: const TextStyle(color: Colors.white, fontSize: 20, fontWeight: FontWeight.w800, height: 1.1)),
            const SizedBox(height: 3),
            Row(
              children: [
                Container(width: 7, height: 7, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                const SizedBox(width: 5),
                Flexible(
                  child: Text(label,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(color: Colors.white.withValues(alpha: 0.9), fontSize: 11.5, fontWeight: FontWeight.w700)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

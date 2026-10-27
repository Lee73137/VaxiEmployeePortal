import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../api/inventory_api.dart';
import '../api/invoices_api.dart';
import '../api/itineraries_api.dart';
import '../models/invoice.dart';
import '../models/itinerary.dart';
import '../navigation/app_modules.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import '../utils/formatting.dart';
import '../widgets/app_widgets.dart';
import 'profile_screen.dart';

/// Home tab: greeting + headline numbers pulled from the live modules,
/// shortcuts, today's visits and the four module groups. Each number loads
/// independently, so one failing endpoint only blanks its own tile.
class DashboardScreen extends StatefulWidget {
  final VoidCallback onOpenMenu;
  final ValueChanged<int> onOpenGroup;

  const DashboardScreen({super.key, required this.onOpenMenu, required this.onOpenGroup});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  InvoiceDashboard? _invoices;
  bool _invoicesFailed = false;
  int? _lowStock;
  bool _stockFailed = false;
  List<Itinerary>? _todayVisits;
  bool _visitsFailed = false;

  static const _quickAccess = ['Itineraries', 'Clinic Bookings', 'Collectibles', 'Returns', 'Clinics', 'Sales Summary'];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    await Future.wait([_loadInvoices(), _loadStock(), _loadVisits()]);
  }

  Future<void> _loadInvoices() async {
    try {
      final d = await InvoicesApi(context.read<AuthProvider>().client).dashboard();
      if (mounted) setState(() { _invoices = d; _invoicesFailed = false; });
    } catch (_) {
      if (mounted) setState(() => _invoicesFailed = true);
    }
  }

  Future<void> _loadStock() async {
    try {
      final r = await InventoryApi(context.read<AuthProvider>().client).list();
      final low = r.items.where((i) => i.statusLabel == 'Low Stock' || i.statusLabel == 'Out of Stock').length;
      if (mounted) setState(() { _lowStock = low; _stockFailed = false; });
    } catch (_) {
      if (mounted) setState(() => _stockFailed = true);
    }
  }

  Future<void> _loadVisits() async {
    try {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final r = await ItinerariesApi().list(
        username: context.read<AuthProvider>().userName,
        dateFrom: today,
        dateTo: today,
      );
      if (mounted) setState(() { _todayVisits = r.items; _visitsFailed = false; });
    } catch (_) {
      if (mounted) setState(() => _visitsFailed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final pending = _todayVisits?.where((v) => v.statusLabel == 'Pending').length;

    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: EdgeInsets.zero,
        children: [
          _Hero(
            name: auth.displayName,
            onOpenMenu: widget.onOpenMenu,
            overdue: _invoices?.overdue,
            failed: _invoicesFailed,
            onTapOverdue: () => openModule(context, moduleNamed('Invoices')),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        color: AppPalette.black,
                        icon: Icons.event_available_rounded,
                        label: 'Due in 7 days',
                        value: _invoices == null ? null : '${_invoices!.dueSoon.totalItems}',
                        caption: _invoices == null ? null : formatMoney(_invoices!.dueSoon.totalBalance),
                        failed: _invoicesFailed,
                        onTap: () => openModule(context, moduleNamed('Invoices')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        color: AppPalette.green,
                        icon: Icons.storefront_rounded,
                        label: 'Visits today',
                        value: _todayVisits == null ? null : '${_todayVisits!.length}',
                        caption: _todayVisits == null ? null : 'scheduled',
                        failed: _visitsFailed,
                        onTap: () => openModule(context, moduleNamed('Itineraries')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _StatTile(
                        color: AppPalette.red,
                        icon: Icons.pending_actions_rounded,
                        label: 'Awaiting approval',
                        value: pending == null ? null : '$pending',
                        caption: pending == null ? null : 'of today\'s visits',
                        failed: _visitsFailed,
                        onTap: () => openModule(context, moduleNamed('Itineraries')),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _StatTile(
                        color: AppPalette.red,
                        icon: Icons.inventory_rounded,
                        label: 'Low / out of stock',
                        value: _lowStock == null ? null : '$_lowStock',
                        caption: _lowStock == null ? null : 'items to reorder',
                        failed: _stockFailed,
                        onTap: () => openModule(context, moduleNamed('Inventory')),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Quick access'),
                SizedBox(
                  height: 80,
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: _quickAccess.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, i) {
                      final module = moduleNamed(_quickAccess[i]);
                      final group = appModuleGroups.firstWhere((g) => g.modules.contains(module));
                      return _QuickAction(module: module, color: group.color);
                    },
                  ),
                ),
                const SizedBox(height: 16),
                SectionHeader(
                  title: 'Today\'s visits',
                  action: 'See all',
                  onAction: () => openModule(context, moduleNamed('Itineraries')),
                ),
                _TodayVisits(visits: _todayVisits, failed: _visitsFailed),
                const SizedBox(height: 20),
                const SectionHeader(title: 'Browse'),
                GridView.count(
                  crossAxisCount: 2,
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  mainAxisSpacing: 12,
                  crossAxisSpacing: 12,
                  childAspectRatio: 1.9,
                  children: [
                    for (var i = 0; i < appModuleGroups.length; i++)
                      _GroupTile(group: appModuleGroups[i], onTap: () => widget.onOpenGroup(i)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

String _greeting() {
  final h = DateTime.now().hour;
  if (h < 12) return 'Good morning';
  if (h < 18) return 'Good afternoon';
  return 'Good evening';
}

String _todayLabel() {
  const days = ['Monday', 'Tuesday', 'Wednesday', 'Thursday', 'Friday', 'Saturday', 'Sunday'];
  const months = ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'];
  final d = DateTime.now();
  return '${days[d.weekday - 1]}, ${months[d.month - 1]} ${d.day}';
}

class _Hero extends StatelessWidget {
  final String name;
  final VoidCallback onOpenMenu;
  final InvoiceList? overdue;
  final bool failed;
  final VoidCallback onTapOverdue;

  const _Hero({required this.name, required this.onOpenMenu, required this.overdue, required this.failed, required this.onTapOverdue});

  @override
  Widget build(BuildContext context) {
    final firstName = name.trim().split(RegExp(r'\s+')).first;

    return Container(
      decoration: const BoxDecoration(
        gradient: AppPalette.heroGradient,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
      ),
      padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 6, 16, 16),
      child: Stack(
        children: [
          // Soft coloured glows - gives the header depth without an image.
          Positioned(top: -40, right: -30, child: _Glow(color: AppPalette.red, size: 170)),
          Positioned(bottom: -60, left: -40, child: _Glow(color: AppPalette.green, size: 190)),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: onOpenMenu,
                    tooltip: 'Menu',
                    icon: const Icon(Icons.menu_rounded, color: Colors.white),
                    style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.12)),
                  ),
                  const Spacer(),
                  Tooltip(
                    message: 'Profile & settings',
                    child: GestureDetector(
                      onTap: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ProfileScreen())),
                      child: InitialsAvatar(name: name, size: 36),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Text(_todayLabel(), style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 13, fontWeight: FontWeight.w600)),
              const SizedBox(height: 4),
              Text(
                '${_greeting()}, $firstName',
                style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.6),
              ),
              const SizedBox(height: 12),
              Material(
                color: Colors.white.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(22),
                child: InkWell(
                  borderRadius: BorderRadius.circular(22),
                  onTap: onTapOverdue,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Row(
                      children: [
                        Container(
                          width: 38,
                          height: 38,
                          decoration: BoxDecoration(color: AppPalette.red, borderRadius: BorderRadius.circular(15)),
                          child: const Icon(Icons.warning_amber_rounded, color: Colors.white),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Overdue balance', style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 12.5, fontWeight: FontWeight.w600)),
                              const SizedBox(height: 2),
                              overdue != null
                                  ? Text(
                                      formatMoney(overdue!.totalBalance),
                                      style: const TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.w800, letterSpacing: -0.4),
                                    )
                                  : Text(
                                      failed ? 'Unavailable' : 'Loading…',
                                      style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 17, fontWeight: FontWeight.w700),
                                    ),
                            ],
                          ),
                        ),
                        if (overdue != null)
                          Container(
                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.16), borderRadius: BorderRadius.circular(20)),
                            child: Text(
                              '${overdue!.totalItems} invoices',
                              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _Glow extends StatelessWidget {
  final Color color;
  final double size;

  const _Glow({required this.color, required this.size});

  @override
  Widget build(BuildContext context) {
    return IgnorePointer(
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: RadialGradient(colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _StatTile extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String label;
  final String? value;
  final String? caption;
  final bool failed;
  final VoidCallback onTap;

  const _StatTile({
    required this.color,
    required this.icon,
    required this.label,
    required this.value,
    required this.caption,
    required this.failed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Container(
          decoration: BoxDecoration(border: Border(top: BorderSide(color: color, width: 4))),
          padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  IconWell(icon: icon, color: color, size: 30),
                  const Spacer(),
                  Icon(Icons.arrow_outward_rounded, size: 16, color: scheme.outline),
                ],
              ),
              const SizedBox(height: 6),
              SizedBox(
                height: 26,
                child: value != null
                    ? Text(value!, style: const TextStyle(fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.6))
                    : failed
                        ? Text('—', style: TextStyle(fontSize: 21, fontWeight: FontWeight.w800, color: scheme.outline))
                        : const Align(
                            alignment: Alignment.centerLeft,
                            child: SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)),
                          ),
              ),
              const SizedBox(height: 2),
              Text(label, style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 1),
              Text(
                failed ? 'Couldn\'t load' : (caption ?? ' '),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _QuickAction extends StatelessWidget {
  final AppModule module;
  final Color color;

  const _QuickAction({required this.module, required this.color});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => openModule(context, module),
        child: Column(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                gradient: AppPalette.accentGradient(color),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [BoxShadow(color: color.withValues(alpha: 0.3), blurRadius: 12, offset: const Offset(0, 5))],
              ),
              child: Icon(module.icon, color: Colors.white, size: 21),
            ),
            const SizedBox(height: 8),
            Text(
              module.label,
              maxLines: 2,
              textAlign: TextAlign.center,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, height: 1.15),
            ),
          ],
        ),
      ),
    );
  }
}

class _TodayVisits extends StatelessWidget {
  final List<Itinerary>? visits;
  final bool failed;

  const _TodayVisits({required this.visits, required this.failed});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (visits == null) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Center(
            child: failed
                ? Text('Couldn\'t load today\'s visits', style: TextStyle(color: scheme.onSurfaceVariant))
                : const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
          ),
        ),
      );
    }
    if (visits!.isEmpty) {
      return Card(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Row(
            children: [
              const IconWell(icon: Icons.beach_access_rounded, color: AppPalette.green),
              const SizedBox(width: 14),
              Expanded(
                child: Text('No visits scheduled for today.', style: TextStyle(color: scheme.onSurfaceVariant, fontWeight: FontWeight.w600)),
              ),
            ],
          ),
        ),
      );
    }

    final shown = visits!.take(4).toList();
    return Card(
      child: Column(
        children: [
          for (var i = 0; i < shown.length; i++) ...[
            if (i > 0) Divider(height: 1, indent: 72, color: scheme.outlineVariant.withValues(alpha: 0.4)),
            ListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
              leading: const IconWell(icon: Icons.location_on_rounded, color: AppPalette.green, size: 40),
              title: Text(shown[i].clinicName ?? 'Clinic', maxLines: 1, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14.5)),
              trailing: _StatusPill(label: shown[i].statusLabel),
              onTap: () => openModule(context, moduleNamed('Itineraries')),
            ),
          ],
          if (visits!.length > shown.length)
            Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: Text('+${visits!.length - shown.length} more', style: TextStyle(color: scheme.primary, fontWeight: FontWeight.w700, fontSize: 13)),
            ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  final String label;

  const _StatusPill({required this.label});

  @override
  Widget build(BuildContext context) {
    final color = switch (label) {
      'Completed' => AppPalette.green,
      'Approved' => AppPalette.red,
      _ => AppPalette.black,
    };
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(color: AppPalette.tint(color, b), borderRadius: BorderRadius.circular(20)),
      child: Text(label, style: TextStyle(color: AppPalette.onTint(color, b), fontSize: 11.5, fontWeight: FontWeight.w800)),
    );
  }
}

class _GroupTile extends StatelessWidget {
  final AppModuleGroup group;
  final VoidCallback onTap;

  const _GroupTile({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final count = group.modules.where((m) => m.isAvailable).length;

    return Material(
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: Ink(
        decoration: BoxDecoration(gradient: AppPalette.accentGradient(group.color)),
        child: InkWell(
          onTap: onTap,
          child: Stack(
            children: [
              Positioned(right: -14, bottom: -16, child: Icon(group.icon, size: 60, color: Colors.white.withValues(alpha: 0.16))),
              Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(group.icon, color: Colors.white, size: 20),
                    const Spacer(),
                    Text(group.label, style: const TextStyle(color: Colors.white, fontWeight: FontWeight.w800, fontSize: 13.5, height: 1.15)),
                    const SizedBox(height: 3),
                    Text('$count pages', style: TextStyle(color: Colors.white.withValues(alpha: 0.8), fontSize: 12, fontWeight: FontWeight.w600)),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

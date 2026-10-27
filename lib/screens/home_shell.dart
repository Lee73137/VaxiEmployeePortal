import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../navigation/app_modules.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_drafts_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import 'dashboard_screen.dart';
import 'group_hub_screen.dart';
import 'login_screen.dart';
import 'profile_screen.dart';

/// The signed-in app frame: a bottom bar with the dashboard plus one tab per
/// module group, and a drawer menu listing every page grouped the same way.
class HomeShell extends StatefulWidget {
  const HomeShell({super.key});

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> with WidgetsBindingObserver {
  final _scaffoldKey = GlobalKey<ScaffoldState>();
  int _tab = 0;
  Timer? _syncTimer;

  void _openMenu() => _scaffoldKey.currentState?.openDrawer();

  void _goToGroup(int groupIndex) => setState(() => _tab = groupIndex + 1);

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Keep the offline booking data current whenever there's signal, so a
    // booking can still be made later with none, then send anything saved
    // while offline. Both silently no-op with no connection.
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final user = context.read<AuthProvider>().userName;
      await context.read<BookingDraftsProvider>().ensureFreshPack(user);
      await _autoSync();
    });
    // Retry every minute so bookings go out soon after signal returns, even
    // if the app just stays open.
    _syncTimer = Timer.periodic(const Duration(minutes: 1), (_) => _autoSync());
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _syncTimer?.cancel();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _autoSync();
  }

  /// Sends bookings saved on the phone, and says so when any went out.
  Future<void> _autoSync() async {
    if (!mounted) return;
    final drafts = context.read<BookingDraftsProvider>();
    final sent = await drafts.syncPending(context.read<AuthProvider>().userName);
    if (sent > 0 && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$sent saved booking${sent == 1 ? ' was' : 's were'} submitted automatically.'),
      ));
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      drawer: AppMenuDrawer(
        onGroupSelected: (i) {
          Navigator.of(context).pop();
          _goToGroup(i);
        },
      ),
      body: IndexedStack(
        index: _tab,
        children: [
          DashboardScreen(onOpenMenu: _openMenu, onOpenGroup: _goToGroup),
          for (final group in appModuleGroups)
            GroupHubScreen(group: group, onOpenMenu: _openMenu),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _tab,
        onDestinationSelected: (i) => setState(() => _tab = i),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.space_dashboard_outlined),
            selectedIcon: Icon(Icons.space_dashboard_rounded),
            label: 'Home',
          ),
          for (final group in appModuleGroups)
            NavigationDestination(
              icon: Icon(
                group.icon,
                color: AppPalette.onTint(group.color, Theme.of(context).brightness).withValues(alpha: 0.75),
              ),
              selectedIcon: Icon(group.icon, color: AppPalette.onTint(group.color, Theme.of(context).brightness)),
              label: group.tabLabel,
            ),
        ],
      ),
    );
  }
}

class AppMenuDrawer extends StatelessWidget {
  final ValueChanged<int> onGroupSelected;

  const AppMenuDrawer({super.key, required this.onGroupSelected});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final auth = context.watch<AuthProvider>();

    return Drawer(
      child: Column(
        children: [
          Material(
            color: Colors.transparent,
            child: Ink(
              width: double.infinity,
              decoration: const BoxDecoration(
                gradient: AppPalette.heroGradient,
                borderRadius: BorderRadius.only(
                  bottomRight: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
              ),
              child: InkWell(
                borderRadius: const BorderRadius.only(
                  bottomRight: Radius.circular(28),
                  topRight: Radius.circular(28),
                ),
                onTap: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const ProfileScreen()),
                  );
                },
                child: Padding(
                  padding: EdgeInsets.fromLTRB(
                    20,
                    MediaQuery.of(context).padding.top + 20,
                    20,
                    22,
                  ),
                  child: Row(
                    children: [
                      InitialsAvatar(name: auth.displayName, size: 52),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              auth.displayName,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 17,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '@${auth.userName ?? ''} · Profile & settings',
                              style: TextStyle(
                                color: Colors.white.withValues(alpha: 0.7),
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const Icon(
                        Icons.chevron_right_rounded,
                        color: Colors.white,
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: ListView(
              padding: const EdgeInsets.fromLTRB(12, 12, 12, 12),
              children: [
                for (var i = 0; i < appModuleGroups.length; i++) ...[
                  _GroupHeader(
                    group: appModuleGroups[i],
                    onTap: () => onGroupSelected(i),
                  ),
                  for (final module in appModuleGroups[i].modules)
                    ListTile(
                      dense: true,
                      visualDensity: const VisualDensity(vertical: -1),
                      contentPadding: const EdgeInsets.only(left: 14, right: 8),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      leading: Icon(
                        module.icon,
                        size: 21,
                        color: module.isAvailable
                            ? AppPalette.onTint(appModuleGroups[i].color, Theme.of(context).brightness)
                            : scheme.outline,
                      ),
                      title: Text(
                        module.label,
                        style: TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          color: module.isAvailable
                              ? scheme.onSurface
                              : scheme.onSurfaceVariant,
                        ),
                      ),
                      trailing: module.isAvailable ? null : const SoonBadge(),
                      onTap: () {
                        Navigator.of(context).pop();
                        openModule(context, module);
                      },
                    ),
                  const SizedBox(height: 8),
                ],
              ],
            ),
          ),
          const Divider(height: 1),
          ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 24,
              vertical: 6,
            ),
            leading: const Icon(Icons.logout_rounded, color: AppPalette.red),
            title: const Text(
              'Log out',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                color: AppPalette.red,
              ),
            ),
            onTap: () async {
              final navigator = Navigator.of(context);
              await context.read<AuthProvider>().logout();
              navigator.pushAndRemoveUntil(
                MaterialPageRoute(builder: (_) => const LoginScreen()),
                (route) => false,
              );
            },
          ),
          SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
        ],
      ),
    );
  }
}

class _GroupHeader extends StatelessWidget {
  final AppModuleGroup group;
  final VoidCallback onTap;

  const _GroupHeader({required this.group, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(12),
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 10, 12, 6),
        child: Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: group.color,
                borderRadius: BorderRadius.circular(4),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                group.label.toUpperCase(),
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.8,
                  color: AppPalette.onTint(
                    group.color,
                    Theme.of(context).brightness,
                  ),
                ),
              ),
            ),
            Icon(Icons.arrow_forward_rounded, size: 16, color: AppPalette.onTint(group.color, Theme.of(context).brightness)),
          ],
        ),
      ),
    );
  }
}

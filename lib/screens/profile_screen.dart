import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../providers/booking_drafts_provider.dart';
import '../providers/settings_provider.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';
import '../widgets/module_widgets.dart';
import 'clinic_bookings_list_screen.dart';
import 'login_screen.dart';

/// Profile: who's signed in, the app's text size, the offline data kept on
/// this phone, and log out.
class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  static const _presets = <String, double>{'Small': 0.9, 'Default': 1.0, 'Large': 1.15, 'Extra large': 1.3};

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<BookingDraftsProvider>().load(context.read<AuthProvider>().userName);
    });
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final settings = context.watch<SettingsProvider>();
    final drafts = context.watch<BookingDraftsProvider>();
    final scheme = Theme.of(context).colorScheme;
    final b = Theme.of(context).brightness;

    return Scaffold(
      body: ListView(
        padding: EdgeInsets.zero,
        children: [
          Container(
            decoration: const BoxDecoration(
              gradient: AppPalette.heroGradient,
              borderRadius: BorderRadius.vertical(bottom: Radius.circular(32)),
            ),
            padding: EdgeInsets.fromLTRB(12, MediaQuery.of(context).padding.top + 4, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconButton(
                  onPressed: () => Navigator.of(context).maybePop(),
                  icon: const Icon(Icons.arrow_back_rounded, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.14)),
                ),
                const SizedBox(height: 10),
                Padding(
                  padding: const EdgeInsets.only(left: 8),
                  child: Row(
                    children: [
                      InitialsAvatar(name: auth.displayName, size: 54),
                      const SizedBox(width: 16),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(auth.displayName,
                                style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w800, letterSpacing: -0.4)),
                            const SizedBox(height: 2),
                            Text('@${auth.userName ?? ''}', style: TextStyle(color: Colors.white.withValues(alpha: 0.75))),
                            if (auth.repCode?.trim().isNotEmpty ?? false) ...[
                              const SizedBox(height: 8),
                              HeroFilterChips(labels: ['Rep code ${auth.repCode!.trim()}']),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _Section(
                  icon: Icons.format_size_rounded,
                  color: AppPalette.red,
                  title: 'Text size',
                  subtitle: 'Make the app\'s text smaller if things look cramped, or bigger to read more easily.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppPalette.tint(AppPalette.red, b), borderRadius: BorderRadius.circular(14)),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('VETS 4 PETS CLINIC', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 15)),
                            const SizedBox(height: 2),
                            Text('Booking · 3 items · ₱12,450.00', style: TextStyle(color: scheme.onSurfaceVariant)),
                          ],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Text('A', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w800)),
                          Expanded(
                            child: Slider(
                              value: settings.textScale,
                              min: SettingsProvider.minTextScale,
                              max: SettingsProvider.maxTextScale,
                              divisions: 10,
                              activeColor: AppPalette.red,
                              label: '${(settings.textScale * 100).round()}%',
                              onChanged: settings.setTextScale,
                            ),
                          ),
                          const Text('A', style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                        ],
                      ),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          for (final e in _presets.entries)
                            ChoiceChip(
                              label: Text(e.key),
                              showCheckmark: false,
                              selected: (settings.textScale - e.value).abs() < 0.01,
                              selectedColor: AppPalette.tint(AppPalette.red, b),
                              onSelected: (_) => settings.setTextScale(e.value),
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _Section(
                  icon: Icons.cloud_download_rounded,
                  color: AppPalette.green,
                  title: 'Offline bookings',
                  subtitle: 'Clinics, items and prices are saved on this phone so you can create bookings with no signal. '
                      'A booking submitted with no signal is sent automatically once you\'re back online; one kept with '
                      '"Save to phone" waits for you to submit it.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _InfoRow(
                        label: 'Last downloaded',
                        value: drafts.pack == null ? 'Not yet' : BookingDraftsProvider.formatWhen(drafts.pack!.generatedAt),
                      ),
                      if (drafts.pack != null)
                        _InfoRow(label: 'Saved for offline', value: '${drafts.pack!.clinics.length} clinics · ${drafts.pack!.items.length} items'),
                      _InfoRow(label: 'Bookings waiting to submit', value: '${drafts.drafts.length}'),
                      if (drafts.packError != null)
                        Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(drafts.packError!, style: const TextStyle(color: AppPalette.red, fontWeight: FontWeight.w600, fontSize: 12.5)),
                        ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Expanded(
                            child: FilledButton.icon(
                              style: FilledButton.styleFrom(backgroundColor: AppPalette.greenText),
                              onPressed: drafts.refreshingPack ? null : () => drafts.refreshPack(auth.userName),
                              icon: drafts.refreshingPack
                                  ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                                  : const Icon(Icons.download_rounded),
                              label: Text(drafts.refreshingPack ? 'Downloading…' : 'Download now'),
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: () => Navigator.of(context).push(MaterialPageRoute(builder: (_) => const ClinicBookingsListScreen())),
                              icon: const Icon(Icons.local_shipping_outlined),
                              label: const Text('Bookings'),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 10),
                _Section(
                  icon: Icons.logout_rounded,
                  color: AppPalette.red,
                  title: 'Account',
                  subtitle: drafts.drafts.isEmpty
                      ? 'Log out of vaxihubV2 on this phone.'
                      : 'You have ${drafts.drafts.length} booking${drafts.drafts.length == 1 ? '' : 's'} saved on this phone. '
                          'They stay saved and come back when you log in again.',
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(foregroundColor: AppPalette.red, side: const BorderSide(color: AppPalette.red)),
                    onPressed: () async {
                      final navigator = Navigator.of(context);
                      await context.read<AuthProvider>().logout();
                      navigator.pushAndRemoveUntil(MaterialPageRoute(builder: (_) => const LoginScreen()), (route) => false);
                    },
                    icon: const Icon(Icons.logout_rounded),
                    label: const Text('Log out'),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  final String subtitle;
  final Widget child;

  const _Section({required this.icon, required this.color, required this.title, required this.subtitle, required this.child});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                IconWellSmall(icon: icon, color: color),
                const SizedBox(width: 12),
                Expanded(child: Text(title, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800))),
              ],
            ),
            const SizedBox(height: 8),
            Text(subtitle, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13, height: 1.4)),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final String label;
  final String value;

  const _InfoRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(child: Text(label, style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 13))),
          const SizedBox(width: 12),
          Flexible(child: Text(value, textAlign: TextAlign.end, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13))),
        ],
      ),
    );
  }
}

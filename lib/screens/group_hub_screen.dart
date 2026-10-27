import 'package:flutter/material.dart';
import '../navigation/app_modules.dart';
import '../theme/app_theme.dart';
import '../widgets/app_widgets.dart';

/// One bottom-bar tab: a colour-coded header for the group, then a roomy
/// card per page in it.
class GroupHubScreen extends StatelessWidget {
  final AppModuleGroup group;
  final VoidCallback onOpenMenu;

  const GroupHubScreen({super.key, required this.group, required this.onOpenMenu});

  @override
  Widget build(BuildContext context) {
    final available = group.modules.where((m) => m.isAvailable).length;

    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: Container(
            decoration: BoxDecoration(
              gradient: AppPalette.accentGradient(group.color),
              borderRadius: const BorderRadius.vertical(bottom: Radius.circular(22)),
            ),
            padding: EdgeInsets.fromLTRB(20, MediaQuery.of(context).padding.top + 6, 16, 16),
            child: Stack(
              children: [
                // Oversized faded group icon as a background motif.
                Positioned(
                  right: -18,
                  bottom: -26,
                  child: Icon(group.icon, size: 96, color: Colors.white.withValues(alpha: 0.12)),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    IconButton(
                      onPressed: onOpenMenu,
                      icon: const Icon(Icons.menu_rounded, color: Colors.white),
                      tooltip: 'Menu',
                      style: IconButton.styleFrom(backgroundColor: Colors.white.withValues(alpha: 0.16)),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      group.label,
                      style: const TextStyle(color: Colors.white, fontSize: 21, fontWeight: FontWeight.w800, letterSpacing: -0.6),
                    ),
                    const SizedBox(height: 6),
                    Text(group.description, style: TextStyle(color: Colors.white.withValues(alpha: 0.85), fontSize: 14)),
                    const SizedBox(height: 10),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(color: Colors.white.withValues(alpha: 0.18), borderRadius: BorderRadius.circular(20)),
                      child: Text(
                        '$available ${available == 1 ? 'page' : 'pages'}',
                        style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.w700),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(14, 14, 14, 20),
          sliver: SliverList.separated(
            itemCount: group.modules.length,
            separatorBuilder: (_, _) => const SizedBox(height: 8),
            itemBuilder: (context, i) => _ModuleCard(module: group.modules[i], color: group.color),
          ),
        ),
      ],
    );
  }
}

class _ModuleCard extends StatelessWidget {
  final AppModule module;
  final Color color;

  const _ModuleCard({required this.module, required this.color});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final enabled = module.isAvailable;

    return Opacity(
      opacity: enabled ? 1 : 0.55,
      child: Card(
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () => openModule(context, module),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 8, 10),
            child: Row(
              children: [
                IconWell(icon: module.icon, color: color, size: 40),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(module.label, style: const TextStyle(fontSize: 14.5, fontWeight: FontWeight.w700)),
                      const SizedBox(height: 3),
                      Text(module.subtitle, style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
                enabled ? Icon(Icons.chevron_right_rounded, color: scheme.outline) : const SoonBadge(),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

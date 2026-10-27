import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/clinic_accounts_provider.dart';
import '../providers/auth_provider.dart';
import '../models/clinic_account.dart';

class ClinicAccountsListScreen extends StatefulWidget {
  const ClinicAccountsListScreen({super.key});

  @override
  State<ClinicAccountsListScreen> createState() => _ClinicAccountsListScreenState();
}

class _ClinicAccountsListScreenState extends State<ClinicAccountsListScreen> {
  final Set<String> _sending = {};

  String? get _username => context.read<AuthProvider>().userName;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ClinicAccountsProvider>().refresh(_username);
    });
  }

  Future<void> _sendReset(ClinicAccount account) async {
    if (account.email == null || account.email!.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('This account has no email on file.')));
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Send password reset?'),
        content: Text('This will email a real, working reset link to ${account.email} for "${account.displayName}". Continue?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(onPressed: () => Navigator.pop(ctx, true), child: const Text('Send')),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _sending.add(account.id));
    final provider = context.read<ClinicAccountsProvider>();
    final ok = await provider.sendPasswordReset(account);
    if (!mounted) return;
    setState(() => _sending.remove(account.id));

    if (ok) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Reset link sent to ${account.email}.')));
      await provider.refresh(_username);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(provider.errorMessage ?? 'Could not send reset link.')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<ClinicAccountsProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('VaxiShApp Accounts')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
            child: SearchBar(
              key: const Key('clinicAccountSearchField'),
              hintText: 'Search by username, email, or clinic…',
              leading: const Icon(Icons.search),
              elevation: const WidgetStatePropertyAll(0),
              backgroundColor: WidgetStatePropertyAll(scheme.surfaceContainerHighest.withValues(alpha: 0.5)),
              onChanged: (v) {
                context.read<ClinicAccountsProvider>().setSearch(v);
                context.read<ClinicAccountsProvider>().refresh(_username);
              },
            ),
          ),
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    '${provider.totalItems} account${provider.totalItems == 1 ? '' : 's'}',
                    style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
                  ),
                ),
              ],
            ),
          ),
          if (provider.errorMessage != null)
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(12)),
                child: Row(
                  children: [
                    Icon(Icons.error_outline, color: scheme.onErrorContainer, size: 18),
                    const SizedBox(width: 8),
                    Expanded(child: Text(provider.errorMessage!, style: TextStyle(color: scheme.onErrorContainer, fontSize: 13))),
                  ],
                ),
              ),
            ),
          Expanded(
            child: provider.isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
                    onRefresh: () => context.read<ClinicAccountsProvider>().refresh(_username),
                    child: _list(provider, scheme),
                  ),
          ),
          if (provider.totalPages > 1)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  IconButton(
                    icon: const Icon(Icons.chevron_left),
                    onPressed: provider.page > 1 ? () => provider.goToPage(provider.page - 1, _username) : null,
                  ),
                  Text('Page ${provider.page} of ${provider.totalPages}', style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                  IconButton(
                    icon: const Icon(Icons.chevron_right),
                    onPressed: provider.page < provider.totalPages ? () => provider.goToPage(provider.page + 1, _username) : null,
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _list(ClinicAccountsProvider provider, ColorScheme scheme) {
    if (provider.items.isEmpty) {
      return ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(48),
            child: Column(
              children: [
                Icon(Icons.phone_android_outlined, size: 56, color: scheme.onSurfaceVariant.withValues(alpha: 0.5)),
                const SizedBox(height: 12),
                Text('No accounts found.', style: TextStyle(color: scheme.onSurfaceVariant)),
              ],
            ),
          ),
        ],
      );
    }

    return ListView.separated(
      key: const Key('clinicAccountsList'),
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: provider.items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) {
        final a = provider.items[index];
        final sending = _sending.contains(a.id);

        return Card(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 20,
                  backgroundColor: a.isrestricted ? scheme.surfaceContainerHighest : scheme.primaryContainer,
                  foregroundColor: a.isrestricted ? scheme.onSurfaceVariant : scheme.onPrimaryContainer,
                  child: Text(a.displayName.isNotEmpty ? a.displayName[0].toUpperCase() : '?', style: const TextStyle(fontWeight: FontWeight.bold)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(a.displayName, style: const TextStyle(fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
                      const SizedBox(height: 2),
                      Text(
                        [a.userName, a.email, if (a.salesRepCode?.isNotEmpty ?? false) a.salesRepCode].where((s) => s != null && s.isNotEmpty).join(' · '),
                        style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (a.isrestricted || a.resetLinkCount > 0) ...[
                        const SizedBox(height: 4),
                        Wrap(
                          spacing: 6,
                          children: [
                            if (a.isrestricted)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: scheme.errorContainer, borderRadius: BorderRadius.circular(8)),
                                child: Text('Restricted', style: TextStyle(fontSize: 10, color: scheme.onErrorContainer)),
                              ),
                            if (a.resetLinkCount > 0)
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: scheme.surfaceContainerHighest, borderRadius: BorderRadius.circular(8)),
                                child: Text('${a.resetLinkCount} reset link${a.resetLinkCount == 1 ? '' : 's'}', style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                              ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                IconButton(
                  key: Key('resetButton_${a.id}'),
                  tooltip: 'Send password reset',
                  icon: sending ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.lock_reset_outlined),
                  onPressed: sending ? null : () => _sendReset(a),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

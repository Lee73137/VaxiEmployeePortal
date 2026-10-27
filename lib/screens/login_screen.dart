import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import '../theme/app_theme.dart';
import 'home_shell.dart';

class LoginScreen extends StatefulWidget {
  final bool sessionExpired;

  const LoginScreen({super.key, this.sessionExpired = false});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _usernameController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final ok = await auth.login(
      _usernameController.text.trim(),
      _passwordController.text,
    );
    if (ok && mounted) {
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (_) => const HomeShell()),
      );
    }
  }

  @override
  void dispose() {
    _usernameController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: AppPalette.black,
      body: Container(
        decoration: const BoxDecoration(gradient: AppPalette.heroGradient),
        child: Stack(
          children: [
            const Positioned(top: -60, right: -50, child: _Glow(color: AppPalette.red, size: 260)),
            const Positioned(top: 140, left: -90, child: _Glow(color: AppPalette.green, size: 240)),
            const Positioned(top: 40, left: 120, child: _Glow(color: AppPalette.black, size: 120)),
            SafeArea(
              bottom: false,
              child: LayoutBuilder(
                builder: (context, constraints) => SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(minHeight: constraints.maxHeight),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Padding(
                          padding: const EdgeInsets.fromLTRB(28, 48, 28, 36),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 64,
                                height: 64,
                                decoration: BoxDecoration(
                                  gradient: const LinearGradient(
                                    colors: [AppPalette.red, AppPalette.black],
                                    begin: Alignment.topLeft,
                                    end: Alignment.bottomRight,
                                  ),
                                  borderRadius: BorderRadius.circular(20),
                                  boxShadow: [
                                    BoxShadow(color: AppPalette.red.withValues(alpha: 0.45), blurRadius: 24, offset: const Offset(0, 10)),
                                  ],
                                ),
                                alignment: Alignment.center,
                                child: const Text('V', style: TextStyle(color: Colors.white, fontSize: 32, fontWeight: FontWeight.w800)),
                              ),
                              const SizedBox(height: 28),
                              const Text(
                                'Welcome to\nvaxihubV2',
                                style: TextStyle(color: Colors.white, fontSize: 34, fontWeight: FontWeight.w800, height: 1.1, letterSpacing: -1),
                              ),
                              const SizedBox(height: 10),
                              Text(
                                'Sales, clinics, field work and reports - all in one place.',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.75), fontSize: 15, height: 1.4),
                              ),
                              const SizedBox(height: 20),
                              const Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  _FeatureChip(label: 'Sales', color: AppPalette.red),
                                  _FeatureChip(label: 'Clinics', color: AppPalette.green),
                                  _FeatureChip(label: 'Field', color: Colors.white),
                                  _FeatureChip(label: 'Reports', color: AppPalette.redSoft),
                                ],
                              ),
                            ],
                          ),
                        ),
                        Container(
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: scheme.surfaceContainer,
                            borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                          ),
                          padding: EdgeInsets.fromLTRB(24, 28, 24, MediaQuery.of(context).padding.bottom + 24),
                          child: Center(
                            child: ConstrainedBox(
                              constraints: const BoxConstraints(maxWidth: 420),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text('Sign in', style: Theme.of(context).textTheme.headlineSmall),
                                  const SizedBox(height: 4),
                                  Text('Use your Vaxilife account.', style: TextStyle(color: scheme.onSurfaceVariant)),
                                  if (widget.sessionExpired) ...[
                                    const SizedBox(height: 16),
                                    _Banner(
                                      icon: Icons.info_outline,
                                      color: AppPalette.black,
                                      text: 'Your session has expired. Please log in again.',
                                    ),
                                  ],
                                  const SizedBox(height: 22),
                                  TextField(
                                    key: const Key('usernameField'),
                                    controller: _usernameController,
                                    textInputAction: TextInputAction.next,
                                    decoration: const InputDecoration(
                                      labelText: 'Username',
                                      prefixIcon: Icon(Icons.person_outline),
                                    ),
                                  ),
                                  const SizedBox(height: 14),
                                  TextField(
                                    key: const Key('passwordField'),
                                    controller: _passwordController,
                                    obscureText: _obscurePassword,
                                    textInputAction: TextInputAction.done,
                                    decoration: InputDecoration(
                                      labelText: 'Password',
                                      prefixIcon: const Icon(Icons.lock_outline),
                                      suffixIcon: IconButton(
                                        icon: Icon(_obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                                        onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                                      ),
                                    ),
                                    onSubmitted: (_) => _submit(),
                                  ),
                                  if (auth.errorMessage != null) ...[
                                    const SizedBox(height: 14),
                                    _Banner(icon: Icons.error_outline, color: AppPalette.red, text: auth.errorMessage!),
                                  ],
                                  const SizedBox(height: 22),
                                  DecoratedBox(
                                    decoration: BoxDecoration(
                                      gradient: const LinearGradient(colors: [AppPalette.red, Color(0xFF8E1B1B)]),
                                      borderRadius: BorderRadius.circular(16),
                                      boxShadow: [
                                        BoxShadow(color: AppPalette.red.withValues(alpha: 0.35), blurRadius: 18, offset: const Offset(0, 8)),
                                      ],
                                    ),
                                    child: FilledButton(
                                      key: const Key('loginButton'),
                                      style: FilledButton.styleFrom(backgroundColor: Colors.transparent, shadowColor: Colors.transparent),
                                      onPressed: auth.isLoading ? null : _submit,
                                      child: auth.isLoading
                                          ? const SizedBox(
                                              width: 20,
                                              height: 20,
                                              child: CircularProgressIndicator(strokeWidth: 2.4, color: Colors.white),
                                            )
                                          : const Text('Log in'),
                                    ),
                                  ),
                                  const SizedBox(height: 20),
                                  Text(
                                    '© 2026 Vaxilife Corp',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: scheme.onSurfaceVariant, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
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
          gradient: RadialGradient(colors: [color.withValues(alpha: 0.4), color.withValues(alpha: 0)]),
        ),
      ),
    );
  }
}

class _FeatureChip extends StatelessWidget {
  final String label;
  final Color color;

  const _FeatureChip({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.15)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
          const SizedBox(width: 7),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12.5, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

class _Banner extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String text;

  const _Banner({required this.icon, required this.color, required this.text});

  @override
  Widget build(BuildContext context) {
    final b = Theme.of(context).brightness;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(color: AppPalette.tint(color, b), borderRadius: BorderRadius.circular(14)),
      child: Row(
        children: [
          Icon(icon, color: AppPalette.onTint(color, b), size: 18),
          const SizedBox(width: 10),
          Expanded(child: Text(text, style: TextStyle(color: AppPalette.onTint(color, b), fontSize: 13, fontWeight: FontWeight.w600))),
        ],
      ),
    );
  }
}

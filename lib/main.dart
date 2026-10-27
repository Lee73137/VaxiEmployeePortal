import 'dart:async';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'api/api_client.dart';
import 'providers/auth_provider.dart';
import 'providers/customers_provider.dart';
import 'providers/inventory_provider.dart';
import 'providers/invoices_provider.dart';
import 'providers/returns_provider.dart';
import 'providers/forecast_provider.dart';
import 'providers/clinics_provider.dart';
import 'providers/clinic_history_provider.dart';
import 'providers/itineraries_provider.dart';
import 'providers/collectibles_provider.dart';
import 'providers/clinic_accounts_provider.dart';
import 'providers/promo_invoices_provider.dart';
import 'providers/sales_pivot_provider.dart';
import 'providers/sales_summary_provider.dart';
import 'providers/performance_provider.dart';
import 'providers/product_sales_provider.dart';
import 'providers/marketing_support_provider.dart';
import 'providers/clinic_bookings_provider.dart';
import 'providers/booking_drafts_provider.dart';
import 'providers/settings_provider.dart';
import 'api/clinic_bookings_api.dart';
import 'screens/login_screen.dart';
import 'screens/home_shell.dart';
import 'theme/app_theme.dart';

void main() {
  runApp(const VaxiCsrApp());
}

class VaxiCsrApp extends StatefulWidget {
  const VaxiCsrApp({super.key});

  @override
  State<VaxiCsrApp> createState() => _VaxiCsrAppState();
}

class _VaxiCsrAppState extends State<VaxiCsrApp> {
  final _navigatorKey = GlobalKey<NavigatorState>();
  late final ApiClient _apiClient;
  late final AuthProvider _authProvider;
  final _settings = SettingsProvider();
  StreamSubscription<void>? _unauthorizedSub;

  @override
  void initState() {
    super.initState();
    _apiClient = ApiClient();
    _authProvider = AuthProvider(_apiClient);
    _settings.load();

    // Lives for the whole app (this State is created once at the root and
    // never disposed by navigation), so a 401 from any screen at any time
    // reliably clears the session and kicks back to Login - one place to
    // handle it instead of every screen catching it individually.
    _unauthorizedSub = _apiClient.onUnauthorized.listen((_) {
      _authProvider.logout();
      _navigatorKey.currentState?.pushAndRemoveUntil(
        MaterialPageRoute(
          builder: (_) => const LoginScreen(sessionExpired: true),
        ),
        (route) => false,
      );
    });
  }

  @override
  void dispose() {
    _unauthorizedSub?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider.value(value: _authProvider),
        ChangeNotifierProvider(create: (_) => CustomersProvider(_apiClient)),
        ChangeNotifierProvider(create: (_) => InventoryProvider(_apiClient)),
        ChangeNotifierProvider(create: (_) => InvoicesProvider(_apiClient)),
        ChangeNotifierProvider(create: (_) => ReturnsProvider(_apiClient)),
        ChangeNotifierProvider(create: (_) => ForecastProvider(_apiClient)),
        ChangeNotifierProvider(create: (_) => ClinicsProvider(_apiClient)),
        ChangeNotifierProvider(
          create: (_) => ClinicHistoryProvider(_apiClient),
        ),
        ChangeNotifierProvider(create: (_) => ItinerariesProvider()),
        ChangeNotifierProvider(create: (_) => CollectiblesProvider()),
        ChangeNotifierProvider(create: (_) => ClinicAccountsProvider()),
        ChangeNotifierProvider(create: (_) => PromoInvoicesProvider()),
        ChangeNotifierProvider(create: (_) => SalesPivotProvider()),
        ChangeNotifierProvider(create: (_) => SalesSummaryProvider()),
        ChangeNotifierProvider(create: (_) => PerformanceProvider()),
        ChangeNotifierProvider(create: (_) => ProductSalesProvider()),
        ChangeNotifierProvider(create: (_) => MarketingSupportProvider()),
        ChangeNotifierProvider(create: (_) => ClinicBookingsProvider()),
        ChangeNotifierProvider(create: (_) => BookingDraftsProvider(ClinicBookingsApi())),
        ChangeNotifierProvider.value(value: _settings),
      ],
      child: Consumer<SettingsProvider>(
        builder: (context, settings, _) => MaterialApp(
          navigatorKey: _navigatorKey,
          title: 'vaxihubV2',
          debugShowCheckedModeBanner: false,
          theme: buildTheme(Brightness.light),
          darkTheme: buildTheme(Brightness.dark),
          themeMode: ThemeMode.system,
          // The Profile page's font size, multiplied onto the phone's own
          // accessibility setting rather than replacing it.
          builder: (context, child) {
            final mq = MediaQuery.of(context);
            final system = mq.textScaler.scale(1);
            return MediaQuery(
              data: mq.copyWith(textScaler: TextScaler.linear(system * settings.textScale)),
              child: child!,
            );
          },
          home: const _StartupGate(),
        ),
      ),
    );
  }
}

class _StartupGate extends StatefulWidget {
  const _StartupGate();

  @override
  State<_StartupGate> createState() => _StartupGateState();
}

class _StartupGateState extends State<_StartupGate> {
  bool _checked = false;
  bool _loggedIn = false;

  @override
  void initState() {
    super.initState();
    _check();
  }

  Future<void> _check() async {
    // Login (vaximobileapi) issues no token - a persisted username is the
    // session, so that's what decides whether to skip the login screen.
    final auth = context.read<AuthProvider>();
    await auth.restoreSession();
    setState(() {
      _loggedIn = auth.isLoggedIn;
      _checked = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (!_checked) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _loggedIn ? const HomeShell() : const LoginScreen();
  }
}

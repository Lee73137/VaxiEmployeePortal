import 'package:flutter/material.dart';
import '../theme/app_theme.dart';
import '../screens/customers_list_screen.dart';
import '../screens/inventory_list_screen.dart';
import '../screens/invoices_list_screen.dart';
import '../screens/returns_list_screen.dart';
import '../screens/forecast_screen.dart';
import '../screens/clinics_list_screen.dart';
import '../screens/clinic_history_list_screen.dart';
import '../screens/itineraries_list_screen.dart';
import '../screens/collectibles_list_screen.dart';
import '../screens/clinic_accounts_list_screen.dart';
import '../screens/promo_invoices_screen.dart';
import '../screens/sales_pivot_screen.dart';
import '../screens/sales_summary_screen.dart';
import '../screens/performance_screen.dart';
import '../screens/product_sales_screen.dart';
import '../screens/marketing_support_list_screen.dart';
import '../screens/clinic_bookings_list_screen.dart';

/// One page of the app, as shown in the menu, the group tabs and the
/// dashboard. [builder] is null for pages that aren't built yet ("Soon").
class AppModule {
  final String label;
  final String subtitle;
  final IconData icon;
  final WidgetBuilder? builder;

  const AppModule({required this.label, required this.subtitle, required this.icon, this.builder});

  bool get isAvailable => builder != null;
}

class AppModuleGroup {
  final String label;
  final String tabLabel;
  final String description;
  final IconData icon;
  final Color color;
  final List<AppModule> modules;

  const AppModuleGroup({
    required this.label,
    required this.tabLabel,
    required this.description,
    required this.icon,
    required this.color,
    required this.modules,
  });
}

/// The single source of truth for navigation - add a page here and it shows
/// up in the drawer menu, its group's tab and the dashboard counts.
final List<AppModuleGroup> appModuleGroups = [
  AppModuleGroup(
    label: 'Sales & Billing',
    tabLabel: 'Sales',
    description: 'Invoices, collections, promos and returns',
    icon: Icons.receipt_long_rounded,
    color: AppPalette.red,
    modules: [
      AppModule(label: 'Invoices', subtitle: 'Overdue and due-soon balances', icon: Icons.receipt_long_outlined, builder: (_) => const InvoicesListScreen()),
      AppModule(label: 'Collectibles', subtitle: 'Unpaid balances per clinic', icon: Icons.payments_outlined, builder: (_) => const CollectiblesListScreen()),
      AppModule(label: 'Promo Invoices', subtitle: 'Invoices billed under promos', icon: Icons.local_offer_outlined, builder: (_) => const PromoInvoicesScreen()),
      AppModule(label: 'Returns', subtitle: 'Record and review product returns', icon: Icons.assignment_return_outlined, builder: (_) => const ReturnsListScreen()),
    ],
  ),
  AppModuleGroup(
    label: 'Clinics & Customers',
    tabLabel: 'Clinics',
    description: 'Master files, history and app accounts',
    icon: Icons.local_hospital_rounded,
    color: AppPalette.green,
    modules: [
      AppModule(label: 'Clinics', subtitle: 'Clinic master file', icon: Icons.local_hospital_outlined, builder: (_) => const ClinicsListScreen()),
      AppModule(label: 'Customers', subtitle: 'QuickBooks customer records', icon: Icons.people_outline, builder: (_) => const CustomersListScreen()),
      AppModule(label: 'Clinic History', subtitle: 'Invoices and bookings per clinic', icon: Icons.history_outlined, builder: (_) => const ClinicHistoryListScreen()),
      AppModule(label: 'VaxiShApp Accounts', subtitle: 'Clinic mobile app logins', icon: Icons.phone_android_outlined, builder: (_) => const ClinicAccountsListScreen()),
      const AppModule(label: 'Birthday Calendar', subtitle: 'Customer birthdays and anniversaries', icon: Icons.cake_outlined),
    ],
  ),
  AppModuleGroup(
    label: 'Field Operations',
    tabLabel: 'Field',
    description: 'Visits, bookings, stock and marketing',
    icon: Icons.route_rounded,
    color: AppPalette.black,
    modules: [
      AppModule(label: 'Itineraries', subtitle: 'Plan and log clinic visits', icon: Icons.map_outlined, builder: (_) => const ItinerariesListScreen()),
      AppModule(label: 'Clinic Bookings', subtitle: 'Orders waiting for delivery', icon: Icons.local_shipping_outlined, builder: (_) => const ClinicBookingsListScreen()),
      AppModule(label: 'Inventory', subtitle: 'Head-office stock on hand', icon: Icons.inventory_2_outlined, builder: (_) => const InventoryListScreen()),
      AppModule(label: 'Marketing Support', subtitle: 'Requests for marketing materials', icon: Icons.campaign_outlined, builder: (_) => const MarketingSupportListScreen()),
      const AppModule(label: 'Messages', subtitle: 'SMS to clinics', icon: Icons.sms_outlined),
    ],
  ),
  AppModuleGroup(
    label: 'Reports & Insights',
    tabLabel: 'Reports',
    description: 'Sales reports, performance and forecasting',
    icon: Icons.insights_rounded,
    color: AppPalette.red,
    modules: [
      AppModule(label: 'Sales Summary', subtitle: 'Monthly sales by customer', icon: Icons.grid_on_outlined, builder: (_) => const SalesSummaryScreen()),
      AppModule(label: 'Sales Pivot Report', subtitle: 'Sales by rep, location and year', icon: Icons.pivot_table_chart_outlined, builder: (_) => const SalesPivotScreen()),
      AppModule(label: 'Product Sales', subtitle: 'Units and amounts per product', icon: Icons.bar_chart_rounded, builder: (_) => const ProductSalesScreen()),
      AppModule(label: 'Performance', subtitle: 'Rep targets versus actuals', icon: Icons.speed_outlined, builder: (_) => const PerformanceScreen()),
      AppModule(label: 'Sales Forecast', subtitle: 'Suggested purchase orders', icon: Icons.query_stats_outlined, builder: (_) => const ForecastScreen()),
    ],
  ),
];

/// Opens [module], or says it's coming soon when it isn't built yet.
void openModule(BuildContext context, AppModule module) {
  final builder = module.builder;
  if (builder == null) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${module.label} is coming soon')));
    return;
  }
  Navigator.of(context).push(MaterialPageRoute(builder: builder));
}

/// Looks a module up by label - used by the dashboard's shortcuts.
AppModule moduleNamed(String label) =>
    appModuleGroups.expand((g) => g.modules).firstWhere((m) => m.label == label);

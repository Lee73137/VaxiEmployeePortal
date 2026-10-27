import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import 'package:vaxicsr_mobile/api/api_client.dart';
import 'package:vaxicsr_mobile/providers/auth_provider.dart';
import 'package:vaxicsr_mobile/providers/customers_provider.dart';
import 'package:vaxicsr_mobile/screens/login_screen.dart';

void main() {
  testWidgets('Login screen renders username, password, and submit', (WidgetTester tester) async {
    final apiClient = ApiClient();

    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider(create: (_) => AuthProvider(apiClient)),
          ChangeNotifierProvider(create: (_) => CustomersProvider(apiClient)),
        ],
        child: const MaterialApp(home: LoginScreen()),
      ),
    );
    await tester.pump();

    expect(find.text('Sign in'), findsOneWidget);
    expect(find.byKey(const Key('usernameField')), findsOneWidget);
    expect(find.byKey(const Key('passwordField')), findsOneWidget);
    expect(find.byKey(const Key('loginButton')), findsOneWidget);
  });
}

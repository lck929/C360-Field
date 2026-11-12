import 'package:c360/core/theme/app_theme.dart';
import 'package:c360/features/auth/di/auth_providers.dart';
import 'package:c360/features/auth/presentation/providers/auth_controller.dart';
import 'package:c360/features/auth/presentation/providers/auth_state.dart';
import 'package:c360/features/auth/presentation/screens/login_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../helpers/fakes.dart';

void main() {
  late FakeAuthRepository repository;
  late ProviderContainer container;

  Future<void> pumpLogin(WidgetTester tester) async {
    tester.view.physicalSize = const Size(1170, 2532);
    tester.view.devicePixelRatio = 3;
    addTearDown(tester.view.reset);
    repository = FakeAuthRepository();
    container = ProviderContainer(overrides: [authRepositoryProvider.overrideWithValue(repository)]);
    addTearDown(container.dispose);
    await tester.pumpWidget(
      UncontrolledProviderScope(
        container: container,
        child: MaterialApp(theme: lightTheme, home: const LoginScreen()),
      ),
    );
    await tester.pump();
  }

  Future<void> tapSignIn(WidgetTester tester) async {
    await tester.ensureVisible(find.text('Sign in'));
    await tester.tap(find.text('Sign in'));
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
  }

  testWidgets('asks for both fields before signing in', (tester) async {
    await pumpLogin(tester);

    await tapSignIn(tester);

    expect(find.text('Enter your Employee ID and password.'), findsOneWidget);
    expect(repository.lastEmployeeId, isNull);
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('shows the credentials error for a wrong password', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byKey(const Key('employeeIdField')), 'scl10234');
    await tester.enterText(find.byKey(const Key('passwordField')), 'wrong');
    await tapSignIn(tester);

    expect(find.text('Employee ID or password is incorrect. Check both and try again.'), findsOneWidget);
    expect(repository.lastEmployeeId, 'SCL10234');
    expect(container.read(authProvider), isA<SignedOut>());
    await tester.pumpWidget(const SizedBox());
  });

  testWidgets('signs in with valid credentials', (tester) async {
    await pumpLogin(tester);

    await tester.enterText(find.byKey(const Key('employeeIdField')), 'SCL10234');
    await tester.enterText(find.byKey(const Key('passwordField')), 'secret');
    await tapSignIn(tester);

    expect(container.read(employeeProvider)?.name, 'Ravi Kumar');
    await tester.pumpWidget(const SizedBox());
  });
}

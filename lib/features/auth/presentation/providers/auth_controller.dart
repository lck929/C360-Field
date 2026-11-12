import 'dart:async';

import 'package:c360/core/error/app_exception.dart';
import 'package:c360/core/error/error_codes.dart';
import 'package:c360/features/auth/di/auth_providers.dart';
import 'package:c360/features/auth/domain/entities/employee.dart';
import 'package:c360/features/auth/presentation/providers/auth_state.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AuthController extends Notifier<AuthState> {
  static const sessionEnded =
      'Your session ended. Sign in again. Records saved on this phone are safe and will sync after you sign in.';

  @override
  AuthState build() {
    Future.microtask(_restore);
    return const AuthLoading();
  }

  Future<void> _restore() async {
    final restored = await ref.read(restoreSessionProvider)();
    if (!ref.mounted) return;
    final employee = restored.employee;
    state = employee != null
        ? SignedIn(employee)
        : SignedOut(notice: restored.expired ? sessionEnded : null, lastEmployeeId: restored.lastEmployeeId);
    if (employee != null) unawaited(refreshProfile());
  }

  Future<String?> signIn(String employeeId, String password) =>
      _attempt(() => ref.read(signInProvider)(employeeId, password));

  Future<String?> signInWithMicrosoft() => _attempt(() => ref.read(signInWithMicrosoftProvider)());

  Future<String?> _attempt(Future<Employee> Function() signIn) async {
    try {
      final employee = await signIn();
      if (ref.mounted) state = SignedIn(employee);
      return null;
    } on AppException catch (e) {
      if (e.code == ErrorCodes.invalidCredentials) {
        return 'Employee ID or password is incorrect. Check both and try again.';
      }
      if (e.type == FailureType.network) return 'No network. Connect to the internet to sign in.';
      return e.message;
    } catch (_) {
      return 'Something went wrong. Try again.';
    }
  }

  Future<void> refreshProfile() async {
    try {
      final employee = await ref.read(refreshProfileProvider)();
      if (ref.mounted && state is SignedIn) state = SignedIn(employee);
    } on AppException catch (e) {
      if (e.type == FailureType.unauthorized) await expireSession();
    } catch (_) {}
  }

  Future<void> expireSession() async {
    final current = state;
    if (current is! SignedIn) return;
    await ref.read(endSessionProvider)();
    if (ref.mounted) state = SignedOut(notice: sessionEnded, lastEmployeeId: current.employee.employeeId);
  }

  Future<void> signOut() async {
    final current = state;
    await ref.read(signOutProvider)();
    if (ref.mounted) state = SignedOut(lastEmployeeId: current is SignedIn ? current.employee.employeeId : null);
  }
}

final authProvider = NotifierProvider<AuthController, AuthState>(AuthController.new);

final employeeProvider = Provider<Employee?>((ref) {
  final auth = ref.watch(authProvider);
  return auth is SignedIn ? auth.employee : null;
});

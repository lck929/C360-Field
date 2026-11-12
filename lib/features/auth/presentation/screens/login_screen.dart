import 'package:c360/core/theme/app_palette.dart';
import 'package:c360/core/widgets/inline_alert.dart';
import 'package:c360/features/auth/presentation/providers/auth_controller.dart';
import 'package:c360/features/auth/presentation/providers/auth_state.dart';
import 'package:c360/features/auth/presentation/widgets/login_hero.dart';
import 'package:c360/features/auth/presentation/widgets/microsoft_logo.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _employeeId = TextEditingController();
  final _password = TextEditingController();
  final _passwordFocus = FocusNode();
  var _obscure = true;
  var _busy = '';
  String? _error;

  @override
  void initState() {
    super.initState();
    final auth = ref.read(authProvider);
    if (auth is SignedOut) _employeeId.text = auth.lastEmployeeId ?? '';
  }

  @override
  void dispose() {
    _employeeId.dispose();
    _password.dispose();
    _passwordFocus.dispose();
    super.dispose();
  }

  Future<void> _run(String which, Future<String?> Function() action) async {
    if (_busy.isNotEmpty) return;
    setState(() {
      _error = null;
      _busy = which;
    });
    final error = await action();
    if (!mounted) return;
    setState(() {
      _busy = '';
      _error = error;
    });
    if (error != null && which == 'password') _passwordFocus.requestFocus();
  }

  void _signIn() {
    if (_employeeId.text.trim().isEmpty || _password.text.isEmpty) {
      setState(() => _error = 'Enter your Employee ID and password.');
      return;
    }
    _run('password', () => ref.read(authProvider.notifier).signIn(_employeeId.text, _password.text));
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final notice = auth is SignedOut ? auth.notice : null;
    final p = context.palette;
    final busy = _busy.isNotEmpty;
    const label = TextStyle(fontSize: 13, fontWeight: FontWeight.w500);

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle.light,
      child: Scaffold(
        body: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          child: Column(
            children: [
              const LoginHero(),
              Transform.translate(
                offset: const Offset(0, -20),
                child: Container(
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: p.background,
                    borderRadius: const BorderRadius.vertical(top: Radius.circular(22)),
                  ),
                  padding: const EdgeInsets.fromLTRB(22, 24, 22, 26),
                  child: AutofillGroup(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('C360 Field', style: serif(size: 15, color: Brand.gold)),
                        const SizedBox(height: 2),
                        Text('Welcome back', style: Theme.of(context).textTheme.headlineLarge),
                        const SizedBox(height: 2),
                        Text('Sign in to record your attendance.', style: TextStyle(color: p.mutedForeground)),
                        if (notice != null) ...[const SizedBox(height: 14), InlineAlert(message: notice, warning: true)],
                        if (_error != null) ...[const SizedBox(height: 14), InlineAlert(message: _error!)],
                        const SizedBox(height: 14),
                        const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('Employee ID', style: label)),
                        TextField(
                          key: const Key('employeeIdField'),
                          controller: _employeeId,
                          enabled: !busy,
                          textCapitalization: TextCapitalization.characters,
                          autofillHints: const [AutofillHints.username],
                          textInputAction: TextInputAction.next,
                          onSubmitted: (_) => _passwordFocus.requestFocus(),
                          decoration: const InputDecoration(hintText: 'e.g. SCL10234'),
                        ),
                        const SizedBox(height: 14),
                        const Padding(padding: EdgeInsets.only(bottom: 6), child: Text('Password', style: label)),
                        TextField(
                          key: const Key('passwordField'),
                          controller: _password,
                          focusNode: _passwordFocus,
                          enabled: !busy,
                          obscureText: _obscure,
                          autofillHints: const [AutofillHints.password],
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) => _signIn(),
                          decoration: InputDecoration(
                            hintText: 'Enter your password',
                            suffixIcon: IconButton(
                              tooltip: _obscure ? 'Show password' : 'Hide password',
                              icon: Icon(_obscure ? Icons.visibility_outlined : Icons.visibility_off_outlined),
                              color: p.mutedForeground,
                              onPressed: () => setState(() => _obscure = !_obscure),
                            ),
                          ),
                        ),
                        const SizedBox(height: 20),
                        FilledButton(
                          onPressed: busy ? null : _signIn,
                          child: Text(_busy == 'password' ? 'Signing in…' : 'Sign in'),
                        ),
                        Padding(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                          child: Row(
                            children: [
                              Expanded(child: Divider(color: p.border)),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 12),
                                child: Text('or', style: TextStyle(fontSize: 12, color: p.mutedForeground)),
                              ),
                              Expanded(child: Divider(color: p.border)),
                            ],
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: busy
                              ? null
                              : () => _run('microsoft', ref.read(authProvider.notifier).signInWithMicrosoft),
                          icon: const MicrosoftLogo(),
                          label: Text(_busy == 'microsoft' ? 'Opening Microsoft sign-in…' : 'Sign in with Microsoft'),
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
    );
  }
}

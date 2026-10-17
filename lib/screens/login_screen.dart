import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_failure.dart';
import '../core/input_validation.dart';
import '../core/theme/app_theme.dart';
import '../providers.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key, this.initialError});
  final String? initialError;
  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final phone = TextEditingController();
  final password = TextEditingController();
  final formKey = GlobalKey<FormState>();
  bool obscure = true;
  String? submitError;

  @override
  void dispose() { phone.dispose(); password.dispose(); super.dispose(); }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    setState(() => submitError = null);
    if (!formKey.currentState!.validate()) {
      setState(() => submitError = 'لطفاً موارد مشخص‌شده در فرم را اصلاح کنید');
      return;
    }
    await ref.read(authProvider.notifier).login(
      normalizeIranMobile(phone.text),
      password.text,
    );
    if (!mounted) return;
    final result = ref.read(authProvider);
    if (result.hasError) {
      setState(() => submitError = friendlyErrorMessage(result.error));
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    final errorText = submitError ??
        (auth.hasError ? friendlyErrorMessage(auth.error) : null) ??
        (widget.initialError == null ? null : friendlyErrorMessage(widget.initialError));
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: formKey,
                autovalidateMode: AutovalidateMode.onUserInteraction,
                child: Column(crossAxisAlignment: CrossAxisAlignment.stretch, children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(28),
                    child: Image.asset('assets/branding/ahanchi-logo.png', width: 92, height: 92),
                  ),
                  const SizedBox(height: 22),
                  const Text('آهن‌چی', style: TextStyle(fontSize: 34, fontWeight: FontWeight.w900, color: AhanChiColors.graphite)),
                  const SizedBox(height: 6),
                  const Text('هر تکه فلز، دوباره ارزشمند می‌شود', style: TextStyle(color: AhanChiColors.muted)),
                  const SizedBox(height: 36),
                  TextFormField(
                    controller: phone, keyboardType: TextInputType.phone, textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.telephoneNumber],
                    textInputAction: TextInputAction.next,
                    decoration: const InputDecoration(labelText: 'شماره موبایل', hintText: '09123456789', prefixIcon: Icon(Icons.phone_rounded)),
                    validator: validateIranMobile,
                    onChanged: (_) {
                      if (submitError != null) setState(() => submitError = null);
                    },
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: password, obscureText: obscure, textDirection: TextDirection.ltr,
                    autofillHints: const [AutofillHints.password],
                    textInputAction: TextInputAction.done,
                    onFieldSubmitted: (_) {
                      if (!auth.isLoading) submit();
                    },
                    decoration: InputDecoration(
                      labelText: 'رمز عبور', prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility : Icons.visibility_off)),
                    ),
                    validator: validatePassword,
                    onChanged: (_) {
                      if (submitError != null) setState(() => submitError = null);
                    },
                  ),
                  if (errorText != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.errorContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                        Icon(Icons.error_outline, color: Theme.of(context).colorScheme.onErrorContainer),
                        const SizedBox(width: 8),
                        Expanded(child: Text(errorText, style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer))),
                      ]),
                    ),
                  ],
                  const SizedBox(height: 24),
                  FilledButton.icon(
                    onPressed: auth.isLoading ? null : submit,
                    icon: auth.isLoading ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.login_rounded),
                    label: const Text('ورود به سامانه'),
                  ),
                ]),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

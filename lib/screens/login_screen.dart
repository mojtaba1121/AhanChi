import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
  late final TextEditingController server;
  final formKey = GlobalKey<FormState>();
  bool obscure = true;

  @override
  void initState() {
    super.initState();
    server = TextEditingController(text: ref.read(repositoryProvider).api.serverUrl);
  }

  @override
  void dispose() { phone.dispose(); password.dispose(); server.dispose(); super.dispose(); }

  Future<void> submit() async {
    if (!formKey.currentState!.validate()) return;
    await ref.read(authProvider.notifier).login(phone.text.trim(), password.text, server.text.trim());
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authProvider);
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 440),
              child: Form(
                key: formKey,
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
                    decoration: const InputDecoration(labelText: 'شماره موبایل', prefixIcon: Icon(Icons.phone_rounded)),
                    validator: (value) => RegExp(r'^09\d{9}$').hasMatch(value ?? '') ? null : 'شماره موبایل صحیح نیست',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: password, obscureText: obscure, textDirection: TextDirection.ltr,
                    decoration: InputDecoration(
                      labelText: 'رمز عبور', prefixIcon: const Icon(Icons.lock_rounded),
                      suffixIcon: IconButton(onPressed: () => setState(() => obscure = !obscure), icon: Icon(obscure ? Icons.visibility : Icons.visibility_off)),
                    ),
                    validator: (value) => (value?.length ?? 0) >= 8 ? null : 'رمز عبور حداقل ۸ کاراکتر است',
                  ),
                  const SizedBox(height: 14),
                  ExpansionTile(
                    tilePadding: EdgeInsets.zero,
                    title: const Text('تنظیم آدرس سرور', style: TextStyle(fontSize: 14)),
                    children: [TextFormField(
                      controller: server, textDirection: TextDirection.ltr,
                      decoration: const InputDecoration(labelText: 'API URL', hintText: 'https://api.example.com/api/v1'),
                      validator: (value) {
                        final uri = Uri.tryParse(value ?? '');
                        return uri != null && uri.hasScheme && uri.host.isNotEmpty ? null : 'آدرس سرور صحیح نیست';
                      },
                    )],
                  ),
                  if (widget.initialError != null || auth.hasError) ...[
                    const SizedBox(height: 12),
                    Text(widget.initialError ?? auth.error.toString(), style: TextStyle(color: Theme.of(context).colorScheme.error)),
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

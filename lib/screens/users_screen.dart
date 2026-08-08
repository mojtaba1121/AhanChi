import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_failure.dart';
import '../core/input_validation.dart';
import '../providers.dart';

class UsersScreen extends ConsumerStatefulWidget {
  const UsersScreen({super.key});

  @override
  ConsumerState<UsersScreen> createState() => _UsersScreenState();
}

class _UsersScreenState extends ConsumerState<UsersScreen> {
  late Future<List<Map<String, dynamic>>> future;

  @override
  void initState() {
    super.initState();
    future = _loadUsers();
  }

  Future<List<Map<String, dynamic>>> _loadUsers() {
    return ref.read(repositoryProvider).api.list('/users');
  }

  void _refresh() {
    setState(() => future = _loadUsers());
  }

  Future<void> add() async {
    final created = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _CreateRepresentativeDialog(),
    );
    if (created != true || !mounted) return;

    _refresh();
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('نماینده با موفقیت ایجاد شد'),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) => Stack(children: [
    FutureBuilder<List<Map<String, dynamic>>>(
      future: future,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: CircularProgressIndicator());
        }
        if (snapshot.hasError) {
          return Center(child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(mainAxisSize: MainAxisSize.min, children: [
              const Icon(Icons.cloud_off_outlined, size: 48),
              const SizedBox(height: 12),
              Text(friendlyErrorMessage(snapshot.error), textAlign: TextAlign.center),
              const SizedBox(height: 12),
              OutlinedButton.icon(
                onPressed: _refresh,
                icon: const Icon(Icons.refresh),
                label: const Text('تلاش دوباره'),
              ),
            ]),
          ));
        }

        final users = snapshot.data ?? [];
        if (users.isEmpty) {
          return const Center(child: Text('هنوز نماینده‌ای ایجاد نشده است'));
        }
        return RefreshIndicator(
          onRefresh: () async {
            _refresh();
            await future;
          },
          child: ListView.builder(
            padding: const EdgeInsets.fromLTRB(12, 12, 12, 90),
            itemCount: users.length,
            itemBuilder: (_, index) {
              final user = users[index];
              final fullName = (user['fullName'] as String?)?.trim() ?? '';
              return Card(child: ListTile(
                leading: CircleAvatar(child: Text(fullName.isEmpty ? '؟' : fullName.substring(0, 1))),
                title: Text(fullName.isEmpty ? 'بدون نام' : fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text('${user['phone'] ?? ''} • ${user['city'] ?? ''} ${user['village'] ?? ''}'),
                trailing: Chip(label: Text(user['role'] == 'REPRESENTATIVE' ? 'نماینده' : 'مدیر')),
              ));
            },
          ),
        );
      },
    ),
    Positioned(
      bottom: 18,
      left: 18,
      child: FloatingActionButton.extended(
        onPressed: add,
        icon: const Icon(Icons.person_add),
        label: const Text('نماینده جدید'),
      ),
    ),
  ]);
}

class _CreateRepresentativeDialog extends ConsumerStatefulWidget {
  const _CreateRepresentativeDialog();

  @override
  ConsumerState<_CreateRepresentativeDialog> createState() => _CreateRepresentativeDialogState();
}

class _CreateRepresentativeDialogState extends ConsumerState<_CreateRepresentativeDialog> {
  final formKey = GlobalKey<FormState>();
  final name = TextEditingController();
  final phone = TextEditingController();
  final password = TextEditingController();
  final city = TextEditingController();
  final village = TextEditingController();
  bool saving = false;
  bool obscurePassword = true;
  String? submitError;

  @override
  void dispose() {
    name.dispose();
    phone.dispose();
    password.dispose();
    city.dispose();
    village.dispose();
    super.dispose();
  }

  Future<void> submit() async {
    FocusScope.of(context).unfocus();
    setState(() => submitError = null);
    if (!formKey.currentState!.validate()) {
      setState(() => submitError = 'لطفاً موارد مشخص‌شده در فرم را اصلاح کنید');
      return;
    }

    setState(() => saving = true);
    final cityValue = city.text.trim();
    final villageValue = village.text.trim();
    try {
      await ref.read(repositoryProvider).api.post('/users', {
        'fullName': name.text.trim(),
        'phone': normalizeIranMobile(phone.text),
        'password': password.text,
        'role': 'REPRESENTATIVE',
        if (cityValue.isNotEmpty) 'city': cityValue,
        if (villageValue.isNotEmpty) 'village': villageValue,
      });
      if (mounted) Navigator.pop(context, true);
    } catch (error) {
      if (!mounted) return;
      setState(() {
        saving = false;
        submitError = friendlyErrorMessage(error);
      });
    }
  }

  @override
  Widget build(BuildContext context) => AlertDialog(
    title: const Text('نماینده جدید'),
    content: SizedBox(
      width: 420,
      child: SingleChildScrollView(
        child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'نام کامل *'),
              validator: validateFullName,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'شماره موبایل *', hintText: '09123456789'),
              validator: validateIranMobile,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: password,
              obscureText: obscurePassword,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              decoration: InputDecoration(
                labelText: 'رمز موقت *',
                helperText: 'حداقل ۸ کاراکتر',
                suffixIcon: IconButton(
                  onPressed: () => setState(() => obscurePassword = !obscurePassword),
                  icon: Icon(obscurePassword ? Icons.visibility : Icons.visibility_off),
                ),
              ),
              validator: validatePassword,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: city,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'شهر'),
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: village,
              textInputAction: TextInputAction.done,
              onFieldSubmitted: (_) {
                if (!saving) submit();
              },
              decoration: const InputDecoration(labelText: 'روستا'),
            ),
            if (submitError != null) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.errorContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  submitError!,
                  style: TextStyle(color: Theme.of(context).colorScheme.onErrorContainer),
                ),
              ),
            ],
          ]),
        ),
      ),
    ),
    actions: [
      TextButton(
        onPressed: saving ? null : () => Navigator.pop(context, false),
        child: const Text('انصراف'),
      ),
      FilledButton.icon(
        onPressed: saving ? null : submit,
        icon: saving
            ? const SizedBox.square(dimension: 18, child: CircularProgressIndicator(strokeWidth: 2))
            : const Icon(Icons.person_add),
        label: Text(saving ? 'در حال ایجاد...' : 'ایجاد نماینده'),
      ),
    ],
  );
}

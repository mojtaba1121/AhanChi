import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/api_failure.dart';
import '../core/input_validation.dart';
import '../core/theme/app_theme.dart';
import '../providers.dart';

class SellersScreen extends ConsumerWidget {
  const SellersScreen({super.key});

  Future<void> add(BuildContext context, WidgetRef ref) async {
    final formKey = GlobalKey<FormState>();
    final name = TextEditingController();
    final phone = TextEditingController();
    final city = TextEditingController();
    final village = TextEditingController();
    try {
      final saved = await showDialog<bool>(context: context, builder: (dialogContext) => AlertDialog(
        title: const Text('فروشنده جدید'),
        content: SingleChildScrollView(child: Form(
          key: formKey,
          autovalidateMode: AutovalidateMode.onUserInteraction,
          child: Column(mainAxisSize: MainAxisSize.min, children: [
            TextFormField(
              controller: name,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'نام و نام خانوادگی *'),
              validator: validateFullName,
            ),
            const SizedBox(height: 10),
            TextFormField(
              controller: phone,
              keyboardType: TextInputType.phone,
              textDirection: TextDirection.ltr,
              textInputAction: TextInputAction.next,
              decoration: const InputDecoration(labelText: 'موبایل *', hintText: '09123456789'),
              validator: validateIranMobile,
            ),
            const SizedBox(height: 10),
            TextFormField(controller: city, textInputAction: TextInputAction.next, decoration: const InputDecoration(labelText: 'شهر')),
            const SizedBox(height: 10),
            TextFormField(controller: village, textInputAction: TextInputAction.done, decoration: const InputDecoration(labelText: 'روستا')),
          ]),
        )),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext, false), child: const Text('انصراف')),
          FilledButton(
            onPressed: () {
              if (formKey.currentState!.validate()) Navigator.pop(dialogContext, true);
            },
            child: const Text('ثبت'),
          ),
        ],
      ));
      if (saved != true || !context.mounted) return;

      final result = await ref.read(repositoryProvider).addSeller(
        fullName: name.text.trim(),
        phone: normalizeIranMobile(phone.text),
        city: city.text.trim(),
        village: village.text.trim(),
      );
      ref.invalidate(sellersProvider);
      ref.invalidate(pendingCountProvider);
      if (context.mounted) {
        final synced = result != null && result.failed == 0;
        final detail = result?.lastError == null ? '' : '\n${result!.lastError}';
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(
          synced ? 'فروشنده ذخیره و با سرور همگام شد' : 'فروشنده روی گوشی ذخیره شد و بعداً ارسال می‌شود$detail',
        )));
      }
    } catch (error) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(friendlyErrorMessage(error))));
      }
    } finally {
      name.dispose(); phone.dispose(); city.dispose(); village.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) => Stack(children: [
    ref.watch(sellersProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, _) => Center(child: Text(error.toString())),
      data: (items) => items.isEmpty
          ? const Center(child: Text('اولین فروشنده را ثبت کنید'))
          : ListView.builder(padding: const EdgeInsets.fromLTRB(12, 12, 12, 90), itemCount: items.length, itemBuilder: (_, index) {
            final item = items[index];
            return Card(child: ListTile(
              leading: CircleAvatar(backgroundColor: const Color(0xFFE7EFEA), child: Text(item.fullName.substring(0, 1), style: const TextStyle(color: AhanChiColors.graphite, fontWeight: FontWeight.w900))),
              title: Text(item.fullName, style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text([item.phone, item.city, item.village].where((value) => value?.isNotEmpty == true).join(' • ')),
              trailing: Icon(item.synced ? Icons.cloud_done_outlined : Icons.cloud_off_outlined, color: item.synced ? AhanChiColors.recycledGreen : AhanChiColors.copper),
            ));
          }),
    ),
    Positioned(bottom: 18, left: 18, child: FloatingActionButton.extended(onPressed: () => add(context, ref), icon: const Icon(Icons.person_add_alt_1), label: const Text('فروشنده جدید'))),
  ]);
}

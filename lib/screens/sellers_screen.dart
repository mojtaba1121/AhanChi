import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers.dart';

class SellersScreen extends ConsumerWidget {
  const SellersScreen({super.key});

  Future<void> add(BuildContext context, WidgetRef ref) async {
    final name = TextEditingController(); final phone = TextEditingController(); final city = TextEditingController(); final village = TextEditingController();
    final saved = await showDialog<bool>(context: context, builder: (context) => AlertDialog(
      title: const Text('فروشنده جدید'),
      content: SingleChildScrollView(child: Column(mainAxisSize: MainAxisSize.min, children: [
        TextField(controller: name, decoration: const InputDecoration(labelText: 'نام و نام خانوادگی *')),
        const SizedBox(height: 10), TextField(controller: phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'موبایل')),
        const SizedBox(height: 10), TextField(controller: city, decoration: const InputDecoration(labelText: 'شهر')),
        const SizedBox(height: 10), TextField(controller: village, decoration: const InputDecoration(labelText: 'روستا')),
      ])),
      actions: [TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('انصراف')), FilledButton(onPressed: () => Navigator.pop(context, name.text.trim().length >= 2), child: const Text('ثبت'))],
    ));
    if (saved == true) {
      await ref.read(repositoryProvider).addSeller(fullName: name.text.trim(), phone: phone.text.trim(), city: city.text.trim(), village: village.text.trim());
      ref.invalidate(sellersProvider); ref.invalidate(pendingCountProvider);
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

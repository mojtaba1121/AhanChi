import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/theme/app_theme.dart';
import '../providers.dart';

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).valueOrNull!;
    final repository = ref.watch(repositoryProvider);
    return ListView(padding: const EdgeInsets.all(16), children: [
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
        CircleAvatar(radius: 28, backgroundColor: AhanChiColors.graphite, child: Text(session.fullName.substring(0, 1), style: const TextStyle(color: Colors.white, fontSize: 22, fontWeight: FontWeight.w900))),
        const SizedBox(width: 14),
        Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [Text(session.fullName, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w900)), Text(session.phone), Text(session.isManager ? 'مدیر سامانه' : 'نماینده')])),
      ]))),
      const SizedBox(height: 14),
      Card(child: Column(children: [
        ListTile(leading: const Icon(Icons.dns_outlined), title: const Text('آدرس سرور'), subtitle: Text(repository.api.serverUrl, textDirection: TextDirection.ltr)),
        const Divider(height: 1),
        ListTile(leading: const Icon(Icons.sync_outlined), title: const Text('همگام‌سازی اکنون'), onTap: () async {
          final result = await repository.sync.syncAll();
          ref.invalidate(pendingCountProvider); ref.invalidate(materialsProvider); ref.invalidate(sellersProvider); ref.invalidate(purchasesProvider);
          if (context.mounted) ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result.synced} ارسال موفق، ${result.failed} ناموفق')));
        }),
      ])),
      const SizedBox(height: 14),
      Card(child: Column(children: [
        const ListTile(leading: Icon(Icons.info_outline), title: Text('نسخه برنامه'), trailing: Text('0.1.0')), const Divider(height: 1),
        ListTile(leading: const Icon(Icons.logout_rounded, color: Colors.red), title: const Text('خروج از حساب', style: TextStyle(color: Colors.red)), onTap: () => ref.read(authProvider.notifier).logout()),
      ])),
    ]);
  }
}

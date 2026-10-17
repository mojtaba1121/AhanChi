import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formatters.dart';
import '../providers.dart';

class PurchasesScreen extends ConsumerWidget {
  const PurchasesScreen({super.key, this.remote = false});
  final bool remote;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (!remote) return const SizedBox.shrink();
    return ref.watch(remotePurchasesProvider).when(
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (_, __) => Center(child: OutlinedButton.icon(
        onPressed: () => ref.invalidate(remotePurchasesProvider),
        icon: const Icon(Icons.refresh), label: const Text('دریافت خریدها از سرور'),
      )),
      data: (rows) {
        if (rows.isEmpty) return const Center(child: Text('هنوز خریدی ثبت نشده است'));
        return RefreshIndicator(
          onRefresh: () => ref.refresh(remotePurchasesProvider.future),
          child: ListView.builder(padding: const EdgeInsets.all(12), itemCount: rows.length, itemBuilder: (_, index) {
            final row = rows[index];
            final seller = row['seller'] as Map<String, dynamic>? ?? {};
            final material = row['material'] as Map<String, dynamic>? ?? {};
            final representative = row['representative'] as Map<String, dynamic>? ?? {};
            return Card(child: ListTile(
              leading: const CircleAvatar(child: Icon(Icons.recycling_outlined)),
              title: Text('${seller['fullName'] ?? 'فروشنده'} • ${material['nameFa'] ?? 'ماده'}', style: const TextStyle(fontWeight: FontWeight.w700)),
              subtitle: Text('${representative['fullName'] ?? ''}\n${weight((row['weightGrams'] ?? 0) as int)} × ${toman((row['pricePerKgToman'] ?? 0) as int)}'),
              isThreeLine: true,
              trailing: Text(toman((row['totalAmountToman'] ?? 0) as int), style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w900)),
            ));
          }),
        );
      },
    );
  }
}

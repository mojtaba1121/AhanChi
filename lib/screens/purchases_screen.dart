import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formatters.dart';
import '../providers.dart';

class PurchasesScreen extends ConsumerStatefulWidget {
  const PurchasesScreen({super.key, this.remote = false});
  final bool remote;
  @override
  ConsumerState<PurchasesScreen> createState() => _PurchasesScreenState();
}

class _PurchasesScreenState extends ConsumerState<PurchasesScreen> {
  late Future<List<Map<String, dynamic>>> remoteFuture;
  @override
  void initState() { super.initState(); remoteFuture = ref.read(repositoryProvider).api.list('/purchases'); }

  @override
  Widget build(BuildContext context) {
    if (!widget.remote) return const SizedBox.shrink();
    return FutureBuilder<List<Map<String, dynamic>>>(
      future: remoteFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
        if (snapshot.hasError) {
          return Center(child: OutlinedButton.icon(
            onPressed: () => setState(() => remoteFuture = ref.read(repositoryProvider).api.list('/purchases')),
            icon: const Icon(Icons.refresh), label: const Text('دریافت خریدها از سرور'),
          ));
        }
        final rows = snapshot.data!;
        if (rows.isEmpty) return const Center(child: Text('هنوز خریدی ثبت نشده است'));
        return RefreshIndicator(
          onRefresh: () async { setState(() => remoteFuture = ref.read(repositoryProvider).api.list('/purchases')); await remoteFuture; },
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

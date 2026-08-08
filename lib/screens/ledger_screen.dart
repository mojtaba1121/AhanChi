import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formatters.dart';
import '../models/models.dart';
import '../providers.dart';

class LedgerScreen extends ConsumerStatefulWidget {
  const LedgerScreen({super.key});
  @override
  ConsumerState<LedgerScreen> createState() => _LedgerScreenState();
}

class _LedgerScreenState extends ConsumerState<LedgerScreen> {
  String? sellerId;
  String type = 'PAYMENT_TO_SELLER';
  final amount = TextEditingController();
  final note = TextEditingController();
  bool saving = false;
  @override
  void dispose() { amount.dispose(); note.dispose(); super.dispose(); }

  Future<void> save() async {
    final value = int.tryParse(amount.text);
    if (sellerId == null || value == null || value <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فروشنده و مبلغ صحیح را وارد کنید'))); return;
    }
    setState(() => saving = true);
    await ref.read(repositoryProvider).addLedger(sellerLocalId: sellerId!, type: type, amountToman: value, note: note.text.trim());
    ref.invalidate(pendingCountProvider);
    if (mounted) { setState(() { saving = false; amount.clear(); note.clear(); }); ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('عملیات مالی ثبت شد'))); }
  }

  @override
  Widget build(BuildContext context) {
    final sellers = ref.watch(sellersProvider).valueOrNull ?? <SellerItem>[];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('ثبت عملیات مالی', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 6), const Text('پرداخت یا دریافت وجه برای حساب هر فروشنده ثبت می‌شود.'),
      const SizedBox(height: 22),
      DropdownButtonFormField<String>(
        initialValue: sellerId, isExpanded: true, decoration: const InputDecoration(labelText: 'فروشنده'),
        items: sellers.map((item) => DropdownMenuItem(value: item.localId, child: Text(item.fullName))).toList(),
        onChanged: (value) => setState(() => sellerId = value),
      ),
      const SizedBox(height: 14),
      SegmentedButton<String>(
        segments: const [
          ButtonSegment(value: 'PAYMENT_TO_SELLER', label: Text('پرداخت به فروشنده'), icon: Icon(Icons.arrow_upward_rounded)),
          ButtonSegment(value: 'RECEIPT_FROM_SELLER', label: Text('دریافت از فروشنده'), icon: Icon(Icons.arrow_downward_rounded)),
        ],
        selected: {type}, onSelectionChanged: (value) => setState(() => type = value.first),
      ),
      const SizedBox(height: 14),
      TextField(controller: amount, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'مبلغ به تومان', prefixIcon: Icon(Icons.payments_outlined))),
      const SizedBox(height: 14),
      TextField(controller: note, maxLines: 2, decoration: const InputDecoration(labelText: 'توضیحات یا شماره پیگیری')),
      const SizedBox(height: 18),
      if (amount.text.isNotEmpty) Card(child: ListTile(title: const Text('مبلغ عملیات'), trailing: Text(toman(int.tryParse(amount.text) ?? 0), style: const TextStyle(fontWeight: FontWeight.w900)))),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: saving ? null : save, icon: const Icon(Icons.save_outlined), label: const Text('ثبت عملیات')),
    ]);
  }
}

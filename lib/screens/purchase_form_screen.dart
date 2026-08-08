import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formatters.dart';
import '../models/models.dart';
import '../providers.dart';

class PurchaseFormScreen extends ConsumerStatefulWidget {
  const PurchaseFormScreen({super.key});
  @override
  ConsumerState<PurchaseFormScreen> createState() => _PurchaseFormScreenState();
}

class _PurchaseFormScreenState extends ConsumerState<PurchaseFormScreen> {
  String? sellerId, materialId;
  final weightController = TextEditingController();
  final priceController = TextEditingController();
  final noteController = TextEditingController();
  int total = 0; bool saving = false;

  @override
  void initState() { super.initState(); weightController.addListener(recalculate); priceController.addListener(recalculate); }
  @override
  void dispose() { weightController.dispose(); priceController.dispose(); noteController.dispose(); super.dispose(); }
  void recalculate() {
    try { setState(() => total = calculateTotal(kilogramsTextToGrams(weightController.text), int.parse(priceController.text.replaceAll(',', '')))); }
    catch (_) { if (total != 0) setState(() => total = 0); }
  }

  Future<void> save() async {
    if (sellerId == null || materialId == null || total <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('فروشنده، نوع ماده، وزن و قیمت را کامل کنید'))); return;
    }
    setState(() => saving = true);
    await ref.read(repositoryProvider).addPurchase(
      sellerLocalId: sellerId!, materialId: materialId!, weightGrams: kilogramsTextToGrams(weightController.text),
      pricePerKgToman: int.parse(priceController.text.replaceAll(',', '')), note: noteController.text.trim(),
    );
    ref.invalidate(purchasesProvider); ref.invalidate(pendingCountProvider);
    if (mounted) {
      setState(() { saving = false; sellerId = null; materialId = null; total = 0; weightController.clear(); priceController.clear(); noteController.clear(); });
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('خرید ذخیره شد؛ در صورت نبود اینترنت بعداً ارسال می‌شود')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final sellers = ref.watch(sellersProvider).valueOrNull ?? <SellerItem>[];
    final materials = ref.watch(materialsProvider).valueOrNull ?? <MaterialItem>[];
    return ListView(padding: const EdgeInsets.all(16), children: [
      Text('ثبت خرید جدید', style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w900)),
      const SizedBox(height: 6), const Text('اطلاعات روی گوشی ذخیره می‌شود و نیازی به اینترنت لحظه‌ای ندارد.'),
      const SizedBox(height: 22),
      DropdownButtonFormField<String>(
        initialValue: sellerId, isExpanded: true, decoration: const InputDecoration(labelText: 'فروشنده', prefixIcon: Icon(Icons.person_outline)),
        items: sellers.map((item) => DropdownMenuItem(value: item.localId, child: Text(item.fullName))).toList(),
        onChanged: (value) => setState(() => sellerId = value),
      ),
      if (sellers.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('ابتدا از بخش فروشنده‌ها یک نفر را ثبت کنید.', style: TextStyle(color: Colors.deepOrange))),
      const SizedBox(height: 14),
      DropdownButtonFormField<String>(
        initialValue: materialId, isExpanded: true, decoration: const InputDecoration(labelText: 'نوع فلز', prefixIcon: Icon(Icons.category_outlined)),
        items: materials.map((item) => DropdownMenuItem(value: item.id, child: Text(item.nameFa))).toList(),
        onChanged: (value) => setState(() => materialId = value),
      ),
      if (materials.isEmpty) const Padding(padding: EdgeInsets.only(top: 8), child: Text('برای دریافت فهرست مواد یک‌بار به سرور متصل شوید.', style: TextStyle(color: Colors.deepOrange))),
      const SizedBox(height: 14),
      TextField(controller: weightController, keyboardType: const TextInputType.numberWithOptions(decimal: true), inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'[0-9.,٫]'))], decoration: const InputDecoration(labelText: 'وزن به کیلوگرم', hintText: 'مثلاً 25.400', prefixIcon: Icon(Icons.scale_outlined))),
      const SizedBox(height: 14),
      TextField(controller: priceController, keyboardType: TextInputType.number, inputFormatters: [FilteringTextInputFormatter.digitsOnly], decoration: const InputDecoration(labelText: 'قیمت هر کیلو به تومان', prefixIcon: Icon(Icons.sell_outlined))),
      const SizedBox(height: 14),
      TextField(controller: noteController, maxLines: 2, decoration: const InputDecoration(labelText: 'توضیحات اختیاری', prefixIcon: Icon(Icons.notes_outlined))),
      const SizedBox(height: 18),
      Card(child: Padding(padding: const EdgeInsets.all(20), child: Row(children: [
        const Expanded(child: Text('مبلغ کل معامله', style: TextStyle(fontWeight: FontWeight.w700))),
        Text(toman(total), style: const TextStyle(fontSize: 19, fontWeight: FontWeight.w900)),
      ]))),
      const SizedBox(height: 18),
      FilledButton.icon(onPressed: saving ? null : save, icon: saving ? const SizedBox.square(dimension: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.save_outlined), label: const Text('ذخیره خرید')),
    ]);
  }
}

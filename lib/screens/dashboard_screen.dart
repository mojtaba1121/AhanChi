import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../core/formatters.dart';
import '../core/theme/app_theme.dart';
import '../providers.dart';

class DashboardScreen extends ConsumerWidget {
  const DashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final session = ref.watch(authProvider).valueOrNull;
    if (session?.isManager == true) return const _ManagerDashboard();
    final purchases = ref.watch(purchasesProvider);
    final pending = ref.watch(pendingCountProvider).valueOrNull ?? 0;
    return RefreshIndicator(
      onRefresh: () async { await ref.read(repositoryProvider).sync.syncAll(); ref.invalidate(purchasesProvider); ref.invalidate(pendingCountProvider); },
      child: purchases.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => ListView(children: [Center(child: Text(error.toString()))]),
        data: (items) {
          final today = DateTime.now();
          final todayItems = items.where((item) => item.purchasedAt.toLocal().year == today.year && item.purchasedAt.toLocal().month == today.month && item.purchasedAt.toLocal().day == today.day).toList();
          final totalWeight = todayItems.fold<int>(0, (sum, item) => sum + item.weightGrams);
          final totalAmount = todayItems.fold<int>(0, (sum, item) => sum + item.totalAmountToman);
          return ListView(padding: const EdgeInsets.all(16), children: [
            _HeroCard(title: 'عملکرد امروز', subtitle: '${todayItems.length} خرید ثبت‌شده', value: weight(totalWeight), icon: Icons.scale_rounded),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(child: _MetricCard(label: 'ارزش خرید', value: toman(totalAmount), icon: Icons.payments_outlined)),
              const SizedBox(width: 12),
              Expanded(child: _MetricCard(label: 'در انتظار ارسال', value: '$pending مورد', icon: Icons.cloud_upload_outlined, accent: pending > 0)),
            ]),
            const SizedBox(height: 22),
            const Text('آخرین خریدها', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
            const SizedBox(height: 10),
            if (items.isEmpty) const _EmptyState(message: 'هنوز خریدی ثبت نشده است') else ...items.take(8).map((item) => Card(
              child: ListTile(
                leading: CircleAvatar(backgroundColor: item.synced ? const Color(0xFFE2F1E9) : const Color(0xFFFFE8DB), child: Icon(item.synced ? Icons.cloud_done : Icons.cloud_off, color: item.synced ? AhanChiColors.recycledGreen : AhanChiColors.copper)),
                title: Text(weight(item.weightGrams), style: const TextStyle(fontWeight: FontWeight.w700)),
                subtitle: Text(toman(item.totalAmountToman)),
                trailing: Text(item.synced ? 'ارسال‌شده' : 'آفلاین', style: const TextStyle(fontSize: 11)),
              ),
            )),
          ]);
        },
      ),
    );
  }
}

class _ManagerDashboard extends ConsumerStatefulWidget {
  const _ManagerDashboard();
  @override
  ConsumerState<_ManagerDashboard> createState() => _ManagerDashboardState();
}

class _ManagerDashboardState extends ConsumerState<_ManagerDashboard> {
  late Future<Map<String, dynamic>> future;
  @override
  void initState() { super.initState(); future = ref.read(repositoryProvider).api.get('/reports/dashboard'); }
  Future<void> refresh() async { setState(() => future = ref.read(repositoryProvider).api.get('/reports/dashboard')); await future; }

  @override
  Widget build(BuildContext context) => FutureBuilder<Map<String, dynamic>>(
    future: future,
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const Center(child: CircularProgressIndicator());
      if (snapshot.hasError) {
        return Center(child: Padding(padding: const EdgeInsets.all(24), child: Column(mainAxisSize: MainAxisSize.min, children: [
          const Icon(Icons.cloud_off_rounded, size: 56), const SizedBox(height: 12),
          const Text('برای گزارش مدیر اتصال به سرور لازم است'), const SizedBox(height: 12),
          OutlinedButton.icon(onPressed: refresh, icon: const Icon(Icons.refresh), label: const Text('تلاش دوباره')),
        ])));
      }
      final data = snapshot.data!;
      final overview = (data['overview'] as Map<String, dynamic>?) ?? {};
      final materials = (data['byMaterial'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final reps = (data['byRepresentative'] as List<dynamic>? ?? []).cast<Map<String, dynamic>>();
      final largest = data['largestCreditor'] as Map<String, dynamic>?;
      return RefreshIndicator(
        onRefresh: refresh,
        child: ListView(padding: const EdgeInsets.all(16), children: [
          _HeroCard(title: 'خرید ۳۰ روز اخیر', subtitle: '${overview['purchaseCount'] ?? 0} تراکنش', value: weight((overview['totalWeightGrams'] as num? ?? 0).round()), icon: Icons.analytics_rounded),
          const SizedBox(height: 14),
          Row(children: [
            Expanded(child: _MetricCard(label: 'ارزش کل', value: toman((overview['totalAmountToman'] as num? ?? 0).round()), icon: Icons.stacked_line_chart)),
            const SizedBox(width: 12),
            Expanded(child: _MetricCard(label: 'بدهی فروشندگان', value: toman((overview['totalPayableToman'] as num? ?? 0).round()), icon: Icons.account_balance_wallet_outlined, accent: true)),
          ]),
          const SizedBox(height: 14),
          if (largest != null) _MetricCard(label: 'بزرگ‌ترین طلبکار: ${largest['fullName']}', value: toman((largest['balanceToman'] as num? ?? 0).round()), icon: Icons.person_pin_circle_outlined),
          const SizedBox(height: 22),
          const Text('تفکیک مواد', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          const SizedBox(height: 10),
          if (materials.isEmpty) const _EmptyState(message: 'داده‌ای در این بازه وجود ندارد') else ...materials.map((row) => Card(child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [Expanded(child: Text(row['nameFa'] as String, style: const TextStyle(fontWeight: FontWeight.w800))), Text(weight((row['totalWeightGrams'] as num).round()))]),
              const SizedBox(height: 8),
              LinearProgressIndicator(value: ((row['totalWeightGrams'] as num).toDouble() / ((materials.first['totalWeightGrams'] as num).toDouble().clamp(1, double.infinity))).clamp(0, 1).toDouble(), minHeight: 8, borderRadius: BorderRadius.circular(8)),
              const SizedBox(height: 8),
              Text('میانگین وزنی: ${toman((row['weightedAveragePricePerKgToman'] as num? ?? 0).round())} / کیلو', style: Theme.of(context).textTheme.bodySmall),
            ]),
          ))),
          const SizedBox(height: 22),
          const Text('عملکرد نمایندگان', style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ...reps.map((row) => ListTile(
            contentPadding: const EdgeInsets.symmetric(horizontal: 4),
            leading: const CircleAvatar(child: Icon(Icons.person_outline)),
            title: Text(row['fullName'] as String),
            subtitle: Text('${row['city'] ?? ''} • ${row['purchaseCount']} خرید'),
            trailing: Text(weight((row['totalWeightGrams'] as num).round()), style: const TextStyle(fontWeight: FontWeight.w800)),
          )),
        ]),
      );
    },
  );
}

class _HeroCard extends StatelessWidget {
  const _HeroCard({required this.title, required this.subtitle, required this.value, required this.icon});
  final String title, subtitle, value; final IconData icon;
  @override
  Widget build(BuildContext context) => Container(
    padding: const EdgeInsets.all(22),
    decoration: BoxDecoration(color: AhanChiColors.graphite, borderRadius: BorderRadius.circular(24)),
    child: Row(children: [
      Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text(title, style: const TextStyle(color: Colors.white70)), const SizedBox(height: 8),
        Text(value, style: const TextStyle(color: Colors.white, fontSize: 25, fontWeight: FontWeight.w900)),
        const SizedBox(height: 6), Text(subtitle, style: const TextStyle(color: Colors.white54, fontSize: 12)),
      ])),
      Container(padding: const EdgeInsets.all(14), decoration: BoxDecoration(color: Colors.white.withValues(alpha: .1), borderRadius: BorderRadius.circular(18)), child: Icon(icon, color: AhanChiColors.copper, size: 34)),
    ]),
  );
}

class _MetricCard extends StatelessWidget {
  const _MetricCard({required this.label, required this.value, required this.icon, this.accent = false});
  final String label, value; final IconData icon; final bool accent;
  @override
  Widget build(BuildContext context) => Card(child: Padding(padding: const EdgeInsets.all(16), child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
    Icon(icon, color: accent ? AhanChiColors.copper : AhanChiColors.recycledGreen), const SizedBox(height: 14),
    Text(label, style: Theme.of(context).textTheme.bodySmall), const SizedBox(height: 5),
    Text(value, maxLines: 2, overflow: TextOverflow.ellipsis, style: const TextStyle(fontWeight: FontWeight.w900, fontSize: 15)),
  ])));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.message}); final String message;
  @override
  Widget build(BuildContext context) => Padding(padding: const EdgeInsets.all(32), child: Column(children: [const Icon(Icons.inbox_outlined, size: 48, color: AhanChiColors.muted), const SizedBox(height: 12), Text(message)]));
}

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/models.dart';
import '../providers.dart';
import 'dashboard_screen.dart';
import 'ledger_screen.dart';
import 'purchase_form_screen.dart';
import 'purchases_screen.dart';
import 'sellers_screen.dart';
import 'settings_screen.dart';
import 'users_screen.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key, required this.session});
  final AuthSession session;
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> with WidgetsBindingObserver {
  int index = 0;
  bool syncing = false;

  @override
  void initState() { super.initState(); WidgetsBinding.instance.addObserver(this); }
  @override
  void dispose() { WidgetsBinding.instance.removeObserver(this); super.dispose(); }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) { if (state == AppLifecycleState.resumed) sync(); }

  Future<void> sync() async {
    if (syncing) return;
    setState(() => syncing = true);
    final result = await ref.read(repositoryProvider).sync.syncAll();
    ref.invalidate(materialsProvider); ref.invalidate(sellersProvider); ref.invalidate(purchasesProvider); ref.invalidate(pendingCountProvider);
    if (mounted) {
      setState(() => syncing = false);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('${result.synced} مورد همگام شد؛ ${result.failed} خطا')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final isManager = widget.session.isManager;
    final pages = isManager
        ? const [DashboardScreen(), PurchasesScreen(remote: true), UsersScreen(), SettingsScreen()]
        : const [DashboardScreen(), PurchaseFormScreen(), SellersScreen(), LedgerScreen(), SettingsScreen()];
    final destinations = isManager
        ? const [
          NavigationDestination(icon: Icon(Icons.dashboard_outlined), selectedIcon: Icon(Icons.dashboard), label: 'گزارش'),
          NavigationDestination(icon: Icon(Icons.receipt_long_outlined), label: 'خریدها'),
          NavigationDestination(icon: Icon(Icons.groups_outlined), label: 'نماینده‌ها'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'تنظیمات'),
        ]
        : const [
          NavigationDestination(icon: Icon(Icons.home_outlined), selectedIcon: Icon(Icons.home), label: 'خانه'),
          NavigationDestination(icon: Icon(Icons.add_circle_outline), selectedIcon: Icon(Icons.add_circle), label: 'ثبت خرید'),
          NavigationDestination(icon: Icon(Icons.people_outline), label: 'فروشنده‌ها'),
          NavigationDestination(icon: Icon(Icons.account_balance_wallet_outlined), label: 'حساب'),
          NavigationDestination(icon: Icon(Icons.settings_outlined), label: 'تنظیمات'),
        ];
    return Scaffold(
      appBar: AppBar(
        title: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Text(isManager ? 'مرکز مدیریت آهن‌چی' : 'پنل نماینده', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          Text(widget.session.fullName, style: Theme.of(context).textTheme.labelSmall),
        ]),
        actions: [
          Consumer(builder: (_, ref, __) => ref.watch(pendingCountProvider).maybeWhen(
            data: (count) => Badge(isLabelVisible: count > 0, label: Text('$count'), child: IconButton(onPressed: sync, tooltip: 'همگام‌سازی', icon: syncing ? const SizedBox.square(dimension: 22, child: CircularProgressIndicator(strokeWidth: 2)) : const Icon(Icons.sync_rounded))),
            orElse: () => IconButton(onPressed: sync, icon: const Icon(Icons.sync_rounded)),
          )),
          const SizedBox(width: 8),
        ],
      ),
      body: IndexedStack(index: index, children: pages),
      bottomNavigationBar: NavigationBar(
        selectedIndex: index,
        onDestinationSelected: (value) => setState(() => index = value),
        destinations: destinations,
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
      ),
    );
  }
}

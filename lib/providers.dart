import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'data/app_repository.dart';
import 'data/local_database.dart';
import 'models/models.dart';

final preferencesProvider = Provider<SharedPreferences>((_) => throw UnimplementedError());
final repositoryProvider = Provider<AppRepository>((ref) => AppRepository(preferences: ref.watch(preferencesProvider), db: LocalDatabase.instance));

class AuthController extends StateNotifier<AsyncValue<AuthSession?>> {
  AuthController(this.repository) : super(const AsyncLoading()) { restore(); }
  final AppRepository repository;
  Future<void> restore() async {
    state = AsyncData(await repository.restoreSession());
  }
  Future<void> login(String phone, String password) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(() => repository.login(phone, password));
  }
  Future<void> logout() async { await repository.logout(); state = const AsyncData(null); }
}

final authProvider = StateNotifierProvider<AuthController, AsyncValue<AuthSession?>>((ref) => AuthController(ref.watch(repositoryProvider)));
final materialsProvider = FutureProvider.autoDispose((_) => LocalDatabase.instance.materials());
final sellersProvider = FutureProvider.autoDispose((_) => LocalDatabase.instance.sellers());
final purchasesProvider = FutureProvider.autoDispose((_) => LocalDatabase.instance.purchases());
final pendingCountProvider = FutureProvider.autoDispose((_) => LocalDatabase.instance.pendingCount());
final managerDashboardProvider = FutureProvider.autoDispose<Map<String, dynamic>>(
  (ref) => ref.watch(repositoryProvider).api.get('/reports/dashboard'),
);
final remotePurchasesProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(repositoryProvider).api.list('/purchases'),
);
final usersProvider = FutureProvider.autoDispose<List<Map<String, dynamic>>>(
  (ref) => ref.watch(repositoryProvider).api.list('/users'),
);

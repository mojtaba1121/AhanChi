import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:workmanager/workmanager.dart';
import 'core/theme/app_theme.dart';
import 'data/api_client.dart';
import 'data/local_database.dart';
import 'data/sync_service.dart';
import 'providers.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

const backgroundSyncTask = 'ir.ahanchi.backgroundSync';

@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((_, __) async {
    final preferences = await SharedPreferences.getInstance();
    if (preferences.getString('access_token') == null) return true;
    try {
      await SyncService(LocalDatabase.instance, ApiClient(preferences)).syncAll();
      return true;
    } catch (_) {
      return false;
    }
  });
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  final preferences = await SharedPreferences.getInstance();
  await LocalDatabase.instance.database;
  if (!kIsWeb && defaultTargetPlatform == TargetPlatform.android) {
    await Workmanager().initialize(callbackDispatcher);
    await Workmanager().registerPeriodicTask(
      'ahanchi-periodic-sync',
      backgroundSyncTask,
      frequency: const Duration(minutes: 15),
      existingWorkPolicy: ExistingPeriodicWorkPolicy.keep,
      constraints: Constraints(networkType: NetworkType.connected),
    );
  }
  runApp(ProviderScope(
    overrides: [preferencesProvider.overrideWithValue(preferences)],
    child: const AhanChiApp(),
  ));
}

class AhanChiApp extends ConsumerWidget {
  const AhanChiApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return MaterialApp(
      title: 'آهن‌چی',
      debugShowCheckedModeBanner: false,
      theme: AhanChiTheme.light(),
      locale: const Locale('fa'),
      supportedLocales: const [Locale('fa'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      home: ref.watch(authProvider).when(
        loading: () => const _SplashScreen(),
        error: (error, _) => LoginScreen(initialError: error.toString()),
        data: (session) => session == null ? const LoginScreen() : HomeScreen(session: session),
      ),
    );
  }
}

class _SplashScreen extends StatelessWidget {
  const _SplashScreen();
  @override
  Widget build(BuildContext context) => const Scaffold(
    body: Center(child: Column(mainAxisSize: MainAxisSize.min, children: [
      ClipRRect(borderRadius: BorderRadius.all(Radius.circular(24)), child: Image(image: AssetImage('assets/branding/ahanchi-logo.png'), width: 92, height: 92)),
      SizedBox(height: 20),
      Text('آهن‌چی', style: TextStyle(fontSize: 28, fontWeight: FontWeight.w800)),
      SizedBox(height: 20),
      CircularProgressIndicator(),
    ])),
  );
}

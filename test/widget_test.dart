import 'package:ahanchi/main.dart';
import 'package:ahanchi/providers.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('shows the Persian login screen for a signed-out user', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(preferences)],
        child: const AhanChiApp(),
      ),
    );
    await tester.pumpAndSettle();

    expect(find.text('آهن‌چی'), findsOneWidget);
    expect(find.text('ورود به سامانه'), findsOneWidget);
  });

  testWidgets('shows clear validation messages for an empty login form', (tester) async {
    SharedPreferences.setMockInitialValues({});
    final preferences = await SharedPreferences.getInstance();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [preferencesProvider.overrideWithValue(preferences)],
        child: const AhanChiApp(),
      ),
    );
    await tester.pumpAndSettle();
    await tester.tap(find.text('ورود به سامانه'));
    await tester.pump();

    expect(find.text('شماره موبایل الزامی است'), findsOneWidget);
    expect(find.text('رمز عبور الزامی است'), findsOneWidget);
    expect(find.text('لطفاً موارد مشخص‌شده در فرم را اصلاح کنید'), findsOneWidget);
  });
}

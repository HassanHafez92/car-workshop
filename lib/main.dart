import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:easy_localization/easy_localization.dart';
import 'theme/app_theme.dart';
import 'views/main_layout.dart';
import 'views/auth/login_view.dart';
import 'providers/auth_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await EasyLocalization.ensureInitialized();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('ar'), Locale('en')],
      path: 'assets/translations',
      fallbackLocale: const Locale('ar'),
      startLocale: const Locale('ar'), // Set Arabic RTL as default
      child: const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);

    Widget homeWidget;
    if (authState.isLoading && authState.currentUser == null) {
      homeWidget = const Scaffold(
        body: Center(
          child: CircularProgressIndicator(color: AppColors.primary),
        ),
      );
    } else if (authState.currentUser == null) {
      homeWidget = const LoginView();
    } else {
      homeWidget = const MainLayout();
    }

    return MaterialApp(
      title: 'مركز صيانة السيارات',
      localizationsDelegates: context.localizationDelegates,
      supportedLocales: context.supportedLocales,
      locale: context.locale,
      theme: AppTheme.lightTheme,
      home: homeWidget,
      debugShowCheckedModeBanner: false,
    );
  }
}

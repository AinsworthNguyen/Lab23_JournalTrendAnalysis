import 'package:easy_localization/easy_localization.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/navigation/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/profile/presentation/blocs/theme_cubit.dart';
import 'injection_container.dart';
import 'core/firebase/firebase_messaging_service.dart';
import 'core/firebase/firebase_remote_config_service.dart';

import 'firebase_options.dart';

void main() async {
  // Ensure framework services are active
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase core services
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  // Initialize easy localization
  await EasyLocalization.ensureInitialized();

  // Initialize local Hive database
  await Hive.initFlutter();
  await Hive.openBox('analytics_cache');
  await Hive.openBox('search_history');
  await Hive.openBox('user_activity_logs');

  // Configure GetIt locator registrations
  await configureDependencies();

  // Initialize messaging and remote config services
  await getIt<IFirebaseMessagingService>().initialize();
  await getIt<IFirebaseRemoteConfigService>().initialize();

  runApp(
    EasyLocalization(
      supportedLocales: const [Locale('en'), Locale('vi')],
      path: 'assets/translations',
      fallbackLocale: const Locale('en'),
      child: BlocProvider<ThemeCubit>(
        create: (context) => getIt<ThemeCubit>(),
        child: const MyApp(),
      ),
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ThemeCubit, ThemeMode>(
      builder: (context, themeMode) {
        return MaterialApp.router(
          title: 'Journal Trend Analysis',
          theme: AppTheme.lightTheme,
          darkTheme: AppTheme.darkTheme,
          themeMode: themeMode,
          routerConfig: appRouter,
          localizationsDelegates: context.localizationDelegates,
          supportedLocales: context.supportedLocales,
          locale: context.locale,
          debugShowCheckedModeBanner: false,
        );
      },
    );
  }
}

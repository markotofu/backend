import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'supabase_config.dart';
import 'splash_screen.dart';

import 'theme_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.supabaseUrl,
    anonKey: SupabaseConfig.supabaseAnonKey,
  );

  final themeController = ThemeController();
  await themeController.load();

  runApp(MyApp(themeController: themeController));
}

final supabase = Supabase.instance.client;

class MyApp extends StatelessWidget {
  const MyApp({super.key, required this.themeController});

  final ThemeController themeController;

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: themeController,
      builder: (context, _) {
        return ThemeControllerScope(
          controller: themeController,
          child: MaterialApp(
            title: 'Flutter Exam App',
            debugShowCheckedModeBanner: false,
            themeMode: themeController.mode,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: Colors.blue),
              useMaterial3: true,
            ),
            darkTheme: ThemeData(
              brightness: Brightness.dark,
              colorScheme: ColorScheme.fromSeed(
                seedColor: Colors.blue,
                brightness: Brightness.dark,
              ),
              useMaterial3: true,
            ),
            home: const SplashScreen(),
          ),
        );
      },
    );
  }
}

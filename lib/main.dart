// Dr. Vroom Trainer App — 닥터브릉이 교육 앱
// Main entry point
///
/// This app allows trainers and experts to:
/// 1. Review diagnosis sessions from clients
/// 2. Label sound data with correct fault codes
/// 3. Upload new sound patterns to the knowledge base
/// 4. Monitor AI model performance and knowledge growth

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:hive_flutter/hive_flutter.dart';

import 'core/theme/app_theme.dart';
import 'core/constants/app_constants.dart';
import 'providers/auth_provider.dart';
import 'providers/trainer_provider.dart';
import 'screens/splash/splash_screen.dart';
import 'screens/auth/login_screen.dart';
import 'screens/dashboard/dashboard_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Hive
  await Hive.initFlutter();
  await Hive.openBox(AppConstants.sessionsBoxName);
  await Hive.openBox(AppConstants.settingsBoxName);

  runApp(const DrVroomTrainerApp());
}

class DrVroomTrainerApp extends StatelessWidget {
  const DrVroomTrainerApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()..initialize()),
        ChangeNotifierProvider(create: (_) => TrainerProvider()..initialize()),
      ],
      child: MaterialApp(
        title: AppConstants.appName,
        debugShowCheckedModeBanner: false,
        theme: AppTheme.trainerTheme,
        home: const SplashScreen(),
        routes: {
          '/login': (ctx) => const LoginScreen(),
          '/dashboard': (ctx) => const DashboardScreen(),
        },
      ),
    );
  }
}

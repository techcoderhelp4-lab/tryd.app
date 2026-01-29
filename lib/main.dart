import 'package:firebase_core/firebase_core.dart';
import "package:flutter_riverpod/flutter_riverpod.dart";
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'src/features/onboarding/presentation/splash_screen.dart';
import 'src/features/notifications/data/real_time_notification_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
  runApp(
    const ProviderScope(
      child: MyApp(),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> {
  @override
  void initState() {
    super.initState();
    // Initialize notification service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(realTimeNotificationServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
        designSize: const Size(375, 812), // Standard design size
        minTextAdapt: true,
        splitScreenMode: true,
        builder: (context, child) {
          return MaterialApp(
            title: 'Tryd',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xFF910EBF)),
              useMaterial3: true,
            ),
            home: const SplashScreen(),
          );
        },
    );
  }
}

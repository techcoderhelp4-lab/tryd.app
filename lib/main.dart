import 'dart:io';
import 'package:firebase_core/firebase_core.dart';
import "package:flutter_riverpod/flutter_riverpod.dart";
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:device_preview/device_preview.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'src/features/onboarding/presentation/splash_screen.dart';
import 'src/features/notifications/data/real_time_notification_service.dart';
import 'core/network/sync_service.dart';

final GlobalKey<ScaffoldMessengerState> scaffoldMessengerKey = GlobalKey<ScaffoldMessengerState>();

void main() async {
  WidgetsBinding widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  // Firebase only supported on Android, iOS, Web, macOS
  if (!Platform.isLinux && !Platform.isWindows) {
    await Firebase.initializeApp();
  }
  runApp(
    DevicePreview(
      enabled: !kReleaseMode,
      builder: (context) => const ProviderScope(
        child: MyApp(),
      ),
    ),
  );
}

class MyApp extends ConsumerStatefulWidget {
  const MyApp({super.key});

  @override
  ConsumerState<MyApp> createState() => _MyAppState();
}

class _MyAppState extends ConsumerState<MyApp> with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    // Initialize services
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(realTimeNotificationServiceProvider).init();
      ref.read(syncServiceProvider).init();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      debugPrint('App: Resumed — refreshing connections');
      ref.read(realTimeNotificationServiceProvider).reconnect();
      ref.read(syncServiceProvider).init();
    } else if (state == AppLifecycleState.paused || 
               state == AppLifecycleState.hidden || 
               state == AppLifecycleState.inactive) {
      debugPrint('App: Background — pausing connections');
      ref.read(realTimeNotificationServiceProvider).pause();
    }
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
            scaffoldMessengerKey: scaffoldMessengerKey,
            debugShowCheckedModeBanner: false,
            locale: DevicePreview.locale(context),
            builder: DevicePreview.appBuilder,
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

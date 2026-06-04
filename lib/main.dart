import 'package:angle_mvp/core/theme/app_theme.dart';
import 'package:angle_mvp/core/router/router_provider.dart';
import 'package:angle_mvp/core/services/lifecycle_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  // Use your computer's local IP (192.168.0.123) for real-device debugging
  // If you switch back to an emulator, you may need 10.0.2.2 (Android) or localhost (iOS/Web)
  const String supabaseUrl = 'http://127.0.0.1:8000';

  await Supabase.initialize(
    url: supabaseUrl,
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJyb2xlIjoiYW5vbiIsImlzcyI6InN1cGFiYXNlIiwiaWF0IjoxNzc1MzQwMDAwLCJleHAiOjE5MzMxMDY0MDB9.A9an-61EspHMgGVQnqsxxQPuSRV6IVGf82_lTqJatQ8',
  );

  runApp(const ProviderScope(child: MyApp()));
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
    // Initialize lifecycle service
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(lifecycleServiceProvider).init();
    });
  }

  @override
  Widget build(BuildContext context) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Safety App MVP',
      theme: AppTheme.darkTheme,
      routerConfig: router,
      debugShowCheckedModeBanner: false,
    );
  }
}

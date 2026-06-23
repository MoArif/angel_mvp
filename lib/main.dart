import 'package:angle_mvp/core/theme/app_theme.dart';
import 'package:angle_mvp/core/router/router_provider.dart';
import 'package:angle_mvp/core/services/lifecycle_service.dart';
import 'package:angle_mvp/core/constants/supabase_config.dart';
import 'package:angle_mvp/services/sms_relay_service.dart';
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
  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
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
      ref.read(smsRelayServiceProvider);
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

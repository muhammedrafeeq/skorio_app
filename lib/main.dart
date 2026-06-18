import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/network/supabase_config.dart';
import 'core/routing/router.dart';
import 'core/theme/theme.dart';
import 'core/services/notifications_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: SupabaseConfig.url,
    anonKey: SupabaseConfig.anonKey,
  );

  if (!kIsWeb) {
    try {
      await NotificationsService.instance.initFCM();
    } catch (e) {
      debugPrint('Firebase not configured: $e');
    }
  }

  runApp(
    const ProviderScope(
      child: SkorioApp(),
    ),
  );
}

class SkorioApp extends ConsumerWidget {
  const SkorioApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: 'Skorio',
      debugShowCheckedModeBanner: false,
      theme: SkorioTheme.darkTheme,
      routerConfig: router,
    );
  }
}

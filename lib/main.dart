import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter_gemma/core/api/flutter_gemma.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'core/theme/app_theme.dart';
import 'core/router/app_router.dart';
import 'firebase_options.dart';
import 'presentation/providers/theme_provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  // Initialize Gemma (no token needed for public models like Gemma 3 1B)
  await FlutterGemma.initialize();
  runApp(const ProviderScope(child: PackLiteApp()));
}

class PackLiteApp extends ConsumerWidget {
  const PackLiteApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeState = ref.watch(themeProvider);
    final cs = themeState.colorScheme;
    final router = buildRouter(ref);
    return MaterialApp.router(
      title: 'PackLite',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(cs.primary, cs.secondary),
      darkTheme: AppTheme.dark(cs.primary, cs.secondary),
      themeMode: themeState.mode,
      routerConfig: router,
    );
  }
}

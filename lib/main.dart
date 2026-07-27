import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'src/config/theme.dart';
import 'src/config/api_config.dart';
import 'src/navigation/app_router.dart';
import 'src/notification/notification_handler.dart';
import 'src/services/app_poller.dart';

Future<void> main() async {
  // Minimal initialization - app launches almost immediately
  WidgetsFlutterBinding.ensureInitialized();
  ApiConfig.setEnvironment(ApiEnvironment.local);

  runApp(const ProviderScope(child: MyApp()));
}

class MyApp extends ConsumerWidget {
  const MyApp({super.key});
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      NotificationHandler.init(ref, navigatorKey);
    });
    // Ensure the global app poller is created and running so providers
    // auto-refresh across screens without user intervention.
    ref.read(appPollerProvider);
    return MaterialApp(
      title: 'ZaddyExpress',
      debugShowCheckedModeBanner: false,
      theme: createAppTheme(),
      navigatorKey: navigatorKey,
      initialRoute: '/splash',
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
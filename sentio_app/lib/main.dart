import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/config/constants.dart';
import 'package:sentio_app/config/router.dart';
import 'package:sentio_app/providers/app_provider.dart';
import 'package:sentio_app/services/notification_service.dart';
import 'package:sentio_app/services/push_service.dart';
import 'package:sentio_app/widgets/celebration_overlay_manager.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await initializeDateFormatting('es');

  await Supabase.initialize(
    url: SentioConstants.supabaseUrl,
    anonKey: SentioConstants.supabaseAnonKey,
  );

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
    systemNavigationBarColor: SentioColors.background,
    systemNavigationBarIconBrightness: Brightness.light,
  ));

  final appProvider = AppProvider();
  await appProvider.initialize();

  await NotificationService.instance.initialize();

  // Push (no-op hasta que haya onesignal_app_id en app_config)
  await PushService.instance.initialize();

  runApp(SentioApp(appProvider: appProvider));
}

class SentioApp extends StatefulWidget {
  final AppProvider appProvider;

  const SentioApp({super.key, required this.appProvider});

  @override
  State<SentioApp> createState() => _SentioAppState();
}

class _SentioAppState extends State<SentioApp> {
  late final _router = createRouter(widget.appProvider);

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: widget.appProvider,
      child: MaterialApp.router(
        title: 'B2Better',
        debugShowCheckedModeBanner: false,
        theme: SentioTheme.light(),
        darkTheme: SentioTheme.dark(),
        themeMode: ThemeMode.light,
        routerConfig: _router,
        builder: (context, child) {
          final provider = context.watch<AppProvider>();
          // Fallback global de emoji: garantiza que los emojis (usados como
          // íconos de emociones, chat, etc.) se rendericen en todos los
          // dispositivos/renderers, no como cuadros vacíos.
          return DefaultTextStyle.merge(
            style: const TextStyle(fontFamilyFallback: ['NotoEmoji']),
            child: Stack(
              children: [
                child!,
                CelebrationOverlayManager(provider: provider),
              ],
            ),
          );
        },
      ),
    );
  }
}

import 'package:flutter/foundation.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

/// Push vía OneSignal.
///
/// No hace nada hasta que exista `onesignal_app_id` en la tabla `app_config`
/// (lectura pública). Así la app sigue funcionando sin push configurado, y el
/// día que se cargue el App ID en el admin, el push se activa solo.
///
/// La REST API key NUNCA va en el cliente: vive en `app_secrets` y la usa
/// `send_push()` en el backend.
class PushService {
  PushService._();
  static final PushService instance = PushService._();

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;
    try {
      final row = await Supabase.instance.client
          .from('app_config')
          .select('value')
          .eq('key', 'onesignal_app_id')
          .maybeSingle();
      final appId = (row?['value'] as String?)?.trim() ?? '';
      if (appId.isEmpty) return; // push no configurado todavía

      OneSignal.initialize(appId);
      await OneSignal.Notifications.requestPermission(true);
      _initialized = true;

      // Si ya hay sesión, vincular el usuario.
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId != null) await OneSignal.login(userId);
    } catch (e) {
      debugPrint('PushService.initialize: $e');
    }
  }

  /// Vincula el dispositivo al usuario (externalId = id de Supabase) para que
  /// `send_push(p_user_id, ...)` llegue a sus dispositivos.
  Future<void> login(String userId) async {
    if (!_initialized) return;
    try {
      await OneSignal.login(userId);
    } catch (e) {
      debugPrint('PushService.login: $e');
    }
  }

  Future<void> logout() async {
    if (!_initialized) return;
    try {
      await OneSignal.logout();
    } catch (e) {
      debugPrint('PushService.logout: $e');
    }
  }
}

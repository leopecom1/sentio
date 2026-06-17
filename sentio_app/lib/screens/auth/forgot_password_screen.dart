import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';

/// Flujo de recuperación de contraseña en dos pasos:
///  1) Ingresar email → se envía un código de 6 dígitos por correo (Resend).
///  2) Ingresar el código + la nueva contraseña → se valida y se cambia.
/// En éxito, el usuario queda logueado con la nueva contraseña.
class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _codeController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _codeSent = false;
  bool _loading = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _codeController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SentioColors.error,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  void _showOk(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: SentioColors.accent,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String _friendlyError(Object error) {
    if (error is PostgrestException) {
      final msg = error.message.toLowerCase();
      if (msg.contains('invalid_code') || msg.contains('código')) {
        return 'El código es incorrecto o ya expiró.';
      }
      if (msg.contains('expired')) {
        return 'El código expiró. Pedí uno nuevo.';
      }
      if (msg.contains('too_many') || msg.contains('rate')) {
        return 'Demasiados intentos. Esperá unos minutos.';
      }
      return error.message;
    }
    if (error is AuthException) {
      return error.message;
    }
    return 'Algo salió mal. Revisá tu conexión e intentá de nuevo.';
  }

  Future<void> _sendCode() async {
    final email = _emailController.text.trim();
    if (email.isEmpty || !email.contains('@')) {
      _showError('Ingresá un email válido.');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AppProvider>().requestPasswordReset(email);
      if (!mounted) return;
      setState(() => _codeSent = true);
      _showOk('Si el correo existe, te enviamos un código de 6 dígitos.');
    } catch (e) {
      _showError(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _resetPassword() async {
    final email = _emailController.text.trim();
    final code = _codeController.text.trim();
    final password = _passwordController.text;

    if (code.length != 6) {
      _showError('El código debe tener 6 dígitos.');
      return;
    }
    if (password.length < 6) {
      _showError('La nueva contraseña debe tener al menos 6 caracteres.');
      return;
    }
    setState(() => _loading = true);
    try {
      await context.read<AppProvider>().verifyPasswordReset(email, code, password);
      if (!mounted) return;
      _showOk('¡Contraseña actualizada! Ya podés entrar.');
      final provider = context.read<AppProvider>();
      if (provider.hasCompletedOnboarding) {
        context.go('/');
      } else {
        context.go('/onboarding');
      }
    } catch (e) {
      _showError(_friendlyError(e));
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: SentioColors.background,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_rounded, color: SentioColors.textPrimary),
          onPressed: () {
            if (_codeSent) {
              setState(() => _codeSent = false);
            } else {
              context.go('/auth?mode=login');
            }
          },
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              Text(
                _codeSent ? 'Revisá tu correo' : 'Recuperar contraseña',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  fontWeight: FontWeight.w800,
                  color: SentioColors.textPrimary,
                  letterSpacing: -0.5,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _codeSent
                    ? 'Ingresá el código de 6 dígitos que te enviamos a ${_emailController.text.trim()} y elegí tu nueva contraseña.'
                    : 'Te enviaremos un código de 6 dígitos a tu correo para que puedas crear una nueva contraseña.',
                style: GoogleFonts.manrope(
                  fontSize: 15,
                  color: SentioColors.textSecondary,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              if (!_codeSent) ..._buildEmailStep() else ..._buildCodeStep(),
            ],
          ),
        ),
      ),
    );
  }

  List<Widget> _buildEmailStep() {
    return [
      Text('Email', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      TextField(
        controller: _emailController,
        keyboardType: TextInputType.emailAddress,
        autofillHints: const [AutofillHints.email],
        decoration: const InputDecoration(hintText: 'tu@email.com'),
      ),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: _loading ? null : _sendCode,
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Enviar código'),
      ),
    ];
  }

  List<Widget> _buildCodeStep() {
    return [
      Text('Código de 6 dígitos', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      TextField(
        controller: _codeController,
        keyboardType: TextInputType.number,
        // Permite que iOS/Android autocompleten el código del email/SMS.
        autofillHints: const [AutofillHints.oneTimeCode],
        maxLength: 6,
        textAlign: TextAlign.center,
        style: GoogleFonts.manrope(
          fontSize: 28,
          fontWeight: FontWeight.w700,
          letterSpacing: 12,
          color: SentioColors.textPrimary,
        ),
        inputFormatters: [FilteringTextInputFormatter.digitsOnly],
        decoration: const InputDecoration(
          hintText: '······',
          counterText: '',
        ),
      ),
      const SizedBox(height: 20),
      Text('Nueva contraseña', style: Theme.of(context).textTheme.labelLarge),
      const SizedBox(height: 8),
      TextField(
        controller: _passwordController,
        obscureText: _obscurePassword,
        autofillHints: const [AutofillHints.newPassword],
        decoration: InputDecoration(
          hintText: '••••••••',
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword
                  ? Icons.visibility_off_outlined
                  : Icons.visibility_outlined,
              color: SentioColors.textTertiary,
            ),
            onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
          ),
        ),
      ),
      const SizedBox(height: 32),
      ElevatedButton(
        onPressed: _loading ? null : _resetPassword,
        child: _loading
            ? const SizedBox(
                height: 20,
                width: 20,
                child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
              )
            : const Text('Cambiar contraseña'),
      ),
      const SizedBox(height: 16),
      Center(
        child: TextButton(
          onPressed: _loading ? null : _sendCode,
          child: const Text(
            'Reenviar código',
            style: TextStyle(color: SentioColors.accent),
          ),
        ),
      ),
    ];
  }
}

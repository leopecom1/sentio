import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import 'package:sentio_app/config/theme.dart';
import 'package:sentio_app/providers/app_provider.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  bool _isLogin = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final provider = context.read<AppProvider>();
    if (_isLogin) {
      await provider.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
    } else {
      await provider.signUp(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
    }

    if (!mounted) return;
    if (provider.hasCompletedOnboarding) {
      context.go('/');
    } else {
      context.go('/onboarding');
    }
  }

  @override
  Widget build(BuildContext context) {
    final provider = context.watch<AppProvider>();

    return Scaffold(
      backgroundColor: SentioColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 60),
              // Logo
              Center(
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        color: SentioColors.primary,
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: const Icon(
                        Icons.spa_rounded,
                        color: Colors.white,
                        size: 32,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Sentio',
                      style: GoogleFonts.manrope(
                        fontSize: 32,
                        color: SentioColors.textPrimary,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 48),
              // Title
              Text(
                _isLogin ? 'Bienvenido de vuelta' : 'Creá tu cuenta',
                style: GoogleFonts.manrope(
                  fontSize: 28,
                  color: SentioColors.textPrimary,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isLogin
                    ? 'Tu espacio te está esperando.'
                    : 'Un paso hacia conocerte mejor.',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: SentioColors.textSecondary,
                    ),
              ),
              const SizedBox(height: 32),
              // Form
              if (!_isLogin) ...[
                Text('Nombre', style: Theme.of(context).textTheme.labelLarge),
                const SizedBox(height: 8),
                TextField(
                  controller: _nameController,
                  textCapitalization: TextCapitalization.words,
                  decoration: const InputDecoration(
                    hintText: '¿Cómo te llamás?',
                  ),
                ),
                const SizedBox(height: 20),
              ],
              Text('Email', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  hintText: 'tu@email.com',
                ),
              ),
              const SizedBox(height: 20),
              Text('Contraseña', style: Theme.of(context).textTheme.labelLarge),
              const SizedBox(height: 8),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                decoration: InputDecoration(
                  hintText: '••••••••',
                  suffixIcon: IconButton(
                    icon: Icon(
                      _obscurePassword ? Icons.visibility_off_outlined : Icons.visibility_outlined,
                      color: SentioColors.textTertiary,
                    ),
                    onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                  ),
                ),
              ),
              const SizedBox(height: 32),
              // Submit button
              ElevatedButton(
                onPressed: provider.isLoading ? null : _submit,
                child: provider.isLoading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(_isLogin ? 'Entrar' : 'Crear cuenta'),
              ),
              const SizedBox(height: 16),
              // Toggle
              Center(
                child: TextButton(
                  onPressed: () => setState(() => _isLogin = !_isLogin),
                  child: Text(
                    _isLogin
                        ? '¿No tenés cuenta? Creá una'
                        : '¿Ya tenés cuenta? Entrá',
                    style: const TextStyle(color: SentioColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              // Spacer at bottom
              Center(
                child: Text(
                  'Tu espacio seguro para emprendedores',
                  style: TextStyle(
                    color: SentioColors.textTertiary,
                    fontSize: 13,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

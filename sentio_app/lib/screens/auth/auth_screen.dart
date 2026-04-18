import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
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

class _AuthScreenState extends State<AuthScreen> with TickerProviderStateMixin {
  bool _isLogin = true;
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;

  late AnimationController _gradientController;

  @override
  void initState() {
    super.initState();
    _gradientController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _gradientController.dispose();
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
      body: Stack(
        children: [
          // Animated gradient background
          _buildAnimatedBackground(),
          // Content
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 60),
                  // Logo B2Better (green)
                  Center(
                    child: SvgPicture.asset(
                      'assets/images/b2better_logo_green.svg',
                      height: 48,
                      colorFilter: const ColorFilter.mode(
                        SentioColors.accent,
                        BlendMode.srcIn,
                      ),
                    ),
                  ),
                  const SizedBox(height: 56),
                  // Title
                  Text(
                    _isLogin ? 'Bienvenido de vuelta' : 'Creá tu cuenta',
                    style: GoogleFonts.manrope(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      color: SentioColors.textPrimary,
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _isLogin
                        ? 'Tu espacio te está esperando.'
                        : 'Un paso hacia conocerte mejor.',
                    style: GoogleFonts.manrope(
                      fontSize: 15,
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
                        style: const TextStyle(color: SentioColors.accent),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // Legal links (centered)
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Al continuar aceptás nuestros',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.manrope(
                            color: SentioColors.textTertiary,
                            fontSize: 12,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            GestureDetector(
                              onTap: () => context.push('/legal/terms'),
                              child: Text(
                                'Términos',
                                style: GoogleFonts.manrope(
                                  color: SentioColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            Text(
                              '  y  ',
                              style: GoogleFonts.manrope(
                                color: SentioColors.textTertiary,
                                fontSize: 12,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.push('/legal/privacy'),
                              child: Text(
                                'Política de Privacidad',
                                style: GoogleFonts.manrope(
                                  color: SentioColors.accent,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  Center(
                    child: Text(
                      'Tu espacio seguro para emprendedores',
                      style: TextStyle(
                        color: SentioColors.textTertiary,
                        fontSize: 13,
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ══════════════════════════════════════
  // ANIMATED GRADIENT BACKGROUND
  // ══════════════════════════════════════

  Widget _buildAnimatedBackground() {
    return AnimatedBuilder(
      animation: _gradientController,
      builder: (context, _) {
        final t = _gradientController.value;
        return Stack(
          children: [
            // Primary orb (blue)
            Positioned(
              left: -120 + t * 100,
              top: -80 + t * 60,
              child: Container(
                width: 340,
                height: 340,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      SentioColors.primary.withValues(alpha: 0.32),
                      SentioColors.primary.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Accent orb (green)
            Positioned(
              right: -100 + t * 80,
              top: 150 - t * 40,
              child: Container(
                width: 280,
                height: 280,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      SentioColors.accent.withValues(alpha: 0.22),
                      SentioColors.accent.withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Pink orb
            Positioned(
              left: -50 + t * 50,
              bottom: 80 + t * 60,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFFFF6B9D).withValues(alpha: 0.12),
                      const Color(0xFFFF6B9D).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
            // Purple orb
            Positioned(
              right: -80 + t * 40,
              bottom: -50 + t * 80,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      const Color(0xFF9B8EC4).withValues(alpha: 0.15),
                      const Color(0xFF9B8EC4).withValues(alpha: 0.0),
                    ],
                  ),
                ),
              ),
            ),
          ],
        );
      },
    );
  }
}

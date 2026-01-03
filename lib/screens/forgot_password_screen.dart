import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/primary_button.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final emailController = TextEditingController();
  final AuthService authService = AuthService();

  bool loading = false;
  String? error;

  void sendRecoveryEmail() async {
    final email = emailController.text.trim();

    if (email.isEmpty) {
      setState(() {
        error = 'Ingresa tu correo institucional';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await authService.resetPassword(email);

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Correo de recuperación enviado. Revisa tu bandeja.',
          ),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;

      setState(() {
        error = e.toString().replaceFirst('Exception: ', '');
      });
    } finally {
      if (mounted) {
        setState(() {
          loading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        children: [
          // 🔵 FONDO AZUL DEGRADADO (MISMO SISTEMA VISUAL)
          SizedBox(
            height: size.height,
            width: size.width,
            child: const DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    Color(0xFF0B2D5C),
                    Color(0xFF134B8A),
                    Color(0xFF1E6FD9),
                  ],
                ),
              ),
            ),
          ),

          SafeArea(
            child: SingleChildScrollView(
              physics: const BouncingScrollPhysics(),
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 56),

                  // HEADER
                  Text(
                    'Recuperar acceso',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Te ayudamos a restablecer tu contraseña',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),

                  const SizedBox(height: 48),

                  // CARD PRINCIPAL
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.25),
                          blurRadius: 50,
                          offset: const Offset(0, 25),
                        ),
                      ],
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Correo institucional',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Ingresa el correo con el que te registraste y te enviaremos un enlace para restablecer tu contraseña.',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                            height: 1.4,
                          ),
                        ),

                        const SizedBox(height: 28),

                        CustomTextField(
                          label: 'Correo institucional',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          icon: Icons.school_outlined,
                        ),

                        const SizedBox(height: 20),

                        if (error != null)
                          Padding(
                            padding:
                                const EdgeInsets.only(top: 4, bottom: 12),
                            child: Text(
                              error!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),

                        const SizedBox(height: 8),

                        PrimaryButton(
                          text: 'Enviar enlace',
                          onPressed: sendRecoveryEmail,
                          loading: loading,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // FOOTER
                  Center(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: Text(
                        'Volver al inicio de sesión',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: Colors.white,
                        ),
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
}

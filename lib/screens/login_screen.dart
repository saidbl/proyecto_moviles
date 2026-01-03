import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/primary_button.dart';
import 'register_screen.dart';
import 'forgot_password_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final AuthService authService = AuthService();

  bool loading = false;
  String? error;

  void login() async {
    setState(() {
      loading = true;
      error = null;
    });

    try {
      await authService.signIn(
        emailController.text.trim(),
        passwordController.text.trim(),
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Bienvenido')),
      );
    } catch (e) {
      if (!mounted) return;
      setState(() {
        error = 'Correo o contraseña incorrectos';
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
          // 🔵 FONDO DEGRADADO SIEMPRE COMPLETO
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
                  const SizedBox(height: 64),

                  // HEADER
                  Text(
                    'ESCOM Eventos',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Plataforma académica de eventos del IPN',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),

                  const SizedBox(height: 56),

                  // CARD PRINCIPAL
                  Container(
                    padding: const EdgeInsets.all(30),
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
                          'Acceso institucional',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Ingresa con tu cuenta oficial del IPN',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 32),

                        CustomTextField(
                          label: 'Correo institucional',
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          icon: Icons.school_outlined,
                        ),
                        const SizedBox(height: 20),

                        CustomTextField(
                          label: 'Contraseña',
                          controller: passwordController,
                          obscure: true,
                          icon: Icons.lock_outline_rounded,
                        ),

                        const SizedBox(height: 14),

                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      const ForgotPasswordScreen(),
                                ),
                              );
                            },
                            child: const Text('¿Olvidaste tu contraseña?'),
                          ),
                        ),

                        if (error != null)
                          Padding(
                            padding: const EdgeInsets.only(
                              top: 8,
                              bottom: 14,
                            ),
                            child: Text(
                              error!,
                              style: TextStyle(
                                color: Colors.red.shade700,
                                fontSize: 13,
                              ),
                            ),
                          ),

                        const SizedBox(height: 10),

                        PrimaryButton(
                          text: 'Ingresar',
                          onPressed: login,
                          loading: loading,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // FOOTER
                  Center(
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          '¿Aún no tienes cuenta?',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.white.withOpacity(0.9),
                          ),
                        ),
                        TextButton(
                          onPressed: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (_) =>
                                    const RegisterScreen(),
                              ),
                            );
                          },
                          child: const Text(
                            'Crear cuenta',
                            style: TextStyle(color: Colors.white),
                          ),
                        ),
                      ],
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

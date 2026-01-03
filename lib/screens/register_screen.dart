import 'package:flutter/material.dart';
import '../services/auth_service.dart';
import '../widgets/custom_textfield.dart';
import '../widgets/primary_button.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final passwordController = TextEditingController();
  final confirmPasswordController = TextEditingController();

  final AuthService authService = AuthService();

  bool loading = false;
  String? error;

  void register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        error = 'Todos los campos son obligatorios';
      });
      return;
    }

    if (password.length < 6) {
      setState(() {
        error = 'La contraseña debe tener al menos 6 caracteres';
      });
      return;
    }

    if (password != confirmPassword) {
      setState(() {
        error = 'Las contraseñas no coinciden';
      });
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      await authService.register(
        email: email,
        password: password,
        name: name,
      );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso')),
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
          // 🔵 FONDO AZUL DEGRADADO (MISMO QUE LOGIN)
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
                    'Crear cuenta',
                    style: theme.textTheme.headlineLarge?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.w800,
                      letterSpacing: -0.8,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Únete a la comunidad académica de ESCOM',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withOpacity(0.9),
                    ),
                  ),

                  const SizedBox(height: 48),

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
                          'Registro institucional',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Solo alumnos con correo @alumno.ipn.mx',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: Colors.grey.shade600,
                          ),
                        ),

                        const SizedBox(height: 32),

                        CustomTextField(
                          label: 'Nombre completo',
                          controller: nameController,
                          icon: Icons.person_outline_rounded,
                        ),
                        const SizedBox(height: 20),

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
                        const SizedBox(height: 20),

                        CustomTextField(
                          label: 'Confirmar contraseña',
                          controller: confirmPasswordController,
                          obscure: true,
                          icon: Icons.lock_reset_rounded,
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
                          text: 'Crear cuenta',
                          onPressed: register,
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
                        '¿Ya tienes cuenta? Inicia sesión',
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

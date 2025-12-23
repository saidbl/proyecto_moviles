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

  bool isInstitutionalEmail(String email) {
    return email.endsWith('@alumno.ipn.mx');
  }

  void register() async {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    final confirmPassword = confirmPasswordController.text.trim();

    // VALIDACIONES
    if (name.isEmpty ||
        email.isEmpty ||
        password.isEmpty ||
        confirmPassword.isEmpty) {
      setState(() {
        error = 'Todos los campos son obligatorios';
      });
      return;
    }

    if (!isInstitutionalEmail(email)) {
      setState(() {
        error = 'Usa tu correo institucional (@alumno.ipn.mx)';
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

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Registro exitoso')),
      );

      Navigator.pop(context); // volver al login
    } catch (e) {
      setState(() {
        error = 'No se pudo registrar el usuario';
      });
    } finally {
      setState(() {
        loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registro')),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              CustomTextField(
                label: 'Nombre completo',
                controller: nameController,
                icon: Icons.person,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Correo institucional',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Contraseña',
                controller: passwordController,
                obscure: true,
                icon: Icons.lock,
              ),
              const SizedBox(height: 16),

              CustomTextField(
                label: 'Confirmar contraseña',
                controller: confirmPasswordController,
                obscure: true,
                icon: Icons.lock_outline,
              ),
              const SizedBox(height: 24),

              if (error != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: Text(
                    error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),

              PrimaryButton(
                text: 'Crear cuenta',
                onPressed: register,
                loading: loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

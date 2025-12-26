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

      if (!mounted) return; // ✅ FIX

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Correo de recuperación enviado. Revisa tu bandeja.'),
        ),
      );

      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return; // ✅ FIX

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
    return Scaffold(
      appBar: AppBar(title: const Text('Recuperar contraseña')),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              const Text(
                'Ingresa tu correo institucional y te enviaremos un enlace para restablecer tu contraseña.',
                style: TextStyle(color: Colors.grey),
              ),
              const SizedBox(height: 24),

              CustomTextField(
                label: 'Correo institucional',
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                icon: Icons.email,
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
                text: 'Enviar correo',
                onPressed: sendRecoveryEmail,
                loading: loading,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

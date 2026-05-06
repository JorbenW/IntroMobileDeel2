import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/topbar.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/pink_button.dart';
import '../bottom_navbar.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;

  void _login() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (c) => const MainNavigation()),
          (r) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Fout bij inloggen');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _showError(String m) => ScaffoldMessenger.of(
    context,
  ).showSnackBar(SnackBar(content: Text(m), backgroundColor: Colors.red));

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: const CustomAppBar(showProfileIcon: false),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(30),
          child: Form(
            key: _formKey,
            child: Column(
              children: [
                const Text(
                  "Welkom terug!",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 30),
                AuthTextField(
                  hintText: 'E-mailadres',
                  controller: _emailController,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Voer een geldig e-mailadres in'
                      : null,
                ),
                AuthTextField(
                  hintText: 'Wachtwoord',
                  isPassword: true,
                  controller: _passwordController,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Voer je wachtwoord in' : null,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : PinkButton(text: 'INLOGGEN', onPressed: _login),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

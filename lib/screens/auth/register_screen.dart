import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../widgets/topbar.dart';
import '../../widgets/auth_text_field.dart';
import '../../widgets/pink_button.dart';
import '../bottom_navbar.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _isLoading = false;

  void _register() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      UserCredential uc = await FirebaseAuth.instance
          .createUserWithEmailAndPassword(
            email: _emailController.text.trim(),
            password: _passwordController.text,
          );
      await uc.user?.updateDisplayName(_usernameController.text);
      if (mounted) {
        Navigator.pushAndRemoveUntil(
          context,
          MaterialPageRoute(builder: (c) => const MainNavigation()),
          (r) => false,
        );
      }
    } on FirebaseAuthException catch (e) {
      _showError(e.message ?? 'Fout bij registratie');
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
                  "Nieuw Account",
                  style: TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: Colors.deepPurple,
                  ),
                ),
                const SizedBox(height: 30),
                AuthTextField(
                  hintText: 'Gebruikersnaam',
                  controller: _usernameController,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Vul een naam in' : null,
                ),
                AuthTextField(
                  hintText: 'E-mailadres',
                  controller: _emailController,
                  validator: (v) => (v == null || !v.contains('@'))
                      ? 'Ongeldig e-mailadres'
                      : null,
                ),
                AuthTextField(
                  hintText: 'Wachtwoord',
                  isPassword: true,
                  controller: _passwordController,
                  validator: (v) {
                    if (v == null || v.length < 6) return 'Minimaal 6 tekens';
                    if (!v.contains(RegExp(r'[0-9]')))
                      return 'Moet een cijfer bevatten';
                    if (!v.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]')))
                      return 'Moet een speciaal teken bevatten';
                    return null;
                  },
                ),
                AuthTextField(
                  hintText: 'Bevestig Wachtwoord',
                  isPassword: true,
                  controller: _confirmPasswordController,
                  validator: (v) => (v != _passwordController.text)
                      ? 'Wachtwoorden komen niet overeen'
                      : null,
                ),
                const SizedBox(height: 30),
                _isLoading
                    ? const CircularProgressIndicator()
                    : PinkButton(text: 'REGISTREREN', onPressed: _register),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:formative1/theme/devtrack_theme.dart';
import '../app_colors.dart';
import './signup_page.dart';
// importing the database helper
import '../database/database_helper.dart';
import 'home_shell.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _hidePassword = true;
  // checking if the login is in progress
  bool _isLoggingIn = false;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  // checking the login details
  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoggingIn = true;
    });

    final user = await DatabaseHelper.instance.loginUser(
      email: _emailCtrl.text,
      password: _passCtrl.text,
    );

    if (!mounted) {
      return;
    }

    if (user == null) {
      setState(() {
        _isLoggingIn = false;
      });

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Incorrect email or password'),
        ),
      );

      return;
    }

    // opening the dashboard
    Navigator.pushAndRemoveUntil(
      context,
      MaterialPageRoute(
        builder: (context) {
          return HomeShell(
            user: user,
          );
        },
      ),
          (route) => false,
    );
  }

  void _openSignUp() async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const SignUpPage()),
    );
    _emailCtrl.clear();
    _passCtrl.clear();
  }

  OutlineInputBorder _border(Color color, [double width = 1]) {
    return OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: BorderSide(color: color, width: width),
    );
  }

  InputDecoration _fieldStyle(String hint, IconData icon, {Widget? suffix}) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: DevTrackColors.muted),
      prefixIcon: Icon(icon, color: DevTrackColors.ink),
      suffixIcon: suffix,
      filled: true,
      fillColor: DevTrackColors.surface,
      contentPadding: const EdgeInsets.symmetric(vertical: 18),
      enabledBorder: _border(DevTrackColors.border),
      focusedBorder: _border(DevTrackColors.ink, 2),
      errorBorder: _border(DevTrackColors.overdue),
      focusedErrorBorder: _border(DevTrackColors.overdue, 2),
      errorStyle: const TextStyle(color: DevTrackColors.overdue),
    );
  }

  String? _checkEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@')) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _checkPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter your password';
    }
    if (value.length < 6) {
      return 'At least 6 characters';
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DevTrackColors.background,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset('images/devtrack_logo.png', height: 120),
                  const SizedBox(height: 24),
                  const Text(
                    'Project & SLA\nTask Tracker',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: DevTrackColors.ink,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Plan. Track. Deliver Together.',
                    style: TextStyle(fontSize: 16, color: DevTrackColors.muted),
                  ),
                  const SizedBox(height: 32),
                  TextFormField(
                    controller: _emailCtrl,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    cursorColor: DevTrackColors.ink,
                    decoration: _fieldStyle('Email', Icons.mail_outline),
                    validator: _checkEmail,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _passCtrl,
                    obscureText: _hidePassword,
                    textInputAction: TextInputAction.done,
                    cursorColor: DevTrackColors.ink,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: _fieldStyle(
                      'Password',
                      Icons.lock_outline,
                      suffix: IconButton(
                        icon: Icon(
                          _hidePassword
                              ? Icons.visibility_off
                              : Icons.visibility,
                          color: DevTrackColors.muted,
                        ),
                        onPressed: () =>
                            setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                    validator: _checkPassword,
                  ),
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: _submit,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: DevTrackColors.ink,
                        foregroundColor: DevTrackColors.surface,
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: const Text(
                        'Sign In',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: TextStyle(color: DevTrackColors.muted),
                      ),
                      GestureDetector(
                        onTap: _openSignUp,
                        child: const Text(
                          'Sign Up',
                          style: TextStyle(
                            color: DevTrackColors.onTrack,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
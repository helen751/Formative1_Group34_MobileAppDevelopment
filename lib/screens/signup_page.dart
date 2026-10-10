import 'package:flutter/material.dart';
import 'package:formative1/theme/devtrack_theme.dart';

class SignUpPage extends StatefulWidget {
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  final _confirmCtrl = TextEditingController();
  bool _hidePassword = true;
  bool _hideConfirm = true;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    _confirmCtrl.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      FocusScope.of(context).unfocus();
      Navigator.pop(context);
    }
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

  Widget _visibilityToggle(bool hidden, VoidCallback onPressed) {
    return IconButton(
      icon: Icon(
        hidden ? Icons.visibility_off : Icons.visibility,
        color: DevTrackColors.muted,
      ),
      onPressed: onPressed,
    );
  }

  String? _checkName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your name';
    }
    if (value.trim().length < 2) {
      return 'Name is too short';
    }
    return null;
  }

  String? _checkEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Please enter your email';
    }
    if (!value.contains('@') || !value.contains('.')) {
      return 'Enter a valid email';
    }
    return null;
  }

  String? _checkPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please enter a password';
    }
    if (value.length < 6) {
      return 'At least 6 characters';
    }
    return null;
  }

  String? _checkConfirm(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passCtrl.text) {
      return 'Passwords do not match';
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
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Form(
              key: _formKey,
              child: Column(
                children: [
                  Image.asset('images/devtrack_logo.png', height: 90),
                  const SizedBox(height: 20),
                  const Text(
                    'Create your account',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                      height: 1.2,
                      color: DevTrackColors.ink,
                    ),
                  ),
                  const SizedBox(height: 10),
                  const Text(
                    'Start tracking projects with your team.',
                    style: TextStyle(fontSize: 16, color: DevTrackColors.muted),
                  ),
                  const SizedBox(height: 28),
                  TextFormField(
                    controller: _nameCtrl,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    cursorColor: DevTrackColors.ink,
                    decoration: _fieldStyle('Full name', Icons.person_outline),
                    validator: _checkName,
                  ),
                  const SizedBox(height: 16),
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
                    textInputAction: TextInputAction.next,
                    cursorColor: DevTrackColors.ink,
                    decoration: _fieldStyle(
                      'Password',
                      Icons.lock_outline,
                      suffix: _visibilityToggle(
                        _hidePassword,
                        () => setState(() => _hidePassword = !_hidePassword),
                      ),
                    ),
                    validator: _checkPassword,
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _confirmCtrl,
                    obscureText: _hideConfirm,
                    textInputAction: TextInputAction.done,
                    cursorColor: DevTrackColors.ink,
                    onFieldSubmitted: (_) => _submit(),
                    decoration: _fieldStyle(
                      'Confirm password',
                      Icons.lock_outline,
                      suffix: _visibilityToggle(
                        _hideConfirm,
                        () => setState(() => _hideConfirm = !_hideConfirm),
                      ),
                    ),
                    validator: _checkConfirm,
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
                        'Create Account',
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
                        'Already have an account? ',
                        style: TextStyle(color: DevTrackColors.muted),
                      ),
                      GestureDetector(
                        onTap: () => Navigator.pop(context),
                        child: const Text(
                          'Sign In',
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
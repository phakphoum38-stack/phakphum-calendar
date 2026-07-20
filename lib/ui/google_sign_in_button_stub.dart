import 'package:flutter/material.dart';

class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: enabled ? onPressed : null,
    icon: const Icon(Icons.login),
    label: const Text('เข้าสู่ระบบด้วย Google'),
  );
}

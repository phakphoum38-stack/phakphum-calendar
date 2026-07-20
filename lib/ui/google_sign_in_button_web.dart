import 'package:flutter/material.dart';
import 'package:google_sign_in_web/web_only.dart' as web;

class GoogleLoginButton extends StatelessWidget {
  const GoogleLoginButton({
    super.key,
    required this.onPressed,
    this.enabled = true,
  });

  final VoidCallback onPressed;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return const SizedBox(
        width: 220,
        height: 42,
        child: Center(child: CircularProgressIndicator()),
      );
    }
    return SizedBox(width: 260, height: 44, child: web.renderButton());
  }
}

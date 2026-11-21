import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class BacaButton extends StatelessWidget {
  const BacaButton({
    required this.label,
    required this.onPressed,
    this.icon,
    super.key,
  });

  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton.icon(
        onPressed: onPressed,
        icon: Icon(icon ?? Icons.arrow_forward_rounded, size: 22),
        label: Text(label),
        style: ElevatedButton.styleFrom(
          minimumSize: const Size(
            AppTokens.minimumTouchTarget,
            AppTokens.buttonHeight,
          ),
        ),
      ),
    );
  }
}

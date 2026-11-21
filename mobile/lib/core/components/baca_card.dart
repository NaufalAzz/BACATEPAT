import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class BacaCard extends StatelessWidget {
  const BacaCard({required this.child, this.padding, super.key});

  final Widget child;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTokens.space16),
        child: child,
      ),
    );
  }
}

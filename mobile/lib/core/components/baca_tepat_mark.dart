import 'package:flutter/material.dart';

import '../theme/app_tokens.dart';

class BacaTepatMark extends StatelessWidget {
  const BacaTepatMark({this.size = 38, super.key});

  final double size;

  @override
  Widget build(BuildContext context) => Container(
    width: size,
    height: size,
    padding: EdgeInsets.only(right: size * 0.08, bottom: size * 0.08),
    decoration: BoxDecoration(
      color: AppTokens.accent,
      borderRadius: BorderRadius.circular(size * 0.3),
    ),
    child: Container(
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: AppTokens.primary,
        borderRadius: BorderRadius.circular(size * 0.3),
      ),
      child: Text(
        'B',
        style: TextStyle(
          color: Colors.white,
          fontSize: size * 0.58,
          fontWeight: FontWeight.w900,
          height: 1,
        ),
      ),
    ),
  );
}

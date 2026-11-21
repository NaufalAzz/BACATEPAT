import 'package:flutter/material.dart';

import '../core/components/baca_button.dart';
import '../core/components/baca_card.dart';
import '../core/theme/app_tokens.dart';

/// A small theme preview while product screens are still out of scope.
class FoundationOverview extends StatelessWidget {
  const FoundationOverview({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 560),
            child: ListView(
              padding: const EdgeInsets.all(AppTokens.space24),
              shrinkWrap: true,
              children: [
                const Icon(
                  Icons.menu_book_rounded,
                  color: AppTokens.primary,
                  size: 56,
                ),
                const SizedBox(height: AppTokens.space16),
                Text(
                  'BacaTepat',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineLarge,
                ),
                const SizedBox(height: AppTokens.space8),
                Text(
                  'Fondasi tampilan siap dikembangkan',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppTokens.space24),
                const BacaCard(
                  child: Text(
                    'Ruang belajar yang nyaman untuk siswa dan informatif untuk Guru.',
                  ),
                ),
                const SizedBox(height: AppTokens.space16),
                BacaButton(
                  label: 'Fondasi siap',
                  icon: Icons.check_circle_outline_rounded,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

abstract final class StudentColors {
  static const mint = AppTokens.mint;
  static const sunshine = AppTokens.sunshine;
  static const peach = AppTokens.coralSoft;
  static const sky = AppTokens.sky;
}

class StudentPageHeading extends StatelessWidget {
  const StudentPageHeading({
    required this.title,
    required this.subtitle,
    super.key,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppTokens.space16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.headlineMedium),
        const SizedBox(height: AppTokens.space4),
        Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
      ],
    ),
  );
}

class StudentPanel extends StatelessWidget {
  const StudentPanel({
    required this.child,
    this.color,
    this.padding,
    super.key,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Card(
    color: color ?? Colors.white,
    child: Padding(
      padding: padding ?? const EdgeInsets.all(AppTokens.space16),
      child: child,
    ),
  );
}

class StudentAction extends StatelessWidget {
  const StudentAction({
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = AppTokens.primary,
    super.key,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;

  @override
  Widget build(BuildContext context) => SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
      onPressed: onPressed,
      icon: Icon(icon),
      label: Text(label),
      style: FilledButton.styleFrom(
        minimumSize: const Size(
          AppTokens.minimumTouchTarget,
          AppTokens.studentButtonHeight,
        ),
        backgroundColor: color,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        textStyle: Theme.of(context).textTheme.labelLarge,
      ),
    ),
  );
}

class StudentEmptyState extends StatelessWidget {
  const StudentEmptyState({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) => StudentPanel(
    color: StudentColors.sky,
    child: Column(
      children: [
        const Icon(
          Icons.auto_stories_rounded,
          size: 44,
          color: AppTokens.primary,
        ),
        const SizedBox(height: AppTokens.space8),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge,
        ),
      ],
    ),
  );
}

class StudentProgressBar extends StatelessWidget {
  const StudentProgressBar({
    required this.label,
    required this.value,
    super.key,
  });

  final String label;
  final int value;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTokens.space4),
    child: Row(
      children: [
        Flexible(
          flex: 3,
          child: Text(label, style: Theme.of(context).textTheme.bodyMedium),
        ),
        Expanded(
          child: ClipRRect(
            borderRadius: BorderRadius.circular(99),
            child: LinearProgressIndicator(
              value: value.clamp(0, 100) / 100,
              minHeight: 14,
              backgroundColor: AppTokens.outline,
              color: value < 60 ? AppTokens.accent : AppTokens.primary,
            ),
          ),
        ),
        const SizedBox(width: AppTokens.space8),
        SizedBox(
          width: 44,
          child: Text(
            '$value%',
            textAlign: TextAlign.end,
            style: Theme.of(context).textTheme.labelLarge,
          ),
        ),
      ],
    ),
  );
}

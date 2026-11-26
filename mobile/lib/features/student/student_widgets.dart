import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

abstract final class StudentColors {
  static const mint = AppTokens.mint;
  static const sunshine = AppTokens.sunshine;
  static const peach = AppTokens.coralSoft;
  static const sky = AppTokens.sky;
}

/// Small uppercase label above a section title.
class StudentSectionLabel extends StatelessWidget {
  const StudentSectionLabel(this.label, {this.color = AppTokens.mutedText, super.key});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) => Text(
    label.toUpperCase(),
    style: TextStyle(
      fontSize: 10,
      height: 1.4,
      letterSpacing: 1.1,
      fontWeight: FontWeight.w900,
      color: color,
    ),
  );
}

class StudentPageHeading extends StatelessWidget {
  const StudentPageHeading({
    super.key,
    required this.title,
    required this.subtitle,
  });

  final String title;
  final String subtitle;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppTokens.space20),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: AppTokens.space8),
        Text(
          subtitle,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTokens.mutedText,
            height: 1.5,
          ),
        ),
      ],
    ),
  );
}

class StudentPanel extends StatelessWidget {
  const StudentPanel({
    super.key,
    required this.child,
    this.color,
    this.padding,
  });

  final Widget child;
  final Color? color;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: color ?? AppTokens.surface,
      borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
      border: Border.all(color: AppTokens.outline),
      boxShadow: AppTokens.cardShadow,
    ),
    // ListTile needs a Material ancestor to paint ink and its own background.
    child: Material(
      type: MaterialType.transparency,
      child: Padding(
        padding: padding ?? const EdgeInsets.all(AppTokens.space16),
        child: child,
      ),
    ),
  );
}

class StudentAction extends StatelessWidget {
  const StudentAction({
    super.key,
    required this.label,
    required this.icon,
    required this.onPressed,
    this.color = AppTokens.primary,
    this.iconColor,
    this.textColor,
    this.expanded = true,
  });

  final String label;
  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final Color? iconColor;
  final Color? textColor;
  final bool expanded;

  @override
  Widget build(BuildContext context) => FilledButton.icon(
    onPressed: onPressed,
    icon: Icon(icon, color: iconColor, size: 20),
    label: Text(
      label,
      style: Theme.of(context).textTheme.labelLarge?.copyWith(
        color: textColor ?? AppTokens.surface,
        fontWeight: FontWeight.w700,
        fontSize: 14,
      ),
    ),
    style: FilledButton.styleFrom(
      minimumSize: Size(
        expanded ? double.infinity : AppTokens.minimumTouchTarget,
        AppTokens.studentButtonHeight,
      ),
      backgroundColor: color,
      foregroundColor: textColor ?? AppTokens.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
      ),
      elevation: 0,
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space20,
        vertical: AppTokens.space12,
      ),
    ),
  );
}

class StudentEmptyState extends StatelessWidget {
  const StudentEmptyState({
    super.key,
    required this.message,
    this.icon = Icons.auto_stories_outlined,
    this.iconColor = AppTokens.primary,
    this.action,
  });

  final String message;
  final IconData icon;
  final Color iconColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) => StudentPanel(
    padding: const EdgeInsets.symmetric(
      horizontal: AppTokens.space20,
      vertical: AppTokens.space28,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 40, color: iconColor),
        const SizedBox(height: AppTokens.space12),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: AppTokens.mutedText,
            height: 1.5,
          ),
        ),
        if (action != null) ...[
          const SizedBox(height: AppTokens.space16),
          action!,
        ],
      ],
    ),
  );
}

/// Answer option drawn as a square tile, as in the question designs.
class StudentChoiceTile extends StatelessWidget {
  const StudentChoiceTile({
    super.key,
    required this.text,
    required this.selected,
    required this.correct,
    required this.onTap,
    this.enabled = true,
  });

  final String text;
  final bool selected;
  final bool correct;
  final VoidCallback? onTap;
  final bool enabled;

  @override
  Widget build(BuildContext context) {
    final background = !selected
        ? AppTokens.surface
        : correct
        ? StudentColors.mint
        : StudentColors.peach;
    final border = !selected
        ? AppTokens.outline
        : correct
        ? AppTokens.primary
        : AppTokens.coral;
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
        child: AnimatedContainer(
          duration: AppTokens.durationFast,
          height: 80,
          alignment: Alignment.center,
          decoration: BoxDecoration(
            color: background,
            borderRadius: BorderRadius.circular(AppTokens.radiusLarge),
            border: Border.all(color: border, width: selected ? 1.5 : 1),
          ),
          child: Text(
            text,
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
              fontWeight: FontWeight.w800,
              color: AppTokens.text,
            ),
          ),
        ),
      ),
    );
  }
}

class StudentProgressBar extends StatelessWidget {
  const StudentProgressBar({
    super.key,
    required this.label,
    required this.value,
    this.max = 100,
    this.height = 8,
    this.showPercent = true,
  });

  final String label;
  final int value;
  final int max;
  final double height;
  final bool showPercent;

  Color get _progressColor {
    if (value < 60) return AppTokens.coral;
    if (value < 80) return AppTokens.accent;
    return AppTokens.primary;
  }

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(vertical: AppTokens.space6),
    child: Row(
      children: [
        Expanded(
          flex: 3,
          child: Text(
            label,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: AppTokens.text,
            ),
          ),
        ),
        Expanded(
          flex: 7,
          child: ClipRRect(
            borderRadius: BorderRadius.circular(AppTokens.radiusRound),
            child: LinearProgressIndicator(
              value: (value / max).clamp(0.0, 1.0),
              minHeight: height,
              backgroundColor: const Color(0xFFE9EEEC),
              color: _progressColor,
            ),
          ),
        ),
        if (showPercent) ...[
          const SizedBox(width: AppTokens.space12),
          SizedBox(
            width: 32,
            child: Text(
              '$value',
              textAlign: TextAlign.end,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: AppTokens.text,
              ),
            ),
          ),
        ],
      ],
    ),
  );
}

class StudentChip extends StatelessWidget {
  const StudentChip({
    required this.label,
    this.icon,
    this.color = AppTokens.primary,
    this.backgroundColor,
    this.selected = false,
    this.onTap,
    super.key,
  });

  final String label;
  final IconData? icon;
  final Color color;
  final Color? backgroundColor;
  final bool selected;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(AppTokens.radiusRound),
    child: Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space14,
        vertical: AppTokens.space8,
      ),
      decoration: BoxDecoration(
        color:
            backgroundColor ??
            (selected ? AppTokens.text : AppTokens.surface),
        borderRadius: BorderRadius.circular(AppTokens.radiusRound),
        border: Border.all(
          color: selected ? AppTokens.text : AppTokens.outline,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 15, color: selected ? Colors.white : color),
            const SizedBox(width: AppTokens.space6),
          ],
          Text(
            label,
            style: Theme.of(context).textTheme.labelMedium?.copyWith(
              color: selected ? Colors.white : color,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    ),
  );
}

class StudentAvatar extends StatelessWidget {
  const StudentAvatar({
    required this.name,
    this.radius = 24,
    this.backgroundColor,
    super.key,
  });

  final String name;
  final double radius;
  final Color? backgroundColor;

  @override
  Widget build(BuildContext context) => CircleAvatar(
    radius: radius,
    backgroundColor: backgroundColor ?? AppTokens.sunshine,
    child: Text(
      name.characters.first.toUpperCase(),
      style: TextStyle(
        fontSize: radius * 0.6,
        fontWeight: FontWeight.w800,
        color: backgroundColor != null ? Colors.white : AppTokens.text,
      ),
    ),
  );
}

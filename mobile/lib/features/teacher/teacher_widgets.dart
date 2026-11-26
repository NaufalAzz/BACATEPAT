import 'package:flutter/material.dart';

import '../../core/theme/app_tokens.dart';

class TeacherPageHeading extends StatelessWidget {
  const TeacherPageHeading({
    required this.title,
    required this.subtitle,
    this.section,
    this.action,
    super.key,
  });

  final String title;
  final String subtitle;
  final String? section;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.only(bottom: AppTokens.space16),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (section != null) ...[
          Text(
            section!,
            style: const TextStyle(fontSize: 14, color: AppTokens.text),
          ),
          const SizedBox(height: AppTokens.space12),
        ],
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 22,
                      height: 1.3,
                      fontWeight: FontWeight.w500,
                      color: AppTokens.text,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    subtitle,
                    style: const TextStyle(
                      fontSize: 11.5,
                      color: AppTokens.mutedText,
                    ),
                  ),
                ],
              ),
            ),
            if (action != null) ...[const SizedBox(width: 12), action!],
          ],
        ),
      ],
    ),
  );
}

class TeacherPanel extends StatelessWidget {
  const TeacherPanel({
    required this.child,
    this.title,
    this.eyebrow,
    this.trailing,
    this.color,
    this.padding,
    super.key,
  });

  final Widget child;
  final String? title;
  final String? eyebrow;
  final Widget? trailing;
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
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (title != null) ...[
              if (eyebrow != null) ...[
                Text(
                  eyebrow!.toUpperCase(),
                  style: const TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w900,
                    color: AppTokens.mutedText,
                  ),
                ),
                const SizedBox(height: 2),
              ],
              Row(
                children: [
                  Expanded(
                    child: Text(
                      title!,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: AppTokens.text,
                      ),
                    ),
                  ),
                  ?trailing,
                ],
              ),
              const SizedBox(height: AppTokens.space12),
            ],
            child,
          ],
        ),
      ),
    ),
  );
}

/// Form card used by every create/edit screen.
class TeacherFormPanel extends StatelessWidget {
  const TeacherFormPanel({
    required this.sections,
    required this.saveLabel,
    required this.onSave,
    required this.onCancel,
    super.key,
  });

  final List<Widget> sections;
  final String saveLabel;
  final VoidCallback onSave;
  final VoidCallback onCancel;

  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: AppTokens.surface,
      borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
      border: Border.all(color: AppTokens.outline),
      boxShadow: AppTokens.cardShadow,
    ),
    clipBehavior: Clip.antiAlias,
    child: Column(
      children: [
        for (var i = 0; i < sections.length; i++) ...[
          Padding(
            padding: const EdgeInsets.all(AppTokens.space16),
            child: sections[i],
          ),
          if (i < sections.length - 1)
            const Divider(height: 1, color: AppTokens.outline),
        ],
        Container(
          width: double.infinity,
          color: const Color(0xFFF7F9F8),
          padding: const EdgeInsets.fromLTRB(16, 10, 12, 10),
          child: Wrap(
            alignment: WrapAlignment.end,
            crossAxisAlignment: WrapCrossAlignment.center,
            spacing: AppTokens.space8,
            runSpacing: AppTokens.space6,
            children: [
              TextButton(
                onPressed: onCancel,
                style: TextButton.styleFrom(
                  foregroundColor: AppTokens.text,
                  minimumSize: const Size(0, 40),
                ),
                child: const Text(
                  'Batal',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ),
              FilledButton(
                onPressed: onSave,
                style: FilledButton.styleFrom(
                  minimumSize: const Size(0, 40),
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  textStyle: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                child: Text(saveLabel),
              ),
            ],
          ),
        ),
      ],
    ),
  );
}

class TeacherFormSection extends StatelessWidget {
  const TeacherFormSection({
    required this.title,
    required this.children,
    this.description,
    super.key,
  });

  final String title;
  final String? description;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      Text(
        title,
        style: const TextStyle(
          fontSize: 17,
          fontWeight: FontWeight.w500,
          color: AppTokens.text,
        ),
      ),
      if (description != null) ...[
        const SizedBox(height: 2),
        Text(
          description!,
          style: const TextStyle(fontSize: 11.5, color: AppTokens.mutedText),
        ),
      ],
      const SizedBox(height: AppTokens.space16),
      for (var i = 0; i < children.length; i++) ...[
        if (i > 0) const SizedBox(height: AppTokens.space12),
        children[i],
      ],
    ],
  );
}

class MetricTile extends StatelessWidget {
  const MetricTile({
    required this.label,
    required this.value,
    required this.icon,
    this.tint = AppTokens.primary,
    this.subtitle,
    super.key,
  });

  final String label;
  final String value;
  final IconData icon;
  final Color tint;
  final String? subtitle;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      final iconTile = Container(
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: tint.withValues(alpha: 0.14),
          borderRadius: BorderRadius.circular(AppTokens.radiusMedium),
        ),
        child: Icon(icon, color: tint, size: 24),
      );
      final texts = Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label.toUpperCase(),
            style: const TextStyle(
              fontSize: 9.5,
              letterSpacing: 0.8,
              color: AppTokens.mutedText,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: const TextStyle(
              fontSize: 26,
              height: 1.2,
              fontWeight: FontWeight.w700,
              color: AppTokens.text,
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 2),
            Text(
              subtitle!,
              style: const TextStyle(
                fontSize: 11.5,
                color: AppTokens.mutedText,
              ),
            ),
          ],
        ],
      );
      return Container(
        decoration: BoxDecoration(
          color: AppTokens.surface,
          borderRadius: BorderRadius.circular(AppTokens.radiusXLarge),
          border: Border.all(color: AppTokens.outline, width: 1),
          boxShadow: [
            BoxShadow(
              color: AppTokens.text.withValues(alpha: 0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        padding: const EdgeInsets.all(AppTokens.space14),
        // Narrow tiles stack so long labels never force a cramped column.
        child: constraints.maxWidth < 240
            ? Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  iconTile,
                  const SizedBox(height: AppTokens.space12),
                  texts,
                ],
              )
            : Row(
                children: [
                  iconTile,
                  const SizedBox(width: AppTokens.space16),
                  Expanded(child: texts),
                ],
              ),
      );
    },
  );
}

class StatusBadge extends StatelessWidget {
  const StatusBadge({
    required this.label,
    this.variant = StatusVariant.neutral,
    super.key,
  });

  final String label;
  final StatusVariant variant;

  @override
  Widget build(BuildContext context) {
    Color bgColor;
    Color fgColor;

    switch (variant) {
      case StatusVariant.success:
        bgColor = AppTokens.success.withValues(alpha: 0.12);
        fgColor = AppTokens.success;
        break;
      case StatusVariant.warning:
        bgColor = AppTokens.warning.withValues(alpha: 0.12);
        fgColor = AppTokens.warning;
        break;
      case StatusVariant.error:
        bgColor = AppTokens.error.withValues(alpha: 0.12);
        fgColor = AppTokens.error;
        break;
      case StatusVariant.info:
        bgColor = AppTokens.secondary.withValues(alpha: 0.12);
        fgColor = AppTokens.secondary;
        break;
      case StatusVariant.active:
        bgColor = AppTokens.primary.withValues(alpha: 0.12);
        fgColor = AppTokens.primary;
        break;
      case StatusVariant.pending:
        bgColor = AppTokens.accent.withValues(alpha: 0.12);
        fgColor = AppTokens.accent;
        break;
      default:
        bgColor = AppTokens.outline.withValues(alpha: 0.2);
        fgColor = AppTokens.mutedText;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppTokens.space12,
        vertical: AppTokens.space6,
      ),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(AppTokens.radiusRound),
        border: Border.all(color: fgColor.withValues(alpha: 0.3), width: 1),
      ),
      child: Text(
        label,
        style: Theme.of(context).textTheme.labelMedium
            ?.copyWith(color: fgColor, fontWeight: FontWeight.w700),
      ),
    );
  }
}

enum StatusVariant { neutral, success, warning, error, info, active, pending }

class EmptyState extends StatelessWidget {
  const EmptyState({
    required this.message,
    this.icon = Icons.inbox_outlined,
    this.iconColor = AppTokens.mutedText,
    this.action,
    super.key,
  });

  final String message;
  final IconData icon;
  final Color iconColor;
  final Widget? action;

  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(
      horizontal: AppTokens.space24,
      vertical: AppTokens.space32,
    ),
    child: Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 56, color: iconColor),
        const SizedBox(height: AppTokens.space16),
        Text(
          message,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.bodyLarge
              ?.copyWith(color: AppTokens.text, height: 1.5),
        ),
        if (action != null) ...[
          const SizedBox(height: AppTokens.space20),
          action!,
        ],
      ],
    ),
  );
}

class TeacherChip extends StatelessWidget {
  const TeacherChip({
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
  Widget build(BuildContext context) {
    final bgColor =
        backgroundColor ?? color.withValues(alpha: selected ? 0.15 : 0.08);
    final fgColor = selected ? color : color.withValues(alpha: 0.8);

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(AppTokens.radiusRound),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: AppTokens.space16,
          vertical: AppTokens.space8,
        ),
        decoration: BoxDecoration(
          color: bgColor,
          borderRadius: BorderRadius.circular(AppTokens.radiusRound),
          border: Border.all(
            color: selected ? color : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: fgColor),
              const SizedBox(width: AppTokens.space8),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelMedium
                  ?.copyWith(color: fgColor, fontWeight: FontWeight.w700),
            ),
          ],
        ),
      ),
    );
  }
}

class TeacherAvatar extends StatelessWidget {
  const TeacherAvatar({
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
    backgroundColor:
        backgroundColor ?? AppTokens.secondary.withValues(alpha: 0.12),
    child: Text(
      name.characters.first.toUpperCase(),
      style: TextStyle(
        fontSize: radius * 0.65,
        fontWeight: FontWeight.w800,
        color: backgroundColor != null ? Colors.white : AppTokens.secondary,
      ),
    ),
  );
}

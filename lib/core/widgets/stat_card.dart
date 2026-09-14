import 'package:flutter/material.dart';
import '../theme/app_colors.dart';
import 'explain_tooltip.dart'; // Added import for ExplainTooltip

class StatCard extends StatelessWidget {
  final String title;
  final String value;
  final IconData? icon;
  final Color? iconColor;
  final Color? iconBgColor;
  final String? trendText;
  final bool? isPositiveTrend;
  final Color? valueColor;
  final VoidCallback? onTap;
  final String? tooltipMessage; // Added tooltip parameter

  const StatCard({
    super.key,
    required this.title,
    required this.value,
    this.icon,
    this.iconColor,
    this.iconBgColor,
    this.trendText,
    this.isPositiveTrend,
    this.valueColor,
    this.onTap,
    this.tooltipMessage,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    Widget card = MouseRegion(
      cursor: SystemMouseCursors.click,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: context.border, width: 1),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.01),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top row: Title and Icon
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Text(
                      title,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        fontWeight: FontWeight.w500,
                        color: context.textSecondary,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (icon != null)
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: iconBgColor ?? Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        icon,
                        color: iconColor,
                        size: 18,
                      ),
                    ),
                ],
              ),
              const SizedBox(height: 8),
              // Middle row: Large Value
              Text(
                value,
                style: theme.textTheme.displaySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 22,
                  letterSpacing: -0.5,
                  color: valueColor ?? context.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              // Bottom row: Trend indicator if available
              if (trendText != null)
                Row(
                  children: [
                    if (isPositiveTrend != null)
                      Icon(
                        isPositiveTrend! ? Icons.arrow_upward : Icons.arrow_downward,
                        size: 12,
                        color: isPositiveTrend! ? context.success : context.error,
                      ),
                    if (isPositiveTrend != null) const SizedBox(width: 2),
                    Expanded(
                      child: Text(
                        trendText!,
                        style: theme.textTheme.labelMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          fontSize: 10,
                          color: isPositiveTrend == null
                              ? context.textMuted
                              : (isPositiveTrend! ? context.success : context.error),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ],
                )
              else
                const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );

    if (tooltipMessage != null) {
      return ExplainTooltip(
        message: tooltipMessage!,
        child: card,
      );
    }

    return card;
  }
}

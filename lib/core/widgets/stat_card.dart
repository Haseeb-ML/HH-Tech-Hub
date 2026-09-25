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
          padding: EdgeInsets.all(MediaQuery.of(context).size.width < 600 ? 12 : 16),
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
              FittedBox(
                fit: BoxFit.scaleDown,
                alignment: Alignment.centerLeft,
                child: Text(
                  value,
                  style: theme.textTheme.displaySmall?.copyWith(
                    fontWeight: FontWeight.w700,
                    fontSize: 22,
                    letterSpacing: -0.5,
                    color: valueColor ?? context.textPrimary,
                  ),
                  maxLines: 1,
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

    String generateAutoTooltip(String t) {
      final lower = t.toLowerCase();
      if (lower.contains('active project')) return 'The number of projects currently in progress.';
      if (lower.contains('total project')) return 'The total number of projects created in the system.';
      if (lower.contains('completed task')) return 'Tasks that have been successfully finished.';
      if (lower.contains('pending task') || lower.contains('in progress')) return 'Tasks that are currently being worked on.';
      if (lower.contains('total task')) return 'All tasks across all projects.';
      if (lower.contains('income')) return 'Total revenue generated.';
      if (lower.contains('expense')) return 'Total expenses incurred.';
      if (lower.contains('balance')) return 'The current net balance available.';
      if (lower.contains('loan')) return 'Money lent or borrowed that needs repayment.';
      if (lower.contains('asset')) return 'Valuable items owned by the company.';
      if (lower.contains('inventory')) return 'Items currently in stock.';
      if (lower.contains('sales') || lower.contains('invoice')) return 'Total sales invoices generated.';
      if (lower.contains('purchase')) return 'Total purchase orders created.';
      if (lower.contains('employee') || lower.contains('staff')) return 'Total number of team members.';
      if (lower.contains('attendance')) return 'Daily attendance record of employees.';
      if (lower.contains('salary')) return 'Total salaries paid to employees.';
      if (lower.contains('advance')) return 'Advances given to employees.';
      return 'Shows the current statistics for $t.';
    }

    final message = tooltipMessage ?? generateAutoTooltip(title);

    return ExplainTooltip(
      message: message,
      child: card,
    );
  }
}

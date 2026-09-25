import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';

class AccessDeniedScreen extends StatelessWidget {
  final String? attemptedPath;

  const AccessDeniedScreen({super.key, this.attemptedPath});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isMobile = MediaQuery.of(context).size.width < 600;

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Center(
        child: SingleChildScrollView(
          padding: EdgeInsets.all(isMobile ? 20 : 32),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 540),
            child: GlassCard(
              child: Padding(
                padding: EdgeInsets.all(isMobile ? 24 : 40),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Shield Icon with Red Accent
                    Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: context.error.withValues(alpha: 0.12),
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: context.error.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: Icon(
                        Icons.security_outlined,
                        size: 48,
                        color: context.error,
                      ),
                    ),
                    const SizedBox(height: 24),

                    // Title
                    Text(
                      'Access Restricted',
                      style: theme.textTheme.headlineSmall?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: context.textPrimary,
                        letterSpacing: -0.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),

                    // Explanation
                    Text(
                      'You do not have permission to view or manage this module. Access to this resource is restricted by role-based security policies.',
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 13.5,
                        height: 1.5,
                      ),
                      textAlign: TextAlign.center,
                    ),

                    if (attemptedPath != null && attemptedPath!.isNotEmpty) ...[
                      const SizedBox(height: 18),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                        decoration: BoxDecoration(
                          color: context.scaffoldBg,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: context.border),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(Icons.link_off_rounded, size: 16, color: context.textMuted),
                            const SizedBox(width: 8),
                            Flexible(
                              child: Text(
                                attemptedPath!,
                                style: TextStyle(
                                  color: context.textMuted,
                                  fontSize: 12,
                                  fontFamily: 'monospace',
                                ),
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],

                    const SizedBox(height: 32),

                    // Actions
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        ElevatedButton.icon(
                          onPressed: () {
                            if (context.canPop()) {
                              context.pop();
                            } else {
                              context.go('/dashboard');
                            }
                          },
                          icon: const Icon(Icons.arrow_back_rounded, size: 18),
                          label: const Text('Return to Safety'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: context.primaryColor,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Need access? Please request authorization from your Super Administrator.',
                      style: TextStyle(
                        color: context.textMuted,
                        fontSize: 11.5,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

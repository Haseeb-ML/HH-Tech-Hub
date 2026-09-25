import 'package:flutter/material.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/administration/shared/widgets/admin_sub_nav.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class BackupScreen extends ConsumerWidget {
  const BackupScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(adminProvider);
    final theme = Theme.of(context);

    // Calculate metrics
    final totalBackups = state.backups.length;
    final lastBackupDate = state.backups.isNotEmpty ? state.backups.last.date : 'N/A';

    return Scaffold(
      backgroundColor: context.scaffoldBg,
      body: Column(
        children: [
          // Sub Navigation Tab Bar
          const AdminSubNav(activeRoute: '/administration/backup'),

          // Screen Content
          Expanded(
            child: LayoutBuilder(
              builder: (context, screenConstraints) {
                final isMobile = screenConstraints.maxWidth < 650;
                final pagePadding = isMobile ? 16.0 : 24.0;

                Widget importBtn = ElevatedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final successColor = context.success;
                          final errorColor = context.error;
                          try {
                            await ref.read(adminProvider.notifier).importBackup();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(tr('Database imported and reloaded successfully.')),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: successColor,
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('${tr("Import failed")}: $e'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: errorColor,
                              ),
                            );
                          }
                        },
                  icon: const Icon(Icons.file_upload, size: 18),
                  label: Text(tr('Import Backup')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.info,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                  ),
                );

                Widget backupBtn = ElevatedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final successColor = context.success;
                          await ref.read(adminProvider.notifier).triggerBackup();
                          messenger.showSnackBar(
                            SnackBar(
                              content: Text(tr('Local database backup generated successfully.')),
                              behavior: SnackBarBehavior.floating,
                              backgroundColor: successColor,
                              action: SnackBarAction(
                                label: tr('OPEN FOLDER'),
                                textColor: Colors.white,
                                onPressed: () {
                                  ref.read(adminProvider.notifier).openBackupsFolder();
                                },
                              ),
                            ),
                          );
                        },
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.backup, size: 18),
                  label: Text(tr('Backup Local DB')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.primaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                  ),
                );

                Widget deleteBtn = ElevatedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final successColor = context.success;
                          final errorColor = context.error;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: context.cardBg,
                              title: Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, color: errorColor),
                                  const SizedBox(width: 8),
                                  Text(
                                    tr('Warning'),
                                    style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              content: Text(
                                tr('Are you absolutely sure you want to delete all database data? This action is permanent and cannot be undone.'),
                                style: TextStyle(color: context.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: errorColor,
                                    foregroundColor: Colors.white,
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                                  ),
                                  child: Text(tr('Delete All')),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await ref.read(adminProvider.notifier).clearAllDatabaseData();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(tr('All database data deleted successfully.')),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: successColor,
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('${tr("Failed to delete data")}: $e'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: errorColor,
                                ),
                              );
                            }
                          }
                        },
                  icon: state.isLoading
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.delete_forever, size: 18),
                  label: Text(tr('Delete All Data')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.error,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                  ),
                );

                final seedDemoBtn = OutlinedButton.icon(
                  onPressed: state.isLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final successColor = context.success;
                          final errorColor = context.error;
                          final confirm = await showDialog<bool>(
                            context: context,
                            builder: (context) => AlertDialog(
                              backgroundColor: context.cardBg,
                              title: Row(
                                children: [
                                  Icon(Icons.download_done, color: context.primaryColor),
                                  const SizedBox(width: 8),
                                  Text(tr('Load Demo Data'), style: TextStyle(color: context.textPrimary)),
                                ],
                              ),
                              content: Text(
                                tr('This will populate sample employees, clients, bank accounts, and projects for testing. Proceed?'),
                                style: TextStyle(color: context.textSecondary),
                              ),
                              actions: [
                                TextButton(
                                  onPressed: () => Navigator.pop(context, false),
                                  child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                                ),
                                ElevatedButton(
                                  onPressed: () => Navigator.pop(context, true),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.primaryColor,
                                    foregroundColor: Colors.white,
                                  ),
                                  child: Text(tr('Load Demo Data')),
                                ),
                              ],
                            ),
                          );

                          if (confirm == true) {
                            try {
                              await ref.read(adminProvider.notifier).seedInitialDemoData();
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text(tr('Demo data loaded successfully! All modules are now populated.')),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: successColor,
                                ),
                              );
                            } catch (e) {
                              messenger.showSnackBar(
                                SnackBar(
                                  content: Text('Failed to load demo data: $e'),
                                  behavior: SnackBarBehavior.floating,
                                  backgroundColor: errorColor,
                                ),
                              );
                            }
                          }
                        },
                  icon: const Icon(Icons.download_done, size: 18),
                  label: Text(tr('Load Demo Data')),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: context.primaryColor,
                    side: BorderSide(color: context.primaryColor),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                  ),
                );

                return SingleChildScrollView(
                  padding: EdgeInsets.all(pagePadding),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Title
                      Text(
                        'Database Backup & Restore',
                        style: (isMobile ? theme.textTheme.headlineSmall : theme.textTheme.displaySmall)?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: context.textPrimary,
                          letterSpacing: -0.5,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Generate compressed local database files or restore system state backups.',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: context.textSecondary,
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Action buttons & Danger Zone
                      if (isMobile) ...[
                        Row(
                          children: [
                            Expanded(child: importBtn),
                            const SizedBox(width: 8),
                            Expanded(child: backupBtn),
                          ],
                        ),
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: seedDemoBtn,
                        ),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: context.error.withValues(alpha: 0.07),
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: context.error.withValues(alpha: 0.25)),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 15, color: context.error),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      tr('Warning: Irreversible action. Wipes all database data.'),
                                      style: TextStyle(
                                        color: context.error,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              SizedBox(
                                width: double.infinity,
                                child: deleteBtn,
                              ),
                            ],
                          ),
                        ),
                      ] else ...[
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Row(
                              children: [
                                importBtn,
                                const SizedBox(width: 8),
                                backupBtn,
                                const SizedBox(width: 8),
                                seedDemoBtn,
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                              decoration: BoxDecoration(
                                color: context.error.withValues(alpha: 0.06),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: context.error.withValues(alpha: 0.2)),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(Icons.warning_amber_rounded, size: 15, color: context.error),
                                  const SizedBox(width: 6),
                                  Text(
                                    tr('Warning: Irreversible!'),
                                    style: TextStyle(
                                      color: context.error,
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  const SizedBox(width: 10),
                                  deleteBtn,
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                      const SizedBox(height: 24),

                      // Metrics cards (2 cards per row on both mobile and desktop)
                      GridView.count(
                        crossAxisCount: isMobile ? 1 : 2,
                        crossAxisSpacing: isMobile ? 10 : 14,
                        mainAxisSpacing: isMobile ? 10 : 14,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        childAspectRatio: isMobile ? 2.5 : 2.5,
                        children: [
                          StatCard(
                            title: tr('Last Completed Backup'),
                            tooltipMessage: "Detailed statistics and information regarding ${tr('Last Completed Backup')}.",
                            value: lastBackupDate.split(' ')[0],
                            icon: Icons.access_time_outlined,
                            iconColor: context.success,
                            iconBgColor: context.successLight,
                            trendText: tr('Previous backup execution'),
                          ),
                          StatCard(
                            title: 'Total Backups Available',
                            tooltipMessage: 'Detailed statistics and information regarding Total Backups Available.',
                            value: '$totalBackups',
                            icon: Icons.storage_outlined,
                            iconColor: context.info,
                            iconBgColor: context.infoLight,
                            trendText: tr('Stored local archives'),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                  // Backups list card
                  GlassCard(
                    title: tr('System Database Backup History'),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: SizedBox(
                        width: double.infinity,
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: DataTable(
                            headingRowColor: WidgetStateProperty.all(context.scaffoldBg),
                            columns: [
                              DataColumn(label: Text('Filename', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('File Size', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Backup Date', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text(tr('Status'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Created By', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                              DataColumn(label: Text('Actions', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                            ],
                            rows: state.backups.reversed.map((backup) {
                              return DataRow(
                                cells: [
                                  DataCell(
                                    SizedBox(
                                      width: 240,
                                      child: Row(
                                        children: [
                                          Icon(Icons.inventory_2_outlined, size: 16, color: context.primaryColor),
                                          const SizedBox(width: 8),
                                          Expanded(
                                            child: Text(
                                              backup.filename,
                                              style: TextStyle(color: context.textPrimary, fontSize: 13, fontWeight: FontWeight.bold),
                                              overflow: TextOverflow.ellipsis,
                                              maxLines: 1,
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(backup.size, style: TextStyle(color: context.textSecondary, fontSize: 13))),
                                  DataCell(Text(backup.date, style: TextStyle(color: context.textSecondary, fontSize: 13))),
                                  DataCell(
                                    Container(
                                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                      decoration: BoxDecoration(
                                        color: context.successLight,
                                        borderRadius: BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        backup.status,
                                        style: TextStyle(color: context.success, fontSize: 10, fontWeight: FontWeight.bold),
                                      ),
                                    ),
                                  ),
                                  DataCell(Text(backup.createdBy, style: TextStyle(color: context.textSecondary, fontSize: 13))),
                                  DataCell(
                                    Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        TextButton.icon(
                                          onPressed: () async {
                                            final messenger = ScaffoldMessenger.of(context);
                                            final successColor = context.success;
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                backgroundColor: context.cardBg,
                                                title: Text('Restore System Database', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
                                                content: Text('${tr("Are you sure you want to restore the system state from")} "${backup.filename}"? ${tr("This will rollback recent transactions.")}', style: TextStyle(color: context.textSecondary)),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: Colors.white),
                                                    child: const Text('Restore'),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await ref.read(adminProvider.notifier).triggerRestore(backup.filename);
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text('${tr("System restored from")} "${backup.filename}" ${tr("successfully.")}'),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: successColor,
                                                ),
                                              );
                                            }
                                          },
                                          icon: const Icon(Icons.settings_backup_restore, size: 14),
                                          label: const Text('Restore', style: TextStyle(fontSize: 12)),
                                          style: TextButton.styleFrom(foregroundColor: context.primaryColor),
                                        ),
                                        const SizedBox(width: 4),
                                        IconButton(
                                          tooltip: 'Export / Download Backup',
                                          icon: Icon(Icons.download, size: 16, color: context.info),
                                          onPressed: () async {
                                            final messenger = ScaffoldMessenger.of(context);
                                            final successColor = context.success;
                                            final errorColor = context.error;
                                            try {
                                              await ref.read(adminProvider.notifier).exportBackupFile(backup.filename);
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(tr('Backup file exported successfully.')),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: successColor,
                                                ),
                                              );
                                            } catch (e) {
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text('${tr("Export failed")}: $e'),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: errorColor,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                        IconButton(
                                          tooltip: 'Delete Backup',
                                          icon: Icon(Icons.delete_outline, size: 16, color: context.error),
                                          onPressed: () async {
                                            final messenger = ScaffoldMessenger.of(context);
                                            final successColor = context.success;
                                            final confirm = await showDialog<bool>(
                                              context: context,
                                              builder: (context) => AlertDialog(
                                                backgroundColor: context.cardBg,
                                                title: Text('Delete Backup File', style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
                                                content: Text('Are you sure you want to delete backup file "${backup.filename}"?', style: TextStyle(color: context.textSecondary)),
                                                actions: [
                                                  TextButton(
                                                    onPressed: () => Navigator.pop(context, false),
                                                    child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                                                  ),
                                                  ElevatedButton(
                                                    onPressed: () => Navigator.pop(context, true),
                                                    style: ElevatedButton.styleFrom(backgroundColor: context.error, foregroundColor: Colors.white),
                                                    child: Text(tr('Delete')),
                                                  ),
                                                ],
                                              ),
                                            );
                                            if (confirm == true) {
                                              await ref.read(adminProvider.notifier).deleteBackupFile(backup.id, backup.filename);
                                              messenger.showSnackBar(
                                                SnackBar(
                                                  content: Text(tr('Backup file deleted successfully.')),
                                                  behavior: SnackBarBehavior.floating,
                                                  backgroundColor: successColor,
                                                ),
                                              );
                                            }
                                          },
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    ],
  ),
);
  }
}

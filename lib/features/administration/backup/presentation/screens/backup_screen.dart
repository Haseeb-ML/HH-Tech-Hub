import 'dart:io';
import 'package:flutter/material.dart';
import 'package:path_provider/path_provider.dart';
import 'package:software_house_erp/core/localization/app_localization.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';
import 'package:software_house_erp/core/widgets/stat_card.dart';
import 'package:software_house_erp/core/widgets/glass_card.dart';
import 'package:software_house_erp/features/administration/shared/widgets/admin_sub_nav.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class BackupScreen extends ConsumerStatefulWidget {
  const BackupScreen({super.key});

  @override
  ConsumerState<BackupScreen> createState() => _BackupScreenState();
}

class _BackupScreenState extends ConsumerState<BackupScreen> {
  bool _isImporting = false;
  bool _isBackingUp = false;
  bool _isSeedingDemo = false;
  bool _isDeleting = false;

  @override
  Widget build(BuildContext context) {
    final tr = ref.watch(translationProvider);
    final state = ref.watch(adminProvider);
    final theme = Theme.of(context);

    final isAnyActionLoading = state.isLoading || _isImporting || _isBackingUp || _isSeedingDemo || _isDeleting;

    // Calculate metrics
    final totalBackups = state.backups.length;
    final lastBackupDate = state.backups.isNotEmpty ? state.backups.first.date : 'N/A';

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
                  onPressed: isAnyActionLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final successColor = context.success;
                          final errorColor = context.error;
                          setState(() => _isImporting = true);
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
                          } finally {
                            if (mounted) setState(() => _isImporting = false);
                          }
                        },
                  icon: _isImporting
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.file_upload, size: 18),
                  label: Text(tr('Import Backup')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: context.info,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                  ),
                );

                Widget backupBtn = ElevatedButton.icon(
                  onPressed: isAnyActionLoading
                      ? null
                      : () async {
                          setState(() => _isBackingUp = true);
                          try {
                            await _showBackupDestinationModal(
                              context: context,
                              ref: ref,
                            );
                          } finally {
                            if (mounted) setState(() => _isBackingUp = false);
                          }
                        },
                  icon: _isBackingUp
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

                Widget demoDataBtn = ElevatedButton.icon(
                  onPressed: isAnyActionLoading
                      ? null
                      : () async {
                          final messenger = ScaffoldMessenger.of(context);
                          final successColor = context.success;
                          final errorColor = context.error;
                          setState(() => _isSeedingDemo = true);
                          try {
                            await ref.read(adminProvider.notifier).seedInitialDemoData();
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text(tr('All module demo testing data loaded successfully! / تمام ماڈیولز کا ڈیٹا لوڈ ہو گیا')),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: successColor,
                              ),
                            );
                          } catch (e) {
                            messenger.showSnackBar(
                              SnackBar(
                                content: Text('Load demo failed: $e'),
                                behavior: SnackBarBehavior.floating,
                                backgroundColor: errorColor,
                              ),
                            );
                          } finally {
                            if (mounted) setState(() => _isSeedingDemo = false);
                          }
                        },
                  icon: _isSeedingDemo
                      ? const SizedBox(
                          width: 14,
                          height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Icon(Icons.dataset_linked_outlined, size: 18),
                  label: Text(tr('Load Demo Data (Testing)')),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.amber.shade800,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    padding: EdgeInsets.symmetric(horizontal: isMobile ? 12 : 16, vertical: 12),
                  ),
                );

                Widget deleteBtn = ElevatedButton.icon(
                  onPressed: isAnyActionLoading
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
                            setState(() => _isDeleting = true);
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
                            } finally {
                              if (mounted) setState(() => _isDeleting = false);
                            }
                          }
                        },
                  icon: _isDeleting
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
                            Expanded(child: demoDataBtn),
                            const SizedBox(width: 8),
                            Expanded(child: importBtn),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Row(
                          children: [
                            Expanded(child: backupBtn),
                          ],
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
                                demoDataBtn,
                                const SizedBox(width: 8),
                                importBtn,
                                const SizedBox(width: 8),
                                backupBtn,
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
                      child: state.backups.isEmpty
                          ? Center(
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 36),
                                child: Column(
                                  children: [
                                    Icon(
                                      Icons.inventory_2_outlined,
                                      size: 48,
                                      color: context.textSecondary.withValues(alpha: 0.5),
                                    ),
                                    const SizedBox(height: 12),
                                    Text(
                                      tr('No backups found yet.'),
                                      style: TextStyle(
                                        color: context.textSecondary,
                                        fontSize: 15,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      tr('Click "Backup Local DB" to create your first database archive.'),
                                      style: TextStyle(
                                        color: context.textSecondary.withValues(alpha: 0.8),
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            )
                          : SizedBox(
                              width: double.infinity,
                              child: SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: DataTable(
                                  headingRowColor: WidgetStateProperty.all(context.scaffoldBg),
                                  columns: [
                                    DataColumn(label: Text(tr('Filename'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text(tr('File Size'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text(tr('Backup Date'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text(tr('Status'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text(tr('Created By'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                    DataColumn(label: Text(tr('Actions'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold))),
                                  ],
                                  rows: state.backups.map((backup) {
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
                                              tr(backup.status),
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
                                                  final errorColor = context.error;
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      backgroundColor: context.cardBg,
                                                      title: Text(tr('Restore System Database'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
                                                      content: Text('${tr("Are you sure you want to restore the system state from")} "${backup.filename}"? ${tr("This will rollback recent transactions.")}', style: TextStyle(color: context.textSecondary)),
                                                      actions: [
                                                        TextButton(
                                                          onPressed: () => Navigator.pop(context, false),
                                                          child: Text(tr('Cancel'), style: TextStyle(color: context.textSecondary)),
                                                        ),
                                                        ElevatedButton(
                                                          onPressed: () => Navigator.pop(context, true),
                                                          style: ElevatedButton.styleFrom(backgroundColor: context.primaryColor, foregroundColor: Colors.white),
                                                          child: Text(tr('Restore')),
                                                        ),
                                                      ],
                                                    ),
                                                  );
                                                  if (confirm == true) {
                                                    try {
                                                      await ref.read(adminProvider.notifier).triggerRestore(backup.filename);
                                                      messenger.showSnackBar(
                                                        SnackBar(
                                                          content: Text('${tr("System restored from")} "${backup.filename}" ${tr("successfully.")}'),
                                                          behavior: SnackBarBehavior.floating,
                                                          backgroundColor: successColor,
                                                        ),
                                                      );
                                                    } catch (e) {
                                                      messenger.showSnackBar(
                                                        SnackBar(
                                                          content: Text('${tr("Restore failed")}: $e'),
                                                          behavior: SnackBarBehavior.floating,
                                                          backgroundColor: errorColor,
                                                        ),
                                                      );
                                                    }
                                                  }
                                                },
                                                icon: const Icon(Icons.settings_backup_restore, size: 14),
                                                label: Text(tr('Restore'), style: const TextStyle(fontSize: 12)),
                                                style: TextButton.styleFrom(foregroundColor: context.primaryColor),
                                              ),
                                              const SizedBox(width: 4),
                                              IconButton(
                                                tooltip: tr('Export / Download Backup'),
                                                icon: Icon(Icons.download, size: 16, color: context.info),
                                                onPressed: () => _showBackupDestinationModal(
                                                  context: context,
                                                  ref: ref,
                                                  existingFilename: backup.filename,
                                                ),
                                              ),
                                              IconButton(
                                                tooltip: tr('Delete Backup'),
                                                icon: Icon(Icons.delete_outline, size: 16, color: context.error),
                                                onPressed: () async {
                                                  final messenger = ScaffoldMessenger.of(context);
                                                  final successColor = context.success;
                                                  final errorColor = context.error;
                                                  final confirm = await showDialog<bool>(
                                                    context: context,
                                                    builder: (context) => AlertDialog(
                                                      backgroundColor: context.cardBg,
                                                      title: Text(tr('Delete Backup File'), style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
                                                      content: Text('${tr("Are you sure you want to delete backup file")} "${backup.filename}"?', style: TextStyle(color: context.textSecondary)),
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
                                                    try {
                                                      await ref.read(adminProvider.notifier).deleteBackupFile(backup.id, backup.filename);
                                                      messenger.showSnackBar(
                                                        SnackBar(
                                                          content: Text(tr('Backup file deleted successfully.')),
                                                          behavior: SnackBarBehavior.floating,
                                                          backgroundColor: successColor,
                                                        ),
                                                      );
                                                    } catch (e) {
                                                      messenger.showSnackBar(
                                                        SnackBar(
                                                          content: Text('${tr("Delete backup failed")}: $e'),
                                                          behavior: SnackBarBehavior.floating,
                                                          backgroundColor: errorColor,
                                                        ),
                                                      );
                                                    }
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

  Future<void> _showBackupDestinationModal({
    required BuildContext context,
    required WidgetRef ref,
    String? existingFilename,
  }) async {
    final tr = ref.read(translationProvider);
    final isExisting = existingFilename != null;
    final screenWidth = MediaQuery.of(context).size.width;
    final isMobile = (Platform.isAndroid || Platform.isIOS) || screenWidth < 650;

    // Resolve storage location path
    String storageLocation = '';
    try {
      if (isMobile) {
        if (Platform.isAndroid) {
          storageLocation = '/storage/emulated/0/Download';
        } else if (Platform.isIOS) {
          final dir = await getApplicationDocumentsDirectory();
          storageLocation = dir.path;
        } else {
          final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
          storageLocation = dir.path;
        }
      } else {
        if (Platform.isWindows) {
          final userProfile = Platform.environment['USERPROFILE'];
          if (userProfile != null && userProfile.isNotEmpty) {
            storageLocation = '$userProfile\\Downloads';
          }
        }
        if (storageLocation.isEmpty) {
          final dir = await getDownloadsDirectory() ?? await getApplicationDocumentsDirectory();
          storageLocation = dir.path;
        }
      }
    } catch (_) {
      storageLocation = isMobile ? '/storage/emulated/0/Download' : 'Downloads';
    }

    if (!context.mounted) return;

    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (modalContext) {
        return Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 620),
            child: Container(
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
                border: Border.all(color: context.border),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.15),
                    blurRadius: 20,
                    offset: const Offset(0, -4),
                  ),
                ],
              ),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
              child: SafeArea(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        decoration: BoxDecoration(
                          color: context.textSecondary.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(2),
                        ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: context.primaryColor.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Icon(
                            isMobile ? Icons.smartphone_rounded : Icons.desktop_windows_rounded,
                            color: context.primaryColor,
                            size: 24,
                          ),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                isMobile
                                    ? (isExisting ? tr('Export Backup') : tr('Backup Local Database'))
                                    : (isExisting ? tr('Export Backup to PC') : tr('Desktop Personal Storage')),
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                  color: context.textPrimary,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                isMobile
                                    ? tr('Choose where you want to save the backup file')
                                    : tr('Save SQLite database directly to your personal computer storage'),
                                style: TextStyle(
                                  fontSize: 13,
                                  color: context.textSecondary,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: context.textSecondary, size: 20),
                          onPressed: () => Navigator.pop(modalContext),
                        ),
                      ],
                    ),
                    const SizedBox(height: 20),

                    if (isMobile) ...[
                      // MOBILE OPTION 1: Mobile Storage (with location details)
                      InkWell(
                        onTap: () async {
                          Navigator.pop(modalContext);
                          await _handleBackupAction(
                            context: context,
                            ref: ref,
                            existingFilename: existingFilename,
                            toGoogleDrive: false,
                            isMobile: true,
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.scaffoldBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: context.info.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.phone_android_rounded, color: context.info, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr('Mobile Storage'),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tr('Save SQLite database directly to Phone Storage / Downloads'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.textSecondary),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: context.info.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: context.info.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.folder_outlined, size: 14, color: context.info),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        '${tr("Location")}: $storageLocation',
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontFamily: 'monospace',
                                          fontWeight: FontWeight.w500,
                                          color: context.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),

                      // MOBILE OPTION 2: Google Drive
                      InkWell(
                        onTap: () async {
                          Navigator.pop(modalContext);
                          await _handleBackupAction(
                            context: context,
                            ref: ref,
                            existingFilename: existingFilename,
                            toGoogleDrive: true,
                            isMobile: true,
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: context.scaffoldBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.border),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: context.success.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.add_to_drive_rounded, color: context.success, size: 24),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr('Google Drive'),
                                          style: TextStyle(
                                            fontSize: 15,
                                            fontWeight: FontWeight.w600,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tr('Sync & upload SQLite database backup to Google Drive'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.textSecondary),
                                ],
                              ),
                              const SizedBox(height: 10),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
                                decoration: BoxDecoration(
                                  color: context.success.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(color: context.success.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.cloud_done_outlined, size: 14, color: context.success),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        tr('Direct Google Drive Sync & Cloud Share'),
                                        style: TextStyle(
                                          fontSize: 11,
                                          fontWeight: FontWeight.w500,
                                          color: context.textPrimary,
                                        ),
                                        overflow: TextOverflow.ellipsis,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ] else ...[
                      // DESKTOP SCREEN: ONLY Desktop Personal Storage (Google Drive option omitted as requested)
                      InkWell(
                        onTap: () async {
                          Navigator.pop(modalContext);
                          await _handleBackupAction(
                            context: context,
                            ref: ref,
                            existingFilename: existingFilename,
                            toGoogleDrive: false,
                            isMobile: false,
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Container(
                          padding: const EdgeInsets.all(18),
                          decoration: BoxDecoration(
                            color: context.scaffoldBg,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: context.primaryColor.withValues(alpha: 0.35), width: 1.5),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  Container(
                                    padding: const EdgeInsets.all(12),
                                    decoration: BoxDecoration(
                                      color: context.primaryColor.withValues(alpha: 0.12),
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                    child: Icon(Icons.laptop_chromebook_rounded, color: context.primaryColor, size: 28),
                                  ),
                                  const SizedBox(width: 16),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          tr('Desktop Personal Storage'),
                                          style: TextStyle(
                                            fontSize: 16,
                                            fontWeight: FontWeight.bold,
                                            color: context.textPrimary,
                                          ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          tr('Save SQLite backup directly to your PC (Downloads, Documents, or Desktop)'),
                                          style: TextStyle(
                                            fontSize: 12,
                                            color: context.textSecondary,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  Icon(Icons.arrow_forward_ios_rounded, size: 14, color: context.primaryColor),
                                ],
                              ),
                              const SizedBox(height: 14),
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                                decoration: BoxDecoration(
                                  color: context.primaryColor.withValues(alpha: 0.08),
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(color: context.primaryColor.withValues(alpha: 0.2)),
                                ),
                                child: Row(
                                  children: [
                                    Icon(Icons.folder_special_outlined, size: 18, color: context.primaryColor),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            tr('Default PC Save Location:'),
                                            style: TextStyle(
                                              fontSize: 11,
                                              color: context.textSecondary,
                                              fontWeight: FontWeight.w500,
                                            ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            storageLocation,
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontFamily: 'monospace',
                                              fontWeight: FontWeight.w600,
                                              color: context.textPrimary,
                                            ),
                                            overflow: TextOverflow.ellipsis,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 14),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton.icon(
                                  onPressed: () async {
                                    Navigator.pop(modalContext);
                                    await _handleBackupAction(
                                      context: context,
                                      ref: ref,
                                      existingFilename: existingFilename,
                                      toGoogleDrive: false,
                                      isMobile: false,
                                    );
                                  },
                                  icon: const Icon(Icons.save_alt_rounded, size: 18),
                                  label: Text(tr('Choose PC Folder & Save')),
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: context.primaryColor,
                                    foregroundColor: Colors.white,
                                    padding: const EdgeInsets.symmetric(vertical: 12),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),
          ),
        );
      },
    );
  }

  Future<void> _handleBackupAction({
    required BuildContext context,
    required WidgetRef ref,
    String? existingFilename,
    required bool toGoogleDrive,
    bool isMobile = false,
  }) async {
    final messenger = ScaffoldMessenger.of(context);
    final successColor = context.success;
    final errorColor = context.error;
    final tr = ref.read(translationProvider);

    try {
      String targetFilename;
      if (existingFilename != null) {
        targetFilename = existingFilename;
      } else {
        final newBackupFile = await ref.read(adminProvider.notifier).triggerBackup();
        targetFilename = newBackupFile.uri.pathSegments.last;
      }

      final exportedPath = await ref.read(adminProvider.notifier).exportBackupFile(
            targetFilename,
            toGoogleDrive: toGoogleDrive,
          );

      if (exportedPath == null) {
        messenger.showSnackBar(
          SnackBar(
            content: Text(tr('Backup export cancelled.')),
            behavior: SnackBarBehavior.floating,
          ),
        );
        return;
      }

      final successMsg = toGoogleDrive
          ? tr('Backup prepared for Google Drive!')
          : (isMobile
              ? tr('Backup saved to mobile storage successfully!')
              : tr('Backup saved to PC storage successfully!'));

      messenger.showSnackBar(
        SnackBar(
          content: Text(successMsg),
          behavior: SnackBarBehavior.floating,
          backgroundColor: successColor,
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text('${tr("Backup failed")}: $e'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: errorColor,
        ),
      );
    }
  }
}


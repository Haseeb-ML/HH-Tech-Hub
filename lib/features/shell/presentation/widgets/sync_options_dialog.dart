import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:software_house_erp/core/services/cloud_sync_service.dart';
import 'package:software_house_erp/core/theme/app_colors.dart';

Future<void> showCloudSyncOptions(BuildContext context, WidgetRef ref) async {
  final syncState = ref.read(cloudSyncStateProvider);
  final isSyncing = syncState.status == SyncStatus.syncing;
  final isMobile = MediaQuery.of(context).size.width < 768;

  String formatTime(DateTime? time) {
    if (time == null) return 'Never';
    return DateFormat('hh:mm a, dd MMM').format(time);
  }

  void triggerSyncAction({bool force = false, bool pushOnly = false}) async {
    final messenger = ScaffoldMessenger.of(context);
    final notifier = ref.read(cloudSyncStateProvider.notifier);
    messenger.clearSnackBars();
    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const SizedBox(
              width: 16,
              height: 16,
              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                pushOnly
                    ? 'Pushing local changes to cloud...'
                    : (force
                        ? 'Force pushing all records to cloud...'
                        : 'Syncing data with cloud (Pull & Push)...'),
                style: const TextStyle(fontSize: 13),
              ),
            ),
          ],
        ),
        duration: const Duration(minutes: 1),
      ),
    );

    try {
      if (pushOnly) {
        await notifier.pushChangesOnly();
        messenger.clearSnackBars();
        messenger.showSnackBar(
          SnackBar(
            backgroundColor: Colors.green.shade700,
            content: const Text('Push complete! Local changes pushed to cloud.'),
            duration: const Duration(seconds: 3),
          ),
        );
        return;
      } else if (force) {
        await notifier.forceSync();
      } else {
        await notifier.syncNow();
      }
    } catch (e) {
      debugPrint('Sync error: $e');
    }

    final state = ref.read(cloudSyncStateProvider);
    messenger.clearSnackBars();
    if (state.status == SyncStatus.error) {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.red.shade700,
          content: Text(state.message ?? 'Sync failed or server error.'),
          duration: const Duration(seconds: 4),
        ),
      );
    } else {
      messenger.showSnackBar(
        SnackBar(
          backgroundColor: Colors.green.shade700,
          content: Text(
            state.syncedCount > 0
                ? (force
                    ? 'Force push complete! ${state.syncedCount} records pushed.'
                    : 'Sync complete! ${state.syncedCount} changes synced.')
                : (force
                    ? 'Force push complete! All records up to date.'
                    : 'Sync complete! Everything is up to date.'),
          ),
          duration: const Duration(seconds: 3),
        ),
      );
    }
  }

  Widget buildContent(BuildContext ctx) {
    Color statusColor;
    if (isSyncing) {
      statusColor = context.primaryColor;
    } else if (syncState.status == SyncStatus.error) {
      statusColor = context.error;
    } else if (syncState.lastSyncedAt != null) {
      statusColor = Colors.green.shade600;
    } else {
      statusColor = context.textSecondary;
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (isMobile) ...[
            Center(
              child: Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.border,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(Icons.cloud_sync_rounded, color: statusColor, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Cloud Synchronization',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: context.textPrimary,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      'Last Synced: ${formatTime(syncState.lastSyncedAt)}',
                      style: TextStyle(fontSize: 12, color: context.textSecondary),
                    ),
                  ],
                ),
              ),
              if (!isMobile)
                IconButton(
                  icon: const Icon(Icons.close, size: 20),
                  onPressed: () => Navigator.pop(ctx),
                ),
            ],
          ),
          if (syncState.message != null && syncState.message!.isNotEmpty) ...[
            const SizedBox(height: 10),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: statusColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: statusColor.withValues(alpha: 0.2)),
              ),
              child: Text(
                syncState.message!,
                style: TextStyle(fontSize: 11, color: statusColor, fontWeight: FontWeight.w500),
              ),
            ),
          ],
          const SizedBox(height: 14),
          const Divider(),
          const SizedBox(height: 8),

          // Option 1: Sync Now (Pull & Push)
          Material(
            color: Colors.transparent,
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.sync_rounded, color: Colors.blue, size: 22),
              ),
              title: Text(
                'Sync Now (Pull & Push)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
              ),
              subtitle: Text(
                'Download latest updates from cloud & upload local changes',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
              enabled: !isSyncing,
              onTap: () {
                Navigator.pop(ctx);
                triggerSyncAction(force: false);
              },
            ),
          ),
          const SizedBox(height: 6),

          // Option 2: Upload Data into Supabase
          Material(
            color: Colors.transparent,
            child: ListTile(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              leading: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.amber.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.cloud_upload_rounded, color: Colors.amber, size: 22),
              ),
              title: Text(
                'Upload Data into Supabase',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: context.textPrimary),
              ),
              subtitle: Text(
                'Force upload all accounts, payments & local records to Supabase',
                style: TextStyle(fontSize: 12, color: context.textSecondary),
              ),
              enabled: !isSyncing,
              onTap: () {
                Navigator.pop(ctx);
                triggerSyncAction(force: true);
              },
            ),
          ),
          const SizedBox(height: 12),
        ],
      ),
    );
  }

  if (isMobile) {
    await showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(child: buildContent(ctx)),
    );
  } else {
    await showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: context.cardBg,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 480),
          child: buildContent(ctx),
        ),
      ),
    );
  }
}

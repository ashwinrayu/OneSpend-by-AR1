import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../../../core/services/sync_service.dart';
import '../../auth/providers/auth_provider.dart';

class SyncStatusBadge extends ConsumerStatefulWidget {
  final bool compact; // For tight mobile headers
  const SyncStatusBadge({super.key, this.compact = false});

  @override
  ConsumerState<SyncStatusBadge> createState() => _SyncStatusBadgeState();
}

class _SyncStatusBadgeState extends ConsumerState<SyncStatusBadge>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 1),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final syncStatus = ref.watch(syncServiceProvider);
    final auth = ref.watch(authControllerProvider);

    if (syncStatus.state == SyncState.syncing) {
      if (!_animController.isAnimating) {
        _animController.repeat();
      }
    } else {
      if (_animController.isAnimating) {
        _animController.stop();
        _animController.reset();
      }
    }

    Color iconColor;
    Color bgColor;
    Color borderColor;
    IconData iconData;
    String label;
    String tooltip;

    switch (syncStatus.state) {
      case SyncState.synced:
        iconColor = const Color(0xFF10B981); // Emerald
        bgColor = const Color(0xFF10B981).withOpacity(0.12);
        borderColor = const Color(0xFF10B981).withOpacity(0.3);
        iconData = Icons.cloud_done_rounded;
        label = 'Synced';
        final timeStr = syncStatus.lastSyncedAt != null
            ? DateFormat('hh:mm a').format(syncStatus.lastSyncedAt!)
            : 'Just now';
        tooltip = 'Cloud synced ($timeStr). Click to refresh.';
        break;

      case SyncState.syncing:
        iconColor = const Color(0xFFF59E0B); // Amber
        bgColor = const Color(0xFFF59E0B).withOpacity(0.12);
        borderColor = const Color(0xFFF59E0B).withOpacity(0.3);
        iconData = Icons.sync_rounded;
        label = 'Syncing...';
        tooltip = 'Syncing ${syncStatus.pendingCount} changes to cloud...';
        break;

      case SyncState.offline:
        iconColor = const Color(0xFF94A3B8); // Slate grey
        bgColor = const Color(0xFF1E222B);
        borderColor = const Color(0xFF333B48);
        iconData = Icons.cloud_off_rounded;
        label = auth.isGuest ? 'Guest' : 'Offline';
        tooltip = auth.isGuest
            ? 'Guest mode (local SQLite). Sign in to enable cloud sync.'
            : (syncStatus.errorMessage ?? 'Offline mode. Changes saved locally.');
        break;

      case SyncState.error:
        iconColor = const Color(0xFFEF4444); // Red
        bgColor = const Color(0xFFEF4444).withOpacity(0.12);
        borderColor = const Color(0xFFEF4444).withOpacity(0.3);
        iconData = Icons.sync_problem_rounded;
        label = 'Sync Issue';
        tooltip = syncStatus.errorMessage ?? 'Sync failed. Tap to retry.';
        break;
    }

    final isCompact = widget.compact;

    return Tooltip(
      message: tooltip,
      waitDuration: const Duration(milliseconds: 300),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            if (auth.isGuest) {
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text(
                    'You are using Guest Mode. Sign in with an account to sync across devices.',
                  ),
                  backgroundColor: const Color(0xFF1E222B),
                  behavior: SnackBarBehavior.floating,
                  action: SnackBarAction(
                    label: 'Sign In',
                    textColor: const Color(0xFF10B981),
                    onPressed: () {
                      ref.read(authControllerProvider.notifier).logout();
                    },
                  ),
                ),
              );
            } else {
              ref.read(syncServiceProvider.notifier).syncNow();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Synchronizing vault with Render Cloud...'),
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                  backgroundColor: Color(0xFF1E222B),
                ),
              );
            }
          },
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: isCompact
                ? const EdgeInsets.all(7)
                : const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: bgColor,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: borderColor, width: 1),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (syncStatus.state == SyncState.syncing)
                  RotationTransition(
                    turns: _animController,
                    child: Icon(iconData, size: 16, color: iconColor),
                  )
                else
                  Icon(iconData, size: 16, color: iconColor),
                if (!isCompact) ...[
                  const SizedBox(width: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: iconColor,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}


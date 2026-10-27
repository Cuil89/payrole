import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import 'sidebar.dart';

class Topbar extends StatelessWidget {
  const Topbar({
    super.key,
    required this.currentTab,
    required this.store,
    this.onMenuPressed,
    this.onNotificationPressed,
    this.isMobile = false,
  });

  final AppTab currentTab;
  final AppStore store;
  final VoidCallback? onMenuPressed;
  final VoidCallback? onNotificationPressed;
  final bool isMobile;

  @override
  Widget build(BuildContext context) {
    final currentUser = store.currentUser;
    final activeRecap = store.activeRecap;

    return Container(
      height: 64,
      padding: EdgeInsets.symmetric(horizontal: isMobile ? 10 : 20),
      decoration: const BoxDecoration(
        color: AppColors.surface,
        border: Border(bottom: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: Row(
        children: [
          // Mobile Menu Button
          if (isMobile) ...[
            IconButton(
              icon: const Icon(AppIcons.menu, size: 20),
              color: AppColors.text2,
              onPressed: onMenuPressed,
              tooltip: 'Buka menu',
            ),
            const SizedBox(width: 4),
          ],

          // Breadcrumb
          Expanded(
            child: Row(
              children: [
                if (!isMobile) ...[
                  const Text(
                    'Ruang kerja',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w400,
                      color: AppColors.textMuted,
                    ),
                  ),
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 6),
                    child: Text(
                      '>',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w400,
                        color: AppColors.textSubtle,
                      ),
                    ),
                  ),
                ],
                Flexible(
                  child: Text(
                    currentTab.label,
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppColors.textStrong,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Period State Machine Indicator
          if (!isMobile) ...[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: _statusColor(activeRecap.status).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: _statusColor(activeRecap.status).withValues(alpha: 0.3),
                  width: 0.8,
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    activeRecap.isLocked ? AppIcons.lock : AppIcons.clock,
                    size: 13,
                    color: _statusColor(activeRecap.status),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    'Minggu 43: ${activeRecap.status.label}',
                    style: TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _statusColor(activeRecap.status),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 12),
          ],

          // 1-Click Role Switcher Demo Dropdown
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<UserRole>(
                value: currentUser.role,
                isDense: true,
                icon: const Icon(AppIcons.chevronsUpDown, size: 14, color: AppColors.textMuted),
                items: UserRole.values.map((role) {
                  return DropdownMenuItem<UserRole>(
                    value: role,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8,
                          height: 8,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: _roleColor(role),
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isMobile ? _shortRoleLabel(role) : role.label,
                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                onChanged: (newRole) {
                  if (newRole != null) {
                    store.switchRole(newRole);
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        duration: const Duration(seconds: 2),
                        content: Text('Beralih ke tampilan role: ${newRole.label}'),
                      ),
                    );
                  }
                },
              ),
            ),
          ),

          const SizedBox(width: 8),

          // Notification Bell
          IconButton(
            icon: const Icon(AppIcons.bell, size: 19),
            color: AppColors.text2,
            tooltip: 'Notifikasi & Log Aktivitas',
            onPressed: onNotificationPressed,
          ),
        ],
      ),
    );
  }

  Color _statusColor(StatusRekap status) {
    switch (status) {
      case StatusRekap.draft:
        return AppColors.textMuted;
      case StatusRekap.diverifikasiMandor:
        return AppColors.amber700;
      case StatusRekap.disetujuiPemilik:
        return AppColors.sky700;
      case StatusRekap.dibayar:
        return AppColors.primary700;
    }
  }

  Color _roleColor(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return AppColors.rose700;
      case UserRole.pemilik:
        return AppColors.amber700;
      case UserRole.adminKeuangan:
        return AppColors.sky700;
      case UserRole.mandor:
        return AppColors.indigo700;
      case UserRole.karyawan:
        return AppColors.primary700;
    }
  }

  String _shortRoleLabel(UserRole role) {
    switch (role) {
      case UserRole.superAdmin:
        return 'Admin';
      case UserRole.pemilik:
        return 'Owner';
      case UserRole.adminKeuangan:
        return 'Keuangan';
      case UserRole.mandor:
        return 'Mandor';
      case UserRole.karyawan:
        return 'Karyawan';
    }
  }
}

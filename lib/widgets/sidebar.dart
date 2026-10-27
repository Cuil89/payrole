import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/theme.dart';
import '../data/models.dart';

enum AppTab {
  summary('Ringkasan', AppIcons.summary),
  superAdmin('Pusat Kendali', AppIcons.shield),
  masterTarif('Master Tarif & HPP', AppIcons.adjust),
  employees('Data Karyawan', AppIcons.employees),
  attendance('Kehadiran & Lembur', AppIcons.attendance),
  payroll('Rekap & Penggajian', AppIcons.payroll),
  mandorPortal('Portal Mandor', AppIcons.process),
  karyawanPortal('Portal Karyawan', AppIcons.fileText),
  reimbursement('Kasbon & Reimburse', AppIcons.reimbursement),
  reports('Laporan & Ekspor', AppIcons.reports),
  settings('Pengaturan', AppIcons.settings),
  help('Pusat Bantuan', AppIcons.help);

  const AppTab(this.label, this.icon);
  final String label;
  final IconData icon;
}

class Sidebar extends StatelessWidget {
  const Sidebar({
    super.key,
    required this.currentTab,
    required this.onSelectTab,
    required this.companyName,
    required this.currentUser,
    this.onLogout,
    this.onHelpClick,
    this.isDrawer = false,
  });

  final AppTab currentTab;
  final ValueChanged<AppTab> onSelectTab;
  final String companyName;
  final UserAccount currentUser;
  final VoidCallback? onLogout;
  final VoidCallback? onHelpClick;
  final bool isDrawer;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 256,
      decoration: BoxDecoration(
        color: AppColors.surface,
        border: isDrawer
            ? null
            : const Border(right: BorderSide(color: AppColors.border, width: 1)),
      ),
      child: SafeArea(
        child: Column(
          children: [
            // Header Logo
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
              child: Row(
                children: [
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    alignment: Alignment.center,
                    child: const Icon(
                      AppIcons.payroll,
                      color: Colors.white,
                      size: 19,
                    ),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'payrole',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 19,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textStrong,
                      letterSpacing: -0.4,
                    ),
                  ),
                  const Text(
                    ' .',
                    style: TextStyle(
                      fontFamily: 'Inter',
                      fontSize: 19,
                      fontWeight: FontWeight.w800,
                      color: AppColors.primary,
                    ),
                  ),
                ],
              ),
            ),

            // Workspace & Active Role Box
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColors.slate100,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.borderStrong),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 30,
                      height: 30,
                      decoration: BoxDecoration(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        companyName.isNotEmpty ? companyName[0].toUpperCase() : 'K',
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            companyName,
                            style: const TextStyle(
                              fontSize: 12.5,
                              fontWeight: FontWeight.w700,
                              color: AppColors.textStrong,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          const SizedBox(height: 1),
                          Text(
                            currentUser.roleBadgeLabel,
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: AppColors.primary700,
                              height: 1.2,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Role-Isolated Navigation Menus
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: _buildRoleSpecificMenuItems(),
              ),
            ),

            // Footer Help Banner
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: AppColors.emerald50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: AppColors.emerald200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(AppIcons.shield, size: 15, color: AppColors.primary700),
                            SizedBox(width: 6),
                            Text(
                              'Akses Terisolasi Server',
                              style: TextStyle(
                                fontSize: 11.5,
                                fontWeight: FontWeight.w700,
                                color: AppColors.primaryDark,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'Sesi: ${currentUser.name}',
                          style: const TextStyle(fontSize: 11, color: AppColors.text2),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  if (onLogout != null)
                    InkWell(
                      onTap: onLogout,
                      borderRadius: BorderRadius.circular(8),
                      child: const Padding(
                        padding: EdgeInsets.symmetric(vertical: 8),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(AppIcons.logout, size: 15, color: AppColors.rose600),
                            SizedBox(width: 6),
                            Text(
                              'Kunci / Logout',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.rose600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<Widget> _buildRoleSpecificMenuItems() {
    switch (currentUser.role) {
      case UserRole.superAdmin:
        return [
          _groupTitle('KONTROL SISTEM'),
          _navItem(AppTab.superAdmin),
          _navItem(AppTab.employees),
          _navItem(AppTab.payroll),
          _navItem(AppTab.reports),
          const SizedBox(height: 16),
          _groupTitle('PENGATURAN'),
          _navItem(AppTab.settings),
          _navItem(AppTab.help),
        ];

      case UserRole.pemilik:
        return [
          _groupTitle('PORTAL EKSEKUTIF PEMILIK'),
          _navItem(AppTab.summary),
          _navItem(AppTab.masterTarif),
          _navItem(AppTab.payroll),
          _navItem(AppTab.reports),
          const SizedBox(height: 16),
          _groupTitle('PREFERENSI'),
          _navItem(AppTab.settings),
          _navItem(AppTab.help),
        ];

      case UserRole.adminKeuangan:
        return [
          _groupTitle('HR & KEUANGAN'),
          _navItem(AppTab.summary),
          _navItem(AppTab.employees),
          _navItem(AppTab.payroll),
          _navItem(AppTab.attendance),
          _navItem(AppTab.reimbursement),
          _navItem(AppTab.reports),
          const SizedBox(height: 16),
          _groupTitle('PENGATURAN'),
          _navItem(AppTab.settings),
          _navItem(AppTab.help),
        ];

      case UserRole.mandor:
        return [
          _groupTitle('PORTAL LAPANGAN'),
          _navItem(AppTab.mandorPortal),
          _navItem(AppTab.attendance),
          const SizedBox(height: 16),
          _groupTitle('BANTUAN'),
          _navItem(AppTab.help),
        ];

      case UserRole.karyawan:
        return [
          _groupTitle('PORTAL MANDIRI PEKERJA'),
          _navItem(AppTab.karyawanPortal),
          const SizedBox(height: 16),
          _groupTitle('BANTUAN'),
          _navItem(AppTab.help),
        ];
    }
  }

  Widget _groupTitle(String title) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(10, 8, 10, 6),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w700,
          color: AppColors.textSubtle,
          letterSpacing: 0.6,
        ),
      ),
    );
  }

  Widget _navItem(AppTab tab) {
    final isSelected = currentTab == tab;

    return Padding(
      padding: const EdgeInsets.only(bottom: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () => onSelectTab(tab),
          borderRadius: BorderRadius.circular(10),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
            decoration: BoxDecoration(
              color: isSelected ? AppColors.emerald50 : Colors.transparent,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Icon(
                  tab.icon,
                  size: 18,
                  color: isSelected ? AppColors.primary : AppColors.text2,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    tab.label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                      color: isSelected ? AppColors.primary : AppColors.text2,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 5,
                    height: 5,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

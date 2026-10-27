import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../widgets/app_card.dart';
import '../widgets/badges.dart';

class SuperAdminPage extends StatefulWidget {
  const SuperAdminPage({super.key, required this.store});

  final AppStore store;

  @override
  State<SuperAdminPage> createState() => _SuperAdminPageState();
}

class _SuperAdminPageState extends State<SuperAdminPage> {
  int _activeSubTab = 0; // 0: User Management, 1: RBAC Matrix, 2: Audit Log

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final users = widget.store.users;
        final auditLogs = widget.store.audit;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 24),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1280),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Header
                  _buildHeader(),
                  const SizedBox(height: 20),

                  // System Status Overview Cards
                  _buildSystemHealthCards(users, auditLogs),
                  const SizedBox(height: 24),

                  // Sub Navigation Bar
                  _buildSubTabBar(),
                  const SizedBox(height: 20),

                  // Sub Tab Contents
                  if (_activeSubTab == 0) _buildUserManagement(users),
                  if (_activeSubTab == 1) _buildRbacMatrix(),
                  if (_activeSubTab == 2) _buildAuditLogExplorer(auditLogs),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildHeader() {
    return const Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(AppIcons.shield, color: AppColors.primary, size: 24),
            SizedBox(width: 10),
            Text('Pusat Kendali & Manajemen Sistem', style: AppText.pageTitle),
          ],
        ),
        SizedBox(height: 4),
        Text(
          'Hak akses tingkat Super Admin: Kelola akun pengguna, konfigurasi RBAC, dan audit keamanan.',
          style: AppText.small,
        ),
      ],
    );
  }

  Widget _buildSystemHealthCards(List<UserAccount> users, List<AuditEntry> auditLogs) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 768;
        return GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 16,
          mainAxisSpacing: 16,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 1.4 : 1.7,
          children: [
            _statCard(
              title: 'Total Akun Pengguna',
              value: '${users.length}',
              subtitle: '5 Role Terdaftar',
              icon: AppIcons.employees,
              color: AppColors.primary,
            ),
            _statCard(
              title: 'Status Database',
              value: 'Online 24/7',
              subtitle: 'Neon Serverless ACID',
              icon: AppIcons.checkCircle,
              color: AppColors.success,
            ),
            _statCard(
              title: 'Periode Berjalan',
              value: 'Minggu 43',
              subtitle: widget.store.activeRecap.status.label,
              icon: AppIcons.calendar,
              color: AppColors.amber700,
            ),
            _statCard(
              title: 'Total Log Keamanan',
              value: '${auditLogs.length}',
              subtitle: 'Immutable Audit Trail',
              icon: AppIcons.lock,
              color: AppColors.sky700,
            ),
          ],
        );
      },
    );
  }

  Widget _statCard({
    required String title,
    required String value,
    required String subtitle,
    required IconData icon,
    required Color color,
  }) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted, fontWeight: FontWeight.w500),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 18, color: color),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700, color: AppColors.textStrong),
              ),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSubTabBar() {
    return Container(
      decoration: const BoxDecoration(
        border: Border(bottom: BorderSide(color: AppColors.border)),
      ),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            _subTabButton('Manajemen User & Role', 0, AppIcons.employees),
            const SizedBox(width: 8),
            _subTabButton('Matriks Hak Akses (RBAC)', 1, AppIcons.shield),
            const SizedBox(width: 8),
            _subTabButton('Audit Log Keamanan', 2, AppIcons.lock),
          ],
        ),
      ),
    );
  }

  Widget _subTabButton(String label, int index, IconData icon) {
    final active = _activeSubTab == index;
    return InkWell(
      onTap: () => setState(() => _activeSubTab = index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          border: Border(
            bottom: BorderSide(
              color: active ? AppColors.primary : Colors.transparent,
              width: 2.5,
            ),
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: active ? AppColors.primary : AppColors.textMuted),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
                color: active ? AppColors.primary : AppColors.textMuted,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // 1. User Management
  Widget _buildUserManagement(List<UserAccount> users) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            alignment: WrapAlignment.spaceBetween,
            spacing: 12,
            runSpacing: 10,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Daftar Akun Pengguna', style: AppText.cardTitle),
                  Text('Akun login terdaftar untuk akses sistem sesuai wewenang role.', style: AppText.small),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                icon: const Icon(AppIcons.add, size: 15),
                label: const Text('Tambah User', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600)),
                onPressed: () => _showAddUserDialog(),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Nama Pengguna', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Email Login', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Role Pengguna', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Keterangan / Divisi', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Status', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
              rows: users.map((u) {
                return DataRow(
                  cells: [
                    DataCell(Text(u.name, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(u.email)),
                    DataCell(_roleBadge(u.role)),
                    DataCell(Text(u.roleBadgeLabel)),
                    DataCell(
                      BadgePill(
                        label: u.isActive ? 'Aktif' : 'Nonaktif',
                        tone: u.isActive ? BadgeTone.emerald : BadgeTone.neutral,
                      ),
                    ),
                    DataCell(
                      Row(
                        children: [
                          IconButton(
                            icon: const Icon(AppIcons.edit, size: 16),
                            tooltip: 'Edit User',
                            onPressed: () {},
                          ),
                          IconButton(
                            icon: const Icon(AppIcons.lock, size: 16),
                            tooltip: 'Reset Password',
                            onPressed: () {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(content: Text('Tautan reset password terkirim ke ${u.email}')),
                              );
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
        ],
      ),
    );
  }

  Widget _roleBadge(UserRole role) {
    Color bg;
    Color fg;
    switch (role) {
      case UserRole.superAdmin:
        bg = AppColors.rose50;
        fg = AppColors.rose700;
      case UserRole.pemilik:
        bg = AppColors.amber50;
        fg = AppColors.amber700;
      case UserRole.adminKeuangan:
        bg = AppColors.sky50;
        fg = AppColors.sky700;
      case UserRole.mandor:
        bg = AppColors.indigo50;
        fg = AppColors.indigo700;
      case UserRole.karyawan:
        bg = AppColors.emerald50;
        fg = AppColors.primary700;
    }
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(6)),
      child: Text(role.label, style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: fg)),
    );
  }

  // 2. RBAC Matrix
  Widget _buildRbacMatrix() {
    final permissions = [
      {'module': 'Manajemen Akun User', 'super': true, 'owner': false, 'finance': false, 'mandor': false, 'worker': false},
      {'module': 'Audit Log Keamanan Lengkap', 'super': true, 'owner': true, 'finance': false, 'mandor': false, 'worker': false},
      {'module': 'Master Tarif & Harga Model', 'super': false, 'owner': true, 'finance': false, 'mandor': false, 'worker': false},
      {'module': 'Laporan HPP & Margin Biaya', 'super': false, 'owner': true, 'finance': false, 'mandor': false, 'worker': false},
      {'module': 'Persetujuan Bayar (Approval)', 'super': false, 'owner': true, 'finance': false, 'mandor': false, 'worker': false},
      {'module': 'Master Karyawan & Rekening', 'super': false, 'owner': true, 'finance': true, 'mandor': false, 'worker': false},
      {'module': 'Buku Besar Kasbon & Cicilan', 'super': false, 'owner': true, 'finance': true, 'mandor': false, 'worker': false},
      {'module': 'Cairkan Gaji & Tutup Minggu', 'super': false, 'owner': false, 'finance': true, 'mandor': false, 'worker': false},
      {'module': 'Input Absensi Lapangan', 'super': false, 'owner': false, 'finance': false, 'mandor': true, 'worker': false},
      {'module': 'Input Hasil Potong/Jahit', 'super': false, 'owner': false, 'finance': false, 'mandor': true, 'worker': false},
      {'module': 'Verifikasi & Kunci Harian', 'super': false, 'owner': false, 'finance': false, 'mandor': true, 'worker': false},
      {'module': 'Akses Slip Gaji Sendiri', 'super': false, 'owner': false, 'finance': false, 'mandor': false, 'worker': true},
    ];

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Matriks Otorisasi Peran (Role-Based Access Control)', style: AppText.cardTitle),
          const SizedBox(height: 4),
          const Text(
            'Aturan pemisahan tugas ketat (Strict Separation of Duties) dikunci dari sisi server.',
            style: AppText.small,
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Modul & Fitur Sistem', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('SUPER_ADMIN', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('PEMILIK', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('ADMIN_KEUANGAN', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('MANDOR', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('KARYAWAN', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
              rows: permissions.map((p) {
                return DataRow(
                  cells: [
                    DataCell(Text(p['module'] as String, style: const TextStyle(fontWeight: FontWeight.w500))),
                    DataCell(_checkIcon(p['super'] as bool)),
                    DataCell(_checkIcon(p['owner'] as bool)),
                    DataCell(_checkIcon(p['finance'] as bool)),
                    DataCell(_checkIcon(p['mandor'] as bool)),
                    DataCell(_checkIcon(p['worker'] as bool)),
                  ],
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _checkIcon(bool granted) {
    if (granted) {
      return const Icon(AppIcons.checkCircle, color: AppColors.success, size: 18);
    }
    return const Icon(AppIcons.close, color: AppColors.slate300, size: 16);
  }

  // 3. Audit Log Explorer
  Widget _buildAuditLogExplorer(List<AuditEntry> auditLogs) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Jejak Audit Keamanan (Immutable Audit Trail)', style: AppText.cardTitle),
                  Text('Seluruh aksi finansial, perubahan tarif, dan persetujuan tersimpan permanen.', style: AppText.small),
                ],
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: auditLogs.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final log = auditLogs[idx];
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(7),
                      decoration: BoxDecoration(
                        color: AppColors.slate100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: const Icon(AppIcons.lock, size: 15, color: AppColors.primary),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Wrap(
                            spacing: 8,
                            runSpacing: 4,
                            crossAxisAlignment: WrapCrossAlignment.center,
                            children: [
                              Text(
                                log.action,
                                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700, color: AppColors.textStrong),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(4)),
                                child: Text(
                                  'Oleh: ${log.userName} (${log.role})',
                                  style: const TextStyle(fontSize: 10.5, fontWeight: FontWeight.w600, color: AppColors.primary700),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 3),
                          Text(log.detail, style: const TextStyle(fontSize: 12, color: AppColors.text2)),
                        ],
                      ),
                    ),
                    Text(
                      Fmt.dateTime(log.at),
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  void _showAddUserDialog() {
    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Tambah Akun Pengguna Baru'),
          content: const Text(
            'Form penambahan akun pengguna dengan penetapan Role dan Divisi penugasan.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Simpan Akun'),
            ),
          ],
        );
      },
    );
  }
}

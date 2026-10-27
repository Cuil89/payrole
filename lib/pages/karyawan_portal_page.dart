import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../widgets/app_card.dart';
import '../widgets/badges.dart';

class KaryawanPortalPage extends StatelessWidget {
  const KaryawanPortalPage({super.key, required this.store});

  final AppStore store;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: store,
      builder: (context, _) {
        // ANTI-IDOR ARCHITECTURE: Strictly fetch by authenticated session karyawanId
        final currentEmpId = store.currentUser.karyawanId ?? 'KNV-001';
        final emp = store.employeeById(currentEmpId) ?? store.activeEmployees.first;

        // Daily piece works for this employee
        final myWorks = store.dailyWork.where((w) => w.karyawanId == emp.id).toList();
        final totalPcs = myWorks.fold(0, (s, w) => s + w.qtyBagus);

        // Kasbon for this employee
        final myLoan = store.loans.firstWhere(
          (l) => l.employeeId == emp.id,
          orElse: () => Loan(
            id: '',
            employeeId: emp.id,
            amount: 0,
            deduction: 0,
            createdAt: DateTime.now(),
          ),
        );

        final slip = store.calculateSlipForEmployee(emp);
        final estimatedThp = slip.thpBersih;
        final gross = slip.upahKotor;
        final totalPieceWage = slip.totalUpahBorong;
        final totalDenda = slip.potonganDenda;
        final actualKasbonDeduction = slip.potonganKasbon;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 900),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildEmployeeBanner(emp),
                  const SizedBox(height: 16),

                  // Big Wage Card (Minggu Ini)
                  _buildTakeHomePayCard(estimatedThp, gross, totalPieceWage, totalPcs, totalDenda, actualKasbonDeduction, emp),
                  const SizedBox(height: 20),

                  // Kasbon Balance Card
                  _buildKasbonBalanceCard(myLoan, actualKasbonDeduction),
                  const SizedBox(height: 20),

                  // Daily Pieces List (Hasil Jahit Harian)
                  _buildDailyPiecesList(myWorks),
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildEmployeeBanner(Employee emp) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 24,
            backgroundColor: AppColors.emerald100,
            child: Text(
              emp.name[0],
              style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 18),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(emp.name, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.textStrong)),
                const SizedBox(height: 2),
                Text(
                  '${emp.id} · ${emp.divisi.label} · Sistem: ${emp.tipeGaji.label}',
                  style: const TextStyle(fontSize: 12, color: AppColors.textMuted),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(8)),
            child: const Text('Karyawan Aktif', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700, color: AppColors.primary700)),
          ),
        ],
      ),
    );
  }

  Widget _buildTakeHomePayCard(
    int thp,
    int gross,
    int pieceWage,
    int totalPcs,
    int totalDenda,
    int kasbonDeduction,
    Employee emp,
  ) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppColors.primary, AppColors.primaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('ESTIMASI UPAH BERSIH MINGGU INI', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.emerald100, letterSpacing: 0.5)),
              Icon(AppIcons.payroll, color: Colors.white, size: 20),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            Fmt.rupiah(thp),
            style: const TextStyle(fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white),
          ),
          const SizedBox(height: 4),
          const Text(
            'Periode: 19 - 24 Okt 2026 (Minggu 43)',
            style: TextStyle(fontSize: 12, color: AppColors.emerald200),
          ),
          const SizedBox(height: 16),
          const Divider(color: Colors.white24, height: 1),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(child: _wageItem('Hasil Jahit ($totalPcs pcs)', Fmt.rupiah(pieceWage))),
              const SizedBox(width: 8),
              Expanded(child: _wageItem('Tunjangan Hadir', Fmt.rupiah(emp.allowance))),
              const SizedBox(width: 8),
              Expanded(child: _wageItem('Potongan Kasbon', '-${Fmt.rupiah(kasbonDeduction)}')),
            ],
          ),
        ],
      ),
    );
  }

  Widget _wageItem(String title, String amount) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 11, color: AppColors.emerald100),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 2),
        FittedBox(
          fit: BoxFit.scaleDown,
          alignment: Alignment.centerLeft,
          child: Text(
            amount,
            style: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700, color: Colors.white),
          ),
        ),
      ],
    );
  }

  Widget _buildKasbonBalanceCard(Loan loan, int currentDeduction) {
    final hasLoan = loan.id.isNotEmpty && !loan.isPaidOff;
    final remaining = hasLoan ? loan.remaining : 0;
    final nextBalance = (remaining - currentDeduction).clamp(0, loan.amount);

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Status Kasbon & Pinjaman Pribadi', style: AppText.cardTitle),
                    Text('Transparansi cicilan & sisa hutang tanpa bunga.', style: AppText.small),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              BadgePill(
                label: hasLoan ? 'Ada Pinjaman' : 'Lunas',
                tone: hasLoan ? BadgeTone.amber : BadgeTone.emerald,
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (!hasLoan)
            const Text('Alhamdulillah, Anda tidak memiliki sisa tanggungan pinjaman/kasbon.', style: TextStyle(color: AppColors.primary700, fontWeight: FontWeight.w500))
          else ...[
            LayoutBuilder(
              builder: (context, constraints) {
                final isNarrow = constraints.maxWidth < 600;
                if (isNarrow) {
                  return Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _loanMetricCard(
                              title: 'Pinjaman Awal',
                              value: Fmt.rupiah(loan.amount),
                              valueColor: AppColors.textStrong,
                              bgColor: AppColors.slate100,
                              borderColor: AppColors.borderStrong,
                              icon: AppIcons.payroll,
                              iconColor: AppColors.textMuted,
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _loanMetricCard(
                              title: 'Potongan Gaji Ini',
                              value: '-${Fmt.rupiah(currentDeduction)}',
                              valueColor: AppColors.rose700,
                              bgColor: AppColors.rose50,
                              borderColor: AppColors.rose600.withValues(alpha: 0.2),
                              icon: Icons.remove_circle_outline,
                              iconColor: AppColors.rose700,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: AppColors.emerald50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.emerald200),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(7),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: const Icon(AppIcons.checkCircle, color: AppColors.primary, size: 18),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Sisa Hutang Setelah Gajian',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary700),
                                  ),
                                  const SizedBox(height: 1),
                                  const Text(
                                    'Tanggungan pokok tanpa bunga berjalan.',
                                    style: TextStyle(fontSize: 10.5, color: AppColors.textMuted),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 8),
                            FittedBox(
                              fit: BoxFit.scaleDown,
                              child: Text(
                                Fmt.rupiah(nextBalance),
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w800,
                                  color: AppColors.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  );
                }
                return Row(
                  children: [
                    Expanded(
                      child: _loanMetricCard(
                        title: 'Total Pinjaman Awal',
                        value: Fmt.rupiah(loan.amount),
                        valueColor: AppColors.textStrong,
                        bgColor: AppColors.slate100,
                        borderColor: AppColors.borderStrong,
                        icon: AppIcons.payroll,
                        iconColor: AppColors.textMuted,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _loanMetricCard(
                        title: 'Potongan Gaji Ini (Cap 50%)',
                        value: '-${Fmt.rupiah(currentDeduction)}',
                        valueColor: AppColors.rose700,
                        bgColor: AppColors.rose50,
                        borderColor: AppColors.rose600.withValues(alpha: 0.2),
                        icon: Icons.remove_circle_outline,
                        iconColor: AppColors.rose700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: _loanMetricCard(
                        title: 'Sisa Hutang Setelah Gajian',
                        value: Fmt.rupiah(nextBalance),
                        valueColor: AppColors.primary700,
                        bgColor: AppColors.emerald50,
                        borderColor: AppColors.emerald200,
                        icon: AppIcons.checkCircle,
                        iconColor: AppColors.primary,
                      ),
                    ),
                  ],
                );
              },
            ),
            const SizedBox(height: 10),
            const Text(
              'Catatan: Pemotongan dibatasi maksimal 50% dari total upah agar gaji Anda tidak minus.',
              style: TextStyle(fontSize: 11.5, color: AppColors.amber700, fontStyle: FontStyle.italic),
            ),
          ],
        ],
      ),
    );
  }

  Widget _loanMetricCard({
    required String title,
    required String value,
    required Color valueColor,
    required Color bgColor,
    required Color borderColor,
    required IconData icon,
    required Color iconColor,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: borderColor),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              Icon(icon, size: 16, color: iconColor),
            ],
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              value,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: valueColor,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDailyPiecesList(List<HasilKerjaHarian> works) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Rincian Hasil Kerja Harian Saya', style: AppText.cardTitle),
                    Text('Daftar setoran potong yang tercatat oleh mandor.', style: AppText.small),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Text(
                '${works.length} Setoran',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (works.isEmpty)
            const Padding(
              padding: EdgeInsets.all(20),
              child: Center(child: Text('Belum ada setoran kerja untuk minggu ini.', style: TextStyle(color: AppColors.textMuted))),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: works.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final w = works[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              w.namaProses,
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${Fmt.date(w.tanggal)} · SPK: ${w.nomorSpk} · ${w.qtyBagus} pcs @ ${Fmt.rupiah(w.snapshotTarif)}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        Fmt.rupiah(w.upahBruto),
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5, color: AppColors.primary),
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
}

import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../services/csv_service.dart';
import '../services/pdf_service.dart';
import '../widgets/app_card.dart';
import '../widgets/badges.dart';

class ReportsPage extends StatefulWidget {
  const ReportsPage({super.key, required this.store});

  final AppStore store;

  @override
  State<ReportsPage> createState() => _ReportsPageState();
}

class _ReportsPageState extends State<ReportsPage> {
  int _selectedTab = 0;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final recapData = widget.store.weeklyRecapReport;
        final hppData = widget.store.hppReportData;
        final prodData = widget.store.productivityByDivisionReport;
        final slips = widget.store.convectionWeeklySlips;

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;

            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 28,
                vertical: 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Wrap(
                        spacing: 16,
                        runSpacing: 12,
                        alignment: WrapAlignment.spaceBetween,
                        crossAxisAlignment: WrapCrossAlignment.center,
                        children: [
                          const Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Pusat Laporan & HPP Konveksi', style: AppText.pageTitle),
                              SizedBox(height: 4),
                              Text(
                                '5 Laporan Wajib: Rekap Gaji, Produktivitas, Kasbon, Biaya HPP per Model, & Ekspor Excel.',
                                style: AppText.small,
                              ),
                            ],
                          ),
                          Wrap(
                            spacing: 10,
                            runSpacing: 8,
                            children: [
                              OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 11),
                                ),
                                icon: const Icon(AppIcons.export, size: 16),
                                label: const Text('Ekspor Rekap Excel (.csv)'),
                                onPressed: () async {
                                  final csv = await CsvService.generateConvectionWeeklyPayrollCsv(
                                    slips: slips,
                                    periodLabel: widget.store.periodLabel,
                                  );
                                  await CsvService.shareCsv(csv, 'Rekap_Gaji_Mingguan_${widget.store.periodLabel}.csv');
                                },
                              ),
                              ElevatedButton.icon(
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.primary,
                                  foregroundColor: Colors.white,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 11),
                                ),
                                icon: const Icon(AppIcons.print, size: 16),
                                label: const Text('Cetak Rekap PDF'),
                                onPressed: () {
                                  PdfService.printOrShareReport(
                                    lines: widget.store.payrollLines,
                                    companyName: widget.store.settings.companyName,
                                    periodLabel: widget.store.periodLabel,
                                  );
                                },
                              ),
                            ],
                          ),
                        ],
                      ),

                      const SizedBox(height: 20),

                      // 5 Report Navigation Tabs
                      SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            _reportTabItem(0, '1. Rekap Gaji & Pengeluaran', AppIcons.payroll),
                            const SizedBox(width: 8),
                            _reportTabItem(1, '2. Produktivitas Bagian', AppIcons.summary),
                            const SizedBox(width: 8),
                            _reportTabItem(2, '3. Saldo Kasbon Berjalan', AppIcons.reimbursement),
                            const SizedBox(width: 8),
                            _reportTabItem(3, '4. Biaya Tenaga Kerja (HPP)', AppIcons.adjust),
                            const SizedBox(width: 8),
                            _reportTabItem(4, '5. Ekspor Data Excel', AppIcons.export),
                          ],
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Active Tab View Content
                      if (_selectedTab == 0)
                        _buildTabWeeklyRecap(recapData, slips)
                      else if (_selectedTab == 1)
                        _buildTabProductivity(prodData)
                      else if (_selectedTab == 2)
                        _buildTabKasbon()
                      else if (_selectedTab == 3)
                        _buildTabHpp(hppData)
                      else
                        _buildTabExportCenter(slips),

                      const SizedBox(height: 40),
                    ],
                  ),
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _reportTabItem(int index, String label, IconData icon) {
    final isSelected = _selectedTab == index;
    return InkWell(
      onTap: () => setState(() => _selectedTab = index),
      borderRadius: BorderRadius.circular(10),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : AppColors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: isSelected ? AppColors.primary : AppColors.borderStrong,
          ),
          boxShadow: isSelected
              ? [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.2),
                    blurRadius: 6,
                    offset: const Offset(0, 2),
                  ),
                ]
              : null,
        ),
        child: Row(
          children: [
            Icon(
              icon,
              size: 16,
              color: isSelected ? Colors.white : AppColors.text2,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 13,
                fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600,
                color: isSelected ? Colors.white : AppColors.textStrong,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ---------------------------------------------------------------- TAB 1: Rekap Gaji & Pengeluaran
  Widget _buildTabWeeklyRecap(Map<String, dynamic> recap, List<SlipGajiMingguan> slips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Top KPI Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            return GridView.count(
              crossAxisCount: isMobile ? 2 : 4,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isMobile ? 1.6 : 1.9,
              children: [
                _metricBox('Total Pengeluaran Gaji', Fmt.rupiah(recap['totalThp'] as int? ?? 0), AppColors.primary, AppColors.emerald50),
                _metricBox('Upah Borongan (Piece)', Fmt.rupiah(recap['totalBorongan'] as int? ?? 0), AppColors.success, AppColors.slate100),
                _metricBox('Upah Harian & Hadir', Fmt.rupiah(recap['totalUpahDasar'] as int? ?? 0), AppColors.sky700, AppColors.sky50),
                _metricBox('Potongan Kasbon Terpotong', Fmt.rupiah(recap['totalKasbon'] as int? ?? 0), AppColors.amber700, AppColors.amber50),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        // Distribution by Payment Method (Tunai vs Transfer vs E-Wallet)
        AppCard(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('Distribusi Metode Pembayaran Mingguan', style: AppText.sectionTitle),
              const SizedBox(height: 4),
              const Text('Klasifikasi pencairan untuk persiapan penarikan tunai amplop dan transfer.', style: AppText.small),
              const SizedBox(height: 16),
              LayoutBuilder(
                builder: (context, constraints) {
                  final isNarrow = constraints.maxWidth < 650;
                  final c1 = _paymentMethodCard(
                    title: 'Tunai (Amplop)',
                    count: recap['tunaiCount'] as int? ?? 0,
                    total: recap['tunaiTotal'] as int? ?? 0,
                    color: AppColors.primary,
                    icon: AppIcons.payroll,
                    isFullWidth: isNarrow,
                  );
                  final c2 = _paymentMethodCard(
                    title: 'Transfer Bank',
                    count: recap['transferCount'] as int? ?? 0,
                    total: recap['transferTotal'] as int? ?? 0,
                    color: AppColors.sky700,
                    icon: AppIcons.reports,
                    isFullWidth: isNarrow,
                  );
                  final c3 = _paymentMethodCard(
                    title: 'E-Wallet',
                    count: recap['ewalletCount'] as int? ?? 0,
                    total: recap['ewalletTotal'] as int? ?? 0,
                    color: AppColors.amber700,
                    icon: AppIcons.check,
                    isFullWidth: isNarrow,
                  );

                  if (isNarrow) {
                    return Column(
                      children: [
                        c1,
                        const SizedBox(height: 10),
                        c2,
                        const SizedBox(height: 10),
                        c3,
                      ],
                    );
                  }
                  return Row(
                    children: [
                      c1,
                      const SizedBox(width: 12),
                      c2,
                      const SizedBox(width: 12),
                      c3,
                    ],
                  );
                },
              ),
            ],
          ),
        ),

        const SizedBox(height: 24),

        // Detail Rincian per Karyawan Table
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text('Daftar Rincian Gaji Bersih per Pekerja', style: AppText.cardTitle),
                    Text('${slips.length} Karyawan Terdaftar', style: AppText.small),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 900),
                  child: DataTable(
                    headingRowColor: const WidgetStatePropertyAll(AppColors.tableHead),
                    headingTextStyle: AppText.tableHead,
                    columns: const [
                      DataColumn(label: Text('KARYAWAN')),
                      DataColumn(label: Text('DIVISI & SKEMA')),
                      DataColumn(label: Text('OUTPUT')),
                      DataColumn(label: Text('UPAH BORONG')),
                      DataColumn(label: Text('UPAH HARIAN')),
                      DataColumn(label: Text('KASBON')),
                      DataColumn(label: Text('DENDA')),
                      DataColumn(label: Text('GAJI BERSIH (THP)')),
                      DataColumn(label: Text('METODE')),
                    ],
                    rows: slips.map((s) {
                      return DataRow(
                        cells: [
                          DataCell(Text(s.karyawanNama, style: AppText.bodyStrong)),
                          DataCell(Text('${s.divisi.label} (${s.tipeGaji.label})', style: AppText.small)),
                          DataCell(Text('${s.totalPotongBagus} pcs', style: AppText.body)),
                          DataCell(Text(Fmt.rupiah(s.totalUpahBorong), style: AppText.body)),
                          DataCell(Text(Fmt.rupiah(s.totalUpahDasar), style: AppText.body)),
                          DataCell(Text('-${Fmt.rupiah(s.potonganKasbon)}', style: const TextStyle(color: AppColors.amber700, fontSize: 13))),
                          DataCell(Text('-${Fmt.rupiah(s.potonganDenda)}', style: const TextStyle(color: AppColors.rose700, fontSize: 13))),
                          DataCell(Text(Fmt.rupiah(s.thpBersih), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary, fontSize: 13.5))),
                          DataCell(Text(s.metodeBayar.label, style: AppText.tiny)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _paymentMethodCard({
    required String title,
    required int count,
    required int total,
    required Color color,
    required IconData icon,
    bool isFullWidth = false,
  }) {
    final card = Container(
      width: isFullWidth ? double.infinity : null,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, size: 16, color: color),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(fontWeight: FontWeight.w700, color: color, fontSize: 12.5),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              Fmt.rupiah(total),
              style: TextStyle(fontWeight: FontWeight.w800, fontSize: 16, color: color),
            ),
          ),
          const SizedBox(height: 4),
          Text('$count Karyawan', style: AppText.small),
        ],
      ),
    );

    if (isFullWidth) return card;
    return Expanded(child: card);
  }

  // ---------------------------------------------------------------- TAB 2: Produktivitas Bagian & Karyawan
  Widget _buildTabProductivity(List<Map<String, dynamic>> prodData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Laporan Produktivitas per Bagian / Divisi', style: AppText.cardTitle),
                        Text('Perbandingan output fisik per lembar kain dan efisiensi tenaga kerja.', style: AppText.small),
                      ],
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(AppIcons.export, size: 15),
                      label: const Text('Unduh CSV'),
                      onPressed: () async {
                        final csv = await CsvService.generateProductivityCsv(
                          dailyWork: widget.store.dailyWork,
                          employees: widget.store.employees,
                          periodLabel: widget.store.periodLabel,
                        );
                        await CsvService.shareCsv(csv, 'Produktivitas_${widget.store.periodLabel}.csv');
                      },
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 800),
                  child: DataTable(
                    headingRowColor: const WidgetStatePropertyAll(AppColors.tableHead),
                    headingTextStyle: AppText.tableHead,
                    columns: const [
                      DataColumn(label: Text('BAGIAN / DIVISI')),
                      DataColumn(label: Text('JUMLAH PEKERJA')),
                      DataColumn(label: Text('OUTPUT LOLOS (PCS)')),
                      DataColumn(label: Text('CACAT REWORK')),
                      DataColumn(label: Text('REJECT FATAL')),
                      DataColumn(label: Text('RATA-RATA / ORANG')),
                      DataColumn(label: Text('TOTAL UPAH TERSERAP')),
                    ],
                    rows: prodData.map((d) {
                      final totalPcs = d['totalPcs'] as int;
                      final workerCount = d['workerCount'] as int;
                      final rework = d['totalRework'] as int;
                      final reject = d['totalReject'] as int;
                      final wage = d['totalWage'] as int;
                      final avg = d['avgPcsPerWorker'] as int;

                      return DataRow(
                        cells: [
                          DataCell(Text(d['label'] as String, style: AppText.bodyStrong)),
                          DataCell(Text('$workerCount orang', style: AppText.body)),
                          DataCell(Text('$totalPcs pcs', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary))),
                          DataCell(Text('$rework pcs', style: TextStyle(color: rework > 0 ? AppColors.amber700 : AppColors.textMuted))),
                          DataCell(Text('$reject pcs', style: TextStyle(color: reject > 0 ? AppColors.rose700 : AppColors.textMuted))),
                          DataCell(Text('$avg pcs / org', style: AppText.body)),
                          DataCell(Text(Fmt.rupiah(wage), style: AppText.bodyStrong)),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- TAB 3: Saldo Kasbon Berjalan
  Widget _buildTabKasbon() {
    final loans = widget.store.loans;
    final totalLoans = loans.fold(0, (s, l) => s + l.amount);
    final totalRemaining = loans.fold(0, (s, l) => s + l.remaining);
    final totalDeductions = loans.fold(0, (s, l) => s + l.deduction);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Summary Cards
        LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 650;
            return GridView.count(
              crossAxisCount: isMobile ? 1 : 3,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              childAspectRatio: isMobile ? 3.4 : 2.0,
              children: [
                _metricBox('Total Kasbon Tersalurkan', Fmt.rupiah(totalLoans), AppColors.textStrong, AppColors.slate100),
                _metricBox('Target Cicilan / Minggu', Fmt.rupiah(totalDeductions), AppColors.amber700, AppColors.amber50),
                _metricBox('Sisa Saldo Kasbon Berjalan', Fmt.rupiah(totalRemaining), AppColors.rose700, AppColors.rose50),
              ],
            );
          },
        ),
        const SizedBox(height: 24),

        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Buku Besar Saldo Kasbon Karyawan', style: AppText.cardTitle),
                        Text('Riwayat pinjaman, cicilan potong gaji, dan sisa kewajiban berjalan.', style: AppText.small),
                      ],
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(AppIcons.export, size: 15),
                      label: const Text('Unduh CSV'),
                      onPressed: () async {
                        final csv = await CsvService.generateLoansCsv(
                          loans: widget.store.loans,
                          employees: widget.store.employees,
                        );
                        await CsvService.shareCsv(csv, 'Saldo_Kasbon_Karyawan_${widget.store.periodLabel}.csv');
                      },
                    ),
                  ],
                ),
              ),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: ConstrainedBox(
                  constraints: const BoxConstraints(minWidth: 800),
                  child: DataTable(
                    headingRowColor: const WidgetStatePropertyAll(AppColors.tableHead),
                    headingTextStyle: AppText.tableHead,
                    columns: const [
                      DataColumn(label: Text('ID BON')),
                      DataColumn(label: Text('NAMA KARYAWAN')),
                      DataColumn(label: Text('JUMLAH AWAL')),
                      DataColumn(label: Text('CICILAN / MINGGU')),
                      DataColumn(label: Text('SISA SALDO')),
                      DataColumn(label: Text('STATUS')),
                    ],
                    rows: loans.map((l) {
                      final emp = widget.store.employeeById(l.employeeId);
                      return DataRow(
                        cells: [
                          DataCell(Text(l.id, style: AppText.tiny)),
                          DataCell(Text(emp?.name ?? l.employeeId, style: AppText.bodyStrong)),
                          DataCell(Text(Fmt.rupiah(l.amount), style: AppText.body)),
                          DataCell(Text(Fmt.rupiah(l.deduction), style: AppText.body)),
                          DataCell(Text(Fmt.rupiah(l.remaining), style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.rose700))),
                          DataCell(
                            BadgePill(
                              label: l.isPaidOff ? 'Lunas' : 'Aktif Mencicil',
                              tone: l.isPaidOff ? BadgeTone.emerald : BadgeTone.amber,
                            ),
                          ),
                        ],
                      );
                    }).toList(),
                  ),
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ---------------------------------------------------------------- TAB 4: Laporan HPP Tenaga Kerja per Model
  Widget _buildTabHpp(List<Map<String, dynamic>> hppData) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppCard(
          padding: EdgeInsets.zero,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.all(16),
                child: Wrap(
                  spacing: 12,
                  runSpacing: 8,
                  alignment: WrapAlignment.spaceBetween,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Laporan Biaya Tenaga Kerja per Model (HPP Konveksi)', style: AppText.cardTitle),
                        Text('Total upah borongan yang dikeluarkan per produk dibagi total produksi.', style: AppText.small),
                      ],
                    ),
                    OutlinedButton.icon(
                      icon: const Icon(AppIcons.export, size: 15),
                      label: const Text('Unduh CSV'),
                      onPressed: () async {
                        final csv = await CsvService.generateHppCsv(
                          products: widget.store.products,
                          processes: widget.store.processes,
                          spkLots: widget.store.spkLots,
                          dailyWork: widget.store.dailyWork,
                        );
                        await CsvService.shareCsv(csv, 'Laporan_HPP_Model_${widget.store.periodLabel}.csv');
                      },
                    ),
                  ],
                ),
              ),
              ListView.separated(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: hppData.length,
                separatorBuilder: (_, _) => const Divider(height: 1),
                itemBuilder: (context, idx) {
                  final item = hppData[idx];
                  final p = item['product'] as ProdukModel;
                  final totalPcs = item['totalPcs'] as int;
                  final totalLaborCost = item['totalLaborCost'] as int;
                  final hppPerPcs = item['hppPerPcs'] as int;
                  final processes = item['processes'] as List<ProsesOperasiTarif>;

                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Wrap(
                          spacing: 12,
                          runSpacing: 8,
                          alignment: WrapAlignment.spaceBetween,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text('${p.kodeModel} - ${p.namaModel}', style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
                                const SizedBox(height: 2),
                                Text(p.deskripsi, style: AppText.small),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                              decoration: BoxDecoration(
                                color: AppColors.emerald50,
                                borderRadius: BorderRadius.circular(10),
                                border: Border.all(color: AppColors.emerald200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  const Text('HPP Upah per Potong:', style: TextStyle(fontSize: 11, color: AppColors.primary700)),
                                  Text(
                                    Fmt.rupiah(hppPerPcs),
                                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w800, color: AppColors.primary),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 20,
                          runSpacing: 8,
                          children: [
                            _subInfo('Total Produksi SPK', '$totalPcs potong'),
                            _subInfo('Total Biaya Upah Langsung', Fmt.rupiah(totalLaborCost)),
                            _subInfo('Jumlah Operasi Proses', '${processes.length} Tahap'),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          children: processes.map((pr) {
                            return Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: AppColors.slate100,
                                borderRadius: BorderRadius.circular(6),
                                border: Border.all(color: AppColors.borderStrong),
                              ),
                              child: Text(
                                '${pr.namaProses}: ${Fmt.rupiah(pr.tarifPerPotong)}',
                                style: const TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600),
                              ),
                            );
                          }).toList(),
                        ),
                      ],
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _subInfo(String title, String val) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: AppText.tiny),
        const SizedBox(height: 2),
        Text(val, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
      ],
    );
  }

  // ---------------------------------------------------------------- TAB 5: Ekspor Data Excel
  Widget _buildTabExportCenter(List<SlipGajiMingguan> slips) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Pusat Unduh File Laporan (.CSV / .XLSX)', style: AppText.sectionTitle),
        const SizedBox(height: 4),
        const Text('Seluruh file laporan diekspor dengan format UTF-8 BOM untuk kompatibilitas penuh dengan Microsoft Excel.', style: AppText.small),
        const SizedBox(height: 16),

        _exportTile(
          title: 'Laporan Rekap Gaji Mingguan',
          subtitle: 'Rincian penerimaan kotor, upah borongan, potongan kasbon, denda, dan upah bersih (THP).',
          icon: AppIcons.payroll,
          onDownload: () async {
            final csv = await CsvService.generateConvectionWeeklyPayrollCsv(
              slips: slips,
              periodLabel: widget.store.periodLabel,
            );
            await CsvService.shareCsv(csv, 'Rekap_Gaji_${widget.store.periodLabel}.csv');
          },
        ),
        const SizedBox(height: 12),

        _exportTile(
          title: 'Laporan Produktivitas per Pekerja & Bagian',
          subtitle: 'Daftar jumlah potong lolos QC, cacat rework, dan reject fatal per proses operasi.',
          icon: AppIcons.summary,
          onDownload: () async {
            final csv = await CsvService.generateProductivityCsv(
              dailyWork: widget.store.dailyWork,
              employees: widget.store.employees,
              periodLabel: widget.store.periodLabel,
            );
            await CsvService.shareCsv(csv, 'Produktivitas_${widget.store.periodLabel}.csv');
          },
        ),
        const SizedBox(height: 12),

        _exportTile(
          title: 'Laporan Saldo Kasbon Karyawan Berjalan',
          subtitle: 'Buku hutang karyawan, riwayat cicilan, dan sisa kewajiban aktif.',
          icon: AppIcons.reimbursement,
          onDownload: () async {
            final csv = await CsvService.generateLoansCsv(
              loans: widget.store.loans,
              employees: widget.store.employees,
            );
            await CsvService.shareCsv(csv, 'Saldo_Kasbon_${widget.store.periodLabel}.csv');
          },
        ),
        const SizedBox(height: 12),

        _exportTile(
          title: 'Laporan Biaya Tenaga Kerja (HPP) per Model',
          subtitle: 'Perhitungan HPP upah tenaga kerja per potong pakaian untuk penetapan harga jual.',
          icon: AppIcons.adjust,
          onDownload: () async {
            final csv = await CsvService.generateHppCsv(
              products: widget.store.products,
              processes: widget.store.processes,
              spkLots: widget.store.spkLots,
              dailyWork: widget.store.dailyWork,
            );
            await CsvService.shareCsv(csv, 'HPP_Tenaga_Kerja_${widget.store.periodLabel}.csv');
          },
        ),
      ],
    );
  }

  Widget _exportTile({
    required String title,
    required String subtitle,
    required IconData icon,
    required VoidCallback onDownload,
  }) {
    return AppCard(
      child: LayoutBuilder(
        builder: (context, constraints) {
          final isNarrow = constraints.maxWidth < 600;
          if (isNarrow) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: AppColors.emerald50,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Icon(icon, color: AppColors.primary, size: 22),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(title, style: AppText.bodyStrong),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(subtitle, style: AppText.small),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton.icon(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    icon: const Icon(AppIcons.export, size: 15),
                    label: const Text('Unduh .CSV'),
                    onPressed: onDownload,
                  ),
                ),
              ],
            );
          }
          return Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: AppColors.primary, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(title, style: AppText.bodyStrong),
                    const SizedBox(height: 2),
                    Text(subtitle, style: AppText.small),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                ),
                icon: const Icon(AppIcons.export, size: 15),
                label: const Text('Unduh .CSV'),
                onPressed: onDownload,
              ),
            ],
          );
        },
      ),
    );
  }

  Widget _metricBox(String title, String val, Color textC, Color bgC) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: bgC,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: textC.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            title,
            style: TextStyle(fontSize: 11.5, color: textC, fontWeight: FontWeight.w500),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 6),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(
              val,
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800, color: textC),
            ),
          ),
        ],
      ),
    );
  }
}

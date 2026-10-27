import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../widgets/app_card.dart';

class MandorPortalPage extends StatefulWidget {
  const MandorPortalPage({super.key, required this.store});

  final AppStore store;

  @override
  State<MandorPortalPage> createState() => _MandorPortalPageState();
}

class _MandorPortalPageState extends State<MandorPortalPage> {
  late String _selectedSpkId;
  late String _selectedKaryawanId;
  late String _selectedProsesId;

  final TextEditingController _qtyBagusCtrl = TextEditingController(text: '50');
  final TextEditingController _qtyReworkCtrl = TextEditingController(text: '0');
  final TextEditingController _qtyRejectCtrl = TextEditingController(text: '0');
  int _tabIndex = 0; // 0: Hasil Kerja, 1: Absensi & Lembur

  @override
  void initState() {
    super.initState();
    final spkLots = widget.store.spkLots;
    _selectedSpkId = spkLots.isNotEmpty ? spkLots.first.id : '';

    final mandorDiv = widget.store.currentUser.divisiMandor ?? DivisiBagian.jahit;
    final divisionEmps = widget.store.activeEmployees.where((e) => e.divisi == mandorDiv).toList();
    _selectedKaryawanId = divisionEmps.isNotEmpty ? divisionEmps.first.id : widget.store.activeEmployees.first.id;

    final divisionProcesses = widget.store.processes.where((p) => p.divisi == mandorDiv).toList();
    _selectedProsesId = divisionProcesses.isNotEmpty ? divisionProcesses.first.id : widget.store.processes.first.id;
  }

  @override
  void dispose() {
    _qtyBagusCtrl.dispose();
    _qtyReworkCtrl.dispose();
    _qtyRejectCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final mandorDiv = widget.store.currentUser.divisiMandor ?? DivisiBagian.jahit;
        final divisionEmps = widget.store.activeEmployees.where((e) => e.divisi == mandorDiv).toList();
        final divisionProcesses = widget.store.processes.where((p) => p.divisi == mandorDiv).toList();

        // Selected SPK & remaining quota
        final selectedSpk = widget.store.spkLots.firstWhere(
          (s) => s.id == _selectedSpkId,
          orElse: () => widget.store.spkLots.first,
        );
        final remainingQuota = widget.store.spkRemainingQuota(selectedSpk.id);

        // Daily work filtered to mandor's division
        final divisionEmpIds = divisionEmps.map((e) => e.id).toSet();
        final divisionWork = widget.store.dailyWork
            .where((w) => divisionEmpIds.contains(w.karyawanId))
            .toList();

        final totalPcsToday = divisionWork.fold(0, (s, w) => s + w.qtyBagus);
        final totalRework = divisionWork.fold(0, (s, w) => s + w.qtyRework);
        final unverifiedCount = divisionWork.where((w) => !w.isVerified).length;

        return SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 1000),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildMandorHeader(mandorDiv),
                  const SizedBox(height: 16),

                  // Mobile-First Metric Cards
                  _buildMandorMetrics(divisionEmps.length, totalPcsToday, totalRework, unverifiedCount),
                  const SizedBox(height: 20),

                  // Tab Switcher for Mandor: Hasil Kerja vs Absensi & Lembur
                  Container(
                    decoration: BoxDecoration(
                      color: AppColors.slate100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: Row(
                      children: [
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _tabIndex = 0),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _tabIndex == 0 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _tabIndex == 0
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Input Hasil Kerja (Pcs)',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _tabIndex == 0 ? AppColors.primary : AppColors.text2,
                                ),
                              ),
                            ),
                          ),
                        ),
                        Expanded(
                          child: InkWell(
                            onTap: () => setState(() => _tabIndex = 1),
                            borderRadius: BorderRadius.circular(10),
                            child: Container(
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              alignment: Alignment.center,
                              decoration: BoxDecoration(
                                color: _tabIndex == 1 ? Colors.white : Colors.transparent,
                                borderRadius: BorderRadius.circular(10),
                                boxShadow: _tabIndex == 1
                                    ? [
                                        BoxShadow(
                                          color: Colors.black.withValues(alpha: 0.05),
                                          blurRadius: 4,
                                          offset: const Offset(0, 1),
                                        ),
                                      ]
                                    : null,
                              ),
                              child: Text(
                                'Absensi & Lembur Divisi',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: _tabIndex == 1 ? AppColors.primary : AppColors.text2,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),

                  if (_tabIndex == 0) ...[
                    // Quick Field Input Form
                    _buildQuickInputForm(selectedSpk, remainingQuota, divisionEmps, divisionProcesses),
                    const SizedBox(height: 24),
                    // Today's Work List & Verification Lock
                    _buildTodayWorkList(divisionWork),
                  ] else ...[
                    // Division Attendance & Overtime Form
                    _buildDivisionAttendance(divisionEmps),
                  ],
                  const SizedBox(height: 36),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildMandorHeader(DivisiBagian mandorDiv) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.primary,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(AppIcons.process, color: Colors.white, size: 24),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Portal Mandor Lapangan: ${mandorDiv.label}',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Petugas: ${widget.store.currentUser.name} · Khusus input data divisi ${mandorDiv.label}',
                  style: const TextStyle(fontSize: 12, color: AppColors.emerald100),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMandorMetrics(int totalWorkers, int totalPcs, int totalRework, int unverified) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isMobile = constraints.maxWidth < 600;
        return GridView.count(
          crossAxisCount: isMobile ? 2 : 4,
          crossAxisSpacing: 10,
          mainAxisSpacing: 10,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          childAspectRatio: isMobile ? 1.5 : 1.9,
          children: [
            _mandorMetricTile('Pekerja Bagian', '$totalWorkers Orang', AppColors.primary),
            _mandorMetricTile('Total Potong Lolos', '$totalPcs pcs', AppColors.success),
            _mandorMetricTile('Cacat Rework', '$totalRework pcs', AppColors.amber700),
            _mandorMetricTile('Menunggu Kunci', '$unverified Batch', unverified > 0 ? AppColors.rose700 : AppColors.textMuted),
          ],
        );
      },
    );
  }

  Widget _mandorMetricTile(String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: AppColors.textMuted)),
          const SizedBox(height: 4),
          Text(value, style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _buildQuickInputForm(
    SpkLotPotong selectedSpk,
    int remainingQuota,
    List<Employee> divisionEmps,
    List<ProsesOperasiTarif> divisionProcesses,
  ) {
    // Current selected process rate
    final selectedProcess = divisionProcesses.firstWhere(
      (p) => p.id == _selectedProsesId,
      orElse: () => divisionProcesses.first,
    );

    final qtyBagus = int.tryParse(_qtyBagusCtrl.text) ?? 0;
    final estimatedBatchWage = qtyBagus * selectedProcess.tarifPerPotong;

    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Input Hasil Kerja Cepat', style: AppText.cardTitle),
                  Text('Pencatatan output fisik harian per pekerja.', style: AppText.small),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: remainingQuota > 0 ? AppColors.emerald50 : AppColors.rose50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Sisa Kuota: $remainingQuota pcs',
                  style: TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: remainingQuota > 0 ? AppColors.primary700 : AppColors.rose700,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // 1. Select SPK Lot
          DropdownButtonFormField<String>(
            initialValue: _selectedSpkId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Pilih SPK / Lot Potong',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            selectedItemBuilder: (context) {
              return widget.store.spkLots.map((s) {
                return Text(
                  '${s.nomorSpk} · ${s.modelNama}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }).toList();
            },
            items: widget.store.spkLots.map((s) {
              final quota = widget.store.spkRemainingQuota(s.id);
              return DropdownMenuItem(
                value: s.id,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '${s.nomorSpk} · ${s.modelNama}',
                      style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      'Target: ${s.realisasiPotong} pcs · Sisa: $quota pcs',
                      style: const TextStyle(fontSize: 11, color: AppColors.textMuted),
                    ),
                  ],
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedSpkId = val);
            },
          ),
          const SizedBox(height: 12),

          // 2. Select Worker (Filtered strictly to this division)
          DropdownButtonFormField<String>(
            initialValue: _selectedKaryawanId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Pilih Penjahit / Pekerja',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            selectedItemBuilder: (context) {
              return divisionEmps.map((e) {
                return Text(
                  '${e.name} (${e.id}) · ${e.tipeGaji.label}',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }).toList();
            },
            items: divisionEmps.map((e) {
              return DropdownMenuItem(
                value: e.id,
                child: Text(
                  '${e.name} (${e.id}) · ${e.tipeGaji.label}',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedKaryawanId = val);
            },
          ),
          const SizedBox(height: 12),

          // 3. Select Process / Operation
          DropdownButtonFormField<String>(
            initialValue: _selectedProsesId,
            isExpanded: true,
            decoration: const InputDecoration(
              labelText: 'Pilih Tahap Kerja / Operasi',
              border: OutlineInputBorder(),
              contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
            ),
            selectedItemBuilder: (context) {
              return divisionProcesses.map((p) {
                return Text(
                  '${p.namaProses} (${Fmt.rupiah(p.tarifPerPotong)}/pcs)',
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                );
              }).toList();
            },
            items: divisionProcesses.map((p) {
              return DropdownMenuItem(
                value: p.id,
                child: Text(
                  '${p.namaProses} · Tarif: ${Fmt.rupiah(p.tarifPerPotong)}/pcs',
                  overflow: TextOverflow.ellipsis,
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) setState(() => _selectedProsesId = val);
            },
          ),
          const SizedBox(height: 16),

          // 4. Quantities: Bagus, Rework, Reject Fatal (Adaptive Layout for Phone Screen)
          LayoutBuilder(
            builder: (context, constraints) {
              final isNarrow = constraints.maxWidth < 620;
              if (isNarrow) {
                return Column(
                  children: [
                    TextField(
                      controller: _qtyBagusCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Bagus (Lolos QC)',
                        suffixText: 'pcs',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                    const SizedBox(height: 10),
                    Row(
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _qtyReworkCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Rework (Bongkar)',
                              suffixText: 'pcs',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: TextField(
                            controller: _qtyRejectCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              labelText: 'Cacat Fatal',
                              suffixText: 'pcs',
                              border: OutlineInputBorder(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                );
              }
              return Row(
                children: [
                  Expanded(
                    flex: 2,
                    child: TextField(
                      controller: _qtyBagusCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Jumlah Bagus (Lolos QC)',
                        suffixText: 'pcs',
                        border: OutlineInputBorder(),
                      ),
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _qtyReworkCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Rework (Bongkar)',
                        suffixText: 'pcs',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: TextField(
                      controller: _qtyRejectCtrl,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Cacat Fatal',
                        suffixText: 'pcs',
                        border: OutlineInputBorder(),
                      ),
                    ),
                  ),
                ],
              );
            },
          ),
          const SizedBox(height: 14),

          // Real-time calculated wage preview banner
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppColors.slate100,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: AppColors.borderStrong),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Estimasi Hak Upah Input Ini:',
                  style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textStrong),
                ),
                Text(
                  Fmt.rupiah(estimatedBatchWage),
                  style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.primary),
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),

          // Submit Button (High-touch target)
          SizedBox(
            width: double.infinity,
            height: 48,
            child: ElevatedButton.icon(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
              icon: const Icon(AppIcons.checkCircle, size: 20),
              label: const Text(
                'Simpan Hasil Kerja Harian',
                style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
              ),
              onPressed: () => _submitDailyWork(selectedSpk),
            ),
          ),
        ],
      ),
    );
  }

  void _submitDailyWork(SpkLotPotong selectedSpk) {
    final qtyBagus = int.tryParse(_qtyBagusCtrl.text) ?? 0;
    final qtyRework = int.tryParse(_qtyReworkCtrl.text) ?? 0;
    final qtyReject = int.tryParse(_qtyRejectCtrl.text) ?? 0;

    if (qtyBagus <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Jumlah bagus harus lebih dari 0.')),
      );
      return;
    }

    try {
      widget.store.addHasilKerja(
        spkLotId: selectedSpk.id,
        tanggal: DateTime.now(),
        karyawanId: _selectedKaryawanId,
        prosesTarifId: _selectedProsesId,
        qtyBagus: qtyBagus,
        qtyRework: qtyRework,
        qtyRejectFatal: qtyReject,
      );

      _qtyBagusCtrl.text = '50';
      _qtyReworkCtrl.text = '0';
      _qtyRejectCtrl.text = '0';

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Hasil kerja berhasil disimpan dengan Price Snapshot permanen!')),
      );
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(backgroundColor: AppColors.rose700, content: Text(e.toString())),
      );
    }
  }

  Widget _buildTodayWorkList(List<HasilKerjaHarian> divisionWork) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Catatan Hasil Kerja Hari Ini', style: AppText.cardTitle),
                  Text('Daftar setoran jahitan yang siap diverifikasi mandor.', style: AppText.small),
                ],
              ),
              Text(
                '${divisionWork.length} Setoran',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (divisionWork.isEmpty)
            const Padding(
              padding: EdgeInsets.all(24),
              child: Center(
                child: Text('Belum ada input hasil kerja hari ini.', style: TextStyle(color: AppColors.textMuted)),
              ),
            )
          else
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: divisionWork.length,
              separatorBuilder: (_, _) => const Divider(height: 1),
              itemBuilder: (context, idx) {
                final w = divisionWork[idx];
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 10),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: w.isVerified ? AppColors.emerald50 : AppColors.amber50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          w.isVerified ? AppIcons.checkCircle : AppIcons.clock,
                          size: 16,
                          color: w.isVerified ? AppColors.primary700 : AppColors.amber700,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              '${w.karyawanNama} - ${w.namaProses}',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'SPK: ${w.nomorSpk} · ${w.qtyBagus} pcs bagus (@ ${Fmt.rupiah(w.snapshotTarif)})'
                              '${w.qtyRejectFatal > 0 ? ' · Cacat: ${w.qtyRejectFatal} pcs' : ''}',
                              style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                            ),
                          ],
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            Fmt.rupiah(w.upahBruto),
                            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13, color: AppColors.primary),
                          ),
                          if (!w.isVerified)
                            TextButton(
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                visualDensity: VisualDensity.compact,
                              ),
                              onPressed: () => widget.store.verifyDailyWork(w.id),
                              child: const Text('Kunci & Verifikasi', style: TextStyle(fontSize: 11, fontWeight: FontWeight.w700)),
                            )
                          else
                            const Text(
                              'Terverifikasi ✓',
                              style: TextStyle(fontSize: 11, color: AppColors.primary700, fontWeight: FontWeight.w600),
                            ),
                        ],
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

  Widget _buildDivisionAttendance(List<Employee> divisionEmps) {
    final today = DateTime.now();
    final records = widget.store.attendanceFor(today);

    return AppCard(
      child: Column(
        children: [
          Wrap(
            spacing: 12,
            runSpacing: 8,
            alignment: WrapAlignment.spaceBetween,
            crossAxisAlignment: WrapCrossAlignment.center,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Absensi & Jam Lembur Divisi', style: AppText.cardTitle),
                  Text('Tandai kehadiran & jam lembur harian pekerja.', style: AppText.small),
                ],
              ),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                icon: const Icon(AppIcons.check, size: 14),
                label: const Text('Semua Hadir'),
                onPressed: () {
                  for (final emp in divisionEmps) {
                    widget.store.setAttendance(emp.id, today, AttendanceStatus.present);
                  }
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Seluruh pekerja divisi ditandai hadir.')),
                  );
                },
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: divisionEmps.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final emp = divisionEmps[idx];
              final record = records.firstWhere(
                (r) => r.employeeId == emp.id,
                orElse: () => AttendanceRecord(
                  employeeId: emp.id,
                  day: Fmt.isoDay(today),
                  status: AttendanceStatus.present,
                ),
              );

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 10),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                emp.name,
                                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13.5),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                '${emp.id} · ${emp.tipeGaji.label}',
                                style: const TextStyle(fontSize: 11.5, color: AppColors.textMuted),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        // Lembur counter
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text('Lembur: ', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                            IconButton(
                              icon: const Icon(Icons.remove_circle_outline, size: 18),
                              onPressed: record.jamLembur > 0
                                  ? () {
                                      final newHours = (record.jamLembur - 1.0).clamp(0.0, 12.0);
                                      widget.store.setAttendance(emp.id, today, record.status, jamLembur: newHours);
                                    }
                                  : null,
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                            Text(
                              '${record.jamLembur.toStringAsFixed(0)} jam',
                              style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                            ),
                            IconButton(
                              icon: const Icon(Icons.add_circle_outline, size: 18),
                              onPressed: () {
                                final newHours = (record.jamLembur + 1.0).clamp(0.0, 12.0);
                                widget.store.setAttendance(emp.id, today, record.status, jamLembur: newHours);
                              },
                              visualDensity: VisualDensity.compact,
                              padding: EdgeInsets.zero,
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    // Large touch buttons for status: Hadir, Izin, Alfa
                    Row(
                      children: [
                        Expanded(
                          child: _attendanceChoiceChip(
                            label: 'Hadir',
                            isSelected: record.status == AttendanceStatus.present,
                            color: AppColors.primary,
                            onTap: () => widget.store.setAttendance(emp.id, today, AttendanceStatus.present, jamLembur: record.jamLembur),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _attendanceChoiceChip(
                            label: 'Izin',
                            isSelected: record.status == AttendanceStatus.leave || record.status == AttendanceStatus.sick,
                            color: AppColors.amber700,
                            onTap: () => widget.store.setAttendance(emp.id, today, AttendanceStatus.leave, jamLembur: 0.0),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: _attendanceChoiceChip(
                            label: 'Alpa',
                            isSelected: record.status == AttendanceStatus.absent,
                            color: AppColors.rose700,
                            onTap: () => widget.store.setAttendance(emp.id, today, AttendanceStatus.absent, jamLembur: 0.0),
                          ),
                        ),
                      ],
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

  Widget _attendanceChoiceChip({
    required String label,
    required bool isSelected,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8),
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: isSelected ? color : AppColors.slate100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? color : AppColors.borderStrong),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: isSelected ? Colors.white : AppColors.text2,
          ),
        ),
      ),
    );
  }
}

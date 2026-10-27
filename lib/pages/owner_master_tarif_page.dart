import 'package:flutter/material.dart';

import '../core/app_icons.dart';
import '../core/format.dart';
import '../core/theme.dart';
import '../data/app_store.dart';
import '../data/models.dart';
import '../widgets/app_card.dart';

class OwnerMasterTarifPage extends StatefulWidget {
  const OwnerMasterTarifPage({super.key, required this.store});

  final AppStore store;

  @override
  State<OwnerMasterTarifPage> createState() => _OwnerMasterTarifPageState();
}

class _OwnerMasterTarifPageState extends State<OwnerMasterTarifPage> {
  late String _selectedModelId;

  @override
  void initState() {
    super.initState();
    _selectedModelId = widget.store.products.first.id;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.store,
      builder: (context, _) {
        final products = widget.store.products;
        final selectedProduct = products.firstWhere(
          (p) => p.id == _selectedModelId,
          orElse: () => products.first,
        );

        final processes = widget.store.processes
            .where((p) => p.modelId == selectedProduct.id)
            .toList()
          ..sort((a, b) => a.urutanOperasi.compareTo(b.urutanOperasi));

        final totalLaborCost = processes.fold(0, (sum, p) => sum + p.tarifPerPotong);
        final spkList = widget.store.spkLots
            .where((s) => s.modelId == selectedProduct.id)
            .toList();

        return LayoutBuilder(
          builder: (context, constraints) {
            final isMobile = constraints.maxWidth < 768;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(
                horizontal: isMobile ? 16 : 24,
                vertical: isMobile ? 18 : 24,
              ),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 1280),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildHeader(isMobile),
                      const SizedBox(height: 20),

                      // Model Tabs Selector
                      _buildModelSelector(products),
                      const SizedBox(height: 20),

                      // Direct Labor Cost (HPP) Summary Banner
                      _buildHppCalculatorCard(selectedProduct, processes, totalLaborCost),
                      const SizedBox(height: 24),

                      // Master Operations & Piece Rates Table
                      _buildOperationsTable(selectedProduct, processes),
                      const SizedBox(height: 28),

                      // SPK Lots for this Model (Quota Monitoring)
                      _buildSpkQuotaOverview(spkList),
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

  Widget _buildHeader(bool isMobile) {
    return Wrap(
      spacing: 16,
      runSpacing: 12,
      alignment: WrapAlignment.spaceBetween,
      crossAxisAlignment: WrapCrossAlignment.center,
      children: [
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(AppIcons.adjust, color: AppColors.primary, size: 24),
                const SizedBox(width: 10),
                Text(
                  isMobile ? 'Master Tarif & HPP' : 'Master Tarif & Biaya Tenaga Kerja (HPP)',
                  style: isMobile ? AppText.pageTitle.copyWith(fontSize: 20) : AppText.pageTitle,
                ),
              ],
            ),
            const SizedBox(height: 4),
            const Text(
              'Eksklusif Pemilik (Owner): Atur tarif borongan & denda reject.',
              style: AppText.small,
            ),
          ],
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: AppColors.amber50,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: AppColors.amber200),
          ),
          child: const Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(AppIcons.lock, size: 14, color: AppColors.amber700),
              SizedBox(width: 6),
              Text(
                'Khusus Akun Pemilik',
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.amber700),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildModelSelector(List<ProdukModel> products) {
    return Wrap(
      spacing: 12,
      runSpacing: 8,
      children: products.map((p) {
        final isSelected = p.id == _selectedModelId;
        return ChoiceChip(
          label: Text(
            '${p.kodeModel} - ${p.namaModel}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
              color: isSelected ? Colors.white : AppColors.textStrong,
            ),
          ),
          selected: isSelected,
          selectedColor: AppColors.primary,
          backgroundColor: AppColors.surface,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
            side: BorderSide(color: isSelected ? AppColors.primary : AppColors.borderStrong),
          ),
          onSelected: (val) {
            if (val) setState(() => _selectedModelId = p.id);
          },
        );
      }).toList(),
    );
  }

  Widget _buildHppCalculatorCard(
    ProdukModel product,
    List<ProsesOperasiTarif> processes,
    int totalLaborCost,
  ) {
    const estimatedFabricCost = 28000; // Rp28.000 bahan kain & benang
    const estimatedAksesoris = 5000; // Rp5.000 kancing, resleting, plastik
    final totalHpp = totalLaborCost + estimatedFabricCost + estimatedAksesoris;
    const targetHargaJual = 75000; // Rp75.000 partai besar
    final profitPcs = targetHargaJual - totalHpp;
    final marginPercent = ((profitPcs / targetHargaJual) * 100).toStringAsFixed(1);

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
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Kalkulator HPP Tenaga Kerja Langsung: ${product.namaModel}', style: AppText.cardTitle),
                  const Text('Simulasi akumulasi biaya upah seluruh operasi per 1 potong pakaian.', style: AppText.small),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(color: AppColors.emerald50, borderRadius: BorderRadius.circular(8)),
                child: Text(
                  'Estimasi Margin: $marginPercent%',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w700, color: AppColors.primary700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          LayoutBuilder(
            builder: (context, constraints) {
              final isMobile = constraints.maxWidth < 768;
              return GridView.count(
                crossAxisCount: isMobile ? 2 : 4,
                crossAxisSpacing: 12,
                mainAxisSpacing: 12,
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                childAspectRatio: isMobile ? 1.6 : 2.1,
                children: [
                  _hppMetricBox('Total Upah Tenaga Kerja', Fmt.rupiah(totalLaborCost), '${processes.length} Tahap Operasi', AppColors.primary),
                  _hppMetricBox('Estimasi Bahan Baku', Fmt.rupiah(estimatedFabricCost), 'Kain Utama + Benang', AppColors.slate300),
                  _hppMetricBox('Total HPP Produksi', Fmt.rupiah(totalHpp), 'Bahan + Aksesoris + Upah', AppColors.amber700),
                  _hppMetricBox('Laba Bersih per Potong', Fmt.rupiah(profitPcs), 'Target Jual: ${Fmt.rupiah(targetHargaJual)}', AppColors.success),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _hppMetricBox(String title, String val, String subtitle, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(title, style: const TextStyle(fontSize: 11, color: AppColors.textMuted), maxLines: 1, overflow: TextOverflow.ellipsis),
          const SizedBox(height: 3),
          FittedBox(
            fit: BoxFit.scaleDown,
            alignment: Alignment.centerLeft,
            child: Text(val, style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w700, color: AppColors.textStrong)),
          ),
          const SizedBox(height: 2),
          Text(subtitle, style: TextStyle(fontSize: 10.5, color: color, fontWeight: FontWeight.w600), maxLines: 1, overflow: TextOverflow.ellipsis),
        ],
      ),
    );
  }

  Widget _buildOperationsTable(ProdukModel product, List<ProsesOperasiTarif> processes) {
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
                  Text('Rincian Tarif per Operasi Kerja', style: AppText.cardTitle),
                  Text('Tarif borongan yang berlaku untuk perhitungan upah karyawan.', style: AppText.small),
                ],
              ),
              Text(
                'Total: ${processes.length} Operasi',
                style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              columns: const [
                DataColumn(label: Text('Urutan', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Divisi Bagian', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Nama Operasi / Tahap Kerja', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Tarif per Potong (Rp)', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Denda Reject Fatal (Rp)', style: TextStyle(fontWeight: FontWeight.w600))),
                DataColumn(label: Text('Aksi', style: TextStyle(fontWeight: FontWeight.w600))),
              ],
              rows: processes.map((p) {
                return DataRow(
                  cells: [
                    DataCell(Text('#${p.urutanOperasi}', style: const TextStyle(fontWeight: FontWeight.w700))),
                    DataCell(Text(p.divisi.label)),
                    DataCell(Text(p.namaProses, style: const TextStyle(fontWeight: FontWeight.w600))),
                    DataCell(Text(Fmt.rupiah(p.tarifPerPotong), style: const TextStyle(color: AppColors.primary, fontWeight: FontWeight.w700))),
                    DataCell(Text(Fmt.rupiah(p.dendaRejectFatal), style: const TextStyle(color: AppColors.rose700))),
                    DataCell(
                      ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.slate100,
                          foregroundColor: AppColors.textStrong,
                          elevation: 0,
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(6)),
                        ),
                        icon: const Icon(AppIcons.edit, size: 14),
                        label: const Text('Ubah Tarif', style: TextStyle(fontSize: 11.5, fontWeight: FontWeight.w600)),
                        onPressed: () => _showEditRateDialog(p),
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

  Widget _buildSpkQuotaOverview(List<SpkLotPotong> spkList) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('Surat Perintah Kerja (SPK) & Kuota Potong', style: AppText.cardTitle),
          const SizedBox(height: 4),
          const Text(
            'Memonitor kuota fisik kain potong agar tidak terjadi klaim jahit siluman (Phantom Claims).',
            style: AppText.small,
          ),
          const SizedBox(height: 16),
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: spkList.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, idx) {
              final spk = spkList[idx];
              final used = widget.store.spkTotalClaims(spk.id);
              final remaining = widget.store.spkRemainingQuota(spk.id);
              final progress = spk.realisasiPotong > 0 ? (used / spk.realisasiPotong).clamp(0.0, 1.0) : 0.0;

              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 12),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(color: AppColors.slate100, borderRadius: BorderRadius.circular(8)),
                      child: const Icon(AppIcons.fileText, size: 18, color: AppColors.primary),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(spk.nomorSpk, style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13)),
                              const SizedBox(width: 8),
                              Text('(${Fmt.date(spk.tanggalPotong)})', style: const TextStyle(fontSize: 12, color: AppColors.textMuted)),
                            ],
                          ),
                          const SizedBox(height: 6),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(4),
                            child: LinearProgressIndicator(
                              value: progress,
                              backgroundColor: AppColors.slate100,
                              valueColor: AlwaysStoppedAnimation<Color>(
                                remaining == 0 ? AppColors.success : AppColors.primary,
                              ),
                              minHeight: 6,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 20),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          'Klaim: $used / ${spk.realisasiPotong} pcs',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 13),
                        ),
                        Text(
                          remaining == 0 ? 'Kuota Selesai Penuh' : 'Sisa kuota: $remaining pcs',
                          style: TextStyle(
                            fontSize: 11.5,
                            fontWeight: FontWeight.w600,
                            color: remaining == 0 ? AppColors.success : AppColors.amber700,
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

  void _showEditRateDialog(ProsesOperasiTarif proses) {
    final tarifCtrl = TextEditingController(text: proses.tarifPerPotong.toString());
    final dendaCtrl = TextEditingController(text: proses.dendaRejectFatal.toString());

    showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Ubah Tarif: ${proses.namaProses}'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Perhatian: Perubahan tarif hanya berlaku untuk input pekerjaan baru (Price Snapshot). Histori rekap minggu lampau tidak akan berubah.',
                style: TextStyle(fontSize: 12, color: AppColors.textMuted),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: tarifCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Tarif per Potong (Rp)',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: dendaCtrl,
                keyboardType: TextInputType.number,
                decoration: const InputDecoration(
                  labelText: 'Denda Reject Fatal (Rp)',
                  prefixText: 'Rp ',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Batal'),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
              onPressed: () {
                final newRate = int.tryParse(tarifCtrl.text) ?? proses.tarifPerPotong;
                final newDenda = int.tryParse(dendaCtrl.text) ?? proses.dendaRejectFatal;
                widget.store.updateProsesTarif(
                  proses.id,
                  newTarifPerPotong: newRate,
                  newDendaRejectFatal: newDenda,
                );
                Navigator.of(context).pop();
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('Tarif ${proses.namaProses} berhasil diperbarui menjadi ${Fmt.rupiah(newRate)}')),
                );
              },
              child: const Text('Simpan Tarif Baru'),
            ),
          ],
        );
      },
    );
  }
}

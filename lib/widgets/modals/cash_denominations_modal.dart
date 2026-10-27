import 'package:flutter/material.dart';

import '../../core/app_icons.dart';
import '../../core/format.dart';
import '../../core/theme.dart';
import '../../data/app_store.dart';

class CashDenominationsModal extends StatelessWidget {
  const CashDenominationsModal({super.key, required this.store});

  final AppStore store;

  static Future<void> show(BuildContext context, AppStore store) {
    return showDialog<void>(
      context: context,
      builder: (context) => CashDenominationsModal(store: store),
    );
  }

  @override
  Widget build(BuildContext context) {
    final denom = store.calculateCashDenominations();

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Expanded(
                    child: Row(
                      children: [
                        Icon(AppIcons.payroll, color: AppColors.primary, size: 22),
                        SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            'Pecahan Uang Amplop',
                            style: AppText.cardTitle,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(AppIcons.close, size: 18),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              const Text(
                'Rincian kebutuhan lembar uang kertas untuk penarikan bank amplop gaji karyawan.',
                style: AppText.small,
              ),
              const SizedBox(height: 16),

              // Total Cash Needed
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: AppColors.emerald50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppColors.emerald200),
                ),
                child: Row(
                  children: [
                    const Expanded(
                      child: Text(
                        'Total Penarikan Kas Tunai:',
                        style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AppColors.primary700),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      alignment: Alignment.centerRight,
                      child: Text(
                        Fmt.rupiah(denom.totalNominal),
                        style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w800, color: AppColors.primaryDark),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Breakdown Table
              Table(
                columnWidths: const {
                  0: FlexColumnWidth(2),
                  1: FlexColumnWidth(1.5),
                  2: FlexColumnWidth(2),
                },
                children: [
                  _tableRow('Pecahan Uang', 'Jumlah Lembar', 'Subtotal', isHeader: true),
                  _tableRow('Rp 100.000', '${denom.rp100k} Lembar', Fmt.rupiah(denom.rp100k * 100000)),
                  _tableRow('Rp 50.000', '${denom.rp50k} Lembar', Fmt.rupiah(denom.rp50k * 50000)),
                  _tableRow('Rp 20.000', '${denom.rp20k} Lembar', Fmt.rupiah(denom.rp20k * 20000)),
                  _tableRow('Rp 10.000', '${denom.rp10k} Lembar', Fmt.rupiah(denom.rp10k * 10000)),
                  _tableRow('Rp 5.000', '${denom.rp5k} Lembar', Fmt.rupiah(denom.rp5k * 5000)),
                  _tableRow('Rp 2.000', '${denom.rp2k} Lembar', Fmt.rupiah(denom.rp2k * 2000)),
                  _tableRow('Rp 1.000', '${denom.rp1k} Lembar', Fmt.rupiah(denom.rp1k * 1000)),
                ],
              ),
              const SizedBox(height: 20),

              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  icon: const Icon(AppIcons.print, size: 16),
                  label: const Text('Cetak Lembar Penarikan Bank', style: TextStyle(fontWeight: FontWeight.w600)),
                  onPressed: () {
                    Navigator.of(context).pop();
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Rincian penarikan bank siap dicetak / disalin.')),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  TableRow _tableRow(String col1, String col2, String col3, {bool isHeader = false}) {
    return TableRow(
      decoration: BoxDecoration(
        color: isHeader ? AppColors.slate100 : Colors.transparent,
        border: const Border(bottom: BorderSide(color: AppColors.border, width: 0.8)),
      ),
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Text(
            col1,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isHeader ? FontWeight.w700 : FontWeight.w600,
              color: isHeader ? AppColors.textStrong : AppColors.text,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Text(
            col2,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isHeader ? FontWeight.w700 : FontWeight.w500,
              color: isHeader ? AppColors.textStrong : AppColors.primary700,
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 6),
          child: Text(
            col3,
            textAlign: TextAlign.end,
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: isHeader ? FontWeight.w700 : FontWeight.w600,
              color: isHeader ? AppColors.textStrong : AppColors.textStrong,
            ),
          ),
        ),
      ],
    );
  }
}

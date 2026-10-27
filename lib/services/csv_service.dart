import 'dart:convert';
import 'dart:io';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../data/models.dart';

abstract final class CsvService {
  /// Exports payroll lines to CSV formatted with UTF-8 BOM for Microsoft Excel.
  static Future<String> generatePayrollCsv({
    required List<PayrollLine> lines,
    required String periodLabel,
  }) async {
    final buffer = StringBuffer();

    // Excel UTF-8 BOM
    buffer.write('\uFEFF');

    // CSV Header
    buffer.writeln(
      'ID;Nama;Departemen;Jabatan;Gaji Pokok;Tunjangan;BPJS Kesehatan;BPJS Ketenagakerjaan;PPh 21;Potongan Bon;Potongan Lain;Total Potongan;Gaji Bersih;Status',
    );

    for (final l in lines) {
      final e = l.employee;
      buffer.writeln([
        _escape(e.id),
        _escape(e.name),
        _escape(e.department),
        _escape(e.position),
        e.baseSalary,
        e.allowance,
        e.bpjsKesehatan,
        e.bpjsKetenagakerjaan,
        e.pph21,
        l.loanDeduction,
        e.otherDeduction,
        l.deduction,
        l.net,
        _escape(l.status.label),
      ].join(';'));
    }

    return buffer.toString();
  }

  /// Exports convection weekly payroll slips to CSV formatted with UTF-8 BOM for Microsoft Excel.
  static Future<String> generateConvectionWeeklyPayrollCsv({
    required List<SlipGajiMingguan> slips,
    required String periodLabel,
  }) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    buffer.writeln(
      'No Slip;ID Karyawan;Nama Karyawan;Divisi;Tipe Gaji;Hari Hadir;Total Potong (Pcs);Upah Dasar Harian;Upah Borongan;Lembur;Bonus & Tunjangan;Potongan Kasbon;Denda Reject;Total Diterima (THP);Metode Bayar;Status',
    );

    for (final s in slips) {
      buffer.writeln([
        _escape(s.nomorSlipResmi ?? s.id),
        _escape(s.karyawanId),
        _escape(s.karyawanNama),
        _escape(s.divisi.label),
        _escape(s.tipeGaji.label),
        s.totalHariHadir,
        s.totalPotongBagus,
        s.totalUpahDasar,
        s.totalUpahBorong,
        s.totalLembur,
        s.totalBonus,
        s.potonganKasbon,
        s.potonganDenda,
        s.thpBersih,
        _escape(s.metodeBayar.label),
        s.statusBayar ? 'Lunas' : 'Draft',
      ].join(';'));
    }

    return buffer.toString();
  }

  /// Exports productivity records to CSV
  static Future<String> generateProductivityCsv({
    required List<HasilKerjaHarian> dailyWork,
    required List<Employee> employees,
    required String periodLabel,
  }) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    buffer.writeln('ID Karyawan;Nama Karyawan;Divisi;SPK;Proses Operasi;Qty Bagus (Pcs);Qty Rework;Qty Reject Fatal;Tarif Snapshot;Total Upah;Denda');

    for (final w in dailyWork) {
      final emp = employees.firstWhere((e) => e.id == w.karyawanId, orElse: () => employees.first);
      buffer.writeln([
        _escape(w.karyawanId),
        _escape(w.karyawanNama),
        _escape(emp.divisi.label),
        _escape(w.nomorSpk),
        _escape(w.namaProses),
        w.qtyBagus,
        w.qtyRework,
        w.qtyRejectFatal,
        w.snapshotTarif,
        w.upahBruto,
        w.totalDenda,
      ].join(';'));
    }

    return buffer.toString();
  }

  /// Exports HPP direct labor cost report to CSV
  static Future<String> generateHppCsv({
    required List<ProdukModel> products,
    required List<ProsesOperasiTarif> processes,
    required List<SpkLotPotong> spkLots,
    required List<HasilKerjaHarian> dailyWork,
  }) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    buffer.writeln('Kode Model;Nama Model;Realisasi Potong (Pcs);Total Biaya Tenaga Kerja (Rp);HPP Upah per Potong (Rp);Jumlah Operasi Proses');

    for (final p in products) {
      final modelSpks = spkLots.where((s) => s.modelId == p.id).toList();
      final totalPcs = modelSpks.fold(0, (s, spk) => s + spk.realisasiPotong);
      final modelProcesses = processes.where((pr) => pr.modelId == p.id).toList();
      final sumTarifOperasi = modelProcesses.fold(0, (s, pr) => s + pr.tarifPerPotong);
      final totalLaborCost = totalPcs * sumTarifOperasi;
      final hppPerPcs = totalPcs > 0 ? (totalLaborCost / totalPcs).round() : sumTarifOperasi;

      buffer.writeln([
        _escape(p.kodeModel),
        _escape(p.namaModel),
        totalPcs,
        totalLaborCost,
        hppPerPcs,
        modelProcesses.length,
      ].join(';'));
    }

    return buffer.toString();
  }

  /// Exports loan records to CSV
  static Future<String> generateLoansCsv({
    required List<Loan> loans,
    required List<Employee> employees,
  }) async {
    final buffer = StringBuffer();
    buffer.write('\uFEFF');
    buffer.writeln('ID Bon;ID Karyawan;Nama Karyawan;Departemen;Jumlah Bon;Potongan;Sisa Hutang;Status;Sinkron Payroll');

    for (final loan in loans) {
      final emp = employees.firstWhere(
        (e) => e.id == loan.employeeId,
        orElse: () => Employee(
          id: loan.employeeId,
          name: loan.employeeId,
          department: '-',
          position: '-',
          email: '',
          phone: '',
          joinDate: DateTime.now(),
          baseSalary: 0,
          allowance: 0,
          bpjsKesehatan: 0,
          bpjsKetenagakerjaan: 0,
          pph21: 0,
        ),
      );

      buffer.writeln([
        _escape(loan.id),
        _escape(loan.employeeId),
        _escape(emp.name),
        _escape(emp.department),
        loan.amount,
        loan.deduction,
        loan.remaining,
        _escape(loan.statusLabel),
        loan.syncToPayroll ? 'Ya' : 'Tidak',
      ].join(';'));
    }

    return buffer.toString();
  }

  static Future<void> shareCsv(String csvContent, String filename) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$filename');
    await file.writeAsString(csvContent, encoding: utf8);

    final params = ShareParams(
      files: [XFile(file.path)],
      subject: 'Ekspor Data $filename',
    );
    await SharePlus.instance.share(params);
  }

  static String _escape(String field) {
    if (field.contains(';') || field.contains('"') || field.contains('\n')) {
      return '"${field.replaceAll('"', '""')}"';
    }
    return field;
  }
}

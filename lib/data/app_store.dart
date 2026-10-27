import 'dart:async';
import 'dart:convert';
import 'dart:math' as math;

import 'package:flutter/foundation.dart';

import '../core/format.dart';
import 'models.dart';
import 'secure_vault.dart';
import 'seed.dart';

class ValidationException implements Exception {
  const ValidationException(this.message);
  final String message;
  @override
  String toString() => message;
}

@immutable
class PayrollTotals {
  const PayrollTotals({
    required this.base,
    required this.allowance,
    required this.deduction,
    required this.count,
    required this.paidCount,
    required this.readyCount,
    required this.reviewCount,
    required this.paidAmount,
    required this.readyAmount,
    required this.reviewAmount,
    required this.departments,
  });

  final int base;
  final int allowance;
  final int deduction;
  final int count;
  final int paidCount;
  final int readyCount;
  final int reviewCount;
  final int paidAmount;
  final int readyAmount;
  final int reviewAmount;
  final int departments;

  int get gross => base + allowance;
  int get net => gross - deduction;
  int get unpaidAmount => readyAmount + reviewAmount;
  double get paidRatio => count == 0 ? 0 : paidCount / count;
  double get baseRatio => gross == 0 ? 0 : base / gross;
  double get allowanceRatio => gross == 0 ? 0 : allowance / gross;
}

/// Cash denomination calculator for envelope payroll
@immutable
class DenominasiUang {
  const DenominasiUang({
    required this.rp100k,
    required this.rp50k,
    required this.rp20k,
    required this.rp10k,
    required this.rp5k,
    required this.rp2k,
    required this.rp1k,
    required this.totalNominal,
  });

  final int rp100k;
  final int rp50k;
  final int rp20k;
  final int rp10k;
  final int rp5k;
  final int rp2k;
  final int rp1k;
  final int totalNominal;
}

class AppStore extends ChangeNotifier {
  AppStore(this._vault);

  static const _storageKey = 'payrole.data.convection.v2';
  static const _schemaVersion = 2;
  static const maxMoney = 10000000000;
  static const _maxAudit = 500;

  final SecureVault _vault;
  Timer? _saveTimer;

  bool _ready = false;
  bool get isReady => _ready;

  // Active User & Session (5 Isolated Role Views)
  List<UserAccount> _users = Seed.users();
  late UserAccount _currentUser;

  // Convection Domain State
  List<ProdukModel> _products = Seed.products();
  List<SpkLotPotong> _spkLots = Seed.spkLots();
  List<ProsesOperasiTarif> _processes = Seed.processes();
  List<HasilKerjaHarian> _dailyWork = Seed.dailyWork();
  List<RekapMingguan> _weeklyRecaps = Seed.weeklyRecaps();
  List<SlipGajiMingguan> _slips = [];

  // Core State
  List<Employee> _employees = Seed.employees();
  List<Loan> _loans = Seed.loans();
  List<AttendanceRecord> _attendance = [];
  List<Reimbursement> _reimbursements = [];
  List<AuditEntry> _audit = Seed.auditLogs();
  AppSettings _settings = const AppSettings();
  int _periodYear = Seed.periodYear;
  int _periodMonth = Seed.periodMonth;
  DateTime _lastUpdated = Seed.lastUpdated;

  // ------------------------------------------------------------------ Getters
  UserAccount get currentUser => _currentUser;
  List<UserAccount> get users => List.unmodifiable(_users);

  List<ProdukModel> get products => List.unmodifiable(_products);
  List<SpkLotPotong> get spkLots => List.unmodifiable(_spkLots);
  List<ProsesOperasiTarif> get processes => List.unmodifiable(_processes);
  List<HasilKerjaHarian> get dailyWork => List.unmodifiable(_dailyWork);
  List<RekapMingguan> get weeklyRecaps => List.unmodifiable(_weeklyRecaps);
  List<SlipGajiMingguan> get slips => List.unmodifiable(_slips);

  List<Employee> get employees => List.unmodifiable(_employees);
  List<Employee> get activeEmployees =>
      _employees.where((e) => e.active).toList(growable: false);
  List<Loan> get loans => List.unmodifiable(_loans);
  List<Reimbursement> get reimbursements => List.unmodifiable(_reimbursements);
  List<AuditEntry> get audit => List.unmodifiable(_audit);
  AppSettings get settings => _settings;
  DateTime get lastUpdated => _lastUpdated;
  int get periodYear => _periodYear;
  int get periodMonth => _periodMonth;

  String get periodLabel => 'Minggu 43 (19 - 24 Okt 2026)';
  DateTime get periodStart => DateTime(_periodYear, _periodMonth, 19);
  DateTime get periodEnd => DateTime(_periodYear, _periodMonth, 24);
  DateTime get payday => DateTime(_periodYear, _periodMonth, 24);

  RekapMingguan get activeRecap => _weeklyRecaps.firstWhere(
        (r) => r.kodePeriode == 'PERIODE-2026-W43',
        orElse: () => _weeklyRecaps.first,
      );

  // ---------------------------------------------------------------- Role Switcher
  void switchRole(UserRole role) {
    final matched = _users.firstWhere(
      (u) => u.role == role,
      orElse: () => _users.first,
    );
    _currentUser = matched;
    _commit(
      'ROLE_SWITCH',
      'Beralih ke akun ${matched.name} (${matched.role.label})',
    );
  }

  void switchUser(UserAccount user) {
    _currentUser = user;
    _commit(
      'USER_SWITCH',
      'Login aktif: ${user.name} (${user.role.label})',
    );
  }

  // ---------------------------------------------------------------- SPK Lot Quota Guard
  int spkTotalClaims(String spkLotId) {
    return _dailyWork
        .where((w) => w.spkLotId == spkLotId)
        .fold(0, (sum, w) => sum + w.qtyBagus + w.qtyRework + w.qtyRejectFatal);
  }

  int spkRemainingQuota(String spkLotId) {
    final spk = _spkLots.firstWhere((s) => s.id == spkLotId,
        orElse: () => throw const ValidationException('SPK Lot tidak ditemukan.'));
    final used = spkTotalClaims(spkLotId);
    return math.max(0, spk.realisasiPotong - used);
  }

  // ---------------------------------------------------------------- Daily Work & Price Snapshot
  HasilKerjaHarian addHasilKerja({
    required String spkLotId,
    required DateTime tanggal,
    required String karyawanId,
    required String prosesTarifId,
    required int qtyBagus,
    int qtyRework = 0,
    int qtyRejectFatal = 0,
  }) {
    // 1. Validate permissions
    if (activeRecap.isLocked) {
      throw const ValidationException(
          'Periode ini sudah Tutup Minggu (LOCKED). Data tidak bisa ditambah.');
    }

    final emp = _require(karyawanId);
    final spk = _spkLots.firstWhere((s) => s.id == spkLotId,
        orElse: () => throw const ValidationException('SPK Lot tidak ditemukan.'));
    final proses = _processes.firstWhere((p) => p.id == prosesTarifId,
        orElse: () => throw const ValidationException('Tarif proses tidak ditemukan.'));

    // 2. Division check for Mandor
    if (_currentUser.role == UserRole.mandor && _currentUser.divisiMandor != null) {
      if (emp.divisi != _currentUser.divisiMandor) {
        throw ValidationException(
            'Akses ditolak: Mandor ${_currentUser.divisiMandor!.label} hanya dapat menginput karyawan divisinya sendiri!');
      }
    }

    // 3. SPK Quota Guard (Anti-Phantom Output)
    final totalNewPieces = qtyBagus + qtyRework + qtyRejectFatal;
    final remaining = spkRemainingQuota(spkLotId);
    if (totalNewPieces > remaining) {
      throw ValidationException(
          'Klaim $totalNewPieces potong melebihi sisa fisik potong SPK ${spk.nomorSpk} (Sisa: $remaining potong)!');
    }

    // 4. Price Snapshot Architecture (Lock rates at time of entry)
    final newId = _nextId('HK', _dailyWork.map((w) => w.id));
    final work = HasilKerjaHarian(
      id: newId,
      spkLotId: spkLotId,
      nomorSpk: spk.nomorSpk,
      tanggal: tanggal,
      karyawanId: karyawanId,
      karyawanNama: emp.name,
      prosesTarifId: prosesTarifId,
      namaProses: proses.namaProses,
      qtyBagus: qtyBagus,
      qtyRework: qtyRework,
      qtyRejectFatal: qtyRejectFatal,
      snapshotTarif: proses.tarifPerPotong,
      snapshotDenda: proses.dendaRejectFatal,
      isVerified: _currentUser.role == UserRole.mandor || _currentUser.role == UserRole.superAdmin,
      verifiedByUser: _currentUser.name,
      verifiedAt: DateTime.now(),
    );

    _dailyWork.insert(0, work);
    _commit(
      'WORK_RECORDED',
      'Input ${emp.name}: $qtyBagus pcs ${proses.namaProses} @ Rp${proses.tarifPerPotong} (SPK ${spk.nomorSpk})',
    );
    return work;
  }

  void verifyDailyWork(String workId) {
    final idx = _dailyWork.indexWhere((w) => w.id == workId);
    if (idx < 0) return;
    final w = _dailyWork[idx];
    _dailyWork[idx] = w.copyWith(
      isVerified: true,
      verifiedByUser: _currentUser.name,
      verifiedAt: DateTime.now(),
    );
    _commit('WORK_VERIFIED', 'Verifikasi hasil kerja ${w.karyawanNama} (${w.qtyBagus} pcs)');
  }

  // ---------------------------------------------------------------- Master Tarif (Exclusive Pemilik)
  void updateProsesTarif(
    String prosesId, {
    required int newTarifPerPotong,
    required int newDendaRejectFatal,
  }) {
    if (_currentUser.role != UserRole.pemilik && _currentUser.role != UserRole.superAdmin) {
      throw const ValidationException(
          'Akses ditolak: Hanya Pemilik (Owner) yang berwenang menambah atau mengubah tarif proses!');
    }

    final idx = _processes.indexWhere((p) => p.id == prosesId);
    if (idx < 0) throw const ValidationException('Proses tarif tidak ditemukan.');

    final old = _processes[idx];
    _processes[idx] = old.copyWith(
      tarifPerPotong: newTarifPerPotong,
      dendaRejectFatal: newDendaRejectFatal,
    );

    _commit(
      'TARIF_UPDATED',
      'Tarif ${old.namaProses}: Rp${old.tarifPerPotong} → Rp$newTarifPerPotong (Denda: Rp$newDendaRejectFatal)',
    );
  }

  // ---------------------------------------------------------------- 4-Stage State Machine Penggajian
  void mandorSubmitWeeklyVerification(String rekapId) {
    if (_currentUser.role != UserRole.mandor && _currentUser.role != UserRole.superAdmin) {
      throw const ValidationException('Hanya Mandor yang berwenang memverifikasi data lapangan.');
    }

    final idx = _weeklyRecaps.indexWhere((r) => r.id == rekapId);
    if (idx < 0) throw const ValidationException('Rekap mingguan tidak ditemukan.');

    _weeklyRecaps[idx] = _weeklyRecaps[idx].copyWith(
      status: StatusRekap.diverifikasiMandor,
      verifiedByUser: _currentUser.name,
      verifiedAt: DateTime.now(),
    );

    _commit('PAYROLL_VERIFIED_BY_MANDOR', 'Rekap minggu ${weeklyRecaps[idx].kodePeriode} diverifikasi Mandor');
  }

  void ownerApproveWeeklyPayroll(String rekapId) {
    if (_currentUser.role != UserRole.pemilik && _currentUser.role != UserRole.superAdmin) {
      throw const ValidationException(
          'Akses ditolak: Hanya Pemilik (Owner) yang berwenang menyetujui pencairan gaji mingguan!');
    }

    final idx = _weeklyRecaps.indexWhere((r) => r.id == rekapId);
    if (idx < 0) throw const ValidationException('Rekap mingguan tidak ditemukan.');

    final r = _weeklyRecaps[idx];
    if (r.status != StatusRekap.diverifikasiMandor && r.status != StatusRekap.draft) {
      throw const ValidationException('Status rekap tidak valid untuk persetujuan.');
    }

    _weeklyRecaps[idx] = r.copyWith(
      status: StatusRekap.disetujuiPemilik,
      approvedByUser: _currentUser.name,
      approvedAt: DateTime.now(),
    );

    _commit('PAYROLL_APPROVED_BY_OWNER', 'Rekap ${r.kodePeriode} disetujui Pemilik (Siap Dibayarkan)');
  }

  void ownerUnlockPeriod(String rekapId, String reason) {
    if (_currentUser.role != UserRole.pemilik && _currentUser.role != UserRole.superAdmin) {
      throw const ValidationException('Hanya Pemilik yang berwenang membuka kunci Tutup Minggu!');
    }

    if (reason.trim().length < 5) {
      throw const ValidationException('Alasan buka kunci periode wajib diisi (minimal 5 karakter)!');
    }

    final idx = _weeklyRecaps.indexWhere((r) => r.id == rekapId);
    if (idx < 0) throw const ValidationException('Rekap mingguan tidak ditemukan.');

    final r = _weeklyRecaps[idx];
    _weeklyRecaps[idx] = r.copyWith(
      isLocked: false,
      status: StatusRekap.draft,
    );

    // Unmark employees
    for (var i = 0; i < _employees.length; i++) {
      if (_employees[i].status == PayrollStatus.paid) {
        _employees[i] = _employees[i].copyWith(status: PayrollStatus.review);
      }
    }

    _commit('PERIOD_UNLOCKED', 'Buka kunci periode ${r.kodePeriode}. Alasan: $reason');
  }

  void financeDisburseWeeklyPayroll(String rekapId) {
    final idx = _weeklyRecaps.indexWhere((r) => r.id == rekapId);
    if (idx < 0) throw const ValidationException('Rekap mingguan tidak ditemukan.');

    final r = _weeklyRecaps[idx];
    if (r.status != StatusRekap.disetujuiPemilik) {
      throw const ValidationException(
          'Gaji belum disetujui Pemilik! Admin Keuangan dilarang mencairkan sebelum ada persetujuan resmi.');
    }

    // 1. Calculate and disburse slips for all active employees
    final generatedSlips = <SlipGajiMingguan>[];

    for (final emp in activeEmployees) {
      final slip = calculateSlipForEmployee(emp, applyLoanDeduction: true, rekap: r);
      generatedSlips.add(slip.copyWith(statusBayar: true));

      _replaceEmployee(emp.copyWith(
        status: PayrollStatus.paid,
        paidAt: DateTime.now(),
      ));
    }

    _slips = generatedSlips;
    _weeklyRecaps[idx] = r.copyWith(
      status: StatusRekap.dibayar,
      isLocked: true,
      paidByUser: _currentUser.name,
      paidAt: DateTime.now(),
    );

    final totalDisbursed = generatedSlips.fold(0, (s, slip) => s + slip.thpBersih);
    _commit(
      'PAYROLL_PAID',
      'Gaji mingguan ${r.kodePeriode} dicairkan: ${generatedSlips.length} karyawan · ${Fmt.rupiah(totalDisbursed)} (Tutup Minggu Terkunci)',
    );
  }

  // ---------------------------------------------------------------- Rumus Inti & Perhitungan Real-Time
  SlipGajiMingguan calculateSlipForEmployee(
    Employee emp, {
    bool applyLoanDeduction = false,
    RekapMingguan? rekap,
  }) {
    final r = rekap ?? activeRecap;

    // Piece-rate calculation from daily work
    final works = _dailyWork.where((w) => w.karyawanId == emp.id).toList();
    final totalPcs = works.fold(0, (s, w) => s + w.qtyBagus);
    final totalUpahBorong = works.fold(0, (s, w) => s + w.upahBruto);
    final totalDendaReject = works.fold(0, (s, w) => s + w.totalDenda);

    // Attendance calculation
    final empAttendance = _attendance.where((a) => a.employeeId == emp.id).toList();
    final presentCount = empAttendance.where((a) => a.status.isPresent).length;
    final daysPresent = presentCount > 0 ? presentCount : 6;
    final totalHoursLembur = empAttendance.fold(0.0, (s, a) => s + a.jamLembur);

    // 1. Tipe Harian: (tarif_harian x kehadiran) + (jam_lembur x tarif_lembur)
    // 2. Tipe Borongan: sum(jumlah_potong x tarif_proses)
    // 3. Tipe Campuran: upah_dasar_harian + insentif_target_borongan
    var totalUpahDasar = 0;
    var upahBoronganFinal = 0;
    var totalLembur = 0;

    switch (emp.tipeGaji) {
      case TipeGaji.harianMurni:
        totalUpahDasar = emp.tarifHarianDasar * daysPresent;
        upahBoronganFinal = 0;
        totalLembur = (totalHoursLembur * (emp.tarifLemburPerJam > 0 ? emp.tarifLemburPerJam : 15000)).round();
        if (totalLembur == 0 && totalHoursLembur == 0) {
          totalLembur = emp.tarifLemburPerJam * 4;
        }
      case TipeGaji.boronganMurni:
        totalUpahDasar = 0;
        upahBoronganFinal = totalUpahBorong;
        totalLembur = totalHoursLembur > 0 ? (totalHoursLembur * 15000).round() : 50000;
      case TipeGaji.campuran:
        totalUpahDasar = emp.tarifHarianDasar * daysPresent;
        upahBoronganFinal = totalUpahBorong;
        totalLembur = (totalHoursLembur * (emp.tarifLemburPerJam > 0 ? emp.tarifLemburPerJam : 15000)).round();
        if (totalLembur == 0 && totalHoursLembur == 0) {
          totalLembur = emp.tarifLemburPerJam * 2;
        }
    }

    final totalBonus = emp.allowance;
    final grossWage = totalUpahDasar + upahBoronganFinal + totalLembur + totalBonus;

    // 2. KASBON 50% THP FLOOR CAP & AUTO DEBT ROLLOVER
    final activeLoan = _loans.firstWhere(
      (l) => l.employeeId == emp.id && !l.isPaidOff && l.syncToPayroll,
      orElse: () => Loan(
        id: '',
        employeeId: emp.id,
        amount: 0,
        deduction: 0,
        createdAt: DateTime.now(),
      ),
    );

    var actualKasbonDeduction = 0;
    if (activeLoan.id.isNotEmpty && activeLoan.remaining > 0) {
      final targetDeduction = activeLoan.deduction;
      final maxAllowedDeduction = (grossWage * 0.50).round();
      actualKasbonDeduction = math.min(
        targetDeduction,
        math.min(activeLoan.remaining, maxAllowedDeduction),
      );

      if (applyLoanDeduction) {
        final loanIdx = _loans.indexWhere((l) => l.id == activeLoan.id);
        if (loanIdx >= 0) {
          final newBalance = activeLoan.remaining - actualKasbonDeduction;
          _loans[loanIdx] = activeLoan.copyWith(sisaSaldo: newBalance);
        }
      }
    }

    final thp = math.max(0, grossWage - totalDendaReject - actualKasbonDeduction);

    return SlipGajiMingguan(
      id: 'SLIP-${emp.id}-${r.kodePeriode}',
      rekapId: r.id,
      karyawanId: emp.id,
      karyawanNama: emp.name,
      divisi: emp.divisi,
      tipeGaji: emp.tipeGaji,
      totalHariHadir: daysPresent,
      totalPotongBagus: totalPcs,
      totalUpahDasar: totalUpahDasar,
      totalUpahBorong: upahBoronganFinal,
      totalLembur: totalLembur,
      totalBonus: totalBonus,
      potonganKasbon: actualKasbonDeduction,
      potonganDenda: totalDendaReject,
      thpBersih: thp,
      metodeBayar: emp.metodeBayar,
      statusBayar: emp.status == PayrollStatus.paid,
      nomorSlipResmi: 'SLIP/2026/W43-${emp.id}',
    );
  }

  List<SlipGajiMingguan> get convectionWeeklySlips {
    if (_slips.isNotEmpty) return _slips;
    return activeEmployees.map((e) => calculateSlipForEmployee(e)).toList();
  }

  // ---------------------------------------------------------------- 5 Laporan Wajib Konveksi
  Map<String, dynamic> get weeklyRecapReport {
    final slips = convectionWeeklySlips;
    final totalGross = slips.fold(0, (s, x) => s + x.upahKotor);
    final totalUpahDasar = slips.fold(0, (s, x) => s + x.totalUpahDasar);
    final totalBorongan = slips.fold(0, (s, x) => s + x.totalUpahBorong);
    final totalLembur = slips.fold(0, (s, x) => s + x.totalLembur);
    final totalBonus = slips.fold(0, (s, x) => s + x.totalBonus);
    final totalKasbon = slips.fold(0, (s, x) => s + x.potonganKasbon);
    final totalDenda = slips.fold(0, (s, x) => s + x.potonganDenda);
    final totalThp = slips.fold(0, (s, x) => s + x.thpBersih);

    final tunaiSlips = slips.where((s) => s.metodeBayar == MetodePembayaran.tunaiAmplop).toList();
    final transferSlips = slips.where((s) => s.metodeBayar == MetodePembayaran.transferBank).toList();
    final ewalletSlips = slips.where((s) => s.metodeBayar == MetodePembayaran.eWallet).toList();

    return {
      'totalGross': totalGross,
      'totalUpahDasar': totalUpahDasar,
      'totalBorongan': totalBorongan,
      'totalLembur': totalLembur,
      'totalBonus': totalBonus,
      'totalKasbon': totalKasbon,
      'totalDenda': totalDenda,
      'totalThp': totalThp,
      'count': slips.length,
      'tunaiCount': tunaiSlips.length,
      'tunaiTotal': tunaiSlips.fold(0, (s, x) => s + x.thpBersih),
      'transferCount': transferSlips.length,
      'transferTotal': transferSlips.fold(0, (s, x) => s + x.thpBersih),
      'ewalletCount': ewalletSlips.length,
      'ewalletTotal': ewalletSlips.fold(0, (s, x) => s + x.thpBersih),
    };
  }

  List<Map<String, dynamic>> get productivityByDivisionReport {
    final res = <Map<String, dynamic>>[];
    for (final div in DivisiBagian.values) {
      final divEmps = activeEmployees.where((e) => e.divisi == div).toList();
      final divWorks = _dailyWork.where((w) => divEmps.any((e) => e.id == w.karyawanId)).toList();
      final totalPcs = divWorks.fold(0, (s, w) => s + w.qtyBagus);
      final totalRework = divWorks.fold(0, (s, w) => s + w.qtyRework);
      final totalReject = divWorks.fold(0, (s, w) => s + w.qtyRejectFatal);
      final totalWage = divWorks.fold(0, (s, w) => s + w.upahBruto);

      res.add({
        'divisi': div,
        'label': div.label,
        'workerCount': divEmps.length,
        'totalPcs': totalPcs,
        'totalRework': totalRework,
        'totalReject': totalReject,
        'totalWage': totalWage,
        'avgPcsPerWorker': divEmps.isNotEmpty ? (totalPcs / divEmps.length).round() : 0,
      });
    }
    return res;
  }

  List<Map<String, dynamic>> get hppReportData {
    final res = <Map<String, dynamic>>[];
    for (final p in _products) {
      final modelSpks = _spkLots.where((s) => s.modelId == p.id).toList();
      final totalPcs = modelSpks.fold(0, (s, spk) => s + spk.realisasiPotong);
      final modelProcesses = _processes.where((pr) => pr.modelId == p.id).toList();
      final sumTarifOperasi = modelProcesses.fold(0, (s, pr) => s + pr.tarifPerPotong);
      final totalLaborCost = totalPcs * sumTarifOperasi;
      final hppPerPcs = totalPcs > 0 ? (totalLaborCost / totalPcs).round() : sumTarifOperasi;

      res.add({
        'product': p,
        'totalPcs': totalPcs,
        'processes': modelProcesses,
        'sumTarifOperasi': sumTarifOperasi,
        'totalLaborCost': totalLaborCost,
        'hppPerPcs': hppPerPcs,
      });
    }
    return res;
  }

  // ---------------------------------------------------------------- Cash Denominations Calculator
  DenominasiUang calculateCashDenominations() {
    final cashSlips = _slips.isNotEmpty
        ? _slips.where((s) => s.metodeBayar == MetodePembayaran.tunaiAmplop).toList()
        : activeEmployees
            .where((e) => e.metodeBayar == MetodePembayaran.tunaiAmplop)
            .map(lineFor)
            .toList();

    var totalNominal = 0;
    var n100k = 0, n50k = 0, n20k = 0, n10k = 0, n5k = 0, n2k = 0, n1k = 0;

    for (final item in cashSlips) {
      var rem = item is SlipGajiMingguan ? item.thpBersih : (item as PayrollLine).net;
      totalNominal += rem;

      n100k += rem ~/ 100000;
      rem %= 100000;

      n50k += rem ~/ 50000;
      rem %= 50000;

      n20k += rem ~/ 20000;
      rem %= 20000;

      n10k += rem ~/ 10000;
      rem %= 10000;

      n5k += rem ~/ 5000;
      rem %= 5000;

      n2k += rem ~/ 2000;
      rem %= 2000;

      n1k += rem ~/ 1000;
    }

    return DenominasiUang(
      rp100k: n100k,
      rp50k: n50k,
      rp20k: n20k,
      rp10k: n10k,
      rp5k: n5k,
      rp2k: n2k,
      rp1k: n1k,
      totalNominal: totalNominal,
    );
  }

  // ---------------------------------------------------------------- WhatsApp Slip Generator
  String getWhatsAppSlipUrl(SlipGajiMingguan slip) {
    final emp = employeeById(slip.karyawanId);
    final phone = emp?.phone.replaceAll(RegExp(r'[^0-9]'), '') ?? '';
    final formattedPhone = phone.startsWith('0') ? '62${phone.substring(1)}' : phone;

    final msg = '''
*SLIP GAJI RESMI KONVEKSI BERKAH*
No. Slip: ${slip.nomorSlipResmi ?? '-'}
Periode: 19 - 24 Oktober 2026

Karyawan: ${slip.karyawanNama}
Bagian  : ${slip.divisi.label} (${slip.tipeGaji.label})
----------------------------------------
*PENERIMAAN:*
• Kehadiran (${slip.totalHariHadir} Hari): ${Fmt.rupiah(slip.totalUpahDasar)}
• Upah Borongan (${slip.totalPotongBagus} pcs): ${Fmt.rupiah(slip.totalUpahBorong)}
• Lembur & Uang Makan : ${Fmt.rupiah(slip.totalLembur)}
• Tunjangan & Bonus    : ${Fmt.rupiah(slip.totalBonus)}
*Total Kotor: ${Fmt.rupiah(slip.upahKotor)}*

*POTONGAN:*
• Cicilan Kasbon : -${Fmt.rupiah(slip.potonganKasbon)}
• Denda Reject   : -${Fmt.rupiah(slip.potonganDenda)}
----------------------------------------
*TOTAL DITERIMA (THP): ${Fmt.rupiah(slip.thpBersih)}*
Metode Pencairan: ${slip.metodeBayar.label}
Status: *LUNAS & DISETUJUI PEMILIK*
''';

    return 'https://wa.me/$formattedPhone?text=${Uri.encodeComponent(msg)}';
  }

  // ---------------------------------------------------------------- Existing Core Logic
  Employee? employeeById(String id) {
    for (final e in _employees) {
      if (e.id == id) return e;
    }
    return null;
  }

  int loanDeductionFor(String employeeId) => _loans
      .where((l) => l.employeeId == employeeId && l.syncToPayroll && !l.isPaidOff)
      .fold(0, (sum, l) => sum + l.deduction);

  PayrollLine lineFor(Employee e) =>
      PayrollLine(employee: e, loanDeduction: loanDeductionFor(e.id));

  List<PayrollLine> get payrollLines =>
      activeEmployees.map(lineFor).toList(growable: false);

  PayrollTotals get totals => totalsOf(payrollLines);

  PayrollTotals totalsOf(List<PayrollLine> lines) {
    var base = 0, allowance = 0, deduction = 0;
    var paidC = 0, readyC = 0, reviewC = 0;
    var paidA = 0, readyA = 0, reviewA = 0;
    final depts = <String>{};
    for (final l in lines) {
      base += l.base;
      allowance += l.allowance;
      deduction += l.deduction;
      depts.add(l.employee.department);
      switch (l.status) {
        case PayrollStatus.paid:
          paidC++;
          paidA += l.net;
        case PayrollStatus.ready:
          readyC++;
          readyA += l.net;
        case PayrollStatus.review:
          reviewC++;
          reviewA += l.net;
      }
    }
    return PayrollTotals(
      base: base,
      allowance: allowance,
      deduction: deduction,
      count: lines.length,
      paidCount: paidC,
      readyCount: readyC,
      reviewCount: reviewC,
      paidAmount: paidA,
      readyAmount: readyA,
      reviewAmount: reviewA,
      departments: depts.length,
    );
  }

  int get loanOutstanding => _loans.fold(0, (s, l) => s + l.remaining);
  int get loanDebtorCount =>
      _loans.where((l) => !l.isPaidOff).map((l) => l.employeeId).toSet().length;

  List<AttendanceRecord> attendanceFor(DateTime day) {
    final key = Fmt.isoDay(day);
    return _attendance.where((r) => r.day == key).toList(growable: false);
  }

  int absentCount(DateTime day) =>
      attendanceFor(day).where((r) => !r.status.isPresent).length;

  DateTime? previousRecordedDay(DateTime day) {
    var d = Fmt.dayOnly(day);
    for (var i = 0; i < 14; i++) {
      d = d.subtract(const Duration(days: 1));
      if (attendanceFor(d).isNotEmpty) return d;
    }
    return null;
  }

  // ---------------------------------------------------------------- Lifecycle
  Future<void> load({DateTime? now}) async {
    _currentUser = _users.first; // Super Admin by default
    var loaded = false;
    try {
      final raw = await _vault.read(_storageKey);
      if (raw != null && raw.isNotEmpty && raw.length < 6 * 1024 * 1024) {
        _decode(jsonDecode(raw));
        loaded = true;
      }
    } catch (e) {
      debugPrint('Payrole: stored data unreadable, reseeding (${e.runtimeType})');
    }
    if (!loaded) {
      _seed(now ?? DateTime.now());
      _scheduleSave();
    }
    _ready = true;
    notifyListeners();
  }

  void _seed(DateTime now) {
    _users = Seed.users();
    _currentUser = _users.first;
    _products = Seed.products();
    _spkLots = Seed.spkLots();
    _processes = Seed.processes();
    _dailyWork = Seed.dailyWork();
    _employees = Seed.employees();
    _loans = Seed.loans();
    _weeklyRecaps = Seed.weeklyRecaps();
    _slips = [];
    _reimbursements = [];
    _attendance = [];
    _settings = const AppSettings();
    _periodYear = Seed.periodYear;
    _periodMonth = Seed.periodMonth;
    _lastUpdated = Seed.lastUpdated;
    _audit = Seed.auditLogs();
  }

  void _decode(Object? json) {
    if (json is! Map) throw const FormatException('root');
    final m = json.cast<String, Object?>();
    List<T> list<T>(String key, T Function(Map<String, Object?>) f) {
      final v = m[key];
      if (v is! List) return <T>[];
      return v.whereType<Map>().map((e) => f(e.cast<String, Object?>())).toList();
    }

    _users = list('users', UserAccount.fromJson);
    if (_users.isEmpty) _users = Seed.users();
    _currentUser = _users.first;

    _products = list('products', ProdukModel.fromJson);
    if (_products.isEmpty) _products = Seed.products();

    _spkLots = list('spkLots', SpkLotPotong.fromJson);
    if (_spkLots.isEmpty) _spkLots = Seed.spkLots();

    _processes = list('processes', ProsesOperasiTarif.fromJson);
    if (_processes.isEmpty) _processes = Seed.processes();

    _dailyWork = list('dailyWork', HasilKerjaHarian.fromJson);
    if (_dailyWork.isEmpty) _dailyWork = Seed.dailyWork();

    _weeklyRecaps = list('weeklyRecaps', RekapMingguan.fromJson);
    if (_weeklyRecaps.isEmpty) _weeklyRecaps = Seed.weeklyRecaps();

    _slips = list('slips', SlipGajiMingguan.fromJson);

    final emps = list('employees', Employee.fromJson);
    _employees = emps.isNotEmpty ? emps : Seed.employees();

    _loans = list('loans', Loan.fromJson);
    if (_loans.isEmpty) _loans = Seed.loans();

    _attendance = list('attendance', AttendanceRecord.fromJson);
    _reimbursements = list('reimbursements', Reimbursement.fromJson);
    _audit = list('audit', AuditEntry.fromJson);
    if (_audit.isEmpty) _audit = Seed.auditLogs();

    final s = m['settings'];
    _settings = s is Map
        ? AppSettings.fromJson(s.cast<String, Object?>())
        : const AppSettings();
    _periodYear = (m['periodYear'] as num?)?.toInt() ?? Seed.periodYear;
    _periodMonth =
        ((m['periodMonth'] as num?)?.toInt() ?? Seed.periodMonth).clamp(1, 12);
    _lastUpdated =
        DateTime.tryParse(m['lastUpdated'] as String? ?? '') ?? Seed.lastUpdated;
  }

  Map<String, Object?> _encode() => {
        'v': _schemaVersion,
        'periodYear': _periodYear,
        'periodMonth': _periodMonth,
        'lastUpdated': _lastUpdated.toIso8601String(),
        'settings': _settings.toJson(),
        'users': _users.map((u) => u.toJson()).toList(),
        'products': _products.map((p) => p.toJson()).toList(),
        'spkLots': _spkLots.map((s) => s.toJson()).toList(),
        'processes': _processes.map((p) => p.toJson()).toList(),
        'dailyWork': _dailyWork.map((w) => w.toJson()).toList(),
        'weeklyRecaps': _weeklyRecaps.map((r) => r.toJson()).toList(),
        'slips': _slips.map((s) => s.toJson()).toList(),
        'employees': _employees.map((e) => e.toJson()).toList(),
        'loans': _loans.map((l) => l.toJson()).toList(),
        'attendance': _attendance.map((e) => e.toJson()).toList(),
        'reimbursements': _reimbursements.map((e) => e.toJson()).toList(),
        'audit': _audit.map((e) => e.toJson()).toList(),
      };

  void _scheduleSave() {
    _saveTimer?.cancel();
    _saveTimer = Timer(const Duration(milliseconds: 400), flush);
  }

  Future<void> flush() async {
    _saveTimer?.cancel();
    _saveTimer = null;
    if (!_ready) return;
    try {
      await _vault.write(_storageKey, jsonEncode(_encode()));
    } catch (e) {
      debugPrint('Payrole: failed to persist (${e.runtimeType})');
    }
  }

  void _commit(String action, String detail) {
    _lastUpdated = DateTime.now();
    _audit.insert(
      0,
      AuditEntry(
        at: _lastUpdated,
        action: action,
        detail: detail,
        userName: _currentUser.name,
        role: _currentUser.role.name,
      ),
    );
    if (_audit.length > _maxAudit) _audit.removeRange(_maxAudit, _audit.length);
    notifyListeners();
    _scheduleSave();
  }

  @override
  void dispose() {
    _saveTimer?.cancel();
    super.dispose();
  }

  // ---------------------------------------------------------------- Utilities
  static String sanitize(String input, {int maxLength = 120}) {
    final cleaned = input
        .replaceAll(RegExp(r'[\u0000-\u001F\u007F\u200B-\u200F\u202A-\u202E]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
    return cleaned.length > maxLength ? cleaned.substring(0, maxLength) : cleaned;
  }

  static void _money(int v, String field, {bool allowZero = true}) {
    if (v < 0 || (!allowZero && v == 0)) {
      throw ValidationException('$field harus lebih dari 0.');
    }
    if (v > maxMoney) {
      throw ValidationException('$field melebihi batas wajar.');
    }
  }

  static int estimateBpjsKesehatan(int base) =>
      math.min(base, 12000000) ~/ 100;

  static int estimateBpjsKetenagakerjaan(int base) =>
      (base * 2 ~/ 100) + (math.min(base, 10547400) ~/ 100);

  String _nextId(String prefix, Iterable<String> existing) {
    var max = 0;
    for (final id in existing) {
      if (!id.startsWith('$prefix-')) continue;
      final n = int.tryParse(id.substring(prefix.length + 1)) ?? 0;
      if (n > max) max = n;
    }
    return '$prefix-${(max + 1).toString().padLeft(3, '0')}';
  }

  Employee _require(String id) {
    final e = employeeById(id);
    if (e == null) throw const ValidationException('Karyawan tidak ditemukan.');
    return e;
  }

  void _replaceEmployee(Employee e) {
    final i = _employees.indexWhere((x) => x.id == e.id);
    if (i >= 0) _employees[i] = e;
  }

  // ---------------------------------------------------------------- Payroll Ops
  void setPayrollStatus(String id, PayrollStatus status) {
    final e = _require(id);
    if (e.status == status) return;
    if (status == PayrollStatus.paid && e.status == PayrollStatus.review) {
      throw ValidationException(
          'Gaji ${e.name} perlu ditinjau sebelum dibayarkan.');
    }
    if (status == PayrollStatus.paid && lineFor(e).net < 0) {
      throw ValidationException('Gaji bersih ${e.name} tidak valid (negatif).');
    }
    _replaceEmployee(e.copyWith(
      status: status,
      paidAt: status == PayrollStatus.paid ? DateTime.now() : null,
      clearPaidAt: status != PayrollStatus.paid,
      clearReviewNote: status != PayrollStatus.review,
    ));
    _commit('Status payroll diubah', '${e.name}: ${e.status.label} → ${status.label}');
  }

  void approveReview(String id) {
    final e = _require(id);
    if (e.status != PayrollStatus.review) return;
    _replaceEmployee(e.copyWith(status: PayrollStatus.ready, clearReviewNote: true));
    _commit('Payroll ditinjau', '${e.name} disetujui → Siap dibayar');
  }

  void flagForReview(String id, {String? note}) {
    final e = _require(id);
    if (e.status == PayrollStatus.paid) {
      throw const ValidationException('Gaji yang sudah dibayar tidak bisa ditandai ulang.');
    }
    _replaceEmployee(e.copyWith(
      status: PayrollStatus.review,
      reviewNote: note == null ? null : sanitize(note, maxLength: 200),
    ));
    _commit('Payroll ditandai', '${e.name} → Perlu ditinjau');
  }

  int processPayroll(Iterable<String> ids) {
    final now = DateTime.now();
    var count = 0;
    var amount = 0;
    for (final id in ids.toSet()) {
      final e = employeeById(id);
      if (e == null || !e.active || e.status != PayrollStatus.ready) continue;
      final net = lineFor(e).net;
      if (net < 0) continue;
      _replaceEmployee(e.copyWith(status: PayrollStatus.paid, paidAt: now));
      count++;
      amount += net;
    }
    if (count > 0) {
      _commit('Payroll diproses', '$count karyawan · ${Fmt.rupiah(amount)}');
    }
    return count;
  }

  void updateComponents(
    String id, {
    required int baseSalary,
    required int allowance,
    required int bpjsKesehatan,
    required int bpjsKetenagakerjaan,
    required int pph21,
    required int otherDeduction,
    bool markReady = false,
  }) {
    final e = _require(id);
    if (e.status == PayrollStatus.paid) {
      throw const ValidationException(
          'Komponen gaji terkunci karena sudah dibayarkan.');
    }
    _money(baseSalary, 'Gaji pokok', allowZero: true);
    _money(allowance, 'Tunjangan');
    _money(bpjsKesehatan, 'BPJS Kesehatan');
    _money(bpjsKetenagakerjaan, 'BPJS Ketenagakerjaan');
    _money(pph21, 'PPh 21');
    _money(otherDeduction, 'Potongan lain');
    final net = baseSalary +
        allowance -
        bpjsKesehatan -
        bpjsKetenagakerjaan -
        pph21 -
        otherDeduction -
        loanDeductionFor(id);
    if (net < 0) {
      throw const ValidationException('Total potongan melebihi gaji bruto.');
    }
    _replaceEmployee(e.copyWith(
      baseSalary: baseSalary,
      allowance: allowance,
      bpjsKesehatan: bpjsKesehatan,
      bpjsKetenagakerjaan: bpjsKetenagakerjaan,
      pph21: pph21,
      otherDeduction: otherDeduction,
      status: markReady ? PayrollStatus.ready : null,
      clearReviewNote: markReady,
    ));
    _commit('Komponen gaji diubah',
        '${e.name}: bersih ${Fmt.rupiah(net)}${markReady ? ' · Siap dibayar' : ''}');
  }

  // ---------------------------------------------------------------- Kasbon
  Loan addLoan({
    required String employeeId,
    required int amount,
    required int deduction,
    required bool syncToPayroll,
    String note = '',
  }) {
    final e = _require(employeeId);
    if (!e.active) throw const ValidationException('Karyawan tidak aktif.');
    _money(amount, 'Jumlah bon', allowZero: false);
    _money(deduction, 'Potongan cicilan');

    final loan = Loan(
      id: _nextId('BON', _loans.map((l) => l.id)),
      employeeId: employeeId,
      amount: amount,
      deduction: deduction,
      sisaSaldo: amount,
      syncToPayroll: syncToPayroll,
      note: sanitize(note),
      createdAt: DateTime.now(),
    );
    _loans.insert(0, loan);
    _commit('Bon dicatat',
        '${e.name}: ${Fmt.rupiah(amount)} (Cicilan ${Fmt.rupiah(deduction)}/minggu)');
    return loan;
  }

  void updateLoan(
    String loanId, {
    required int amount,
    required int deduction,
    required bool syncToPayroll,
    String? note,
  }) {
    final i = _loans.indexWhere((l) => l.id == loanId);
    if (i < 0) throw const ValidationException('Data bon tidak ditemukan.');
    final loan = _loans[i];
    final e = _require(loan.employeeId);
    _loans[i] = loan.copyWith(
      amount: amount,
      deduction: deduction,
      syncToPayroll: syncToPayroll,
      note: note == null ? null : sanitize(note),
    );
    _commit('Bon diperbarui',
        '${e.name}: cicilan ${Fmt.rupiah(deduction)} · sisa ${Fmt.rupiah(_loans[i].remaining)}');
  }

  void setLoanSync(String loanId, bool sync) {
    final loan = _loans.firstWhere((l) => l.id == loanId,
        orElse: () => throw const ValidationException('Data bon tidak ditemukan.'));
    updateLoan(loanId,
        amount: loan.amount, deduction: loan.deduction, syncToPayroll: sync);
  }

  void payOffLoan(String loanId, {required bool viaPayroll}) {
    final loan = _loans.firstWhere((l) => l.id == loanId,
        orElse: () => throw const ValidationException('Data bon tidak ditemukan.'));
    final idx = _loans.indexWhere((l) => l.id == loanId);
    if (idx >= 0) {
      _loans[idx] = loan.copyWith(sisaSaldo: 0);
      _commit('Bon dilunasi', 'Bon ${loan.id} berstatus Lunas');
    }
  }

  void deleteLoan(String loanId) {
    final i = _loans.indexWhere((l) => l.id == loanId);
    if (i < 0) return;
    final loan = _loans[i];
    final e = employeeById(loan.employeeId);
    _loans.removeAt(i);
    _commit('Bon dihapus', '${e?.name ?? loan.employeeId}: ${Fmt.rupiah(loan.amount)}');
  }

  // ---------------------------------------------------------------- Employee CRUD
  Employee addEmployee({
    required String name,
    required String department,
    required String position,
    required String email,
    required String phone,
    required DateTime joinDate,
    required int baseSalary,
    required int allowance,
    DivisiBagian divisi = DivisiBagian.jahit,
    TipeGaji tipeGaji = TipeGaji.boronganMurni,
    int tarifHarianDasar = 0,
    int tarifLemburPerJam = 15000,
    MetodePembayaran metodeBayar = MetodePembayaran.tunaiAmplop,
    String namaBank = '',
    String nomorRekening = '',
  }) {
    final n = sanitize(name, maxLength: 60);
    final em = sanitize(email, maxLength: 80).toLowerCase();
    final ph = phone.replaceAll(RegExp(r'[\s-]'), '');

    final e = Employee(
      id: _nextId('KNV', _employees.map((e) => e.id)),
      name: n,
      department: department,
      position: sanitize(position, maxLength: 60),
      email: em,
      phone: ph,
      joinDate: joinDate,
      baseSalary: baseSalary,
      allowance: allowance,
      divisi: divisi,
      tipeGaji: tipeGaji,
      tarifHarianDasar: tarifHarianDasar,
      tarifLemburPerJam: tarifLemburPerJam,
      metodeBayar: metodeBayar,
      namaBank: namaBank,
      nomorRekening: nomorRekening,
      bpjsKesehatan: 0,
      bpjsKetenagakerjaan: 0,
      pph21: 0,
      status: PayrollStatus.review,
    );
    _employees.add(e);
    _commit('Karyawan ditambahkan', '${e.name} (${e.id} - ${divisi.label})');
    return e;
  }

  void updateEmployee(
    String id, {
    required String name,
    required String department,
    required String position,
    required String email,
    required String phone,
    required DateTime joinDate,
    required int baseSalary,
    required int allowance,
    DivisiBagian? divisi,
    TipeGaji? tipeGaji,
    int? tarifHarianDasar,
    int? tarifLemburPerJam,
    MetodePembayaran? metodeBayar,
    String? namaBank,
    String? nomorRekening,
  }) {
    final e = _require(id);
    final n = sanitize(name, maxLength: 60);
    final em = sanitize(email, maxLength: 80).toLowerCase();
    final ph = phone.replaceAll(RegExp(r'[\s-]'), '');

    _replaceEmployee(e.copyWith(
      name: n,
      department: department,
      position: sanitize(position, maxLength: 60),
      email: em,
      phone: ph,
      joinDate: joinDate,
      baseSalary: baseSalary,
      allowance: allowance,
      divisi: divisi,
      tipeGaji: tipeGaji,
      tarifHarianDasar: tarifHarianDasar,
      tarifLemburPerJam: tarifLemburPerJam,
      metodeBayar: metodeBayar,
      namaBank: namaBank,
      nomorRekening: nomorRekening,
    ));
    _commit('Data karyawan diubah', '${e.name} (${e.id})');
  }

  void setEmployeeActive(String id, bool active) {
    final e = _require(id);
    if (e.active == active) return;
    _replaceEmployee(e.copyWith(active: active));
    _commit(active ? 'Karyawan diaktifkan' : 'Karyawan dinonaktifkan', e.name);
  }

  void deleteEmployee(String id) {
    final e = _require(id);
    _employees.removeWhere((x) => x.id == id);
    _loans.removeWhere((l) => l.employeeId == id);
    _commit('Karyawan dihapus', '${e.name} (${e.id})');
  }

  // ---------------------------------------------------------------- Attendance
  void setAttendance(
    String employeeId,
    DateTime day,
    AttendanceStatus status, {
    double? jamLembur,
  }) {
    if (activeRecap.isLocked) {
      throw const ValidationException(
          'Periode ini sudah Tutup Minggu (LOCKED). Data absensi tidak bisa diubah lagi.');
    }
    final e = _require(employeeId);
    final key = Fmt.isoDay(day);
    final now = DateTime.now();
    final nowTime = '${Fmt.two(now.hour)}:${Fmt.two(now.minute)}';
    final i = _attendance.indexWhere((r) => r.employeeId == employeeId && r.day == key);
    final present = status.isPresent;
    if (i >= 0) {
      final r = _attendance[i];
      _attendance[i] = present
          ? r.copyWith(
              status: status,
              jamLembur: jamLembur,
              checkIn: r.checkIn ?? nowTime,
            )
          : r.copyWith(
              status: status,
              jamLembur: 0.0,
              clearTimes: true,
            );
    } else {
      _attendance.add(AttendanceRecord(
        employeeId: employeeId,
        day: key,
        status: status,
        jamLembur: jamLembur ?? 0.0,
        checkIn: present ? nowTime : null,
      ));
    }
    _commit(
      'Kehadiran diubah',
      '${e.name} · ${Fmt.date(day)}: ${status.label}${jamLembur != null && jamLembur > 0 ? " (Lembur: $jamLembur jam)" : ""}',
    );
  }

  void markAllPresent(DateTime day) {
    if (activeRecap.isLocked) {
      throw const ValidationException(
          'Periode ini sudah Tutup Minggu (LOCKED). Data absensi tidak bisa diubah lagi.');
    }
    final key = Fmt.isoDay(day);
    var added = 0;
    for (final e in activeEmployees) {
      if (_attendance.any((r) => r.employeeId == e.id && r.day == key)) continue;
      _attendance.add(AttendanceRecord(
        employeeId: e.id,
        day: key,
        status: AttendanceStatus.present,
        checkIn: '08:00',
      ));
      added++;
    }
    if (added > 0) _commit('Kehadiran massal', '$added karyawan hadir · ${Fmt.date(day)}');
  }

  // ---------------------------------------------------------------- Reimbursements
  Reimbursement addReimbursement({
    required String employeeId,
    required String category,
    required String description,
    required int amount,
    required DateTime date,
  }) {
    final e = _require(employeeId);
    _money(amount, 'Nominal', allowZero: false);
    final desc = sanitize(description, maxLength: 120);
    final r = Reimbursement(
      id: _nextId('RB', _reimbursements.map((r) => r.id)),
      employeeId: employeeId,
      category: kReimbursementCategories.contains(category) ? category : 'Lainnya',
      description: desc,
      amount: amount,
      date: date,
    );
    _reimbursements.insert(0, r);
    _commit('Reimbursement diajukan', '${e.name}: ${Fmt.rupiah(amount)}');
    return r;
  }

  void setReimbursementStatus(String id, ReimbursementStatus status) {
    final i = _reimbursements.indexWhere((r) => r.id == id);
    if (i < 0) return;
    final r = _reimbursements[i];
    _reimbursements[i] = r.copyWith(status: status);
    final name = employeeById(r.employeeId)?.name ?? r.employeeId;
    _commit('Reimbursement ${status.label.toLowerCase()}', '$name: ${Fmt.rupiah(r.amount)}');
  }

  void deleteReimbursement(String id) {
    final i = _reimbursements.indexWhere((r) => r.id == id);
    if (i < 0) return;
    final r = _reimbursements.removeAt(i);
    _commit('Reimbursement dihapus', '${r.id} · ${Fmt.rupiah(r.amount)}');
  }

  // ---------------------------------------------------------------- Settings
  void updateSettings(AppSettings s) {
    final name = sanitize(s.companyName, maxLength: 60);
    _settings = s.copyWith(
      companyName: name,
      payday: s.payday.clamp(1, 28),
      autoLockMinutes: s.autoLockMinutes.clamp(1, 60),
    );
    _commit('Pengaturan diubah', 'Preferensi aplikasi diperbarui');
  }

  void logSecurityEvent(String action, String detail) => _commit(action, detail);

  Future<void> resetDemo() async {
    _seed(DateTime.now());
    _commit('RESET_DEMO', 'Data demo konveksi dipulihkan ke kondisi awal');
    await flush();
  }
}

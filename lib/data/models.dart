import 'package:flutter/foundation.dart';

// ---------------------------------------------------------------------------
// Roles & Divisions (Konveksi / Garmen)
// ---------------------------------------------------------------------------

enum UserRole {
  superAdmin('Super Admin', 'Pengelola Sistem & User'),
  pemilik('Pemilik (Owner)', 'Laporan, HPP, Approval & Tarif'),
  adminKeuangan('Admin Keuangan', 'Karyawan, Rekap, Kasbon & Slip'),
  mandor('Mandor Lapangan', 'Input & Verifikasi Divisi'),
  karyawan('Karyawan', 'Portal Slip Mandiri');

  const UserRole(this.label, this.description);
  final String label;
  final String description;

  static UserRole parse(Object? v) => UserRole.values.firstWhere(
        (e) => e.name == v,
        orElse: () => UserRole.adminKeuangan,
      );
}

enum DivisiBagian {
  potong('Potong (Cutting)'),
  jahit('Jahit (Sewing)'),
  obras('Obras & Overdeck'),
  pasangKancing('Pasang Kancing / Lubang'),
  finishing('Finishing & Buang Benang'),
  qc('Quality Control (QC)'),
  packing('Packing & Lipat');

  const DivisiBagian(this.label);
  final String label;

  static DivisiBagian parse(Object? v) => DivisiBagian.values.firstWhere(
        (e) => e.name == v,
        orElse: () => DivisiBagian.jahit,
      );
}

enum TipeGaji {
  boronganMurni('Borongan Murni'),
  harianMurni('Harian Murni'),
  campuran('Campuran (Harian + Target)');

  const TipeGaji(this.label);
  final String label;

  static TipeGaji parse(Object? v) {
    final s = v?.toString().toLowerCase() ?? '';
    if (s.contains('campur')) return TipeGaji.campuran;
    if (s.contains('harian')) return TipeGaji.harianMurni;
    return TipeGaji.boronganMurni;
  }
}

enum MetodePembayaran {
  tunaiAmplop('Tunai (Amplop)'),
  transferBank('Transfer Bank'),
  eWallet('E-Wallet (DANA/OVO/GoPay)');

  const MetodePembayaran(this.label);
  final String label;

  static MetodePembayaran parse(Object? v) => MetodePembayaran.values.firstWhere(
        (e) => e.name == v,
        orElse: () => MetodePembayaran.tunaiAmplop,
      );
}

enum StatusRekap {
  draft('Draft (Pencatatan Berjalan)'),
  diverifikasiMandor('Diverifikasi Mandor'),
  disetujuiPemilik('Disetujui Pemilik (Siap Bayar)'),
  dibayar('Dibayar (Tutup Minggu Terkunci)');

  const StatusRekap(this.label);
  final String label;

  static StatusRekap parse(Object? v) => StatusRekap.values.firstWhere(
        (e) => e.name == v,
        orElse: () => StatusRekap.draft,
      );
}

enum PayrollStatus {
  paid('Sudah dibayar'),
  ready('Siap dibayar'),
  review('Perlu ditinjau');

  const PayrollStatus(this.label);
  final String label;

  static PayrollStatus parse(Object? v) => PayrollStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => PayrollStatus.review,
      );
}

enum AttendanceStatus {
  present('Hadir'),
  halfDay('Setengah Hari'),
  late('Terlambat'),
  leave('Izin'),
  sick('Sakit'),
  vacation('Cuti'),
  absent('Alfa');

  const AttendanceStatus(this.label);
  final String label;

  bool get isPresent =>
      this == present || this == halfDay || this == late;

  static AttendanceStatus parse(Object? v) => AttendanceStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => AttendanceStatus.present,
      );
}

enum ReimbursementStatus {
  pending('Menunggu'),
  approved('Disetujui'),
  rejected('Ditolak');

  const ReimbursementStatus(this.label);
  final String label;

  static ReimbursementStatus parse(Object? v) => ReimbursementStatus.values.firstWhere(
        (e) => e.name == v,
        orElse: () => ReimbursementStatus.pending,
      );
}

const kDepartments = [
  'Potong (Cutting)',
  'Jahit (Sewing)',
  'Obras & Overdeck',
  'Pasang Kancing / Lubang',
  'Finishing & Buang Benang',
  'Quality Control (QC)',
  'Packing & Lipat',
  'Operasional',
];

const kReimbursementCategories = [
  'Transportasi',
  'Makan & Konsumsi Lembur',
  'Jarum & Perlengkapan Jahit',
  'Minyak Mesin & Perawatan',
  'Peralatan kerja',
  'Lainnya',
];

// Helper readers
int _int(Object? v, [int fallback = 0]) {
  if (v is int) return v;
  if (v is num) return v.round();
  if (v is String) return int.tryParse(v) ?? fallback;
  return fallback;
}

double _double(Object? v, [double fallback = 0.0]) {
  if (v is double) return v;
  if (v is num) return v.toDouble();
  if (v is String) return double.tryParse(v) ?? fallback;
  return fallback;
}

String _str(Object? v, [String fallback = '']) => v is String ? v : fallback;

DateTime _date(Object? v, DateTime fallback) =>
    v is String ? (DateTime.tryParse(v) ?? fallback) : fallback;

// ---------------------------------------------------------------------------
// User Account & Session
// ---------------------------------------------------------------------------

@immutable
class UserAccount {
  const UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    this.divisiMandor,
    this.karyawanId,
    this.phone = '',
    this.isActive = true,
  });

  final String id;
  final String name;
  final String email;
  final UserRole role;
  final DivisiBagian? divisiMandor; // Only if role == mandor
  final String? karyawanId; // Only if role == karyawan (Anti-IDOR link)
  final String phone;
  final bool isActive;

  String get roleBadgeLabel {
    if (role == UserRole.mandor && divisiMandor != null) {
      return 'Mandor ${divisiMandor!.label}';
    }
    return role.label;
  }

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'role': role.name,
        'divisiMandor': divisiMandor?.name,
        'karyawanId': karyawanId,
        'phone': phone,
        'isActive': isActive,
      };

  factory UserAccount.fromJson(Map<String, Object?> j) => UserAccount(
        id: _str(j['id']),
        name: _str(j['name']),
        email: _str(j['email']),
        role: UserRole.parse(j['role']),
        divisiMandor: j['divisiMandor'] is String
            ? DivisiBagian.parse(j['divisiMandor'])
            : null,
        karyawanId: j['karyawanId'] is String ? j['karyawanId'] as String : null,
        phone: _str(j['phone']),
        isActive: j['isActive'] != false,
      );
}

// ---------------------------------------------------------------------------
// Employee (Karyawan Konveksi)
// ---------------------------------------------------------------------------

@immutable
class Employee {
  const Employee({
    required this.id,
    required this.name,
    required this.department,
    required this.position,
    required this.email,
    required this.phone,
    required this.joinDate,
    required this.baseSalary,
    required this.allowance,
    this.divisi = DivisiBagian.jahit,
    this.tipeGaji = TipeGaji.boronganMurni,
    this.tarifHarianDasar = 0,
    this.tarifLemburPerJam = 15000,
    this.metodeBayar = MetodePembayaran.tunaiAmplop,
    this.namaBank = '',
    this.nomorRekening = '',
    this.bpjsKesehatan = 0,
    this.bpjsKetenagakerjaan = 0,
    this.pph21 = 0,
    this.otherDeduction = 0,
    this.status = PayrollStatus.review,
    this.active = true,
    this.paidAt,
    this.reviewNote,
  });

  final String id;
  final String name;
  final String department;
  final String position;
  final String email;
  final String phone;
  final DateTime joinDate;
  final int baseSalary;
  final int allowance;

  // Convection extensions
  final DivisiBagian divisi;
  final TipeGaji tipeGaji;
  final int tarifHarianDasar;
  final int tarifLemburPerJam;
  final MetodePembayaran metodeBayar;
  final String namaBank;
  final String nomorRekening;

  // Deductions & Status
  final int bpjsKesehatan;
  final int bpjsKetenagakerjaan;
  final int pph21;
  final int otherDeduction;
  final PayrollStatus status;
  final bool active;
  final DateTime? paidAt;
  final String? reviewNote;

  int get statutoryDeduction =>
      bpjsKesehatan + bpjsKetenagakerjaan + pph21 + otherDeduction;

  int get gross => baseSalary + allowance;

  String get subtitle => '$id · ${divisi.label} (${tipeGaji.label})';

  Employee copyWith({
    String? name,
    String? department,
    String? position,
    String? email,
    String? phone,
    DateTime? joinDate,
    int? baseSalary,
    int? allowance,
    DivisiBagian? divisi,
    TipeGaji? tipeGaji,
    int? tarifHarianDasar,
    int? tarifLemburPerJam,
    MetodePembayaran? metodeBayar,
    String? namaBank,
    String? nomorRekening,
    int? bpjsKesehatan,
    int? bpjsKetenagakerjaan,
    int? pph21,
    int? otherDeduction,
    PayrollStatus? status,
    bool? active,
    DateTime? paidAt,
    bool clearPaidAt = false,
    String? reviewNote,
    bool clearReviewNote = false,
  }) =>
      Employee(
        id: id,
        name: name ?? this.name,
        department: department ?? this.department,
        position: position ?? this.position,
        email: email ?? this.email,
        phone: phone ?? this.phone,
        joinDate: joinDate ?? this.joinDate,
        baseSalary: baseSalary ?? this.baseSalary,
        allowance: allowance ?? this.allowance,
        divisi: divisi ?? this.divisi,
        tipeGaji: tipeGaji ?? this.tipeGaji,
        tarifHarianDasar: tarifHarianDasar ?? this.tarifHarianDasar,
        tarifLemburPerJam: tarifLemburPerJam ?? this.tarifLemburPerJam,
        metodeBayar: metodeBayar ?? this.metodeBayar,
        namaBank: namaBank ?? this.namaBank,
        nomorRekening: nomorRekening ?? this.nomorRekening,
        bpjsKesehatan: bpjsKesehatan ?? this.bpjsKesehatan,
        bpjsKetenagakerjaan: bpjsKetenagakerjaan ?? this.bpjsKetenagakerjaan,
        pph21: pph21 ?? this.pph21,
        otherDeduction: otherDeduction ?? this.otherDeduction,
        status: status ?? this.status,
        active: active ?? this.active,
        paidAt: clearPaidAt ? null : (paidAt ?? this.paidAt),
        reviewNote: clearReviewNote ? null : (reviewNote ?? this.reviewNote),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'name': name,
        'department': department,
        'position': position,
        'email': email,
        'phone': phone,
        'joinDate': joinDate.toIso8601String(),
        'baseSalary': baseSalary,
        'allowance': allowance,
        'divisi': divisi.name,
        'tipeGaji': tipeGaji.name,
        'tarifHarianDasar': tarifHarianDasar,
        'tarifLemburPerJam': tarifLemburPerJam,
        'metodeBayar': metodeBayar.name,
        'namaBank': namaBank,
        'nomorRekening': nomorRekening,
        'bpjsKesehatan': bpjsKesehatan,
        'bpjsKetenagakerjaan': bpjsKetenagakerjaan,
        'pph21': pph21,
        'otherDeduction': otherDeduction,
        'status': status.name,
        'active': active,
        'paidAt': paidAt?.toIso8601String(),
        'reviewNote': reviewNote,
      };

  factory Employee.fromJson(Map<String, Object?> j) => Employee(
        id: _str(j['id']),
        name: _str(j['name']),
        department: _str(j['department'], kDepartments.first),
        position: _str(j['position']),
        email: _str(j['email']),
        phone: _str(j['phone']),
        joinDate: _date(j['joinDate'], DateTime(2024)),
        baseSalary: _int(j['baseSalary']),
        allowance: _int(j['allowance']),
        divisi: j['divisi'] is String ? DivisiBagian.parse(j['divisi']) : DivisiBagian.jahit,
        tipeGaji: j['tipeGaji'] is String ? TipeGaji.parse(j['tipeGaji']) : TipeGaji.boronganMurni,
        tarifHarianDasar: _int(j['tarifHarianDasar']),
        tarifLemburPerJam: _int(j['tarifLemburPerJam'], 15000),
        metodeBayar: j['metodeBayar'] is String ? MetodePembayaran.parse(j['metodeBayar']) : MetodePembayaran.tunaiAmplop,
        namaBank: _str(j['namaBank']),
        nomorRekening: _str(j['nomorRekening']),
        bpjsKesehatan: _int(j['bpjsKesehatan']),
        bpjsKetenagakerjaan: _int(j['bpjsKetenagakerjaan']),
        pph21: _int(j['pph21']),
        otherDeduction: _int(j['otherDeduction']),
        status: PayrollStatus.parse(j['status']),
        active: j['active'] != false,
        paidAt: j['paidAt'] is String ? DateTime.tryParse(j['paidAt'] as String) : null,
        reviewNote: j['reviewNote'] is String ? j['reviewNote'] as String : null,
      );
}

// ---------------------------------------------------------------------------
// Produk Model & SPK Lot Potong (Anti-Phantom Output Engine)
// ---------------------------------------------------------------------------

@immutable
class ProdukModel {
  const ProdukModel({
    required this.id,
    required this.kodeModel,
    required this.namaModel,
    this.deskripsi = '',
    this.isActive = true,
  });

  final String id;
  final String kodeModel;
  final String namaModel;
  final String deskripsi;
  final bool isActive;

  Map<String, Object?> toJson() => {
        'id': id,
        'kodeModel': kodeModel,
        'namaModel': namaModel,
        'deskripsi': deskripsi,
        'isActive': isActive,
      };

  factory ProdukModel.fromJson(Map<String, Object?> j) => ProdukModel(
        id: _str(j['id']),
        kodeModel: _str(j['kodeModel']),
        namaModel: _str(j['namaModel']),
        deskripsi: _str(j['deskripsi']),
        isActive: j['isActive'] != false,
      );
}

@immutable
class SpkLotPotong {
  const SpkLotPotong({
    required this.id,
    required this.nomorSpk,
    required this.modelId,
    required this.modelNama,
    required this.tanggalPotong,
    required this.targetQtyPotong,
    required this.realisasiPotong,
    this.status = 'IN_PROGRESS', // IN_PROGRESS, COMPLETED, CLOSED
  });

  final String id;
  final String nomorSpk; // e.g. SPK-2026-101
  final String modelId;
  final String modelNama;
  final DateTime tanggalPotong;
  final int targetQtyPotong;
  final int realisasiPotong; // Max physical cut units available to sewing
  final String status;

  Map<String, Object?> toJson() => {
        'id': id,
        'nomorSpk': nomorSpk,
        'modelId': modelId,
        'modelNama': modelNama,
        'tanggalPotong': tanggalPotong.toIso8601String(),
        'targetQtyPotong': targetQtyPotong,
        'realisasiPotong': realisasiPotong,
        'status': status,
      };

  factory SpkLotPotong.fromJson(Map<String, Object?> j) => SpkLotPotong(
        id: _str(j['id']),
        nomorSpk: _str(j['nomorSpk']),
        modelId: _str(j['modelId']),
        modelNama: _str(j['modelNama']),
        tanggalPotong: _date(j['tanggalPotong'], DateTime(2026, 10, 1)),
        targetQtyPotong: _int(j['targetQtyPotong']),
        realisasiPotong: _int(j['realisasiPotong']),
        status: _str(j['status'], 'IN_PROGRESS'),
      );
}

// ---------------------------------------------------------------------------
// Master Proses Operasi & Tarif Borongan (Eksklusif Pemilik)
// ---------------------------------------------------------------------------

@immutable
class ProsesOperasiTarif {
  const ProsesOperasiTarif({
    required this.id,
    required this.modelId,
    required this.divisi,
    required this.namaProses,
    required this.urutanOperasi,
    required this.tarifPerPotong,
    this.dendaRejectFatal = 0,
    this.updatedAt,
  });

  final String id;
  final String modelId;
  final DivisiBagian divisi;
  final String namaProses;
  final int urutanOperasi;
  final int tarifPerPotong; // Rp per potong lolos QC
  final int dendaRejectFatal; // Rp per potong cacat bahan rusak
  final DateTime? updatedAt;

  ProsesOperasiTarif copyWith({
    int? tarifPerPotong,
    int? dendaRejectFatal,
    String? namaProses,
    int? urutanOperasi,
  }) =>
      ProsesOperasiTarif(
        id: id,
        modelId: modelId,
        divisi: divisi,
        namaProses: namaProses ?? this.namaProses,
        urutanOperasi: urutanOperasi ?? this.urutanOperasi,
        tarifPerPotong: tarifPerPotong ?? this.tarifPerPotong,
        dendaRejectFatal: dendaRejectFatal ?? this.dendaRejectFatal,
        updatedAt: DateTime.now(),
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'modelId': modelId,
        'divisi': divisi.name,
        'namaProses': namaProses,
        'urutanOperasi': urutanOperasi,
        'tarifPerPotong': tarifPerPotong,
        'dendaRejectFatal': dendaRejectFatal,
        'updatedAt': updatedAt?.toIso8601String(),
      };

  factory ProsesOperasiTarif.fromJson(Map<String, Object?> j) => ProsesOperasiTarif(
        id: _str(j['id']),
        modelId: _str(j['modelId']),
        divisi: DivisiBagian.parse(j['divisi']),
        namaProses: _str(j['namaProses']),
        urutanOperasi: _int(j['urutanOperasi'], 1),
        tarifPerPotong: _int(j['tarifPerPotong']),
        dendaRejectFatal: _int(j['dendaRejectFatal']),
        updatedAt: j['updatedAt'] is String
            ? DateTime.tryParse(j['updatedAt'] as String)
            : null,
      );
}

// ---------------------------------------------------------------------------
// Hasil Kerja Harian (Price Snapshot Architecture & Dual Reject)
// ---------------------------------------------------------------------------

@immutable
class HasilKerjaHarian {
  const HasilKerjaHarian({
    required this.id,
    required this.spkLotId,
    required this.nomorSpk,
    required this.tanggal,
    required this.karyawanId,
    required this.karyawanNama,
    required this.prosesTarifId,
    required this.namaProses,
    required this.qtyBagus,
    this.qtyRework = 0,
    this.qtyRejectFatal = 0,
    required this.snapshotTarif,
    required this.snapshotDenda,
    this.isVerified = false,
    this.verifiedByUser,
    this.verifiedAt,
  });

  final String id;
  final String spkLotId;
  final String nomorSpk;
  final DateTime tanggal;
  final String karyawanId;
  final String karyawanNama;
  final String prosesTarifId;
  final String namaProses;

  final int qtyBagus;
  final int qtyRework; // Cacat minor (wajib perbaiki, upah ditahan)
  final int qtyRejectFatal; // Kain rusak permanen (potong denda)

  // Price Snapshots: Saved permanently upon record creation
  final int snapshotTarif;
  final int snapshotDenda;

  final bool isVerified;
  final String? verifiedByUser;
  final DateTime? verifiedAt;

  int get upahBruto => qtyBagus * snapshotTarif;
  int get totalDenda => qtyRejectFatal * snapshotDenda;
  int get upahBersihHarian => (upahBruto - totalDenda).clamp(0, 100000000);

  HasilKerjaHarian copyWith({
    int? qtyBagus,
    int? qtyRework,
    int? qtyRejectFatal,
    bool? isVerified,
    String? verifiedByUser,
    DateTime? verifiedAt,
  }) =>
      HasilKerjaHarian(
        id: id,
        spkLotId: spkLotId,
        nomorSpk: nomorSpk,
        tanggal: tanggal,
        karyawanId: karyawanId,
        karyawanNama: karyawanNama,
        prosesTarifId: prosesTarifId,
        namaProses: namaProses,
        qtyBagus: qtyBagus ?? this.qtyBagus,
        qtyRework: qtyRework ?? this.qtyRework,
        qtyRejectFatal: qtyRejectFatal ?? this.qtyRejectFatal,
        snapshotTarif: snapshotTarif,
        snapshotDenda: snapshotDenda,
        isVerified: isVerified ?? this.isVerified,
        verifiedByUser: verifiedByUser ?? this.verifiedByUser,
        verifiedAt: verifiedAt ?? this.verifiedAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'spkLotId': spkLotId,
        'nomorSpk': nomorSpk,
        'tanggal': tanggal.toIso8601String(),
        'karyawanId': karyawanId,
        'karyawanNama': karyawanNama,
        'prosesTarifId': prosesTarifId,
        'namaProses': namaProses,
        'qtyBagus': qtyBagus,
        'qtyRework': qtyRework,
        'qtyRejectFatal': qtyRejectFatal,
        'snapshotTarif': snapshotTarif,
        'snapshotDenda': snapshotDenda,
        'isVerified': isVerified,
        'verifiedByUser': verifiedByUser,
        'verifiedAt': verifiedAt?.toIso8601String(),
      };

  factory HasilKerjaHarian.fromJson(Map<String, Object?> j) => HasilKerjaHarian(
        id: _str(j['id']),
        spkLotId: _str(j['spkLotId']),
        nomorSpk: _str(j['nomorSpk']),
        tanggal: _date(j['tanggal'], DateTime(2026, 10, 1)),
        karyawanId: _str(j['karyawanId']),
        karyawanNama: _str(j['karyawanNama']),
        prosesTarifId: _str(j['prosesTarifId']),
        namaProses: _str(j['namaProses']),
        qtyBagus: _int(j['qtyBagus']),
        qtyRework: _int(j['qtyRework']),
        qtyRejectFatal: _int(j['qtyRejectFatal']),
        snapshotTarif: _int(j['snapshotTarif']),
        snapshotDenda: _int(j['snapshotDenda']),
        isVerified: j['isVerified'] == true,
        verifiedByUser: j['verifiedByUser'] is String ? j['verifiedByUser'] as String : null,
        verifiedAt: j['verifiedAt'] is String ? DateTime.tryParse(j['verifiedAt'] as String) : null,
      );
}

// ---------------------------------------------------------------------------
// Presensi Harian Konveksi
// ---------------------------------------------------------------------------

@immutable
class PresensiHarian {
  const PresensiHarian({
    required this.id,
    required this.tanggal,
    required this.karyawanId,
    required this.status,
    this.jamLembur = 0.0,
    this.uangMakanLembur = 0, // Flat allowance for piece-rate overtime
    this.checkIn,
    this.checkOut,
    this.isVerified = false,
    this.verifiedByUser,
  });

  final String id;
  final DateTime tanggal;
  final String karyawanId;
  final AttendanceStatus status;
  final double jamLembur;
  final int uangMakanLembur;
  final String? checkIn;
  final String? checkOut;
  final bool isVerified;
  final String? verifiedByUser;

  Map<String, Object?> toJson() => {
        'id': id,
        'tanggal': tanggal.toIso8601String(),
        'karyawanId': karyawanId,
        'status': status.name,
        'jamLembur': jamLembur,
        'uangMakanLembur': uangMakanLembur,
        'checkIn': checkIn,
        'checkOut': checkOut,
        'isVerified': isVerified,
        'verifiedByUser': verifiedByUser,
      };

  factory PresensiHarian.fromJson(Map<String, Object?> j) => PresensiHarian(
        id: _str(j['id']),
        tanggal: _date(j['tanggal'], DateTime(2026, 10, 1)),
        karyawanId: _str(j['karyawanId']),
        status: AttendanceStatus.parse(j['status']),
        jamLembur: _double(j['jamLembur']),
        uangMakanLembur: _int(j['uangMakanLembur']),
        checkIn: j['checkIn'] is String ? j['checkIn'] as String : null,
        checkOut: j['checkOut'] is String ? j['checkOut'] as String : null,
        isVerified: j['isVerified'] == true,
        verifiedByUser: j['verifiedByUser'] is String ? j['verifiedByUser'] as String : null,
      );
}

// ---------------------------------------------------------------------------
// Kasbon & Pinjaman (50% THP Floor & Auto Debt Rollover)
// ---------------------------------------------------------------------------

@immutable
class Loan {
  const Loan({
    required this.id,
    required this.employeeId,
    required this.amount,
    required this.deduction,
    required this.createdAt,
    this.syncToPayroll = true,
    this.note = '',
    this.sisaSaldo,
  });

  final String id;
  final String employeeId;
  final int amount; // Total pinjaman awal
  final int deduction; // Target cicilan mingguan
  final int? sisaSaldo; // Sisa hutang aktual
  final bool syncToPayroll;
  final String note;
  final DateTime createdAt;

  int get remaining => sisaSaldo ?? (amount - deduction).clamp(0, amount);
  bool get isPaidOff => remaining == 0;
  String get statusLabel => isPaidOff ? 'Lunas' : 'Belum lunas';

  Loan copyWith({
    int? amount,
    int? deduction,
    int? sisaSaldo,
    bool? syncToPayroll,
    String? note,
  }) =>
      Loan(
        id: id,
        employeeId: employeeId,
        amount: amount ?? this.amount,
        deduction: deduction ?? this.deduction,
        sisaSaldo: sisaSaldo ?? this.sisaSaldo,
        syncToPayroll: syncToPayroll ?? this.syncToPayroll,
        note: note ?? this.note,
        createdAt: createdAt,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'amount': amount,
        'deduction': deduction,
        'sisaSaldo': sisaSaldo ?? remaining,
        'syncToPayroll': syncToPayroll,
        'note': note,
        'createdAt': createdAt.toIso8601String(),
      };

  factory Loan.fromJson(Map<String, Object?> j) => Loan(
        id: _str(j['id']),
        employeeId: _str(j['employeeId']),
        amount: _int(j['amount']),
        deduction: _int(j['deduction']),
        sisaSaldo: j['sisaSaldo'] != null ? _int(j['sisaSaldo']) : null,
        syncToPayroll: j['syncToPayroll'] != false,
        note: _str(j['note']),
        createdAt: _date(j['createdAt'], DateTime(2026, 10, 1)),
      );
}

// ---------------------------------------------------------------------------
// Rekapitulasi Mingguan & State Machine Penggajian
// ---------------------------------------------------------------------------

@immutable
class RekapMingguan {
  const RekapMingguan({
    required this.id,
    required this.kodePeriode,
    required this.tanggalMulai,
    required this.tanggalSelesai,
    this.status = StatusRekap.draft,
    this.verifiedByUser,
    this.verifiedAt,
    this.approvedByUser,
    this.approvedAt,
    this.paidByUser,
    this.paidAt,
    this.isLocked = false,
  });

  final String id;
  final String kodePeriode; // e.g. PERIODE-2026-W43
  final DateTime tanggalMulai;
  final DateTime tanggalSelesai;
  final StatusRekap status;
  final String? verifiedByUser;
  final DateTime? verifiedAt;
  final String? approvedByUser;
  final DateTime? approvedAt;
  final String? paidByUser;
  final DateTime? paidAt;
  final bool isLocked;

  RekapMingguan copyWith({
    StatusRekap? status,
    String? verifiedByUser,
    DateTime? verifiedAt,
    String? approvedByUser,
    DateTime? approvedAt,
    String? paidByUser,
    DateTime? paidAt,
    bool? isLocked,
  }) =>
      RekapMingguan(
        id: id,
        kodePeriode: kodePeriode,
        tanggalMulai: tanggalMulai,
        tanggalSelesai: tanggalSelesai,
        status: status ?? this.status,
        verifiedByUser: verifiedByUser ?? this.verifiedByUser,
        verifiedAt: verifiedAt ?? this.verifiedAt,
        approvedByUser: approvedByUser ?? this.approvedByUser,
        approvedAt: approvedAt ?? this.approvedAt,
        paidByUser: paidByUser ?? this.paidByUser,
        paidAt: paidAt ?? this.paidAt,
        isLocked: isLocked ?? this.isLocked,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'kodePeriode': kodePeriode,
        'tanggalMulai': tanggalMulai.toIso8601String(),
        'tanggalSelesai': tanggalSelesai.toIso8601String(),
        'status': status.name,
        'verifiedByUser': verifiedByUser,
        'verifiedAt': verifiedAt?.toIso8601String(),
        'approvedByUser': approvedByUser,
        'approvedAt': approvedAt?.toIso8601String(),
        'paidByUser': paidByUser,
        'paidAt': paidAt?.toIso8601String(),
        'isLocked': isLocked,
      };

  factory RekapMingguan.fromJson(Map<String, Object?> j) => RekapMingguan(
        id: _str(j['id']),
        kodePeriode: _str(j['kodePeriode']),
        tanggalMulai: _date(j['tanggalMulai'], DateTime(2026, 10, 19)),
        tanggalSelesai: _date(j['tanggalSelesai'], DateTime(2026, 10, 24)),
        status: StatusRekap.parse(j['status']),
        verifiedByUser: j['verifiedByUser'] is String ? j['verifiedByUser'] as String : null,
        verifiedAt: j['verifiedAt'] is String ? DateTime.tryParse(j['verifiedAt'] as String) : null,
        approvedByUser: j['approvedByUser'] is String ? j['approvedByUser'] as String : null,
        approvedAt: j['approvedAt'] is String ? DateTime.tryParse(j['approvedAt'] as String) : null,
        paidByUser: j['paidByUser'] is String ? j['paidByUser'] as String : null,
        paidAt: j['paidAt'] is String ? DateTime.tryParse(j['paidAt'] as String) : null,
        isLocked: j['isLocked'] == true,
      );
}

// ---------------------------------------------------------------------------
// Slip Gaji Mingguan (Official Breakdown & WhatsApp Ready)
// ---------------------------------------------------------------------------

@immutable
class SlipGajiMingguan {
  const SlipGajiMingguan({
    required this.id,
    required this.rekapId,
    required this.karyawanId,
    required this.karyawanNama,
    required this.divisi,
    required this.tipeGaji,
    required this.totalHariHadir,
    required this.totalPotongBagus,
    required this.totalUpahDasar,
    required this.totalUpahBorong,
    required this.totalLembur,
    required this.totalBonus,
    required this.potonganKasbon,
    required this.potonganDenda,
    required this.thpBersih,
    required this.metodeBayar,
    this.statusBayar = false,
    this.nomorSlipResmi,
  });

  final String id;
  final String rekapId;
  final String karyawanId;
  final String karyawanNama;
  final DivisiBagian divisi;
  final TipeGaji tipeGaji;
  final int totalHariHadir;
  final int totalPotongBagus;
  final int totalUpahDasar;
  final int totalUpahBorong;
  final int totalLembur;
  final int totalBonus;
  final int potonganKasbon;
  final int potonganDenda;
  final int thpBersih;
  final MetodePembayaran metodeBayar;
  final bool statusBayar;
  final String? nomorSlipResmi;

  int get upahKotor => totalUpahDasar + totalUpahBorong + totalLembur + totalBonus;
  int get totalPotongan => potonganKasbon + potonganDenda;

  SlipGajiMingguan copyWith({
    bool? statusBayar,
    String? nomorSlipResmi,
  }) =>
      SlipGajiMingguan(
        id: id,
        rekapId: rekapId,
        karyawanId: karyawanId,
        karyawanNama: karyawanNama,
        divisi: divisi,
        tipeGaji: tipeGaji,
        totalHariHadir: totalHariHadir,
        totalPotongBagus: totalPotongBagus,
        totalUpahDasar: totalUpahDasar,
        totalUpahBorong: totalUpahBorong,
        totalLembur: totalLembur,
        totalBonus: totalBonus,
        potonganKasbon: potonganKasbon,
        potonganDenda: potonganDenda,
        thpBersih: thpBersih,
        metodeBayar: metodeBayar,
        statusBayar: statusBayar ?? this.statusBayar,
        nomorSlipResmi: nomorSlipResmi ?? this.nomorSlipResmi,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'rekapId': rekapId,
        'karyawanId': karyawanId,
        'karyawanNama': karyawanNama,
        'divisi': divisi.name,
        'tipeGaji': tipeGaji.name,
        'totalHariHadir': totalHariHadir,
        'totalPotongBagus': totalPotongBagus,
        'totalUpahDasar': totalUpahDasar,
        'totalUpahBorong': totalUpahBorong,
        'totalLembur': totalLembur,
        'totalBonus': totalBonus,
        'potonganKasbon': potonganKasbon,
        'potonganDenda': potonganDenda,
        'thpBersih': thpBersih,
        'metodeBayar': metodeBayar.name,
        'statusBayar': statusBayar,
        'nomorSlipResmi': nomorSlipResmi,
      };

  factory SlipGajiMingguan.fromJson(Map<String, Object?> j) => SlipGajiMingguan(
        id: _str(j['id']),
        rekapId: _str(j['rekapId']),
        karyawanId: _str(j['karyawanId']),
        karyawanNama: _str(j['karyawanNama']),
        divisi: DivisiBagian.parse(j['divisi']),
        tipeGaji: TipeGaji.parse(j['tipeGaji']),
        totalHariHadir: _int(j['totalHariHadir']),
        totalPotongBagus: _int(j['totalPotongBagus']),
        totalUpahDasar: _int(j['totalUpahDasar']),
        totalUpahBorong: _int(j['totalUpahBorong']),
        totalLembur: _int(j['totalLembur']),
        totalBonus: _int(j['totalBonus']),
        potonganKasbon: _int(j['potonganKasbon']),
        potonganDenda: _int(j['potonganDenda']),
        thpBersih: _int(j['thpBersih']),
        metodeBayar: MetodePembayaran.parse(j['metodeBayar']),
        statusBayar: j['statusBayar'] == true,
        nomorSlipResmi: j['nomorSlipResmi'] is String ? j['nomorSlipResmi'] as String : null,
      );
}

// ---------------------------------------------------------------------------
// Security Audit Log (Immutable Event Tracking)
// ---------------------------------------------------------------------------

@immutable
class AuditEntry {
  const AuditEntry({
    required this.at,
    required this.action,
    required this.detail,
    this.userName = 'Sistem',
    this.role = 'SUPER_ADMIN',
  });

  final DateTime at;
  final String action;
  final String detail;
  final String userName;
  final String role;

  Map<String, Object?> toJson() => {
        'at': at.toIso8601String(),
        'a': action,
        'd': detail,
        'u': userName,
        'r': role,
      };

  factory AuditEntry.fromJson(Map<String, Object?> j) => AuditEntry(
        at: _date(j['at'], DateTime(2026)),
        action: _str(j['a']),
        detail: _str(j['d']),
        userName: _str(j['u'], 'Sistem'),
        role: _str(j['r'], 'SUPER_ADMIN'),
      );
}

// ---------------------------------------------------------------------------
// Old / Compatibility Classes
// ---------------------------------------------------------------------------

@immutable
class PayrollLine {
  const PayrollLine({
    required this.employee,
    required this.loanDeduction,
  });

  final Employee employee;
  final int loanDeduction;

  int get base => employee.baseSalary;
  int get allowance => employee.allowance;
  int get gross => base + allowance;
  int get statutory => employee.statutoryDeduction;
  int get deduction => statutory + loanDeduction;
  int get net => gross - deduction;
  PayrollStatus get status => employee.status;
}

@immutable
class AttendanceRecord {
  const AttendanceRecord({
    required this.employeeId,
    required this.day,
    required this.status,
    this.jamLembur = 0.0,
    this.checkIn,
    this.checkOut,
  });

  final String employeeId;
  final String day;
  final AttendanceStatus status;
  final double jamLembur;
  final String? checkIn;
  final String? checkOut;

  AttendanceRecord copyWith({
    AttendanceStatus? status,
    double? jamLembur,
    String? checkIn,
    String? checkOut,
    bool clearTimes = false,
  }) =>
      AttendanceRecord(
        employeeId: employeeId,
        day: day,
        status: status ?? this.status,
        jamLembur: jamLembur ?? this.jamLembur,
        checkIn: clearTimes ? null : (checkIn ?? this.checkIn),
        checkOut: clearTimes ? null : (checkOut ?? this.checkOut),
      );

  Map<String, Object?> toJson() => {
        'e': employeeId,
        'd': day,
        's': status.name,
        'l': jamLembur,
        'i': checkIn,
        'o': checkOut,
      };

  factory AttendanceRecord.fromJson(Map<String, Object?> j) => AttendanceRecord(
        employeeId: _str(j['e']),
        day: _str(j['d']),
        status: AttendanceStatus.parse(j['s']),
        jamLembur: _double(j['l']),
        checkIn: j['i'] is String ? j['i'] as String : null,
        checkOut: j['o'] is String ? j['o'] as String : null,
      );
}

@immutable
class Reimbursement {
  const Reimbursement({
    required this.id,
    required this.employeeId,
    required this.category,
    required this.description,
    required this.amount,
    required this.date,
    this.status = ReimbursementStatus.pending,
  });

  final String id;
  final String employeeId;
  final String category;
  final String description;
  final int amount;
  final DateTime date;
  final ReimbursementStatus status;

  Reimbursement copyWith({ReimbursementStatus? status}) => Reimbursement(
        id: id,
        employeeId: employeeId,
        category: category,
        description: description,
        amount: amount,
        date: date,
        status: status ?? this.status,
      );

  Map<String, Object?> toJson() => {
        'id': id,
        'employeeId': employeeId,
        'category': category,
        'description': description,
        'amount': amount,
        'date': date.toIso8601String(),
        'status': status.name,
      };

  factory Reimbursement.fromJson(Map<String, Object?> j) => Reimbursement(
        id: _str(j['id']),
        employeeId: _str(j['employeeId']),
        category: _str(j['category'], 'Lainnya'),
        description: _str(j['description']),
        amount: _int(j['amount']),
        date: _date(j['date'], DateTime(2026, 10, 1)),
        status: ReimbursementStatus.parse(j['status']),
      );
}

@immutable
class AppSettings {
  const AppSettings({
    this.companyName = 'Konveksi Berkah Garment',
    this.payday = 25,
    this.autoLockMinutes = 5,
    this.secureScreen = true,
  });

  final String companyName;
  final int payday;
  final int autoLockMinutes;
  final bool secureScreen;

  AppSettings copyWith({
    String? companyName,
    int? payday,
    int? autoLockMinutes,
    bool? secureScreen,
  }) =>
      AppSettings(
        companyName: companyName ?? this.companyName,
        payday: payday ?? this.payday,
        autoLockMinutes: autoLockMinutes ?? this.autoLockMinutes,
        secureScreen: secureScreen ?? this.secureScreen,
      );

  Map<String, Object?> toJson() => {
        'companyName': companyName,
        'payday': payday,
        'autoLockMinutes': autoLockMinutes,
        'secureScreen': secureScreen,
      };

  factory AppSettings.fromJson(Map<String, Object?> j) => AppSettings(
        companyName: _str(j['companyName'], 'Konveksi Berkah Garment'),
        payday: _int(j['payday'], 25).clamp(1, 28),
        autoLockMinutes: _int(j['autoLockMinutes'], 5).clamp(1, 60),
        secureScreen: j['secureScreen'] != false,
      );
}

import 'models.dart';

/// Dataset awal realistis Konveksi Berkah Garment (Periode Akhir Oktober 2026).
abstract final class Seed {
  static const periodYear = 2026;
  static const periodMonth = 10;
  static final lastUpdated = DateTime(2026, 10, 24, 17, 0);

  // ---------------------------------------------------------------------------
  // 5 Akun Pengguna Demo (5 Role Terisolasi)
  // ---------------------------------------------------------------------------
  static List<UserAccount> users() => [
        const UserAccount(
          id: 'USR-001',
          name: 'Bambang Sujatmiko (Super Admin)',
          email: 'superadmin@payrole.id',
          role: UserRole.superAdmin,
          phone: '081122334401',
        ),
        const UserAccount(
          id: 'USR-002',
          name: 'H. Suryanto (Pemilik/Owner)',
          email: 'owner@payrole.id',
          role: UserRole.pemilik,
          phone: '081122334402',
        ),
        const UserAccount(
          id: 'USR-003',
          name: 'Anita Putri (Admin Keuangan)',
          email: 'admin@payrole.id',
          role: UserRole.adminKeuangan,
          phone: '081122334403',
        ),
        const UserAccount(
          id: 'USR-004',
          name: 'Pak Joko (Mandor Jahit)',
          email: 'mandor.jahit@payrole.id',
          role: UserRole.mandor,
          divisiMandor: DivisiBagian.jahit,
          phone: '081122334404',
        ),
        const UserAccount(
          id: 'USR-005',
          name: 'Aditya Pratama (Penjahit)',
          email: 'aditya@payrole.id',
          role: UserRole.karyawan,
          karyawanId: 'KNV-001',
          phone: '081234560001',
        ),
      ];

  // ---------------------------------------------------------------------------
  // Master Model / Katalog Produk Pakaian
  // ---------------------------------------------------------------------------
  static List<ProdukModel> products() => [
        const ProdukModel(
          id: 'PRD-01',
          kodeModel: 'KFL-01',
          namaModel: 'Kemeja Flanel Lengan Panjang',
          deskripsi: 'Kemeja flanel katun premium, saku kiri, kancing depan',
        ),
        const ProdukModel(
          id: 'PRD-02',
          kodeModel: 'KPC-02',
          namaModel: 'Kaos Polos Cotton Combed 30s',
          deskripsi: 'Kaos oblong o-neck combed 30s reaktif super soft',
        ),
        const ProdukModel(
          id: 'PRD-03',
          kodeModel: 'HZF-03',
          namaModel: 'Hoodie Zipper Cotton Fleece',
          deskripsi: 'Jaket hoodie fleece 280 gsm, resleting besi ykk, tali katun',
        ),
      ];

  // ---------------------------------------------------------------------------
  // SPK / Lot Potong (Anti-Phantom Output Quota Guard)
  // ---------------------------------------------------------------------------
  static List<SpkLotPotong> spkLots() => [
        SpkLotPotong(
          id: 'SPK-LOT-101',
          nomorSpk: 'SPK-2026-101',
          modelId: 'PRD-01',
          modelNama: 'Kemeja Flanel Lengan Panjang',
          tanggalPotong: DateTime(2026, 10, 19),
          targetQtyPotong: 500,
          realisasiPotong: 500,
          status: 'IN_PROGRESS',
        ),
        SpkLotPotong(
          id: 'SPK-LOT-102',
          nomorSpk: 'SPK-2026-102',
          modelId: 'PRD-02',
          modelNama: 'Kaos Polos Cotton Combed 30s',
          tanggalPotong: DateTime(2026, 10, 20),
          targetQtyPotong: 1000,
          realisasiPotong: 1020, // Realisasi potong lebih 20 pcs
          status: 'IN_PROGRESS',
        ),
        SpkLotPotong(
          id: 'SPK-LOT-103',
          nomorSpk: 'SPK-2026-103',
          modelId: 'PRD-03',
          modelNama: 'Hoodie Zipper Cotton Fleece',
          tanggalPotong: DateTime(2026, 10, 21),
          targetQtyPotong: 300,
          realisasiPotong: 300,
          status: 'IN_PROGRESS',
        ),
      ];

  // ---------------------------------------------------------------------------
  // Master Proses & Tarif Borongan (Eksklusif Pemilik)
  // ---------------------------------------------------------------------------
  static List<ProsesOperasiTarif> processes() => [
        // Kemeja Flanel (PRD-01)
        const ProsesOperasiTarif(
          id: 'PRC-001',
          modelId: 'PRD-01',
          divisi: DivisiBagian.potong,
          namaProses: 'Potong Pola Kain Flanel',
          urutanOperasi: 1,
          tarifPerPotong: 400,
          dendaRejectFatal: 5000,
        ),
        const ProsesOperasiTarif(
          id: 'PRC-002',
          modelId: 'PRD-01',
          divisi: DivisiBagian.jahit,
          namaProses: 'Jahit Pasang Kerah & Saku',
          urutanOperasi: 2,
          tarifPerPotong: 1200,
          dendaRejectFatal: 8000,
        ),
        const ProsesOperasiTarif(
          id: 'PRC-003',
          modelId: 'PRD-01',
          divisi: DivisiBagian.jahit,
          namaProses: 'Jahit Sambung Badan & Manset',
          urutanOperasi: 3,
          tarifPerPotong: 1800,
          dendaRejectFatal: 8000,
        ),
        const ProsesOperasiTarif(
          id: 'PRC-004',
          modelId: 'PRD-01',
          divisi: DivisiBagian.obras,
          namaProses: 'Obras Keliling Flanel',
          urutanOperasi: 4,
          tarifPerPotong: 700,
          dendaRejectFatal: 4000,
        ),
        const ProsesOperasiTarif(
          id: 'PRC-005',
          modelId: 'PRD-01',
          divisi: DivisiBagian.pasangKancing,
          namaProses: 'Lubang & Pasang 7 Kancing',
          urutanOperasi: 5,
          tarifPerPotong: 500,
          dendaRejectFatal: 2000,
        ),
        const ProsesOperasiTarif(
          id: 'PRC-006',
          modelId: 'PRD-01',
          divisi: DivisiBagian.qc,
          namaProses: 'QC & Periksa Ukuran',
          urutanOperasi: 6,
          tarifPerPotong: 300,
          dendaRejectFatal: 0,
        ),
        const ProsesOperasiTarif(
          id: 'PRC-007',
          modelId: 'PRD-01',
          divisi: DivisiBagian.packing,
          namaProses: 'Setrika Uap & Plastik OPP',
          urutanOperasi: 7,
          tarifPerPotong: 350,
          dendaRejectFatal: 1000,
        ),

        // Kaos Polos Combed 30s (PRD-02)
        const ProsesOperasiTarif(
          id: 'PRC-010',
          modelId: 'PRD-02',
          divisi: DivisiBagian.potong,
          namaProses: 'Potong Tumpuk Kaos Combed',
          urutanOperasi: 1,
          tarifPerPotong: 250,
          dendaRejectFatal: 4000,
        ),
        const ProsesOperasiTarif(
          id: 'PRC-011',
          modelId: 'PRD-02',
          divisi: DivisiBagian.obras,
          namaProses: 'Obras Sambung Pundak & Lengan',
          urutanOperasi: 2,
          tarifPerPotong: 650,
          dendaRejectFatal: 3000,
        ),
        const ProsesOperasiTarif(
          id: 'PRC-012',
          modelId: 'PRD-02',
          divisi: DivisiBagian.jahit,
          namaProses: 'Jahit Pasang Rib Leher (Bisban)',
          urutanOperasi: 3,
          tarifPerPotong: 550,
          dendaRejectFatal: 3000,
        ),
        const ProsesOperasiTarif(
          id: 'PRC-013',
          modelId: 'PRD-02',
          divisi: DivisiBagian.jahit,
          namaProses: 'Overdeck Bawah & Ujung Lengan',
          urutanOperasi: 4,
          tarifPerPotong: 450,
          dendaRejectFatal: 2500,
        ),
        const ProsesOperasiTarif(
          id: 'PRC-014',
          modelId: 'PRD-02',
          divisi: DivisiBagian.packing,
          namaProses: 'Finishing Benang & Lipat Lusinan',
          urutanOperasi: 5,
          tarifPerPotong: 200,
          dendaRejectFatal: 1000,
        ),
      ];

  // ---------------------------------------------------------------------------
  // Data Karyawan Konveksi Nyata
  // ---------------------------------------------------------------------------
  static List<Employee> employees() => [
        // Penjahit Borongan
        Employee(
          id: 'KNV-001',
          name: 'Aditya Pratama',
          department: 'Jahit (Sewing)',
          position: 'Tukang Jahit Senior',
          email: 'aditya@payrole.id',
          phone: '081234560001',
          joinDate: DateTime(2022, 2, 1),
          baseSalary: 0,
          allowance: 50000, // Tunjangan hadir
          divisi: DivisiBagian.jahit,
          tipeGaji: TipeGaji.boronganMurni,
          tarifHarianDasar: 0,
          tarifLemburPerJam: 0,
          metodeBayar: MetodePembayaran.tunaiAmplop,
          status: PayrollStatus.review,
        ),
        Employee(
          id: 'KNV-002',
          name: 'Budi Santoso',
          department: 'Jahit (Sewing)',
          position: 'Tukang Jahit Badan',
          email: 'budi.santoso@payrole.id',
          phone: '081234560002',
          joinDate: DateTime(2022, 5, 10),
          baseSalary: 0,
          allowance: 50000,
          divisi: DivisiBagian.jahit,
          tipeGaji: TipeGaji.boronganMurni,
          tarifHarianDasar: 0,
          tarifLemburPerJam: 0,
          metodeBayar: MetodePembayaran.tunaiAmplop,
          status: PayrollStatus.review,
        ),
        Employee(
          id: 'KNV-003',
          name: 'Siti Aminah',
          department: 'Obras & Overdeck',
          position: 'Operator Mesin Obras',
          email: 'siti.aminah@payrole.id',
          phone: '081234560003',
          joinDate: DateTime(2023, 1, 15),
          baseSalary: 0,
          allowance: 50000,
          divisi: DivisiBagian.obras,
          tipeGaji: TipeGaji.boronganMurni,
          tarifHarianDasar: 0,
          tarifLemburPerJam: 0,
          metodeBayar: MetodePembayaran.transferBank,
          namaBank: 'BCA',
          nomorRekening: '8220192831',
          status: PayrollStatus.review,
        ),
        Employee(
          id: 'KNV-004',
          name: 'Wawan Setiawan',
          department: 'Potong (Cutting)',
          position: 'Kepala Meja Potong',
          email: 'wawan.potong@payrole.id',
          phone: '081234560004',
          joinDate: DateTime(2021, 6, 1),
          baseSalary: 850000, // Upah harian x 6 hari
          allowance: 100000,
          divisi: DivisiBagian.potong,
          tipeGaji: TipeGaji.harianMurni,
          tarifHarianDasar: 140000, // Rp140.000 / hari
          tarifLemburPerJam: 20000,
          metodeBayar: MetodePembayaran.transferBank,
          namaBank: 'BRI',
          nomorRekening: '034101002341503',
          status: PayrollStatus.review,
        ),
        Employee(
          id: 'KNV-005',
          name: 'Rian Hidayat',
          department: 'Potong (Cutting)',
          position: 'Helper Meja Potong',
          email: 'rian.helper@payrole.id',
          phone: '081234560005',
          joinDate: DateTime(2024, 3, 1),
          baseSalary: 600000,
          allowance: 50000,
          divisi: DivisiBagian.potong,
          tipeGaji: TipeGaji.harianMurni,
          tarifHarianDasar: 100000, // Rp100.000 / hari
          tarifLemburPerJam: 15000,
          metodeBayar: MetodePembayaran.tunaiAmplop,
          status: PayrollStatus.review,
        ),
        Employee(
          id: 'KNV-006',
          name: 'Dewi Sartika',
          department: 'Quality Control (QC)',
          position: 'Pemeriksa Jahitan (QC)',
          email: 'dewi.qc@payrole.id',
          phone: '081234560006',
          joinDate: DateTime(2023, 7, 1),
          baseSalary: 720000,
          allowance: 80000,
          divisi: DivisiBagian.qc,
          tipeGaji: TipeGaji.campuran,
          tarifHarianDasar: 120000,
          tarifLemburPerJam: 18000,
          metodeBayar: MetodePembayaran.eWallet,
          namaBank: 'DANA',
          nomorRekening: '081234560006',
          status: PayrollStatus.review,
        ),
        Employee(
          id: 'KNV-007',
          name: 'Agus Santoso',
          department: 'Packing & Lipat',
          position: 'Staf Setrika & Packing',
          email: 'agus.pack@payrole.id',
          phone: '081234560007',
          joinDate: DateTime(2023, 10, 1),
          baseSalary: 660000,
          allowance: 60000,
          divisi: DivisiBagian.packing,
          tipeGaji: TipeGaji.harianMurni,
          tarifHarianDasar: 110000,
          tarifLemburPerJam: 15000,
          metodeBayar: MetodePembayaran.tunaiAmplop,
          status: PayrollStatus.review,
        ),
      ];

  // ---------------------------------------------------------------------------
  // Hasil Kerja Harian Realistis (dengan Snapshot Tarif)
  // ---------------------------------------------------------------------------
  static List<HasilKerjaHarian> dailyWork() => [
        // Aditya Pratama (KNV-001) - Menjahit Kemeja Flanel
        HasilKerjaHarian(
          id: 'HK-001',
          spkLotId: 'SPK-LOT-101',
          nomorSpk: 'SPK-2026-101',
          tanggal: DateTime(2026, 10, 19),
          karyawanId: 'KNV-001',
          karyawanNama: 'Aditya Pratama',
          prosesTarifId: 'PRC-003',
          namaProses: 'Jahit Sambung Badan & Manset',
          qtyBagus: 85,
          qtyRework: 3,
          qtyRejectFatal: 0,
          snapshotTarif: 1800,
          snapshotDenda: 8000,
          isVerified: true,
          verifiedByUser: 'Pak Joko (Mandor)',
          verifiedAt: DateTime(2026, 10, 19, 17, 30),
        ),
        HasilKerjaHarian(
          id: 'HK-002',
          spkLotId: 'SPK-LOT-101',
          nomorSpk: 'SPK-2026-101',
          tanggal: DateTime(2026, 10, 20),
          karyawanId: 'KNV-001',
          karyawanNama: 'Aditya Pratama',
          prosesTarifId: 'PRC-003',
          namaProses: 'Jahit Sambung Badan & Manset',
          qtyBagus: 90,
          qtyRework: 1,
          qtyRejectFatal: 0,
          snapshotTarif: 1800,
          snapshotDenda: 8000,
          isVerified: true,
          verifiedByUser: 'Pak Joko (Mandor)',
          verifiedAt: DateTime(2026, 10, 20, 17, 30),
        ),
        HasilKerjaHarian(
          id: 'HK-003',
          spkLotId: 'SPK-LOT-101',
          nomorSpk: 'SPK-2026-101',
          tanggal: DateTime(2026, 10, 21),
          karyawanId: 'KNV-001',
          karyawanNama: 'Aditya Pratama',
          prosesTarifId: 'PRC-003',
          namaProses: 'Jahit Sambung Badan & Manset',
          qtyBagus: 95,
          qtyRework: 2,
          qtyRejectFatal: 1, // 1 pcs cacat fatal
          snapshotTarif: 1800,
          snapshotDenda: 8000,
          isVerified: true,
          verifiedByUser: 'Pak Joko (Mandor)',
          verifiedAt: DateTime(2026, 10, 21, 17, 30),
        ),
        HasilKerjaHarian(
          id: 'HK-004',
          spkLotId: 'SPK-LOT-101',
          nomorSpk: 'SPK-2026-101',
          tanggal: DateTime(2026, 10, 22),
          karyawanId: 'KNV-001',
          karyawanNama: 'Aditya Pratama',
          prosesTarifId: 'PRC-003',
          namaProses: 'Jahit Sambung Badan & Manset',
          qtyBagus: 88,
          qtyRework: 0,
          qtyRejectFatal: 0,
          snapshotTarif: 1800,
          snapshotDenda: 8000,
          isVerified: true,
          verifiedByUser: 'Pak Joko (Mandor)',
          verifiedAt: DateTime(2026, 10, 22, 17, 30),
        ),
        HasilKerjaHarian(
          id: 'HK-005',
          spkLotId: 'SPK-LOT-101',
          nomorSpk: 'SPK-2026-101',
          tanggal: DateTime(2026, 10, 23),
          karyawanId: 'KNV-001',
          karyawanNama: 'Aditya Pratama',
          prosesTarifId: 'PRC-003',
          namaProses: 'Jahit Sambung Badan & Manset',
          qtyBagus: 92,
          qtyRework: 2,
          qtyRejectFatal: 0,
          snapshotTarif: 1800,
          snapshotDenda: 8000,
          isVerified: true,
          verifiedByUser: 'Pak Joko (Mandor)',
          verifiedAt: DateTime(2026, 10, 23, 17, 30),
        ),

        // Budi Santoso (KNV-002) - Jahit Pasang Kerah Kemeja
        HasilKerjaHarian(
          id: 'HK-010',
          spkLotId: 'SPK-LOT-101',
          nomorSpk: 'SPK-2026-101',
          tanggal: DateTime(2026, 10, 19),
          karyawanId: 'KNV-002',
          karyawanNama: 'Budi Santoso',
          prosesTarifId: 'PRC-002',
          namaProses: 'Jahit Pasang Kerah & Saku',
          qtyBagus: 95,
          qtyRework: 4,
          qtyRejectFatal: 0,
          snapshotTarif: 1200,
          snapshotDenda: 8000,
          isVerified: true,
          verifiedByUser: 'Pak Joko (Mandor)',
          verifiedAt: DateTime(2026, 10, 19, 17, 30),
        ),
        HasilKerjaHarian(
          id: 'HK-011',
          spkLotId: 'SPK-LOT-101',
          nomorSpk: 'SPK-2026-101',
          tanggal: DateTime(2026, 10, 20),
          karyawanId: 'KNV-002',
          karyawanNama: 'Budi Santoso',
          prosesTarifId: 'PRC-002',
          namaProses: 'Jahit Pasang Kerah & Saku',
          qtyBagus: 100,
          qtyRework: 2,
          qtyRejectFatal: 0,
          snapshotTarif: 1200,
          snapshotDenda: 8000,
          isVerified: true,
          verifiedByUser: 'Pak Joko (Mandor)',
          verifiedAt: DateTime(2026, 10, 20, 17, 30),
        ),

        // Siti Aminah (KNV-003) - Obras Kaos Combed
        HasilKerjaHarian(
          id: 'HK-020',
          spkLotId: 'SPK-LOT-102',
          nomorSpk: 'SPK-2026-102',
          tanggal: DateTime(2026, 10, 20),
          karyawanId: 'KNV-003',
          karyawanNama: 'Siti Aminah',
          prosesTarifId: 'PRC-011',
          namaProses: 'Obras Sambung Pundak & Lengan',
          qtyBagus: 280,
          qtyRework: 5,
          qtyRejectFatal: 0,
          snapshotTarif: 650,
          snapshotDenda: 3000,
          isVerified: true,
          verifiedByUser: 'Pak Joko (Mandor)',
          verifiedAt: DateTime(2026, 10, 20, 17, 30),
        ),
      ];

  // ---------------------------------------------------------------------------
  // Data Kasbon Karyawan Konveksi (Pinjaman & Sisa Hutang)
  // ---------------------------------------------------------------------------
  static List<Loan> loans() => [
        Loan(
          id: 'KAS-001',
          employeeId: 'KNV-001', // Aditya Pratama
          amount: 600000, // Total pinjam
          deduction: 150000, // Target potong per minggu
          sisaSaldo: 350000, // Sisa hutang saat ini
          note: 'Kasbon bayar uang semester anak',
          createdAt: DateTime(2026, 10, 5),
          syncToPayroll: true,
        ),
        Loan(
          id: 'KAS-002',
          employeeId: 'KNV-002', // Budi Santoso
          amount: 400000,
          deduction: 100000,
          sisaSaldo: 200000,
          note: 'Tambahan sewa kontrakan',
          createdAt: DateTime(2026, 10, 12),
          syncToPayroll: true,
        ),
        Loan(
          id: 'KAS-003',
          employeeId: 'KNV-005', // Rian Helper
          amount: 250000,
          deduction: 75000,
          sisaSaldo: 100000,
          note: 'Beli obat keluarga',
          createdAt: DateTime(2026, 10, 8),
          syncToPayroll: true,
        ),
      ];

  // ---------------------------------------------------------------------------
  // Rekap Mingguan Berjalan (State Machine: Diverifikasi Mandor)
  // ---------------------------------------------------------------------------
  static List<RekapMingguan> weeklyRecaps() => [
        RekapMingguan(
          id: 'W-43-2026',
          kodePeriode: 'PERIODE-2026-W43',
          tanggalMulai: DateTime(2026, 10, 19),
          tanggalSelesai: DateTime(2026, 10, 24),
          status: StatusRekap.diverifikasiMandor, // Siap diperiksa Pemilik!
          verifiedByUser: 'Pak Joko (Mandor Jahit)',
          verifiedAt: DateTime(2026, 10, 24, 16, 45),
          isLocked: false,
        ),
        RekapMingguan(
          id: 'W-42-2026',
          kodePeriode: 'PERIODE-2026-W42',
          tanggalMulai: DateTime(2026, 10, 12),
          tanggalSelesai: DateTime(2026, 10, 17),
          status: StatusRekap.dibayar,
          verifiedByUser: 'Pak Joko (Mandor Jahit)',
          verifiedAt: DateTime(2026, 10, 17, 17, 0),
          approvedByUser: 'H. Suryanto (Pemilik)',
          approvedAt: DateTime(2026, 10, 18, 10, 30),
          paidByUser: 'Anita Putri (Admin Keuangan)',
          paidAt: DateTime(2026, 10, 19, 09, 0),
          isLocked: true,
        ),
      ];

  // ---------------------------------------------------------------------------
  // Jejak Audit Keamanan Awal
  // ---------------------------------------------------------------------------
  static List<AuditEntry> auditLogs() => [
        AuditEntry(
          at: DateTime(2026, 10, 19, 08, 0),
          action: 'LOGIN_SUCCESS',
          detail: 'Super Admin login dari workstation IP 192.168.1.10',
          userName: 'Bambang Sujatmiko',
          role: 'SUPER_ADMIN',
        ),
        AuditEntry(
          at: DateTime(2026, 10, 19, 09, 15),
          action: 'SPK_CREATED',
          detail: 'Dibuat SPK-2026-101 Kemeja Flanel (500 potong) oleh Pemilik',
          userName: 'H. Suryanto',
          role: 'PEMILIK',
        ),
        AuditEntry(
          at: DateTime(2026, 10, 24, 16, 45),
          action: 'WORK_VERIFIED',
          detail: 'Mandor Jahit mengunci verifikasi hasil kerja mingguan W-43',
          userName: 'Pak Joko',
          role: 'MANDOR',
        ),
      ];
  // ---------------------------------------------------------------------------
  // Riwayat Penggajian Bersih (Bulan ke Bulan)
  // ---------------------------------------------------------------------------
  static List<NetHistoryPoint> get netHistory => const [
        NetHistoryPoint(year: 2026, month: 7, net: 42500000),
        NetHistoryPoint(year: 2026, month: 8, net: 45200000),
        NetHistoryPoint(year: 2026, month: 9, net: 48900000),
      ];
}

class NetHistoryPoint {
  const NetHistoryPoint({
    required this.year,
    required this.month,
    required this.net,
  });

  final int year;
  final int month;
  final int net;
}

class AppRoutes {
  // AUTH
  static const login = '/login';
  static const register = '/register';
  static const verifyEmail = '/verify-email';
  static const forgotPassword = '/forgot-password';

  // MAIN SHELL (bottom bar)
  static const home = '/awal';

  // PROPERTY — Kos → Kamar → Penyewa
  static const listKos = '/kos';
  static const kosDetail = '/kos/detail';
  static const kosStatistik = '/kos/statistik';
  static const kosTambah = '/kos/tambah';
  static const kosEdit = '/kos/edit';
  static const kamarDetail = '/kamar/detail';
  static const kamarTambah = '/kamar/tambah';
  static const kamarEdit = '/kamar/edit';
  static const listPenyewa = '/penyewa';
  static const detailPenyewa = '/penyewa/detail';
  static const profilePenyewa = '/penyewa/profile';
  static const tambahPenyewaKontrak = '/penyewa/tambah';
  static const editPenyewa = '/penyewa/edit';
  static const kontrakDetail = '/kontrak/detail';
  static const kontrakEdit = '/kontrak/edit';

  // PEMBAYARAN — tagihan & transaksi
  static const detailTagihan = '/tagihan/detail';
  static const tagihanTambah = '/tagihan/tambah';
  static const tagihanEdit = '/tagihan/edit';

  // CONTROLL — operasional
  static const checkInCepat = '/check-in/cepat';
  static const dashboard = '/dashboard';
  static const keuangan = '/keuangan';

  // PROFILE
  static const profile = '/profile';
  static const settings = '/settings';
}

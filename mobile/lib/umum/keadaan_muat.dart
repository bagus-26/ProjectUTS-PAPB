/// Keadaan layar untuk penanganan pemanggilan data API
/// Sesuai spesifikasi UTS PAPB & Sistem Terdistribusi (Bagian 4 & 6)
enum KeadaanMuat {
  /// Sedang mengambil data dari server, tombol aksi dimatikan
  memuat,

  /// Data berhasil diperoleh dan siap ditampilkan
  berhasil,

  /// Data kosong (bukan galat, melainkan hasil pencarian/kategori tidak ada)
  kosong,

  /// Terjadi galat jaringan, timeout, atau galat server
  galat,
}


# Kontrak API v1 — Beku

Status: **dibekukan pada Hari 1** (4 November 2026) berdasarkan `docs/PRD.md` versi 1.1 Bagian 6.

## Ringkasan

- Pembungkus sukses: `status`, `code` (string), `message`, `data`.
- Pembungkus gagal: `status`, `code` (string), `message`, `data`, ditambah `errors` khusus 422.
- Identitas pembeli: `Authorization: Bearer <token pelanggan>` melalui middleware `PelangganStatis`.
- 16 endpoint: 14 wajib + `GET /api/kategori` + `GET /api/metode-pembayaran`.
- Kode status: 200, 201, 401, 404, 409, 422, 500.
- Checkout wajib `X-Kunci-Idempoten`, atomik, dan menyalin harga ke detail pesanan.
- Checkout di luar jam buka: 409 dengan `data.alasan = "toko_tutup"`.

## Aturan perubahan

1. Perubahan hanya lewat PR ke `docs/PRD.md` Bagian 6.
2. PR harus disetujui pemilik endpoint dan pemakai endpoint di Flutter.
3. Perubahan diumumkan di grup tim.
4. A3 memperbarui dokumen PDF dan koleksi Postman pada hari yang sama.
5. Jalur endpoint tidak diganti (D-01).

## Rujukan

- `docs/PRD.md` Bagian 6 (kontrak lengkap)
- `docs/PRD.md` Bagian 4.2 (keputusan desain D-01 sampai D-15)
- `docs/PRD.md` Bagian 12.3 (susunan dokumen PDF)

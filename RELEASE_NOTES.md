# Pembaruan The PAMs v1.0.24

Pembaruan The PAMs v1.0.24:

- **Dukungan Penuh Ekstraksi Berkas Memori Browser (Skema `blob:`)**:
  * Mengatasi error *"No host specified in URI blob:https://..."* saat menekan tombol **CETAK** pada menu Jadwal Kuliah, KRS, dan KHS MyUnpam.
  * Berkas PDF yang dibuat secara dinamis oleh JavaScript peramban (*client-side Blob*) kini langsung diekstraksi dari memori peramban menggunakan transmisi biner W3C compliant tanpa parameter credentials/headers yang memicu penolakan browser.
  * Mencegah Dio dari memproses URL skema `blob:` yang hanya ada di RAM peramban.
  * Otomatis memberikan nama berkas resmi yang bermakna (`Jadwal_Kuliah_ThePAMs_...`, `Cetak_KRS_ThePAMs_...`, dsb.) berdasarkan konteks halaman yang sedang aktif.
- **Pembersihan Menu The PAMs AI Tools**:
  * Menghapus opsi manual unduh berkas halaman agar tampilan menu asisten AI lebih bersih dan fokus pada kapabilitas kecerdasan buatan.
- **Pengujian & Kualitas**:
  * Seluruh 24 pengujian otomatis unit & widget tests lulus 100%.
  * Bebas dari error atau peringatan analisis (*0 issues*).

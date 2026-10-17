# Pembaruan UNPAM Mobile v1.0.17

Pembaruan UNPAM Mobile v1.0.17:

- Fitur Baru: Menu Riwayat Pembaruan Aplikasi di Menu Titik 3 (GitHub Releases Live Sync):
  * Mengambil dan menyinkronkan seluruh riwayat rilis aplikasi langsung dari GitHub API (`codewithtama/unpam_mobile`) secara otomatis tanpa hardcode.
  * Menampilkan informasi komprehensif untuk setiap versi: tag versi, tanggal rilis, changelog lengkap, ukuran berkas APK, jumlah unduhan, dan tautan langsung ke halaman rilis GitHub.
  * Dilengkapi detektor pintar untuk menandai versi yang sedang aktif digunakan ("Versi Terpasang Saat Ini") serta tombol cepat pasang jika terdapat versi rilis yang lebih baru.
  * Dukungan offline caching via SharedPreferences agar riwayat tetap dapat dibaca meski tanpa sambungan internet.
- Gerbang Izin Akses Wajib (Mandatory Permission Gatekeeper): Mewajibkan persetujuan seluruh izin perangkat yang dibutuhkan aplikasi (Notifikasi, Kamera untuk AI Vision OCR, serta Akses Media/Penyimpanan untuk berkas tugas) sebelum pengguna dapat masuk dan menggunakan aplikasi.
- Penanganan Izin Permanen (Settings Bridge): Menyediakan deteksi otomatis jika izin diblokir sistem dengan tombol pintas langsung ke menu Pengaturan Aplikasi HP, serta verifikasi otomatis sekembalinya pengguna ke aplikasi.
- Arsitektur AppGate: Mengintegrasikan verifikasi Syarat & Ketentuan Pengguna dan Gerbang Izin Akses secara terpusat pada startup aplikasi.
- Bebas Bug & Zero Overflow: Seluruh antarmuka dirancang responsif dan teruji bebas dari peringatan RenderFlex Overflow.

# Pembaruan UNPAM Mobile v1.0.16

Pembaruan UNPAM Mobile v1.0.16:

- Gerbang Izin Akses Wajib (Mandatory Permission Gatekeeper): Mewajibkan persetujuan seluruh izin perangkat yang dibutuhkan aplikasi sebelum pengguna dapat masuk dan menggunakan aplikasi. Apabila salah satu izin belum atau tidak disetujui, akses ke portal Mentari, MyUnpam, dan fitur aplikasi akan dibatasi demi kelancaran perkuliahan.
- Detail Izin yang Wajib Disetujui:
  * Notifikasi Sistem & Perkuliahan: Memastikan mahasiswa selalu mendapatkan pengingat tenggat tugas, jadwal kuliah, pembaruan materi LMS, dan notifikasi pembaruan aplikasi secara real-time.
  * Kamera (UNPAM AI Vision OCR): Diperlukan agar fitur asisten AI dapat memindai soal kuis, modul materi kuliah, dan dokumen secara langsung melalui kamera.
  * Foto & Media Penyimpanan: Diperlukan untuk mengunggah berkas jawaban tugas mahasiswa ke portal Mentari/MyUnpam serta memilih gambar dari galeri HP.
- Penanganan Izin Permanen (Settings Bridge): Menyediakan deteksi otomatis jika izin diblokir permanen oleh sistem Android dengan tombol pintas langsung ke menu Pengaturan Aplikasi HP, serta verifikasi otomatis sekembalinya pengguna ke aplikasi.
- Arsitektur AppGate: Mengintegrasikan alur Syarat & Ketentuan Pengguna (User Agreement) dan Gerbang Izin Akses secara terpusat pada startup aplikasi.
- Bebas Bug & Zero Overflow: Seluruh tata letak antarmuka dirancang responsif dan teruji bebas dari peringatan RenderFlex Overflow.

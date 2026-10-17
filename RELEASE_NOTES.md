# Pembaruan UNPAM Mobile v1.0.18

Pembaruan UNPAM Mobile v1.0.18:

- **Perbaikan Login Cepat Biometrik MyUnpam (SIAKAD)**:
  * Dukungan deteksi form login otomatis pada portal SIAKAD MyUnpam (`my.unpam.ac.id`) dan Satu Unpam SSO.
  * Selector cerdas untuk berbagai format field input NIM dan Password kampus (`user_id`, `userid`, `npm`, `mhs_nim`, `nim`, dll).
  * Menghilangkan kendala reload berulang (*redirect loop*) saat proses autentikasi biometrik berlangsung di MyUnpam.
  * Banner login biometrik dan menu aksi cepat di AppBar kini sepenuhnya sinkron dan responsif pada tab MyUnpam.

- **Penanganan Otomatis Logout & Layar Konfirmasi Redirect SSO**:
  * Intersepsi cerdas aksi logout pada portal MyUnpam sehingga pengguna langsung diarahkan kembali ke halaman login MyUnpam secara bersih.
  * *Instant Auto-Bypass* berbasis `MutationObserver` dan interval DOM untuk layar dialog "Konfirmasi Redirect" Satu Unpam SSO, secara otomatis memilih "Lanjutkan ke MY UNPAM" tanpa perlu intervensi manual pengguna.

- **Dukungan Unduh Berkas & Dokumen Akademik**:
  * Integrasi `FileDownloadService` untuk menangani unduhan berkas PDF perkuliahan, modul ajar, cetak KRS, cetak KHS, kartu ujian, dan transkrip nilai.
  * Terbuka langsung dengan aplikasi pembaca PDF default perangkat setelah proses unduhan selesai.

- **Peningkatan Responsivitas Antarmuka AI Tools**:
  * Optimasi layout dialog UNPAM AI Tools dan AI Paraphrase Screen agar bebas dari *RenderFlex Overflow* pada berbagai ukuran layar HP.

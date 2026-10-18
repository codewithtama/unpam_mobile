# Pembaruan The PAMs v1.0.23

Pembaruan The PAMs v1.0.23:

- **Bypass Proteksi Cloudflare pada Unduhan Berkas Akademik**:
  * Mengatasi kegagalan dan pemblokiran unduhan berkas PDF perkuliahan (Cetak KRS, KHS, Kartu Ujian UTS/UAS, Jadwal Kuliah, Modul LMS Moodle, Transkrip Nilai) oleh Cloudflare Turnstile & Bot Management.
  * Menerapkan arsitektur **In-WebView Chromium Fetch Bridge**: unduhan dieksekusi langsung di dalam konteks peramban WebView yang memegang sesi login resmi dan sidik jari TLS (*TLS Client Hello*) Chromium asli, menghindari diskrepansi TLS stack Dart/Dio.
  * Aliran biner berkas ditransfer secara aman menggunakan *chunked Base64 streaming* (256 KB per payload) langsung ke sistem penyimpanan lokal tanpa membebani memori (*Zero OOM/Binder Limit*).
  * Otomatis membuka dokumen hasil unduhan dengan aplikasi penampil PDF bawaan perangkat HP (Google PDF Viewer, WPS Office, Adobe Acrobat, dsb.).
  * Menyediakan lapisan cadangan (*Dio fallback*) dan opsi buka di browser eksternal jika dokumen berasal dari host eksternal (Google Drive, Dropbox, repo publik).
- **Format Penamaan Berkas Dokumen The PAMs**:
  * Nama dokumen akademik yang diunduh kini secara rapi diberi penanda resmi The PAMs (`Cetak_KRS_ThePAMs_...`, `Cetak_KHS_ThePAMs_...`, `Kartu_UTS_ThePAMs_...`, `Modul_Kuliah_ThePAMs_...`).
- **Peningkatan Stabilitas & Efisiensi Memori**:
  * Pembersihan berkas sementara secara otomatis setelah berkas dipindahkan ke folder Downloads.
  * Seluruh pengujian otomatis unit & widget test tervalidasi 100% lulus.

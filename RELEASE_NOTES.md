# Pembaruan UNPAM Mobile v1.0.19

Pembaruan UNPAM Mobile v1.0.19:

- **Perbaikan Notifikasi & Deteksi Pembaruan Otomatis (OTA)**:
  * Pembuatan Android Notification Channel v2 khusus dengan prioritas `Importance.max` dan `Priority.high` agar notifikasi update selalu muncul melayang (*heads-up banner*) di status bar HP tanpa perlu dicek manual.
  * Pengecekan otomatis kini berlangsung saat aplikasi dibuka (startup) dan setiap kali pengguna kembali ke aplikasi (*app resume*).
  * Menghilangkan kendala *early return* inisialisasi notifikasi sehingga ketukan pada notifikasi status bar langsung membuka dialog pembaruan (`UpdateDialog`).
  * Dukungan fallback multi-layer pengecekan rilis GitHub (REST API `/releases/latest`, fallback `/releases?per_page=1`, dan parsing Atom XML feed `releases.atom`) untuk menjamin pengecekan tidak terhalang *rate limit* IP.
  * Serialisasi payload lengkap `AppUpdateInfo` untuk mendukung pembukaan dialog update meskipun aplikasi dibuka dari kondisi tertutup penuh (*cold start*).

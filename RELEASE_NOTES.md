# Catatan Pembaruan Rilis The PAMs

## Versi 1.0.27 (Terbaru)

- **Banner Pemantau Stabilitas Jaringan & Latensi Real-Time**:
  - Menghadirkan `TopNetworkStabilityBanner` yang memantau kualitas koneksi internet secara berkala langsung di bagian atas portal.
  - Mendeteksi kondisi jaringan tidak stabil (*high latency*) maupun *offline*, dilengkapi tombol coba lagi instan (*Retry*) dan pemulihan otomatis halaman ketika koneksi kembali normal.
- **Optimasi Performa UI & Reaktif ValueNotifier**:
  - Merefaktor interaksi geser floating pill, resize split-screen AI, pull-to-refresh, dan progress bar webview menggunakan arsitektur `ValueNotifier` dan `ValueListenableBuilder`.
  - Mengeliminasi render ulang (*re-render*) yang tidak perlu pada widget tree utama portal, menjaga animasi tetap mulus pada 60/120 FPS.
- **Peningkatan Split-Screen AI Overlay & Contextual Assistant**:
  - Transisi panel AI yang lebih halus, penyesuaian tinggi fleksibel, dan integrasi ekstraksi materi kuliah yang lebih cepat.
- **Pengunduhan Pembaruan Resumable & Toleran Layar Mati (Screen-Off)**:
  - Mengatasi kegagalan unduhan pembaruan saat layar ponsel mati/tidur (sleep) menggunakan mekanisme HTTP Range Request (HTTP 206 Partial Content), auto-reconnect backoff bergradasi (hingga 10 kali percobaan tanpa mengulang dari 0%), notifikasi progress unduhan di status bar Android, serta izin sistem WAKE_LOCK.
- **Pengujian & Kualitas**:
  - Seluruh 24 pengujian otomatis unit & widget tests lulus 100%.
  - Bebas dari error atau peringatan analisis (*0 issues*).

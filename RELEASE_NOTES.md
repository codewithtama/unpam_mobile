# Pembaruan The PAMs v1.0.22

Pembaruan The PAMs v1.0.22:

- **Rebranding Resmi Menjadi "The PAMs"**:
  * Menetapkan nama aplikasi baru secara resmi menjadi **The PAMs** pada launcher Android, title bar aplikasi, web manifest, dan seluruh dialog sistem.
  * Menghapus semua atribusi merek resmi institusi, menegaskan posisi The PAMs sebagai portal perkuliahan independen pihak ketiga yang aman dan privat bagi mahasiswa.
  * Tetap mempertahankan integrasi resmi portal **Mentari LMS** dan **MyUnpam SIAKAD** tanpa gangguan fungsionalitas.
  * Memperbarui asisten kecerdasan buatan menjadi **The PAMs AI** (The PAMs Cloud AI, The PAMs AI Vision OCR, AI Assistant, dan Parafrase).
- **Distribusi APK Ultra-Ringan (Split-Per-ABI ~18.8 MB)**:
  * Mengompresi dan membagi build APK rilis berdasarkan arsitektur CPU perangkat (`--split-per-abi` + `--obfuscate --split-debug-info`).
  * Ukuran download APK terpangkas drastis hingga **65% lebih hemat** (dari ~55 MB menjadi hanya **~18.8 MB** untuk perangkat Android modern 64-bit `arm64-v8a`).
  * In-App OTA Updater cerdas otomatis mendeteksi chipset HP pengguna dan hanya mengunduh varian APK yang paling sesuai dan efisien.
- **Jaminan Kompatibilitas Pembaruan Android (Zero Data Loss)**:
  * Mempertahankan `applicationId` Android (`com.unpam.mobile.lms`) dan sertifikat penandatanganan rilis (*Release Keystore*) asli, sehingga aplikasi terpasang di HP pengguna akan langsung ter-update secara otomatis tanpa bentrok paket ataupun kehilangan sesi login dan data yang tersimpan.

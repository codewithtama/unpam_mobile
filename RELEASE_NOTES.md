# Catatan Pembaruan Rilis The PAMs

## Versi 1.0.26 (Terbaru)

- **Split-Screen AI Overlay & Mini Assistant**:
  - Menghadirkan panel Split-Screen AI responsif tepat di atas halaman portal perkuliahan (Mentari LMS & MyUnpam SIAKAD). Mahasiswa dapat berkonsultasi, berdiskusi, dan membedah materi tanpa perlu meninggalkan halaman portal.
  - Mendukung penyesuaian tinggi panel secara fleksibel via *drag resize* atau tombol rotasi preset rasio layar (35%, 50%, 65%).
  - Dilengkapi fitur *minimize* menjadi floating pill interaktif serta tombol ekspansi instan ke layar penuh (*Full-Screen AI Assistant*).
  - Terintegrasi langsung dengan ekstraksi teks halaman aktif, ekstraksi seleksi teks di WebView, dan seluruh kapabilitas The PAMs AI Tools.
- **In-Page Contextual Quick Action Floating Pill**:
  - Sistem deteksi cerdas berbasis skrip injeksi peramban yang mengenali konteks halaman aktif secara *real-time*: Forum Diskusi, Tugas / Assignment, Kuis / Ujian Online, Materi Perkuliahan di Mentari LMS, serta KRS, KHS, dan Jadwal Kuliah di MyUnpam.
  - Floating pill kontekstual yang dapat digeser bebas (*draggable*) dengan aksi cepat terpersonalisasi (misal: "Bahas Diskusi", "Bedah Soal Kuis", "Analisis Tugas", "Rangkum Materi").
- **Injeksi Jawaban & Draf Diskusi ke LMS**:
  - Tombol otomatisasi untuk menginjeksi atau menyalin draf argumen diskusi hasil analisis AI langsung ke dalam kolom formulir balasan forum di Mentari LMS.
- **Pengunduhan Pembaruan Resumable & Toleran Layar Mati (Screen-Off)**:
  - Mengatasi kegagalan unduhan pembaruan saat layar ponsel mati/tidur (sleep) menggunakan mekanisme HTTP Range Request (HTTP 206 Partial Content), auto-reconnect backoff bergradasi (hingga 10 kali percobaan tanpa mengulang dari 0%), notifikasi progress unduhan di status bar Android, serta izin sistem WAKE_LOCK.
- **Pengujian & Kualitas**:
  - Seluruh 24 pengujian otomatis unit & widget tests lulus 100%.
  - Bebas dari error atau peringatan analisis (*0 issues*).

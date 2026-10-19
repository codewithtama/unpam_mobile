# Catatan Pembaruan Rilis The PAMs

## Versi 1.0.32 (Terbaru)

- **Rollback to v1.0.25 Engine (Pemulihan Arsitektur Stabil)**:
  - Mengembalikan seluruh basis kode ke arsitektur stabil versi 1.0.25 untuk menjamin keandalan sistem secara menyeluruh.
  - Memungkinkan seluruh pengguna yang telah memasang versi 1.0.26 s/d 1.0.31 untuk menerima pembaruan otomatis tanpa kendala *downgrade*.
- **Fitur Unggulan Basis Mesin v1.0.25**:
  - **Split-Screen AI Overlay & Mini Assistant**: Konsultasi AI responsif di atas portal perkuliahan dengan floating pill dan penyesuaian ukuran tinggi panel (35%, 50%, 65%).
  - **In-Page Contextual Quick Action Floating Pill**: Deteksi cerdas forum diskusi, kuis, tugas, dan materi perkuliahan secara real-time.
  - **Injeksi Jawaban & Draf Diskusi LMS**: Otomatisasi pengisian formulir balasan forum diskusi Mentari LMS.
  - **Pengunduhan Pembaruan Resumable & Toleran Layar Mati**: HTTP Range Request (HTTP 206), auto-reconnect backoff bergradasi, dan notifikasi status bar Android.

## Versi 1.0.25

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

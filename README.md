# UNPAM Mobile (Mentari Portal & UNPAM AI)

> **Tugas Proyek Mata Kuliah:** Mobile Programming (04SIFE001)  
> **Dosen Pengampu:** SAMSO SUPRIYATNA S.Kom., M.Kom.  
> **Mahasiswa:** DIMAS ALFA PRATAMA (NIM: 241011750041)  
> **Program Studi:** Sistem Informasi (S1)  
> **Semester:** 20261 • Shift E (Sabtu)  

---

Aplikasi Android modern berbasis **Flutter** yang mengintegrasikan portal perkuliahan resmi Universitas Pamulang (**Mentari UNPAM**) dengan asisten kecerdasan buatan cerdas (**UNPAM AI**) dan **Kartu Tanda Mahasiswa (KTM) Digital** dalam satu ekosistem terpadu.

Aplikasi dirancang dengan arsitektur **Native Portal Wrapper** yang membungkus web engine Chromium murni untuk menangani seluruh aktivitas akademik (melihat jadwal kuliah, 21 sesi pertemuan, pengerjaan kuis, forum diskusi, presensi, dan pengumpulan tugas) tanpa risiko kegagalan scraping atau pemblokiran Cloudflare Turnstile.

---

## Fitur Utama

### 1. Native Mentari Portal Wrapper
- **Chromium Web Engine Asli:** Menjalankan portal resmi `https://mentari.unpam.ac.id/` dengan performa penuh, rendering JavaScript lengkap, penanganan cookie sesi `httpOnly`, dan kepatuhan terhadap proteksi Cloudflare Turnstile CAPTCHA.
- **Tampilan 100% Native:** Header aplikasi dirancang elegan dengan identitas universitas, title dinamis, tombol muat ulang cepat, dan avatar inisial mahasiswa tanpa bilah alamat peramban (URL address bar).
- **Shortcut Instan Navigasi Mentari (Deep-Link Quick Actions):** Bar navigasi horizontal dan bottom sheet modal untuk lompat langsung sekali tap ke Dashboard Perkuliahan, Presensi & Kehadiran, Kalender & Deadline Tugas, Buku Nilai / KHS, Forum Diskusi, serta Halaman Utama Mentari tanpa navigasi menu bertingkat.
- **Penanganan Tautan Eksternal:** Secara otomatis mendeteksi dan mengarahkan tautan Google Meet, Zoom, WhatsApp dosen/grup kelas, dan dokumen unduhan langsung ke aplikasi native di smartphone.
- **Pull-to-Refresh & Navigasi Cerdas:** Mendukung gestur tarik ke bawah untuk memuat ulang halaman serta integrasi riwayat navigasi tombol kembali Android.

### 2. UNPAM AI (Real Dual-Engine Intelligence & Automation)
- **UNPAM AI Tools (Draggable Floating Pill):** Tombol aksi mengambang yang dapat digeser bebas (draggable) ke posisi mana saja di layar tanpa menghalangi konten perkuliahan.
- **One-Click Forum Discussion Auto-Drafter:** Membaca judul dan topik pertanyaan diskusi forum dosen secara otomatis dari DOM, membuat draf argumen akademis berbobot via AI, dan menyuntikkannya (inject) langsung ke elemen textarea atau rich-text editor (Atto/TinyMCE) di halaman Mentari.
- **Live Quiz Solver & Auto-Highlight Jawaban:** Memindai seluruh butir soal pilihan ganda di halaman kuis webview, menganalisis kunci jawaban paling akurat via AI, dan memberikan sorotan warna hijau menyala (highlight) serta opsi auto-centang pada radio button yang tepat.
- **Ekstraksi DOM Otomatis & Konsultasi:** Mengambil teks soal kuis, instruksi tugas, atau materi modul yang sedang tampil di layar WebView dan mengirimkannya langsung ke UNPAM AI sebagai konteks pembelajaran.
- **Dual-Engine LLM Fallback:**
  - **Default (Cloud AI Publik):** Berjalan gratis tanpa konfigurasi menggunakan model OpenAI / LLaMA via Pollinations API untuk menjawab pertanyaan teks akademik.
  - **Google Gemini Engine:** Mendukung kunci API pribadi Google Generative Language dengan multi-model fallback otomatis (`gemini-3.5-flash-lite`, `gemini-3.5-flash`, `gemini-3.8-flash`, `gemini-flash-latest`, `gemini-2.5-flash`, `gemini-1.5-flash`) untuk penalaran tinggi dan analisis visual gambar/screenshot kuis.
- **Interactive Quiz Generator:** Menghasilkan latihan kuis interaktif dengan pilihan ganda, kunci jawaban, dan pembahasan konsep secara otomatis.

### 3. KTM Digital & Profil Mahasiswa Interaktif
- **Kartu Tanda Mahasiswa (KTM) Digital:** Kartu identitas virtual resmi bergaya kartu pintar perbankan dengan gradien biru-emas UNPAM, chip digital, watermark logo kampus, dan status keaktifan mahasiswa.
- **Formulir Edit Profil Lengkap:** Mahasiswa dapat memperbarui Nama Lengkap, NIM, Program Studi, Fakultas, Kelas, Shift Kuliah, Semester, Email Institusi, Nomor WhatsApp/Telepon, serta Catatan Akademik.
- **Penyimpanan Persisten:** Seluruh data profil tersimpan aman dan persisten secara lokal menggunakan `StorageService` (`SharedPreferences`).

### 4. Navigasi Bersih 3-Tab
- **Mentari:** Akses langsung ke portal perkuliahan utama.
- **UNPAM AI:** Ruang konsultasi akademik, pembahasan soal, dan penalaran tugas.
- **Profil:** Akses KTM digital, edit biodata mahasiswa, pengelolaan API Key Gemini, dan pembersihan cache browser.

---

## Arsitektur Sistem

```
                      +---------------------------------------+
                      |       Aplikasi Flutter (Android)      |
                      +---------------------------------------+
                                          |
        +---------------------------------+---------------------------------+
        |                                 |                                 |
        v                                 v                                 v
+-----------------------+     +-----------------------+     +-----------------------+
|  PortalWebViewScreen  |     |   UNPAM AI Engine     |     |     ProfileScreen     |
| (Native Chromium Shell|     |  (Dual-Engine LLM)    |     |  (KTM Digital & Bio)  |
+-----------------------+     +-----------------------+     +-----------------------+
        |                                 |                                 |
        | [DOM Injection &                | [Multimodal &                   | [Persistent Storage]
        |  Draggable AI Button]           |  Context Prompt]                |
        v                                 v                                 v
+-----------------------+     +-----------------------+     +-----------------------+
|  mentari.unpam.ac.id  |     | 1. Cloud AI (Default) |     |    StorageService     |
| (Sesi Perkuliahan,    |     | 2. Google Gemini API  |     |  (SharedPreferences   |
|  Kuis, Tugas, Forum)  |     |    (Multi-Model List) |     |   Local Key-Value)    |
+-----------------------+     +-----------------------+     +-----------------------+
```

---

## Struktur Direktori Repositori

```text
unpam_mobile/
├── android/                             # Konfigurasi native Android (Gradle, Manifest, App Icons)
├── assets/                              # Aset statis & logo institusi
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── api_constants.dart       # Endpoint portal Mentari & storage keys
│   │   └── services/
│   │       ├── ai_service.dart          # Real Dual-Engine AI (Cloud AI & Gemini Fallback)
│   │       └── storage_service.dart     # Service penyimpanan lokal SharedPreferences
│   ├── models/
│   │   ├── ai_message_model.dart        # Model pesan percakapan & kuis interaktif
│   │   └── student_profile_model.dart   # Model profil mahasiswa dengan validasi data
│   ├── providers/
│   │   ├── ai_provider.dart             # State management UNPAM AI & riwayat konsultasi
│   │   └── auth_provider.dart           # State management profil mahasiswa
│   ├── screens/
│   │   ├── ai_assistant_screen.dart     # Antarmuka UNPAM AI & dialog API Key
│   │   ├── portal_webview_screen.dart   # Shell Chromium Mentari & Draggable AI Button
│   │   └── profile_screen.dart          # KTM Digital & formulir edit profil mahasiswa
│   ├── theme/
│   │   └── app_theme.dart               # Sistem token warna institusi (Navy, Gold, Surface)
│   └── main.dart                        # Titik masuk aplikasi & Provider binding
├── test/
│   └── widget_test.dart                 # Automated unit & widget tests
├── pubspec.yaml                         # Dependensi proyek Flutter
└── README.md                            # Dokumentasi teknis proyek
```

---

## Cara Instalasi & Menjalankan

### Prasyarat
- **Flutter SDK:** Versi `^3.19.0` atau yang lebih baru
- **Dart SDK:** Versi `^3.0.0`
- **Android SDK:** Min SDK 21 (Android 5.0 Lollipop), Target SDK 34
- **Perangkat / Emulator:** Android fisik atau emulator dengan koneksi internet aktif

### Langkah Menjalankan Aplikasi
```bash
# 1. Clone repositori
git clone https://github.com/codewithtama/unpam_mobile.git
cd unpam_mobile

# 2. Unduh dependensi
flutter pub get

# 3. Jalankan analisis statis kode
flutter analyze

# 4. Jalankan pengujian unit otomatis
flutter test

# 5. Jalankan aplikasi pada perangkat Android
flutter run
```

### Kompilasi Release APK
Untuk mengompilasi berkas APK produksi siap instal:
```bash
flutter build apk --split-per-abi --release
```
Berkas APK hasil build akan tersedia di:
- `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (disarankan untuk smartphone Android modern)
- `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk`
- `build/app/outputs/flutter-apk/app-x86_64-release.apk`

---

## Konfigurasi Kunci API UNPAM AI (Opsional)

Secara default, fitur UNPAM AI langsung dapat digunakan secara **gratis** melalui Cloud AI Engine bawaan. Untuk mahasiswa yang ingin mengaktifkan inferensi berkecepatan tinggi dan fitur membaca screenshot gambar/soal visual:
1. Buka tab **UNPAM AI** atau tab **Profil** di dalam aplikasi.
2. Klik ikon kunci (**Pengaturan Gemini API Key**).
3. Masukkan kunci API dari [Google AI Studio](https://aistudio.google.com/).
4. Aplikasi akan secara otomatis memvalidasi kunci via endpoint discovery dan memilih model terbaik (`gemini-3.5-flash-lite` / `gemini-3.5-flash`).

---

## Keamanan & Kepatuhan Privasi

1. **Autentikasi Terenkripsi:** Proses autentikasi mahasiswa dilakukan langsung pada peramban resmi Mentari UNPAM. Kredensial akun (password) tidak pernah dibaca, dicegat, atau disimpan oleh aplikasi.
2. **Keamanan Kunci API:** Kunci API Google Gemini disimpan secara privat di `SharedPreferences` perangkat pengguna dan hanya dikirimkan langsung ke endpoint resmi `generativelanguage.googleapis.com` melalui protokol TLS 1.3 terenkripsi.
3. **Data Isolation:** Seluruh profil mahasiswa dan riwayat chat UNPAM AI tersimpan secara lokal di perangkat tanpa server perantara pihak ketiga.

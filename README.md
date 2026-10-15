# UNPAM LMS Mobile (Mentari & Sakura)

> **Tugas Proyek Mata Kuliah:** Mobile Programming (04SIFE001)  
> **Dosen Pengampu:** SAMSO SUPRIYATNA S.Kom., M.Kom.  
> **Mahasiswa:** DIMAS ALFA PRATAMA (NIM: 241011750041)  
> **Semester:** 20261 • Shift E (Sabtu)  

Aplikasi Android berbasis **Flutter** untuk mengelola aktivitas akademik LMS Universitas Pamulang (Mentari dan Sakura) secara terintegrasi langsung dari smartphone.

Aplikasi tidak hanya berfungsi sebagai viewer (read-only), melainkan menyediakan platform interaktif lengkap: melihat jadwal mata kuliah, memantau 21 pertemuan dan peserta kelas, mengerjakan kuis, mengunggah tugas, berdiskusi di forum, hingga menganalisis soal kuis berbantuan **AI Study Assistant**.

Seluruh data disinkronkan secara langsung dengan server UNPAM menggunakan akun mahasiswa aktif tanpa data mock atau mode demo dummy.

---

## Fitur Utama

- **Dashboard Akademik Real-Time**: Daftar mata kuliah semester berjalan, total SKS, jadwal hari kuliah, nama dosen, dan progress perkuliahan.
- **Universal Cloudflare Clearance**: Mengatasi proteksi Cloudflare Challenge dan TLS Fingerprinting (JA3/JA4) via engine headless Chromium terintegrasi, mencegah error 403 Forbidden.
- **Pengerjaan Kuis & Tugas In-App**: Membuka dan mengerjakan kuis, mengunggah penugasan, mengisi kuesioner, dan berpartisipasi dalam forum diskusi langsung di dalam aplikasi tanpa terlempar ke browser eksternal.
- **Deteksi Otomatis Penyelesaian (Auto-Completion)**: Mendeteksi pengiriman jawaban atau form submit secara otomatis untuk memperbarui status penyelesaian tugas (`completion: true`) dan progress bar.
- **Bahas Soal dengan AI (AI Assistant)**: Ekstraksi otomatis teks pertanyaan dan pilihan ganda dari tampilan kuis ke Asisten AI untuk pembahasan konsep materi dan panduan belajar.
- **Sinkronisasi Data Cerdas & Dual Fallback**: Mendukung sinkronisasi data kelas melalui Sakura API, Mentari API, serta *Headless Sync Bridge* untuk mengekstrak 21 pertemuan dan daftar teman sekelas secara presisi.
- **Offline Caching & Fast Loading**: Penyimpanan lokal untuk detail mata kuliah, pertemuan, dan riwayat tugas, memastikan aplikasi tetap responsif meskipun koneksi server kampus lambat.
- **Pusat Tugas Tertunda (Pending Tasks)**: Agregasi seluruh tugas, kuis, dan forum dari seluruh mata kuliah yang belum diselesaikan dalam satu tampilan ringkas.

---

## Arsitektur Sistem

```
                      [ Aplikasi Flutter (Android) ]
                                    |
          +-------------------------+-------------------------+
          |                                                   |
 [ ChromiumSessionService ]                              [ UI Screens ]
 (Headless WebView Engine)                                    |
  - Cloudflare cf_clearance cookies              +------------+------------+
  - In-engine fetch() bridge                     |                         |
  - Session & Token Sync               [MentariActivityScreen]    [AiAssistantScreen]
          |                            (In-App Task/Quiz Runner)   (AI Problem Solver)
          v                                      |                         |
  +-------+--------------------+                 +------------+------------+
  v                            v                              v
mentari.unpam.ac.id      sakura.unpam.ac.id             Google Gemini API
(Auth, Course List)      (Detail 21 Pertemuan,          (Analisis & Pembahasan)
                          Kuis, Tugas, Forum)
```

### Komponen Arsitektur:

| Lapisan | File / Direktori | Fungsi Utama |
|---|---|---|
| **Engine Clearance** | `lib/core/services/chromium_session_service.dart` | Menjalankan request HTTP di dalam context browser Chromium dengan cookie aktif dan token Cloudflare clearance. |
| **Jaringan & API** | `lib/core/network/api_client.dart` | Prioritas request via Chromium fetch bridge dengan fallback Dio REST API, validasi token, dan header host spesifik. |
| **Penyimpanan Lokal** | `lib/core/services/storage_service.dart` | Pengelolaan cache detail kelas, token sesi JWT, profil mahasiswa, dan kredensial. |
| **Kecerdasan Buatan** | `lib/core/services/ai_service.dart` | Integrasi model AI Gemini untuk asisten belajar, penjabaran materi, dan analisis soal kuis. |
| **Manajemen State** | `lib/providers/` | `AuthProvider` (sesi dan validasi) & `CourseProvider` (kursus, pertemuan, pending tasks, offline state). |
| **Aktivitas In-App** | `lib/screens/mentari_activity_screen.dart` | Browser interaktif WebView dengan DOM extractor, listener form submit, dan tombol Bahas Soal AI. |
| **Sinkronisasi Bridge** | `lib/widgets/mentari_course_sync_sheet.dart` | BottomSheet interaktif & headless extractor untuk sinkronisasi 21 pertemuan dan peserta kelas. |
| **Antarmuka (UI)** | `lib/screens/` & `lib/widgets/` | Dashboard, Detail Pertemuan, Dialog Kuis, Kartu Mata Kuliah, dan Pengaturan Profil. |

---

## Mekanisme Cloudflare Bypass

Server LMS UNPAM (Mentari & Sakura) dilindungi oleh **Cloudflare Managed Challenge** dan proteksi bot yang memvalidasi TLS fingerprinting:
1. Permintaan langsung melalui client HTTP murni (seperti Dio, cURL, atau HttpClient biasa) akan diblokir dengan status `HTTP 403 Forbidden` (`cf-mitigated: challenge`).
2. **Solusi UNPAM LMS Mobile:** Aplikasi menginisialisasi `ChromiumSessionService` yang terpasang di root aplikasi (`main.dart`). Engine ini mempertahankan cookie sesi resmi dan token `cf_clearance` di dalam native `CookieManager`.
3. Seluruh panggilan data penting (`getUserCourses` dan `getCourseDetail`) dieksekusi melalui evaluasi JavaScript `fetch()` di dalam context Chromium yang telah tervalidasi, sehingga request dikenali sebagai interaksi peramban sah.
4. Tersedia tombol sinkronisasi visual (`MentariCourseSyncSheet`) sebagai lapisan fallback jika server menuntut verifikasi visual Turnstile interaktif.

---

## Alur Autentikasi

Aplikasi menyediakan dua metode masuk:

1. **Masuk Lewat Mentari (Web SSO Otomatis):**
   - Aplikasi membuka halaman login resmi Mentari di WebView.
   - Mahasiswa memasukkan NIM dan password serta menyelesaikan CAPTCHA Turnstile.
   - Skrip injector otomatis mendeteksi keberhasilan login, menangkap JWT token dari `localStorage`, `sessionStorage`, dan cookie, lalu memvalidasi token ke server sebelum menyimpan sesi.
2. **Masuk dengan Bearer Token Manual:**
   - Disediakan bagi pengguna yang ingin menempelkan token JWT secara langsung.
   - Token divalidasi ke server sebelum disimpan; token kedaluwarsa atau tidak valid akan langsung ditolak.

---

## Struktur Repositori

```text
unpam_mobile/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── api_constants.dart
│   │   ├── network/
│   │   │   ├── api_client.dart
│   │   │   └── api_exception.dart
│   │   ├── services/
│   │   │   ├── ai_service.dart
│   │   │   ├── chromium_session_service.dart
│   │   │   └── storage_service.dart
│   │   └── telemetry/
│   │       └── ...
│   ├── models/
│   │   ├── course_detail_model.dart
│   │   └── user_course_model.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   └── course_provider.dart
│   ├── screens/
│   │   ├── ai_assistant_screen.dart
│   │   ├── all_pending_tasks_screen.dart
│   │   ├── course_detail_screen.dart
│   │   ├── home_screen.dart
│   │   ├── login_screen.dart
│   │   ├── mentari_activity_screen.dart
│   │   ├── mentari_web_login_screen.dart
│   │   └── profile_screen.dart
│   ├── theme/
│   │   └── app_theme.dart
│   ├── widgets/
│   │   ├── course_card.dart
│   │   ├── mentari_course_sync_sheet.dart
│   │   ├── quiz_dialog.dart
│   │   └── sub_section_tile.dart
│   └── main.dart
├── pubspec.yaml
└── README.md
```

---

## Menjalankan Proyek

### Prasyarat
- **Flutter SDK**: Versi `^3.19.0` atau yang lebih baru
- **Android SDK**: Min SDK 21, Target SDK 34
- **Perangkat / Emulator**: Android 8.0+ (Oreo atau lebih tinggi disarankan)

### Langkah Instalasi
```bash
# 1. Unduh dependensi
flutter pub get

# 2. Verifikasi kesiapan sistem
flutter doctor

# 3. Jalankan analisis statis
dart analyze lib

# 4. Jalankan aplikasi pada perangkat
flutter run
```

---

## Catatan Teknis & Keamanan

- **Kerahasiaan Token:** Token JWT disimpan secara lokal menggunakan `SharedPreferences` perangkat dan langsung dihapus saat pengguna melakukan Logout.
- **Kepatuhan Privasi:** Kredensial akun (password) tidak pernah disimpan di storage aplikasi; proses autentikasi dilakukan langsung melalui halaman resmi Universitas Pamulang.
- **API Status:** Endpoint API Mentari dan Sakura merupakan layanan internal kampus yang dapat mengalami pembaruan sewaktu-waktu. Penanganan error fail-safe dan offline cache dirancang untuk meminimalkan dampak gangguan server.

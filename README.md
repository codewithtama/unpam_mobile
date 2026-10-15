# UNPAM LMS Mobile (Mentari Portal)

> **Tugas Proyek Mata Kuliah:** Mobile Programming (04SIFE001)  
> **Dosen Pengampu:** SAMSO SUPRIYATNA S.Kom., M.Kom.  
> **Mahasiswa:** DIMAS ALFA PRATAMA (NIM: 241011750041)  
> **Semester:** 20261 • Shift E (Sabtu)  

Aplikasi Android berbasis **Flutter** untuk mengelola aktivitas akademik LMS Universitas Pamulang (Mentari) secara terintegrasi langsung dari smartphone.

Aplikasi tidak hanya berfungsi sebagai viewer (read-only), melainkan menyediakan platform interaktif lengkap: melihat jadwal mata kuliah, memantau 21 pertemuan dan peserta kelas, mengerjakan kuis, mengunggah tugas, berdiskusi di forum, hingga menganalisis soal kuis berbantuan **AI Study Assistant**.

Seluruh data disinkronkan secara langsung dengan server UNPAM menggunakan akun mahasiswa aktif tanpa data mock atau mode demo dummy.

---

## Fitur Utama

- **Native Portal WebView Wrapper**: Membungkus portal resmi Mentari secara langsung di dalam engine Chromium asli. Login, sesi SSO, cookie `httpOnly`, dan mitigasi Cloudflare Turnstile ditangani 100% oleh browser engine tanpa risiko kegagalan reverse engineering endpoint API kampus.
- **Pengerjaan Kuis, Tugas, & Forum Asli**: Seluruh fitur kuis interaktif, upload berkas tugas, dan diskusi forum berjalan mulus sesuai rancangan web kampus dengan performa native.
- **Deteksi Eksternal Pintar**: Otomatis mendeteksi dan mengarahkan link Google Meet, Zoom, WhatsApp dosen, serta unduhan dokumen ke aplikasi smartphone terkait.
- **Bahas Soal dengan AI (AI Assistant)**: Ekstraksi teks pertanyaan langsung dari DOM layar web ke Asisten AI Gemini untuk pembahasan konsep materi, rumus, dan panduan belajar.
- **Navigasi Cepat & Tombol AI Mengambang**: Dilengkapi tombol "Tanya AI Halaman Ini" yang dapat digeser bebas (draggable) ke mana saja agar tidak menutupi materi atau form tugas.

---

## Arsitektur Sistem

```
                      [ Aplikasi Flutter (Android) ]
                                    |
          +-------------------------+-------------------------+
          |                                                   |
 [ PortalWebViewScreen ]                                 [ AI Engine ]
  (Native Chromium Shell)                                     |
   - Mentari UNPAM (https://mentari.unpam.ac.id/)      [AiAssistantScreen]
   - Browser Cookie & Session Management               (Multimodal & Context)
   - Cloudflare Turnstile Native Handling                     |
   - History & External App Handler                           v
          |                                           Google Gemini API
          v
  mentari.unpam.ac.id
  (Portal Perkuliahan, Sesi Mahasiswa, Tugas & Kuis)
```

### Komponen Arsitektur:

| Lapisan | File / Direktori | Fungsi Utama |
|---|---|---|
| **Portal Wrapper Shell** | `lib/screens/portal_webview_screen.dart` | Antarmuka utama membungkus Mentari dalam WebView dengan navigasi, history back, pull-to-refresh, dan tombol AI melayang bebas. |
| **Kecerdasan Buatan** | `lib/core/services/ai_service.dart` & `lib/providers/ai_provider.dart` | Integrasi model AI Gemini untuk konsultasi belajar, penjabaran materi, dan analisis soal kuis. |
| **Layar Asisten AI** | `lib/screens/ai_assistant_screen.dart` | Ruang konsultasi belajar dengan kemampuan menerima teks soal yang diekstrak langsung dari layar web. |
| **Penyimpanan Lokal** | `lib/core/services/storage_service.dart` | Pengelolaan kunci API Gemini, pengaturan cache, dan preferensi aplikasi. |
| **Profil & Edit Mahasiswa** | `lib/screens/profile_screen.dart` | Kartu Tanda Mahasiswa (KTM) Digital UNPAM dan formulir interaktif edit profil mahasiswa (Nama, NIM, Prodi, Fakultas, Kelas, Shift, Semester, Email, No. HP). |

---

## Mekanisme Cloudflare & Session Handling

Server LMS UNPAM (Mentari) dilindungi oleh **Cloudflare Managed Challenge** dan proteksi bot yang memvalidasi TLS fingerprinting:
1. Melakukan reverse engineering terhadap REST API kampus rentan terblokir status `HTTP 403 Forbidden` (`cf-mitigated: challenge`) dan perubahan skema payload.
2. **Solusi Portal WebView Wrapper:** Aplikasi memanfaatkan WebView Chromium native. Browser engine secara langsung mengeksekusi JavaScript, memvalidasi Turnstile token, serta menyimpan cookie sesi (`cf_clearance`, `session`, JWT) di persistent storage native.
3. Seluruh interaksi login, kuis, dan pengumpulan tugas bekerja 100% identik dengan portal resmi tanpa perlu reverse engineering.

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
├── android/
├── assets/
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   └── api_constants.dart
│   │   └── services/
│   │       ├── ai_service.dart
│   │       └── storage_service.dart
│   ├── models/
│   │   ├── ai_message_model.dart
│   │   └── student_profile_model.dart
│   ├── providers/
│   │   ├── ai_provider.dart
│   │   └── auth_provider.dart
│   ├── screens/
│   │   ├── ai_assistant_screen.dart
│   │   ├── portal_webview_screen.dart
│   │   └── profile_screen.dart
│   ├── theme/
│   │   └── app_theme.dart
│   └── main.dart
├── test/
│   └── widget_test.dart
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
- **API Status:** Layanan portal Mentari merupakan sistem internal kampus yang dapat mengalami pembaruan sewaktu-waktu. Penanganan error fail-safe dan offline cache dirancang untuk meminimalkan dampak gangguan server.

# UNPAM LMS Mobile (Mentari & Sakura)

> **Tugas Proyek Mata Kuliah: Mobile Programming (04SIFE001)**
> **Dosen Pengampu:** SAMSO SUPRIYATNA S.Kom., M.Kom.
> **Mahasiswa:** DIMAS ALFA PRATAMA (NIM: 241011750041)
> **Semester:** 20261 • Shift E (Sabtu)

Aplikasi Android berbasis **Flutter** untuk melihat mata kuliah, pertemuan, kuis, dan tugas dari LMS Universitas Pamulang (Mentari dan Sakura) langsung dari smartphone.

Seluruh data diambil dari server UNPAM menggunakan akun mahasiswa yang sedang login. Aplikasi tidak memakai data contoh (mock) dan tidak memiliki mode demo. Jika server menolak permintaan atau koneksi gagal, aplikasi menampilkan pesan error, bukan data pengganti.

---

## Latar Belakang

Mengecek tugas dan kuis lewat browser di laptop merepotkan. Aplikasi ini memungkinkan mahasiswa:

1. Melihat daftar mata kuliah semester berjalan beserta dosen, SKS, dan hari kuliah.
2. Membuka detail tiap mata kuliah: pertemuan, kuis, penugasan, forum, dan materi.
3. Melihat aktivitas yang belum selesai (`completion: false`) tanpa membuka pertemuan satu per satu.

---

## Arsitektur

```
              [ Aplikasi Flutter (Android / iOS) ]
                              |
          +-------------------+-------------------+
          v                                       v
 mentari.unpam.ac.id                     sakura.unpam.ac.id
   GET /api/user-course                    GET /api/course/:kode_course
   Daftar mata kuliah                      Pertemuan, kuis, materi, peserta

   Header: Authorization: Bearer <token>
```

Lapisan kode:

| Lapisan | Lokasi | Tugas |
|---|---|---|
| Jaringan | `lib/core/network/api_client.dart` | Dio, header Bearer, penerjemahan error ke `ApiException` |
| Penyimpanan | `lib/core/services/storage_service.dart` | Token dan identitas sesi (`shared_preferences`) |
| State | `lib/providers/` | `AuthProvider`, `CourseProvider` (Provider) |
| UI | `lib/screens/`, `lib/widgets/` | Layar login, home, detail mata kuliah, tugas pending |

---

## Alur Login

Halaman login Mentari dilindungi **Cloudflare Turnstile**, sehingga aplikasi tidak bisa mengirim username dan password langsung ke API. Aplikasi menyediakan dua cara masuk:

1. **Masuk lewat Mentari (WebView).** Aplikasi membuka halaman login Mentari yang asli. Setelah login berhasil, aplikasi mencari token JWT di `localStorage`, `sessionStorage`, dan cookie halaman tersebut, lalu mengujinya ke server.
2. **Bearer Token manual.** Tempel token JWT secara manual jika cara pertama tidak berhasil.

Token selalu divalidasi ke server (`/user-course`) sebelum sesi disimpan. Token yang ditolak tidak pernah tersimpan. Nama dan NIM mahasiswa dibaca dari klaim `fullname` dan `username` pada token.

### Mengambil token manual

1. Login di `https://mentari.unpam.ac.id` lewat Chrome di komputer.
2. Tekan **F12**, buka tab **Application**, lalu **Local Storage** dan pilih `https://mentari.unpam.ac.id`.
3. Salin nilai yang diawali `eyJ...`.
4. Alternatif: tab **Network**, klik request `api/user-course`, salin nilai header `Authorization` tanpa kata `Bearer`.
5. Di aplikasi, centang **Gunakan Bearer Token Manual**, tempel token, lalu tap **Masuk dengan Token**.

> **Keamanan:** token setara dengan akses ke akun Anda. Jangan dibagikan, jangan di-commit ke repositori, dan jangan masuk ke tangkapan layar. Token disimpan lokal di perangkat dan dihapus saat keluar.

---

## Fitur

- Dashboard mata kuliah semester berjalan, total SKS, dan hari kuliah dari data server.
- Tarik ke bawah (pull to refresh) untuk memuat ulang.
- Detail mata kuliah: pertemuan, kuis, tugas, forum, dan materi dari Sakura.
- Ringkasan tugas dan kuis yang belum selesai.
- Penanganan error: sesi berakhir mengarahkan ke login ulang, gangguan jaringan menampilkan tombol coba lagi.

## Keterbatasan

- Login WebView hanya berjalan di Android dan iOS (tidak untuk build web).
- Jika Mentari menyimpan token di cookie `httpOnly`, login WebView tidak dapat membacanya. Gunakan token manual.
- Cloudflare dapat memblokir permintaan API dari aplikasi. Dalam kasus itu aplikasi menampilkan error 403.
- Token Mentari belum tentu diterima oleh API Sakura. Jika detail pertemuan gagal dimuat, periksa kode error yang ditampilkan.
- Ringkasan tugas pending dihitung dari mata kuliah yang terakhir dibuka.
- API UNPAM tidak terdokumentasi publik dan dapat berubah sewaktu-waktu.

---

## Struktur Proyek

```text
unpam_mobile/
├── lib/
│   ├── core/
│   │   ├── constants/api_constants.dart
│   │   ├── network/api_client.dart
│   │   └── services/storage_service.dart
│   ├── models/
│   │   ├── user_course_model.dart
│   │   └── course_detail_model.dart
│   ├── providers/
│   │   ├── auth_provider.dart
│   │   └── course_provider.dart
│   ├── screens/
│   │   ├── login_screen.dart
│   │   ├── mentari_web_login_screen.dart
│   │   ├── home_screen.dart
│   │   ├── course_detail_screen.dart
│   │   └── all_pending_tasks_screen.dart
│   ├── theme/app_theme.dart
│   ├── widgets/
│   └── main.dart
└── pubspec.yaml
```

---

## Menjalankan Proyek

Prasyarat: Flutter SDK dan perangkat atau emulator Android.

```bash
flutter doctor
flutter pub get
flutter run
```

Pemeriksaan kode:

```bash
flutter analyze
```

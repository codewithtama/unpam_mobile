# 📱 UNPAM LMS Mobile (Mentari & Sakura)

> **Tugas Proyek Mata Kuliah: Mobile Programming (04SIFE001)**  
> **Dosen Pengampu:** SAMSO SUPRIYATNA S.Kom., M.Kom.  
> **Mahasiswa:** DIMAS ALFA PRATAMA (NIM: 241011750041)  
> **Semester:** 20261 • Shift E (Sabtu)

---

## 🎯 Latar Belakang Masalah
Mahasiswa sering kali kesulitan dan merasa repot jika setiap kali ingin mengecek tugas kuliah atau kuis harus menyalakan laptop dan membuka browser. Aplikasi Android ini dibangun menggunakan **Flutter** untuk memfasilitasi mahasiswa agar dapat:
1. Mengakses seluruh tugas kuliah, kuis, forum diskusi, dan materi perkuliahan secara langsung dari genggaman (smartphone Android).
2. Mengetahui secara cepat aktivitas apa saja yang **belum diselesaikan** (`completion: false`) tanpa perlu membuka dan menggulir satu per satu dari 21 pertemuan.
3. Mengakses modul pembelajaran (Slide PPT, Buku ISBN, Link Google Meet perkuliahan) dengan satu kali tap.

---

## 🌐 Arsitektur API & Bearer Token

Aplikasi ini mengonsumsi dua ekosistem REST API Universitas Pamulang dengan otentikasi **Bearer Token**:

```
                       [ Android Client (Flutter) ]
                                     │
           ┌─────────────────────────┴─────────────────────────┐
           ▼                                                   ▼
 [ mentari.unpam.ac.id ]                             [ sakura.unpam.ac.id ]
   - Portal Mahasiswa & Krs                            - E-Learning & LMS Kelas
   - Endpoint: /api/user-course                        - Endpoint: /api/course/:kode_course
   - Mengambil 8 Daftar Mata Kuliah                    - Pertemuan 1 s/d 21, RPS, Kuis, PPT
   - Header: Authorization: Bearer <token>             - Header: Authorization: Bearer <token>
```

### Mekanisme Interceptor Bearer Token
Pada `lib/core/network/api_client.dart`, disematkan `AuthInterceptor` menggunakan package `Dio`:
```dart
_dio.interceptors.add(
  InterceptorsWrapper(
    onRequest: (options, handler) {
      final token = _storage.getToken();
      if (token != null && token.isNotEmpty) {
        options.headers['Authorization'] = 'Bearer $token';
      }
      return handler.next(options);
    },
  ),
);
```

---

## ✨ Fitur-Fitur Utama Aplikasi

1. **Dashboard Mahasiswa (Mentari API)**:
   - Menampilkan kartu 8 Mata Kuliah semester 20261 lengkap dengan nama dosen, beban SKS, dan jadwal kuliah (Sabtu Shift E).
   - Indikator total beban studi (20 SKS).
2. **Tab "Tugas Belum Selesai (Pending)"**:
   - Algoritma cerdas yang otomatis menyaring seluruh kuis, penugasan terstruktur, dan forum diskusi yang berstatus `completion: false` dari Pertemuan 1 sampai 21 ke dalam satu daftar ringkas.
3. **Tab "Pertemuan 1 - 21 (Sakura API)"**:
   - Accordion interaktif per pertemuan.
   - Status pengerjaan real-time (centang hijau untuk `completion: true`).
   - Warning banner jika kuis belum terbuka (misal: *"Silakan selesaikan Pretest terlebih dahulu"*).
   - Tombol buka link materi Google Meet dan download materi PPT.
4. **Tab "Teman Sekelas"**:
   - Menampilkan daftar 41 mahasiswa di kelas 04SIFE001 beserta NIM dan email dengan fitur pencarian instan.
5. **Mode Offline & Demo Cepat**:
   - Dilengkapi salinan respons JSON asli dari dosen di `assets/mock/` agar aplikasi dapat dipresentasikan kapan saja di depan dosen tanpa risiko terhalang kendala jaringan atau Cloudflare.

---

## 📁 Struktur Folder Proyek

```text
1CP/
├── assets/
│   └── mock/
│       ├── user_courses.json                  <-- Respon Mentari API (8 Mata Kuliah)
│       └── course_detail_jaringan_komputer.json <-- Respon Sakura API (21 Pertemuan & Kuis)
├── lib/
│   ├── core/
│   │   ├── constants/api_constants.dart       <-- Base URL & endpoints
│   │   ├── network/api_client.dart            <-- Dio + Bearer Interceptor
│   │   └── services/storage_service.dart      <-- Penyimpanan sesi & token
│   ├── models/
│   │   ├── user_course_model.dart             <-- Model Data Mentari
│   │   └── course_detail_model.dart           <-- Model Data Sakura (Sections, Quiz, Students)
│   ├── providers/
│   │   ├── auth_provider.dart                 <-- State login & token
│   │   └── course_provider.dart               <-- State kalkulasi tugas pending & progress
│   ├── screens/
│   │   ├── login_screen.dart                  <-- Layar login + opsi Bearer token manual
│   │   ├── home_screen.dart                   <-- Layar dashboard 8 mata kuliah
│   │   ├── course_detail_screen.dart          <-- Layar detail 3 tab (Pending, Pertemuan, Peserta)
│   │   └── all_pending_tasks_screen.dart      <-- Layar rekapitulasi semua tugas
│   ├── theme/
│   │   └── app_theme.dart                     <-- Brand palette biru & emas UNPAM
│   ├── widgets/
│   │   ├── course_card.dart                   <-- Kartu mata kuliah
│   │   ├── sub_section_tile.dart              <-- Tile item kuis/materi/tugas
│   │   └── quiz_dialog.dart                   <-- Modal detail kuis & durasi
│   └── main.dart                              <-- Entry point Flutter
└── pubspec.yaml
```

---

## 🚀 Cara Menjalankan Proyek

1. **Pastikan Flutter SDK terpasang di komputer:**
   ```bash
   flutter doctor
   ```
2. **Unduh dependencies:**
   ```bash
   flutter pub get
   ```
3. **Jalankan di emulator atau HP Android:**
   ```bash
   flutter run
   ```

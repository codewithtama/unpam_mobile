# The PAMs — Portal Perkuliahan & Akademik Terpadu

[![Flutter](https://img.shields.io/badge/Flutter-3.41.7-02569B?logo=flutter&logoColor=white)](https://flutter.dev)
[![Dart](https://img.shields.io/badge/Dart-3.11.5-0175C2?logo=dart&logoColor=white)](https://dart.dev)
[![Release](https://img.shields.io/badge/Release-v1.0.56-10B981?logo=github&logoColor=white)](https://github.com/codewithtama/unpam_mobile/releases/tag/v1.0.56)
[![Tests](https://img.shields.io/badge/Tests-75%20Passed-brightgreen?logo=checkmarx&logoColor=white)](test/widget_test.dart)
[![Platform](https://img.shields.io/badge/Platform-Android%20(API%2021%2B)-3DDC84?logo=android&logoColor=white)](https://android.com)
[![License](https://img.shields.io/badge/License-Academic-blue.svg)](#keamanan-integritas-sesi--kepatuhan-privasi)

**The PAMs** adalah aplikasi mobile portal perkuliahan dan akademik terpadu independen yang menyatukan seluruh ekosistem digital Universitas Pamulang ke dalam satu wadah native modern berkinerja tinggi. Aplikasi ini memadukan sistem pembelajaran daring (**Mentari LMS**), sistem informasi akademik (**MyUnpam SIAKAD**), portal identitas terpusat (**Satu UNPAM SSO**), serta **Hub Layanan Akademik Native** berbasis integrasi REST API resmi.

Aplikasi ini dirancang khusus untuk kenyamanan dan produktivitas civitas akademika dengan menghadirkan **The PAMs AI Multi-Engine & Vision OCR**, **Jadwal Kuliah & Deadline Tracker Terpadu**, autentikasi biometrik terenkripsi perangkat keras (*Android Hardware Keystore*), jembatan unduhan berkas akademik Chromium dengan ekstraksi memori browser (*skema `blob:`*), gerbang izin wajib (*permission gatekeeper*), sistem pembaruan nirkabel otomatis (*In-App OTA Updater*), dan pemantauan riwayat rilis live langsung dari GitHub REST API.

---

## Daftar Isi
1. [Fitur Utama](#fitur-utama)
2. [Arsitektur Sistem Terpadu](#arsitektur-sistem-terpadu)
3. [Daftar Fitur Mendalam](#daftar-fitur-mendalam)
   - [1. Dual-Portal WebView Berakselerasi GPU](#1-dual-portal-webview-berakselerasi-gpu)
   - [2. Hub Layanan Akademik Native (12 Layanan OpenAPI)](#2-hub-layanan-akademik-native-12-layanan-openapi)
   - [3. Jadwal Kuliah & Deadline Tracker Terpadu](#3-jadwal-kuliah--deadline-tracker-terpadu)
   - [4. Autentikasi In-App SSO & Satu UNPAM Gateway](#4-autentikasi-in-app-sso--satu-unpam-gateway)
   - [5. The PAMs AI Multi-Engine & Multimodal Vision OCR](#5-the-pams-ai-multi-engine--multimodal-vision-ocr)
   - [6. Biometric Auto-Login Vault (Hardware Keystore)](#6-biometric-auto-login-vault-hardware-keystore)
   - [7. Jembatan Unduhan Chromium & Ekstraksi Memori Blob](#7-jembatan-unduhan-chromium--ekstraksi-memori-blob)
   - [8. Gerbang Izin Akses Wajib (Permission Gatekeeper)](#8-gerbang-izin-akses-wajib-permission-gatekeeper)
   - [9. In-App OTA Updater Otomatis & Riwayat Pembaruan Live](#9-in-app-ota-updater-otomatis--riwayat-pembaruan-live)
   - [10. Syarat & Ketentuan Terproteksi (15s Mandatory Timer)](#10-syarat--ketentuan-terproteksi-15s-mandatory-timer)
4. [Daftar Endpoint API Terintegrasi](#daftar-endpoint-api-terintegrasi)
5. [Matriks Spesifikasi Model AI (Per Oktober 2026)](#matriks-spesifikasi-model-ai-per-oktober-2026)
6. [Struktur Direktori Proyek](#struktur-direktori-proyek)
7. [Prasyarat & Cara Menjalankan](#prasyarat--cara-menjalankan)
8. [Kompilasi & Rilis APK](#kompilasi--rilis-apk)
9. [Keamanan, Integritas Sesi & Kepatuhan Privasi](#keamanan-integritas-sesi--kepatuhan-privasi)

---

## Fitur Utama

* **Transformasi 100% Native Mentari LMS & MyUnpam Hub**: Mentari LMS dan MyUnpam SIAKAD kini bertransformasi penuh menjadi antarmuka Flutter native berkinerja tinggi 60fps dengan kartu matakuliah berprogres, 21 pertemuan interaktif, unduh materi PDF langsung, modal pengerjaan kuis Moodle aman, dan 12 modul layanan akademik terpadu.
* **Hub Layanan Akademik Native Lengkap**: Mengintegrasikan 12 modul akademik resmi My UNPAM langsung ke dalam antarmuka Flutter native: Biodata Mahasiswa, Jadwal Kuliah, Nilai Akademik, KHS, KRS, Presensi, Keuangan/SPP, Tugas Akhir/Skripsi, Penugasan Proyek, Pengajuan Izin Kuliah, Dokumen Akademik, dan Sertifikat Seminar.
* **Sinkronisasi Dua Fase Jadwal & Deadline**:
  * **Fase 1 (Jadwal Kuliah)**: Sinkronisasi native langsung via REST API `/api/jadwal-kuliah` dengan pemisahan cerdas antara kelas **Tatap Muka** dan **Online**.
  * **Fase 2 (Deadline Tracker)**: Menarik kalender deadline tugas & kuis aktif dari Moodle Web Service Mentari LMS (`core_calendar_get_action_events_by_timesort`) tanpa perlu membuka halaman modul satu per satu, dengan navigasi balik *in-app* yang mulus.
* **In-App Single Sign-On (SSO) & Satu UNPAM Gateway**: Menjaga seluruh alur autentikasi Satu UNPAM (`satu.unpam.ac.id`), My UNPAM, Mentari, hingga verifikasi Cloudflare Turnstile 100% berada di dalam WebView The PAMs tanpa pernah terlempar (*redirect*) ke peramban eksternal.
* **The PAMs AI Academic Assistant (Multi-Model Engine)**: Asisten cerdas terintegrasi yang mendukung berbagai provider LLM terdepan di dunia: Google Gemini (3.8 Flash, 4 Argon), DeepSeek V4 (Flash & Pro), Anthropic Claude 5.5 (Sonnet & Opus), Alibaba Qwen 3.8-Max, OpenAI GPT-5/4o, OpenRouter, serta mode The PAMs Cloud AI Gratis tanpa kuota/API key.
* **Standardized Floating PAMs AI Tool**: Tombol melayang berbentuk kapsul (stadium pill) resmi berwarna biru tua dengan aksen sparkle gold, hadir seragam di atas portal web maupun di seluruh sub-layar native Akademik untuk memberikan prompt konsultasi cerdas sesuai konteks halaman yang sedang aktif.
* **Jembatan Unduhan Berkas Chromium & Ekstraksi Memori Blob W3C**: Mengatasi masalah unduhan berkas PDF (KRS, KHS, Jadwal Kuliah, Kartu Ujian, Modul LMS). Mendukung ekstraksi biner client-side *skema `blob:`* langsung dari RAM peramban secara streaming tanpa memicu penolakan *W3C Fetch credential*, serta otomatis memintas proteksi Cloudflare Turnstile CAPTCHA.
* **Biometric Auto-Login Vault**: Mengeliminasi keharusan mengetik NIM dan kata sandi secara berulang. Kredensial disimpan dengan enkripsi tingkat perangkat keras (`flutter_secure_storage` / Android Hardware Keystore) dan diisi otomatis melalui verifikasi sidik jari atau sensor wajah.
* **Gerbang Izin Akses Wajib (Mandatory Permission Gatekeeper)**: Memastikan kelengkapan izin sistem Android (Notifikasi, Kamera, dan Media Penyimpanan) sebelum memasuki portal demi stabilitas seluruh fitur perkuliahan.
* **Riwayat Pembaruan Live dari GitHub API**: Menampilkan seluruh riwayat versi rilis beserta changelog lengkap yang ditarik secara dinamis dari GitHub Releases tanpa data hardcode, dilengkapi deteksi arsitektur CPU perangkat (*Split-per-ABI*).
* **Pembaruan Aplikasi Otomatis (In-App OTA Updater)**: Mendeteksi ketersediaan rilis versi baru secara silent di latar belakang, menampilkan Heads-up Notification di status bar Android, dialog unduhan berprogress, dan instalasi instan berkas APK via `open_filex`.
* **Syarat & Ketentuan Terproteksi (15s Mandatory Timer)**: Layar persetujuan etika penggunaan akademik dengan tombol persetujuan yang terkunci hingga hitung mundur 15 detik berakhir guna memastikan kesadaran integritas pengguna.

---

## Arsitektur Sistem Terpadu

```mermaid
graph TD
    A[Mulai Aplikasi] --> B[AppGate Router]
    B -->|Syarat & Ketentuan Belum Disetujui| C[UserAgreementScreen<br>Timer Wajib 15 Detik]
    C -->|Setuju| D[PermissionGateScreen<br>Gerbang Izin Wajib]
    B -->|Ada Izin Belum Disetujui| D
    D -->|Semua Izin Disetujui| E[PortalWebViewScreen<br>Shell Native Terpadu]
    B -->|Semua Valid| E

    subgraph "PortalWebViewScreen (Bottom Navigation 4 Tab)"
        E --> F[Tab 0: Mentari LMS<br>mentari.unpam.ac.id]
        E --> G[Tab 1: MyUnpam SIAKAD<br>my.unpam.ac.id]
        E --> H[Tab 2: Akademik Native Hub<br>12 Layanan OpenAPI My UNPAM]
        E --> I[Tab 3: The PAMs AI Screen<br>Ruang Konsultasi Akademik]

        F -.- P1[Standard Floating PAMs AI Tool]
        G -.- P1
        H -.- P2[Floating PAMs AI Contextual Tool]

        F -->|SSO In-App Filter| SSO[isAllowedInAppNavigation<br>satu.unpam.ac.id / sso.unpam.ac.id]
        G -->|SSO In-App Filter| SSO
    end

    subgraph "Akademik Native Engine"
        H --> AH[AcademicHubScreen]
        AH --> M1[Biodata Mahasiswa]
        AH --> M2[Jadwal Kuliah TM & Online]
        AH --> M3[Nilai Akademik & Transkrip]
        AH --> M4[KRS Semester Aktif]
        AH --> M5[KHS & Komponen Nilai]
        AH --> M6[Presensi & Kehadiran]
        AH --> M7[Keuangan & Tagihan SPP]
        AH --> M8[Tugas Akhir / Skripsi]
        AH --> M9[Penugasan Proyek & MBKM]
        AH --> M10[Pengajuan Izin / Absen Jalan]
        AH --> M11[Dokumen Akademik & SK]
        AH --> M12[Sertifikat Seminar]

        AH --> SWS[ScheduleScreen<br>Dual-Sync Tracker]
        SWS -->|Sync Phase 1| API1[/api/jadwal-kuliah MyUnpam]
        SWS -->|Sync Phase 2| API2[Moodle Web Service Mentari core_calendar]
        SWS -->|Klik Deadline In-App| F
    end

    subgraph "Layanan Inti, Pembaruan & Keamanan"
        E --> BIO[BiometricAuthService<br>Android Hardware Keystore]
        E --> BR[WebViewDownloadBridge<br>W3C Blob Streaming & TLS Engine]
        BR --> FS[FileDownloadService<br>Dio / OpenFilex / Auto-Naming]
        E --> UPD[UpdateCheckerService<br>GitHub Releases REST API + ABI Matcher]
        E --> NOTIF[NotificationService<br>Heads-Up Local Notification]
        I --> AIS[AiService Multi-Provider<br>Gemini / DeepSeek / Claude / Qwen / OpenAI / Cloud]
    end
```

---

## Daftar Fitur Mendalam

### 1. Dual-Portal WebView Berakselerasi GPU
* **Mentari LMS (`mentari.unpam.ac.id`)**:
  * Akses penuh ke materi perkuliahan 21 pertemuan, forum diskusi, penugasan, presensi mandiri, serta pengerjaan kuis interaktif.
  * Terbebas dari kendala proteksi Cloudflare Turnstile CAPTCHA berkat sinkronisasi native header dan User-Agent modern.
* **MyUnpam SIAKAD (`my.unpam.ac.id`)**:
  * Akses terpadu ke portal web MyUnpam untuk fitur administrasi yang memerlukan antarmuka web khusus.
* **Isolasi State `IndexedStack` & GPU Acceleration**:
  * Kedua engine WebView berjalan pada tumpukan terisolasi dengan layer `RepaintBoundary` untuk memastikan render 120 FPS tanpa freeze. Berpindah tab tidak mereset input form, kuis yang sedang dikerjakan, atau status halaman aktif.

### 2. Hub Layanan Akademik Native (12 Layanan OpenAPI)
Diakses melalui tab ke-3 (**Akademik**), menyajikan antarmuka native Material 3 yang cepat, responsif, dan hemat kuota:
1. **Biodata Mahasiswa (`/api/biodata`)**: Profil lengkap, NIM, NIK, Program Studi, Fakultas, Jenjang, Semester Aktif, Status Akademik, Dosen PA, dan kontak terverifikasi.
2. **Jadwal Kuliah (`/api/jadwal-kuliah`)**: Daftar jadwal perkuliahan terstruktur dengan filter chip instan **Tatap Muka** dan **Online**, informasi ruang kelas, gedung, jam kuliah, dan dosen pengampu.
3. **Nilai Akademik (`/api/nilai`)**: Rekapitulasi nilai seluruh semester, status kelulusan mata kuliah, bobot SKS, nilai mutu, dan grafik pencapaian IPK kumulatif.
4. **Kartu Rencana Studi / KRS (`/api/krs`)**: Rincian mata kuliah yang dikontrak pada semester berjalan, kelas, status persetujuan pembimbing akademik, serta rekapitulasi beban SKS.
5. **Kartu Hasil Studi / KHS (`/api/khs`)**: Laporan nilai semesteran detail mencakup 6 komponen nilai riil: Kehadiran/Absensi, Tugas Terstruktur, Kuis, UTS, UAS, dan Nilai Partisipatif.
6. **Presensi & Kehadiran (`/api/kehadiran`)**: Monitoring persentase kehadiran per mata kuliah, batas minimal kehadiran 75%, serta rekap status Hadir, Izin, Sakit, atau Alpa.
7. **Keuangan & Tagihan SPP (`/api/keuangan`)**: Rincian tagihan semesteran, riwayat pembayaran, status lunas, nomor rekening virtual account, dan sisa kewajiban pembayaran.
8. **Tugas Akhir / Skripsi (`/api/tugas-akhir/*`)**: Status pengajuan judul, surat keputusan pembimbing, data Dosen Pembimbing 1 & 2, serta timeline konsultasi bimbingan skripsi.
9. **Penugasan Proyek & MBKM (`/api/penugasan-proyek`)**: Daftar tugas besar proyek perkuliahan, unduh berkas instruksi soal, status validasi dosen, serta input nilai proyek.
10. **Pengajuan Izin / Absen Jalan (`/api/absen-jalan/pengajuan-izin`)**: Riwayat dan formulir pengajuan dispensasi perkuliahan dengan status verifikasi program studi.
11. **Dokumen Akademik (`/api/dokumen`, `/api/dokumen/kategori`)**: Repositori berkas resmi universitas (SK Rektor, Panduan Skripsi, Form Cuti, Surat Keterangan) dengan pencarian dan filter kategori.
12. **Sertifikat Seminar (`/api/sertifikat-seminar`)**: Arsip sertifikat kegiatan ilmiah, webinar, workshop, dan seminar nasional/internasional yang divalidasi universitas.

### 3. Jadwal Kuliah & Deadline Tracker Terpadu
* **Sinkronisasi Dua Fase Otomatis**:
  * **Fase 1 (Jadwal Kuliah)**: Sinkronisasi native langsung via REST API `/api/jadwal-kuliah` dengan cache SharedPreferences terenkripsi dan indikator waktu perbaruan terakhir.
  * **Fase 2 (Deadline Tracker)**: Menarik agenda tugas, kuis, dan ujian dari Mentari LMS melalui Moodle Web Service AJAX (`core_calendar_get_action_events_by_timesort`) menggunakan sesi aktif dan token CSRF `sesskey` secara instan dalam 1 kali panggilan background.
* **Tiga Sub-Tab Tampilan**:
  * **Hari Ini**: Menampilkan mata kuliah aktif hari berjalan lengkap dengan badge status Tatap Muka / Online, waktu mulai-selesai, ruang kelas, dan dosen.
  * **Mingguan**: Tampilan kalender 7 hari ke depan yang dikelompokkan secara kronologis per hari.
  * **Deadline**: Urutan tenggat waktu tugas/kuis berdasarkan urgensi dengan kode warna: Merah (≤1 hari), Oranye (≤3 hari), dan Hijau (>3 hari).
* **Navigasi Balik In-App**:
  * Mengetuk item deadline dari daftar akan langsung mengarahkan pengguna kembali ke dalam tab Mentari LMS di modul tugas terkait secara native tanpa keluar ke peramban eksternal.
* **Pengingat Notifikasi Lokal**:
  * `DeadlineReminderService` mengirimkan notifikasi otomatis pada status bar Android saat tenggat H-0, H-1, dan H-3 terdeteksi.

### 4. Autentikasi In-App SSO & Satu UNPAM Gateway
* **Whitelisting Domain Komprehensif (`isAllowedInAppNavigation`)**:
  * Mengeliminasi bug redirect eksternal saat login My UNPAM dengan mengizinkan seluruh domain dan subdomain resmi UNPAM:
    * `satu.unpam.ac.id` (Gerbang Utama Single Sign-On Kampus)
    * `my.unpam.ac.id` (Portal Mahasiswa SIAKAD)
    * `mentari.unpam.ac.id` (Portal Pembelajaran Moodle)
    * `sso.unpam.ac.id` & `auth.unpam.ac.id` (Layanan Identitas Kampus)
    * `*.unpam.ac.id` (Seluruh subdomain universitas)
    * `challenges.cloudflare.com` & `*.cloudflare.com` (Verifikasi Keamanan Bot)
    * `accounts.google.com` (Integrasi Akun Google Institusi)
* **Auto-Bypass Konfirmasi Redirect SSO**:
  * Skrip JavaScript otomatis mengeksekusi tombol "Lanjutkan ke My UNPAM" pada layar konfirmasi SSO tanpa mengharuskan pengguna mengetuk tombol secara manual.

### 5. The PAMs AI Multi-Engine & Multimodal Vision OCR
* **Standardized Floating PAMs AI Tool**:
  * Desain kapsul stadium pill biru tua khas (`#1E3A8A`) dengan ikon sparkle emas (`#F59E0B`), teks "PAMs AI", drag handle, dan menu titik tiga opsi cepat.
  * Tersedia di portal peramban web (Mentari & MyUnpam) serta di **seluruh sub-layar native Hub Akademik**, menyajikan prompt analisis terarah sesuai modul yang dibuka (analisis beban KRS, evaluasi nilai KHS, panduan skripsi, kalkulasi SPP, dsb.).
* **Multi-Engine Provider LLM**:
  * Dukungan ke berbagai model AI tercanggih di dunia: Google Gemini, DeepSeek, Anthropic Claude, Alibaba Qwen, OpenAI, OpenRouter, dan The PAMs Cloud AI Gratis.
* **Fitur AI Khusus**:
  * **Multimodal Vision OCR**: Memotret lembar soal fisik atau mengambil screenshot dari galeri untuk dianalisis oleh AI Vision secara instan.
  * **Solusi Kuis & Forum Diskusi**: Membedah topik diskusi dan menghasilkan jawaban ilmiah terstruktur beserta referensi literatur.
  * **Parafrase Akademik**: Menyajikan 4 mode gaya penulisan (Formal, Santai, Akademis, Ringkas) dengan komparasi visual side-by-side untuk menurunkan skor plagiarisme/Turnitin.
  * **Kuesioner Evaluasi Dosen**: Mode cepat (pengisian nilai optimal) atau analisis kualitatif guna menghasilkan umpan balik apresiatif dan santun.

### 6. Biometric Auto-Login Vault (Hardware Keystore)
* Mengamankan NIM dan kata sandi menggunakan enkripsi perangkat keras Android (*Hardware-backed Keystore*) via `flutter_secure_storage`.
* *Quick Prompt Sheet* otomatis terpicu saat form login portal terdeteksi, memungkinkan login satu sentuhan via sidik jari atau pemindaian wajah.

### 7. Jembatan Unduhan Chromium & Ekstraksi Memori Blob
* **Pemecahan Galat URI `blob:`**:
  * Mengekstraksi berkas biner PDF client-side langsung dari RAM peramban secara streaming W3C compliant tanpa terhambat kebijakan penolakan kredensial browser.
* **Bypass Cloudflare Turnstile**:
  * Menyalurkan unduhan dokumen terproteksi melalui engine TLS dan cookie sesi aktif peramban Chromium.
* **Penamaan Otomatis & Pratinjau Langsung**:
  * Memberikan nama berkas yang rapi dan deskriptif (`KRS_ThePAMs_...`, `KHS_ThePAMs_...`, `Jadwal_Kuliah_...`) serta langsung membukanya di aplikasi pembaca PDF eksternal pilihan pengguna via `open_filex`.

### 8. Gerbang Izin Akses Wajib (Permission Gatekeeper)
* Memverifikasi 3 izin esensial sebelum pengguna mengakses portal utama:
  1. **Notifikasi Sistem**: Untuk reminder tenggat deadline tugas dan notifikasi pembaruan OTA.
  2. **Kamera**: Untuk fitur The PAMs AI Vision OCR lembar soal fisik.
  3. **Penyimpanan & Media**: Untuk mengunduh berkas materi perkuliahan dan mengunggah lampiran tugas.
* Menyediakan navigasi langsung ke Pengaturan Aplikasi HP (`openAppSettings()`) jika izin ditolak permanen, serta otomatis mendeteksi pemulihan izin saat kembali.

### 9. In-App OTA Updater Otomatis & Riwayat Pembaruan Live
* **Pengecekan Otomatis di Latar Belakang**:
  * Membandingkan SemVer aplikasi lokal dengan rilis terbaru di GitHub Releases REST API.
* **Deteksi Arsitektur Chipset CPU (Split-per-ABI)**:
  * Mengidentifikasi ABI perangkat pengguna (`arm64-v8a`, `armeabi-v7a`, `x86_64`) dan mengunduh berkas APK yang paling ringan (~16–20MB) dibanding APK Universal (~55MB) demi menghemat kuota internet mahasiswa.
* **Riwayat Rilis Dinamis**:
  * Menampilkan seluruh catatan changelog pembaruan langsung dari GitHub API pada menu titik tiga AppBar.

### 10. Syarat & Ketentuan Terproteksi (15s Mandatory Timer)
* Layar integritas akademik pada pembukaan pertama aplikasi.
* Tombol "SAYA SETUJU" dikunci dengan timer hitung mundur 15 detik untuk memastikan mahasiswa membaca dan memahami etika penggunaan kecerdasan buatan dalam perkuliahan.

---

## Daftar Endpoint API Terintegrasi

Layanan native pada tab **Akademik** terhubung ke endpoint resmi My UNPAM SIAKAD (`https://my.unpam.ac.id/api`):

| Layanan Akademik | Endpoint REST API | Metode | Fitur Utama |
| :--- | :--- | :---: | :--- |
| **Biodata Mahasiswa** | `/api/biodata` | `GET` | Profil mahasiswa, prodi, jenjang, PA, semester |
| **Jadwal Kuliah** | `/api/jadwal-kuliah` | `GET` | Jadwal semester aktif, filter Tatap Muka & Online |
| **Nilai Akademik** | `/api/nilai` | `GET` | Rekapitulasi nilai, IPK, mutus, status kelulusan |
| **Kartu Hasil Studi** | `/api/khs` | `GET` | Nilai semesteran & rincian komponen nilai riil |
| **Rencana Studi (KRS)** | `/api/krs` | `GET` | Daftar kontrak SKS, kelas, kurikulum, dosen |
| **Presensi Mahasiswa** | `/api/kehadiran` | `GET` | Rekapitulasi presensi, batas 75%, status H/I/S/A |
| **Keuangan Mahasiswa** | `/api/keuangan` | `GET` | Tagihan SPP, virtual account, riwayat bayar |
| **Tugas Akhir / Skripsi** | `/api/tugas-akhir/*` | `GET` | Status proposal, dosen pembimbing 1 & 2, bimbingan |
| **Penugasan Proyek** | `/api/penugasan-proyek` | `GET` | Tugas proyek mata kuliah, validasi, nilai, soal |
| **Pengajuan Izin** | `/api/absen-jalan/pengajuan-izin`| `GET` | Dispensasi kuliah, pengajuan absen jalan |
| **Dokumen Akademik** | `/api/dokumen`, `/api/dokumen/kategori` | `GET` | Repositori SK, panduan akademik, formulir |
| **Sertifikat Seminar** | `/api/sertifikat-seminar` | `GET` | Arsip sertifikat kegiatan ilmiah terverifikasi |
| **Deadline Mentari LMS** | `/lib/ajax/service.php` | `POST` | Moodle WS `core_calendar_get_action_events_by_timesort` |

---

## Matriks Spesifikasi Model AI (Per Oktober 2026)

Pengguna dapat memilih mesin kecerdasan buatan pada panel pengaturan The PAMs AI:

| Provider | Model Rekomendasi Terkini | Model ID API | Vision OCR | Kemampuan Utama |
| :--- | :--- | :--- | :---: | :--- |
| **The PAMs Cloud AI** | Cloud Native Fast | `openai-fast` | Tidak | **Gratis tanpa kuota & tanpa API Key**. Cepat untuk tanya jawab umum tugas perkuliahan. |
| **Google Gemini** | Gemini 3.8 Flash, 4 Argon | `gemini-3.8-flash` | **Ya** | Multimodal Vision OCR foto lembar soal kuis, jendela konteks 1 Juta token & latensi ultra rendah. |
| **DeepSeek** | DeepSeek V4 (Flash / Pro) | `deepseek-v4-flash` | Tidak | Jendela konteks 1 Juta token, penalaran logika matematika, analisis algoritma & pemrograman. |
| **Anthropic Claude** | Claude Sonnet 5.5, Opus 5.5 | `claude-sonnet-5-5` | **Ya** | Penalaran akademis terstruktur, tata bahasa ilmiah elegan, analisis jurnal komprehensif. |
| **Alibaba Qwen** | Qwen 3.8-Max, 3.7-Max | `qwen3.8-max` | Tidak | Flagship Alibaba Cloud Model Studio dengan kecakapan teknis komprehensif & multibahasa. |
| **OpenAI** | GPT-5, GPT-4o | `gpt-5-mini` | **Ya** | Penalaran mutakhir dan pemahaman konteks multimodal teruji untuk beragam disiplin ilmu. |
| **OpenRouter** | Hub Multi-Model Bebas | Format `provider/model` | **Ya** | Satu API Key untuk mengakses ratusan model open-source maupun komersial global. |

---

## Struktur Direktori Proyek

Arsitektur aplikasi menerapkan pola modular **Feature-First**:

```text
unpam_mobile/
├── .github/
│   └── workflows/
│       └── release-apk.yml                      # CI/CD otomatis kompilasi APK Split-per-ABI & rilis GitHub
├── android/                                     # Konfigurasi native Android (Gradle, Manifest, Keystore)
├── assets/                                      # Aset statis aplikasi (ikon & logo institusi)
│   └── icon/
│       └── app_icon.png                         # Ikon peluncur resmi The PAMs
├── lib/
│   ├── core/
│   │   ├── constants/
│   │   │   ├── api_constants.dart               # URL portal, model AI, storage keys
│   │   │   └── my_unpam_scripts.dart            # JS sniffer token & sinkronisasi sesi MyUnpam
│   │   └── services/
│   │       ├── ai_service.dart                  # Engine komunikasi multi-provider LLM & Vision OCR
│   │       ├── biometric_auth_service.dart      # Layanan autentikasi biometrik & secure hardware keystore
│   │       ├── file_download_service.dart       # Manajemen unduhan dokumen akademik & resolusi nama berkas
│   │       ├── notification_service.dart        # Layanan notifikasi lokal status bar Android
│   │       ├── permission_service.dart          # Manajemen & verifikasi status izin perangkat Android
│   │       ├── storage_service.dart             # Abstraksi SharedPreferences & penyimpanan cache sesi
│   │       ├── update_checker_service.dart      # Layanan GitHub Releases API & OTA update installer
│   │       └── webview_download_bridge.dart     # Jembatan unduhan Chromium & W3C blob memory extractor
│   ├── features/
│   │   ├── academic/                            # Fitur: Hub Layanan Akademik Native
│   │   │   ├── data/
│   │   │   │   ├── academic_portal_service.dart # Klien HTTP Dio untuk 12 endpoint OpenAPI My UNPAM
│   │   │   │   ├── finance_service.dart         # Layanan rincian tagihan & pembayaran keuangan
│   │   │   │   ├── my_unpam_refresher.dart      # Refresher sesi latar belakang tanpa gangguan pengguna
│   │   │   │   ├── my_unpam_session.dart        # Manajemen token JWT & masa berlaku sesi MyUnpam
│   │   │   │   └── my_unpam_web_fetcher.dart    # Web fetcher transparan pendukung pemanggilan API
│   │   │   ├── domain/
│   │   │   │   └── models/                      # Model data typed: Biodata, Jadwal, Nilai, KRS, KHS,
│   │   │   │                                    # Keuangan, Kehadiran, Skripsi, Proyek, Izin, Dokumen, Seminar
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   ├── academic_portal_provider.dart # State provider untuk data portal akademik
│   │   │       │   └── finance_provider.dart         # State provider untuk rincian keuangan SPP
│   │   │       ├── screens/                     # 12 Layanan Layar Native Akademik + Academic Hub Grid
│   │   │       └── widgets/
│   │   │           ├── portal_ai_assist.dart    # Standard Floating PAMs AI Tool untuk Akademik Native
│   │   │           ├── portal_state_views.dart  # Komponen UI: Loading, Empty, Error dengan tombol coba lagi
│   │   │           └── sso_auth_modal.dart      # Modal bottom sheet login Satu UNPAM terintegrasi
│   │   ├── ai_assistant/                        # Fitur: The PAMs AI Academic Assistant
│   │   │   ├── presentation/
│   │   │   │   ├── providers/
│   │   │   │   │   └── ai_provider.dart         # State management AI: model, riwayat chat, Vision OCR
│   │   │   │   ├── screens/
│   │   │   │   │   ├── ai_assistant_screen.dart # Layar percakapan AI, kuis interaktif, & Vision OCR
│   │   │   │   │   └── ai_paraphrase_screen.dart# Layar alat parafrase teks ilmiah akademik
│   │   │   │   └── widgets/
│   │   │   │       └── mini_ai_overlay_panel.dart # Panel AI mengambang split-screen atas WebView
│   │   ├── auth/                                # Fitur: Autentikasi Biometrik
│   │   │   └── presentation/widgets/
│   │   │       ├── biometric_quick_prompt_sheet.dart # Prompt cepat konfirmasi sidik jari/wajah
│   │   │       └── biometric_vault_sheet.dart        # Pengaturan kredensial biometrik tersimpan
│   │   ├── onboarding/                          # Fitur: Onboarding & Permission Gate
│   │   │   └── presentation/screens/
│   │   │       ├── user_agreement_screen.dart   # Layar syarat & ketentuan dengan timer wajib 15 detik
│   │   │       └── permission_gate_screen.dart  # Layar verifikasi persetujuan izin wajib
│   │   ├── portal/                              # Fitur: Shell Portal WebView Terpadu
│   │   │   ├── data/scripts/
│   │   │   │   └── portal_js_scripts.dart       # Injeksi JS: Biometrik, Blob, Jadwal & Deadline scraper
│   │   │   └── presentation/
│   │   │       ├── screens/
│   │   │       │   └── portal_webview_screen.dart # Shell utama Mentari, MyUnpam, Hub Akademik, & AI
│   │   │       └── widgets/
│   │   │           └── portal_bottom_nav.dart   # Bottom navigation bar 4 tab
│   │   ├── schedule/                            # Fitur: Jadwal Kuliah & Deadline Tracker
│   │   │   ├── data/
│   │   │   │   ├── schedule_service.dart        # CRUD cache jadwal & deadline di SharedPreferences
│   │   │   │   └── deadline_reminder_service.dart # Notifikasi reminder lokal H-0, H-1, H-3
│   │   │   ├── domain/models/
│   │   │   │   └── schedule_model.dart          # Model CourseSchedule, CourseDeadline & DeadlineType
│   │   │   └── presentation/
│   │   │       ├── providers/
│   │   │       │   └── schedule_provider.dart   # State provider jadwal & deadline (Dual-Sync Phase 1 & 2)
│   │   │       └── screens/
│   │   │           └── schedule_screen.dart     # Layar 3 sub-tab: Hari Ini, Mingguan, Deadline
│   │   └── updater/                             # Fitur: OTA Updater & Release History
│   │       ├── domain/models/
│   │       │   ├── app_update_info.dart         # Metadata pembaruan & logika pembanding SemVer
│   │       │   └── github_release.dart          # Parser payload rilis GitHub API & pemilih aset ABI
│   │       └── presentation/widgets/
│   │           ├── release_history_dialog.dart  # Dialog riwayat pembaruan sinkron live GitHub API
│   │           └── update_dialog.dart           # Dialog konfirmasi & progress download pembaruan APK
│   ├── theme/
│   │   └── app_theme.dart                       # Sistem tema & token warna institusi (Navy & Gold)
│   └── main.dart                                # Entrypoint aplikasi, MultiProvider & inisialisasi layanan
├── test/
│   ├── academic_portal_test.dart                # Pengujian model dan parsing 12 layanan OpenAPI
│   ├── finance_test.dart                        # Pengujian layanan & provider keuangan mahasiswa
│   ├── my_unpam_session_test.dart               # Pengujian manajemen sesi token & JWT expiration
│   ├── portal_ai_assist_test.dart               # Pengujian widget floating pill PAMs AI
│   └── widget_test.dart                         # Pengujian navigasi SSO in-app, permission, updater (Total 65 tests)
├── analysis_options.yaml                        # Aturan static analysis Dart & Flutter linter (strict mode)
├── pubspec.yaml                                 # Dependensi paket & versi aplikasi (v1.0.54+54)
├── RELEASE_NOTES.md                             # Catatan rilis publik komprehensif
└── README.md                                    # Dokumentasi proyek
```

---

## Prasyarat & Cara Menjalankan

### Prasyarat Pengembangan
* **Flutter SDK**: Versi `3.41.7` (Channel `stable`)
* **Dart SDK**: Versi `3.11.5`
* **Java Development Kit (JDK)**: Versi 17 (Eclipse Temurin direkomendasikan)
* **Android SDK**: Min SDK 21 (Android 5.0 Lollipop), Target SDK 34 (Android 14)
* Perangkat Android fisik atau emulator dengan koneksi internet aktif.

### Langkah Menjalankan Proyek
```bash
# 1. Clone repositori
git clone https://github.com/codewithtama/unpam_mobile.git
cd unpam_mobile

# 2. Unduh seluruh paket dependensi
flutter pub get

# 3. Jalankan static analysis (Harus 0 warning / 0 issue)
flutter analyze

# 4. Jalankan seluruh rangkaian pengujian otomatis (65 tests)
flutter test

# 5. Jalankan aplikasi pada perangkat Android
flutter run
```

---

## Kompilasi & Rilis APK

Aplikasi menggunakan skema penandatanganan ganda (**APK Signature Scheme v1 JAR + v2 Full**) serta kompilasi terisolasi per arsitektur CPU untuk menjamin performa maksimal dan kompatibilitas penuh di seluruh varian vendor Android (Xiaomi HyperOS/MIUI, Samsung OneUI, ColorOS, OriginOS, dsb.).

### Kompilasi Lokal (Split-per-ABI)

```bash
flutter build apk --release --split-per-abi --obfuscate --split-debug-info=build/app/outputs/symbols
```

Berkas APK hasil kompilasi berlokasi di:
* `build/app/outputs/flutter-apk/app-arm64-v8a-release.apk` (HP Android Modern 64-bit, ~16–19MB)
* `build/app/outputs/flutter-apk/app-armeabi-v7a-release.apk` (HP Android 32-bit, ~15–18MB)
* `build/app/outputs/flutter-apk/app-x86_64-release.apk` (Emulator Android, ~18–20MB)

### CI/CD Otomatis via GitHub Actions
Setiap kali tag rilis di-push ke repositori GitHub (contoh: `git tag v1.0.54 && git push origin v1.0.54`), workflow `.github/workflows/release-apk.yml` akan secara otomatis:
1. Memverifikasi kode sumber dan menjalankan `flutter analyze` serta `flutter test`.
2. Mengonfigurasi keystore rilis bertandatangan resmi.
3. Mengompilasi varian APK ringan *Split-per-ABI* dengan proteksi kode `--obfuscate`.
4. Menerbitkan rilis baru di GitHub Releases dengan menyertakan changelog dari `RELEASE_NOTES.md` beserta seluruh berkas APK yang siap diunduh oleh pengguna.

---

## Keamanan, Integritas Sesi & Kepatuhan Privasi

1. **Integritas Sesi & Kredensial Pengguna**:
   Seluruh proses autentikasi akun Mentari LMS, MyUnpam SIAKAD, dan Satu UNPAM SSO diproses secara langsung di dalam peramban web resmi Universitas Pamulang. Kata sandi tidak pernah dikirimkan atau disimpan di server pihak ketiga mana pun.
2. **Penyimpanan Biometrik Terisolasi (Hardware-Backed Keystore)**:
   Kredensial login biometrik dienkripsi menggunakan standar keamanan perangkat keras Android melalui `flutter_secure_storage`.
3. **Kerahasiaan Kunci API AI**:
   API Key pengguna (Gemini, DeepSeek, Claude, Qwen, dsb.) tersimpan secara aman di ruang penyimpanan lokal perangkat dan hanya dikirimkan langsung ke endpoint resmi penyedia model terkait melalui koneksi terenkripsi HTTPS TLS 1.3.
4. **Isolasi Aliran Data Memori (Zero Data Leakage)**:
   Ekstraksi berkas memori *skema `blob:`* diproses secara lokal di dalam memori peramban tanpa perantara jaringan eksternal yang tidak aman.
5. **Penyimpanan Data Akademik & Jadwal Lokal**:
   Seluruh data biodata, nilai, jadwal kuliah, dan tenggat waktu tugas hanya disimpan di perangkat pengguna (`SharedPreferences`) dan tidak pernah dikirimkan ke server eksternal mana pun.
6. **Standar Aksesibilitas WCAG AA**:
   Seluruh antarmuka dirancang responsif terhadap pengaturan skala teks besar pada ponsel pengguna guna mencegah terjadinya *RenderFlex overflow*.

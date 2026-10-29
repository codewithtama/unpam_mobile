# Catatan Pembaruan Rilis The PAMs

## Versi 1.0.48 (Terbaru)

- **Navigasi Deadline In-App Terintegrasi (Buka Langsung di Mentari LMS Tanpa Browser Eksternal)**:
  - **In-App Navigation Seamless**: Mengarahkan klik pada tile daftar deadline di tab Jadwal & Deadline langsung ke WebView Mentari LMS di tab utama aplikasi The PAMs. Pengguna tidak lagi dilempar keluar aplikasi ke Chrome atau peramban eksternal.
  - **Dukungan Push Notifikasi Deadline Terpadu**: Mengetuk notifikasi pengingat deadline (H-1 / hari H) otomatis membuka aplikasi, berpindah ke tab Mentari LMS, dan memuat URL spesifik tugas/kuis mata kuliah secara mulus.
  - **Transisi Halus**: Dialog Jadwal otomatis ditutup dengan animasi pop sebelum WebView mengarahkan ke halaman target perkuliahan dengan delay transisi yang aman.
  - **Pengujian Otomatis**: 32/32 unit & widget tests lulus (termasuk verifikasi in-app navigation callback), 0 analyzer issues.

## Versi 1.0.47

- **Optimasi Ekstrem Performa Mentari Sync (Zero-Framedrop & 60–120 FPS)**:
  - **Eliminasi Total DOM Reflow di WebView**: Menggantikan `tempDiv.innerHTML` dan `tempDiv.innerText` dengan parser string murni (`stripHtmlTags`) berkinerja tinggi. Pemrosesan HTML kursus kini berlangsung dalam hitungan milidetik di memori tanpa memicu layout, reflow, atau pembebanan GPU pada Chromium WebView.
  - **Debounce & Diff-Guard Penjadwalan Alarm**: Menambahkan validasi `_areDeadlinesEqual` pada `ScheduleProvider` untuk mencegah penulisan disk dan penjadwalan ulang jika data tidak berubah. Penjadwalan alarm `AlarmManager` native didebounce 2.000 ms, mengeliminasi banjir ratusan panggilan platform channel IPC yang sebelumnya membekukan thread utama Flutter.
  - **Throttling Evaluasi JavaScript & MutationObserver**: Menghapus eksekusi bertingkat (triplicate calls) pada `_tryExtractDeadlines` menjadi 1 kali evaluasi tertunda (700 ms). Debounce `MutationObserver` dinaikkan menjadi 2.500 ms dengan hash caching payload agar tidak mengirim data duplikat.
  - **Pengujian Otomatis**: 31/31 unit & widget tests lulus, 0 analyzer issues.

## Versi 1.0.46

- **Optimasi Notifikasi Sinkronisasi Deadline (Anti-Spam & Single-Alert)**:
  - **Pembatasan Notifikasi Tunggal (Cukup 1 Kali)**: Notifikasi SnackBar `✓ X deadline/tugas berhasil diperbarui!` kini dibatasi maksimal 1 kali per sesi perkuliahan Mentari, mencegah notifikasi berulang-ulang yang mengganggu pengguna saat berpindah halaman atau saat scanner DOM berjalan.
  - **Debounce Agregasi Multi-Course**: Saat aplikasi memindai banyak mata kuliah di background secara simultan, SnackBar otomatis didebounce (1.200 ms) dan seluruh tugas diagregasi ke dalam 1 pesan ringkasan gabungan di akhir proses.
  - **Pencegahan Penumpukan Antrean SnackBar**: Menambahkan `hideCurrentSnackBar()` sebelum menampilkan notifikasi agar tidak ada penumpukan popup berturut-turut di layar.
  - **JavaScript Batch Accumulator**: Skrip background fetch pada dashboard Mentari kini mengakumulasikan seluruh mata kuliah terlebih dahulu sebelum mengirimkan satu payload terpadu ke aplikasi.
  - **Pengujian Otomatis**: 31/31 unit & widget tests lulus, 0 analyzer issues.

## Versi 1.0.45

- **Ekstraksi Sempurna Accordion Pertemuan Mentari LMS & Proactive Multi-Course Sync**:
  - **Dukungan Struktur Asli Accordion Pertemuan Mentari**: Mengatasi perbedaan arsitektur Mentari LMS (non-standard Moodle layout) dengan parser khusus yang memindai slot aktivitas wajib mahasiswa di setiap pertemuan (`Pertemuan 1` s.d. `Pertemuan 21`):
    - `Pretest`: Terdeteksi otomatis sebagai Kuis ketika berstatus aktif (`QUIZ`).
    - `Posttest`: Terdeteksi otomatis sebagai Kuis ketika berstatus aktif (`QUIZ`).
    - `Penugasan Terstruktur`: Terdeteksi otomatis sebagai Tugas saat dosen mengunggah instruksi/soal (mengabaikan slot berstatus `No content`).
    - `Forum Diskusi`: Terdeteksi otomatis sebagai Tugas diskusi saat topik tersedia (mengabaikan status belum tersedia / `No content`).
  - **Proactive Background Sync dari Dashboard Mentari (`https://mentari.unpam.ac.id/`)**:
    - Saat mahasiswa membuka dashboard Mentari, aplikasi secara otomatis memindai seluruh kartu mata kuliah yang diambil (`a[href*="/u-courses/"]`) dan melakukan background fetch terotentikasi untuk mengekstrak tugas dan kuis dari semua mata kuliah tanpa harus membuka satu per satu.
  - **Kalkulasi Cerdas Jatuh Tempo Mingguan (Smart Due Date Engine)**:
    - Membaca hari jadwal kuliah dari header kursus (contoh: `(Sabtu)` dari `[3] JARINGAN KOMPUTER # 04SIFE001 (Sabtu) [E-1]`) dan menghitung tenggat waktu pengumpulan ke akhir pekan (Minggu 23:59 WIB) atau jadwal kuliah terdekat agar seluruh kuis dan tugas langsung muncul rapi di sub-tab "Mendatang" dengan alarm pengingat aktif.
  - **Pembersihan Nama Mata Kuliah Otomatis**:
    - Menghilangkan noise kode kelas dan bracket (seperti `[3] JARINGAN KOMPUTER # 04SIFE001 (Sabtu) [E-1]` menjadi `JARINGAN KOMPUTER`) untuk tampilan antarmuka dan notifikasi yang bersih dan elegan.
  - **Pengujian Otomatis**: 31/31 unit & widget tests lulus, 0 analyzer issues.

## Versi 1.0.44

- **Penyempurnaan Total Ekstraksi Tugas & Deadline Mentari LMS**:
  - **Perbaikan Root Cause Parser Tanggal Tanpa Tahun & Relatif**: Mengatasi kegagalan scraper akibat format tanggal standar Moodle/Mentari yang tidak mencantumkan tahun (30 Oktober, 23:59, Jumat, 30 Okt, 23:59, Besok, 23:59, Hari ini, 23:59). Semua format tanggal lokal kini 100% terbaca.
  - **Integrasi Soft-Navigation onUrlChange**: Memastikan _tryExtractDeadlines dipanggil otomatis saat navigasi SPA client-side ke halaman mata kuliah (/u-courses/*), dilengkapi retry progresif (0ms, 800ms, 2000ms) untuk menangkap komponen Vue/Next yang di-render secara asinkron.
  - **Dukungan Halaman Rincian Tugas (/mod/assign/view.php)**: Menambahkan parser khusus untuk tabel status pengajuan tugas (submissionstatustable) dengan kolom Batas Waktu, Status Pengumpulan, dan Waktu Tersisa.
  - **Resolusi Cerdas Nama Mata Kuliah**: Menghubungkan kode mata kuliah dari URL Mentari (contoh: 22SIF0242) dengan jadwal resmi MyUnpam, sehingga nama mata kuliah tampil lengkap dan rapi (bukan sekadar kode atau teks generic).
  - **Fallback Tugas Aktif**: Setiap aktivitas tugas, kuis, atau ujian aktif yang tidak mencantumkan tanggal di kartu tetap masuk ke daftar pemantauan deadline agar tidak ada tugas yang terlewat.
  - **Pengujian Otomatis**: 30/30 unit & widget tests lulus, 0 analyzer issues.

## Versi 1.0.43


- **Penyempurnaan Sistem Notifikasi Reminder Deadline Akademik**:
  - **Penjadwalan Alarm Mandiri (zonedSchedule & Timezone WIB)**: Mengaktifkan alarm terjadwal langsung ke subsistem Android AlarmManager untuk pengingat H-3 (08:00 WIB), H-1 (08:00 WIB), H-0 (07:00 WIB), dan H-2 Jam sebelum jatuh tempo.
  - **Konfigurasi AndroidManifest Lengkap**: Menambahkan izin RECEIVE_BOOT_COMPLETED, VIBRATE, SCHEDULE_EXACT_ALARM, USE_EXACT_ALARM, serta receiver ScheduledNotificationReceiver & ScheduledNotificationBootReceiver agar reminder tetap bekerja setelah perangkat reboot atau saat mode Doze.
  - **Fallback Cerdas Mode Alarm**: Mendukung AndroidScheduleMode.exactAllowWhileIdle dengan fallback otomatis ke AndroidScheduleMode.inexactAllowWhileIdle untuk kompatibilitas penuh di Android 12, 13, 14, dan 15 tanpa risiko crash.
  - **Unifikasi NotificationService**: Menyatukan handler kanal notifikasi (NotificationService dan DeadlineReminderService) dalam satu instance plugin terpadu, mencegah hilangnya callback respon tap.
  - **Deep-Navigation saat Notifikasi Diketuk**: Mengetuk notifikasi deadline langsung membuka aplikasi dan mengarahkan pengguna ke sub-tab Deadline pada layar Jadwal & Deadline.
  - **Pemberitahuan Instan Deadline Hari Ini**: Notifikasi Heads-up otomatis muncul saat aplikasi dibuka atau disinkronkan jika terdapat tugas yang jatuh tempo hari ini (<24 jam).
  - **Pengujian Otomatis**: 29/29 unit & widget tests lulus, 0 analyzer issues.

## Versi 1.0.42


- **Penyempurnaan Ekstraksi Deadline & Tugas Mentari LMS**:
  - **Dukungan Halaman Kursus `/u-courses/*`**: Mengekstrak tugas, kuis, dan diskusi langsung dari halaman mata kuliah dan pertemuan Mentari LMS Unpam.
  - **Parser Tanggal Lokal Indonesia Universal**: Mengenali ragam format tanggal Indonesia (`30 Oktober 2026, 23:59`, `30 Okt 2026 23.59`, `30/10/2026 23:59`, dsb.) dengan pemisah jam titik maupun titik dua.
  - **Sinkronisasi Akumulatif (Smart Merge)**: Membuka beberapa mata kuliah berbeda kini mengumpulkan seluruh tugas secara akumulatif tanpa menimpa data yang telah tersimpan sebelumnya.
  - **SPA Soft-Navigation & Network Sniffer**: Menangkap respons API dan memonitor perubahan rute client-side Mentari secara otomatis via `DeadlineChannel`.
  - **Tombol Sinkronisasi Manual Tab Deadline**: Pengguna dapat memicu pemindaian tenggat tugas secara langsung lewat tombol sync di AppBar pada sub-tab Deadline.
  - **Pengujian Otomatis**: 28/28 unit & widget tests lulus, 0 analyzer issues.

## Versi 1.0.41

- **Penyempurnaan Integrasi REST API Jadwal Kuliah MyUnpam**:
  - **Native REST API Payload Adapter**: Menyesuaikan parser `CourseSchedule` agar mengenali struktur JSON asli `https://my.unpam.ac.id/api/jadwal-kuliah` (objek `jadwal` dengan relasi nested `mata_kuliah`, `waktu_kuliah`, `dosen`, dan `ruang`).
  - **Proactive In-WebView Fetch**: Script ekstraksi secara otomatis memanggil endpoint API jadwal menggunakan sesi autentikasi dan cookie aktif dari WebView MyUnpam.
  - **Network Request Sniffer (XHR & Fetch Hook)**: Mengintersep pemanggilan API oleh Single Page Application MyUnpam secara real-time dan meneruskannya ke Flutter via `ScheduleChannel`.
  - **Perbaikan Format Jam Kuliah Unpam**: Mendukung parsing format jam bertitik institusional Unpam (`07.40 - 09.20`) dan menormalkannya ke standar jam `07:40 - 09:20`.
  - **Koreksi Tautan Navigasi MyUnpam**: Memperbaiki routing deep-link ke `/data-akademik/jadwal-kuliah` (sebelumnya `/jadwal-kuliah` yang teredireksi).
  - **Tombol Sinkronisasi Manual**: Menambahkan tombol refresh langsung pada AppBar layar Jadwal dengan indikator proses dan notifikasi SnackBar konfirmasi jumlah mata kuliah tersinkron.
  - **Pengujian Otomatis**: Menambahkan unit test parser API MyUnpam (26/26 unit & widget tests lulus, 0 analyzer issues).

## Versi 1.0.40

- **Fitur Baru: Jadwal Kuliah & Deadline Tracker**:
  - **Tab Jadwal Native**: Menambahkan tab keempat "Jadwal" (ikon `calendar_month`) pada bottom navigation bar tanpa mengganggu tab Mentari dan MyUnpam yang sudah ada.
  - **Scraping Otomatis via JS Injection**: Jadwal kuliah di-scrape otomatis dari halaman MyUnpam SIAKAD, dan deadline/tugas di-scrape dari dashboard Mentari LMS (upcoming events, timeline, assignment tables) menggunakan JavaScript injection pada event `onPageFinished`.
  - **Tiga Sub-Tab Informatif**: Layar Jadwal menampilkan tiga sub-tab — *Hari Ini* (jadwal kuliah aktif hari ini), *Mingguan* (seluruh jadwal 7 hari ke depan dikelompokkan per hari), dan *Deadline* (daftar tugas/kuis/ujian diurutkan berdasarkan urgensi dengan kode warna).
  - **Cache Lokal SharedPreferences**: Data jadwal dan deadline di-cache di `SharedPreferences` tanpa dependensi database baru, dengan indikator "terakhir diperbarui" dan tombol deep-link langsung ke portal terkait.
  - **Notifikasi Reminder Deadline**: `DeadlineReminderService` menampilkan notifikasi immediate saat ditemukan deadline H-0, H-1, dan H-3 — menggunakan kanal notifikasi tersendiri (`the_pams_deadline_reminder_v1`) agar tidak bertabrakan dengan notifikasi OTA.
  - **Banner Deadline Mendesak**: Menampilkan banner peringatan merah di bagian atas sub-tab Deadline jika ada tugas yang jatuh tempo dalam ≤1 hari.
  - **Zero Dependensi Baru**: Seluruh fitur dibangun di atas `flutter_local_notifications` dan `shared_preferences` yang sudah ada, tanpa menambahkan satu pun package baru ke `pubspec.yaml`.
  - **Arsitektur Feature-First**: Semua kode baru terisolasi di `lib/features/schedule/{data,domain,presentation}` sesuai konvensi arsitektur yang sudah ada.
  - **Audit & Pengujian**: 0 analyzer issues dan 100% lulus 25 automated unit tests (zero breaking changes).

## Versi 1.0.39

- **Redesain Floating Action Button (FAB) Menjadi Ramping & Ergonomis**:
  - **Penyusutan Ukuran Drastis (>55% Lebih Ramping)**: Memangkas lebar bentang FAB dari 292dp menjadi ~118–148dp dan menurunkan tinggi tombol dari 50dp menjadi 40dp, sehingga tidak lagi menutupi materi atau tampilan portal perkuliahan.
  - **Penyederhanaan Tipografi & Aksi (Single-Line Compact Title)**: Mengganti label bertumpuk 2 baris menjadi satu baris teks ringkas dan tegas (`compactActionTitle`: *PAMs AI*, *Kuis*, *Draf Forum*, *Kuesioner*, *Tanya AI*).
  - **Integrasi Menu Cepat Terpadu**: Mengganti rentetan tombol horizontal menjadi satu tombol utama aksi cepat dan satu tombol menu `⋮` atau `apps` untuk membuka seluruh menu The PAMs AI tools secara rapi.
  - **Audit & Pengujian**: 0 analyzer issues dan 100% lulus 25 automated unit tests.

## Versi 1.0.38

- **Perbaikan Validasi Pembaruan Aplikasi (Strict Update Guard)**:
  - **Pencegahan Dialog Update False-Positive**: Memperbaiki `_checkAppUpdateSilently()` pada portal web agar memvalidasi `updateInfo.hasUpdate == true` sebelum memicu `UpdateDialog.show()`. Menghilangkan popup notifikasi pembaruan saat pengguna sudah berada di versi terbaru.
  - **Guard Berlapis pada UpdateDialog**: Menambahkan proteksi guard internal pada `UpdateDialog.show()`, otomatis mengembalikan `null` jika tidak ada rilis baru yang valid (`!updateInfo.hasUpdate`).
  - **Proteksi Notifikasi Sistem Heads-up**: Mencegah penayangan banner notifikasi status bar Android di `NotificationService.showUpdateNotification()` jika `hasUpdate == false`.
  - **Peningkatan Presisi Parser Versi Semver**: Memperbarui algoritma sanitasi `_cleanVersion` di `AppUpdateInfo` untuk menghapus sufiks pre-release/build number (`-release`, `-beta`, `+build`) secara bersih sebelum perbandingan semver.
  - **Uji Otomatis Baru**: Menambahkan unit test widget khusus untuk menjamin `UpdateDialog.show` tidak pernah muncul jika `hasUpdate` bernilai `false` (25/25 uji otomatis lulus).

## Versi 1.0.37

- **Finalisasi Migrasi Arsitektur Feature-First Menyeluruh (`lib/features/`)**:
  - **Fitur Onboarding (`lib/features/onboarding/`)**: Memindahkan `UserAgreementScreen` dan `PermissionGateScreen` ke `features/onboarding/presentation/screens/`.
  - **Fitur Asisten AI (`lib/features/ai_assistant/`)**: Memindahkan `AiAssistantScreen`, `AiParaphraseScreen`, dan `MiniAiOverlayPanel` ke presentation layer `features/ai_assistant/`.
  - **Fitur Autentikasi Biometrik (`lib/features/auth/`)**: Memindahkan modal sheet `BiometricVaultSheet` dan `BiometricQuickPromptSheet` ke `features/auth/presentation/widgets/`.
  - **Fitur Pembaruan Sistem & OTA (`lib/features/updater/`)**: Mengelompokkan `AppUpdateInfo`, `GitHubRelease`, `UpdateCheckerService`, `UpdateDialog`, dan `ReleaseHistoryDialog` ke domain, data, dan presentation layer `features/updater/`.
  - **Kompatibilitas Penuh (Zero Breaking Changes)**: Seluruh berkas lama dipertahankan sebagai berkas *barrel re-export*, memastikan import lama tetap valid dan seluruh 24 unit test lulus dengan 0 peringatan analyzer.

## Versi 1.0.36

- **Optimasi Performa & Modularisasi WebView Screen**:
  - **Dekomposisi Berkas Raksasa (229KB, 5.562 baris)**: Memecah berkas monolitik `portal_webview_screen.dart` menjadi modul-modul independen berarsitektur *feature-first* (`lib/features/portal/`), menurunkan bobot layar utama menjadi <95KB.
  - **Ekstraksi Skrip JavaScript Statis (`PortalJsScripts`)**: Memindahkan ~62KB skrip injeksi JS (optimasi frame rate, interceptor download, deteksi form login, ekstraksi kuis & kuesioner otomatis) menjadi konstanta compile-time statis terisolasi.
  - **Isolasi Rendering Frame Rate Tinggi (60–120 FPS)**:
    - Mengganti pemanggilan `setState` global pada gesture floating action button (FAB) dan divider resize split-screen dengan `ValueNotifier<Offset?>` & `ValueNotifier<double>`. Meniadakan jank dan lag frame drop pada UI root saat digeser.
    - Mengisolasi indikator pemuatan progress bar halaman dengan `ValueNotifier<int>`.
    - Membungkus native `IndexedStack` WebView dengan `RepaintBoundary` untuk memisahkan layer compositing GPU Chromium dari elemen Flutter di atasnya.
  - **Pemisahan Dialog Modal & Widget Overlay**:
    - Dialog Forum Draft, Quiz Solver, Questionnaire Solver, AI Tools Menu Sheet, dan Biometric Quick Menu dipisah ke `presentation/dialogs/`.
    - Widget Bottom Navigation, Biometric Banner, White Screen Recovery, Minimized Pill, dan Pull Refresh Indicator dipisah ke `presentation/widgets/`.
  - **Zero Breaking Changes**: Menjaga kompatibilitas penuh via barrel export di `lib/screens/portal_webview_screen.dart` dengan 0 analyzer error/warning dan 100% kelulusan automated unit test.

## Versi 1.0.35

- **Migrasi Arsitektur Modular Feature-First (`lib/features/`)**:
  - Penataan struktur kode modular per-domain bisnis: `features/ai_assistant`, `features/auth`, dan `features/portal`.
  - Pemindahan modul `AiService`, `AiProvider`, dan model AI (`AiMessage`, `ParaphraseResult`, `AiModelConfig`) ke dalam domain & data layer yang terisolasi rapi.
  - Pemindahan modul `BiometricAuthService` dan `BiometricProvider` ke fitur autentikasi terstruktur.
  - Implementasi *backward compatibility* melalui berkas barrel re-export sehingga tidak menimbulkan regresi pada kode eksisting.
  - Lulus audit statis `flutter analyze` dengan 0 peringatan/isu dan seluruh 24 uji otomatis lolos.

## Versi 1.0.34

- **Pembaruan Stabilitas & Sinkronisasi Git**:
  - Sinkronisasi basis kode lokal dengan remote repository (`origin/main`).
  - Pembersihan ambiguitas refname tag dan pembaruan dependensi.
  - Penyiapan rilis OTA otomatis (Over-The-Air) melalui pipeline CI/CD GitHub Actions.

## Versi 1.0.33

- **Pembaruan Konfigurasi Engine AI Mutakhir (Per 21 Oktober 2026)**:
  - **Google Gemini 3.8 Flash & 4 Argon**: Peningkatan default model ID ke `gemini-3.8-flash` dengan Vision OCR canggih untuk lembar soal kuis, jendela konteks 1 Juta token, serta fallback ke `gemini-4-argon` dan seri 3.x.
  - **OpenAI GPT-5 & GPT-4o**: Integrasi model flagship OpenAI terbaru (`gpt-5-mini`, `gpt-5`, `gpt-4o`) dilengkapi fallback otomatis bertingkat dan analisis multimodal vision.
  - **Anthropic Claude 5.5**: Dukungan generasi 5.5 (`claude-sonnet-5-5`, `claude-haiku-5-5`) dengan peningkatan validasi handshake API Key.
  - **DeepSeek V4 & Alibaba Qwen 3.8-Max**: Pembaruan kompatibilitas API Key untuk DeepSeek V4 (`deepseek-v4-flash`, `deepseek-chat`) dan Alibaba Qwen (`qwen3.8-max`).
  - **OpenRouter Multi-Model Hub**: Perutean otomatis ke model global mutakhir dengan basis default `google/gemini-3.8-flash`.

## Versi 1.0.32

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

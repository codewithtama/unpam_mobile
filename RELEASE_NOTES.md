# Catatan Pembaruan Rilis The PAMs

## Versi 1.0.38 (Terbaru)

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

# Catatan Pembaruan Rilis The PAMs

## Versi 1.0.28 (Terbaru)

- **Pembaruan Generasi Model AI Flagship (Oktober 2026)**:
  - **OpenAI**: Menghadirkan dukungan model `GPT-5.5`, `GPT-5.5-mini`, penalaran `o4-mini`, dan `gpt-4.1-mini` lengkap dengan mekanisme otomatis fallback multi-model (`openaiModelsToTry`) untuk menjamin ketersediaan respons saat kuota/traffic tinggi.
  - **DeepSeek**: Integrasi generasi reasoning terbaru `DeepSeek V4 (Flash / Pro)` dan `DeepSeek R2 / Reasoner` dengan kapasitas konteks hingga 1M token untuk penalaran logika, coding, dan matematika akademik.
  - **Google Gemini**: Spesifikasi resmi `Gemini 3.7 Flash` dan `Gemini 3.5 Pro` dengan Vision OCR presisi tinggi untuk membedah screenshot soal kuis dan materi kuliah.
  - **Claude & Qwen**: Dukungan generasi terkini `Claude Sonnet 5.5 / Opus 5.5` serta `Alibaba Qwen 3.8-Max / 3.7-Max` dengan penalaran multibahasa komprehensif.
  - **The PAMs Cloud AI (Gratis)** & **OpenRouter**: Pembaruan label dan deskripsi model all-in-one hub bebas kuota.
- **Banner Pemantau Stabilitas Jaringan & Latensi Real-Time**:
  - `TopNetworkStabilityBanner` yang memantau kualitas koneksi internet secara aktif langsung di atas portal, deteksi offline/latensi tinggi, dan tombol coba lagi (*Retry*) dengan pemulihan otomatis.
- **Optimasi Performa UI Reaktif (`ValueNotifier`)**:
  - Isolasi rendering pada interaksi FAB floating pill, resize split-screen AI, pull-to-refresh, dan progress bar webview tanpa re-render berlebih pada root widget tree portal.
- **Pengunduhan Pembaruan Resumable & Toleran Layar Mati (Screen-Off)**:
  - Transmisi biner HTTP Range Request (HTTP 206 Partial Content), auto-reconnect backoff bergradasi (hingga 10 kali tanpa reset ke 0%), notifikasi progress di status bar Android, serta izin sistem WAKE_LOCK.
- **Pengujian & Kualitas**:
  - Seluruh 24 pengujian otomatis unit & widget tests lulus 100%.
  - Bebas dari error atau peringatan analisis (*0 issues*).

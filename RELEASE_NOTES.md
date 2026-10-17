# Pembaruan UNPAM Mobile v1.0.15

Pembaruan UNPAM Mobile v1.0.15:

- Fitur Baru: Integrasi Portal MyUnpam (`my.unpam.ac.id`) menggunakan Dual-Isolated WebView (`IndexedStack`). Mahasiswa dapat mengakses sistem informasi akademik (SIAKAD, isi KRS, KHS/Nilai, presensi, dan jadwal ujian) tanpa me-reload atau mengganggu sesi pengerjaan kuis/tugas di Mentari.
- Navigasi Baru 3 Menu: Bottom Navigation Bar kini menyediakan akses terpadu ke Mentari (LMS), MyUnpam (SIAKAD), dan UNPAM AI (Asisten Akademik).
- Penanganan Cerdas Cetak Berkas Dokumen: Otomatis mendeteksi unduhan berkas PDF (Cetak KRS, KHS, Transkrip, dan Kartu Ujian) di MyUnpam agar dapat langsung dibuka/diunduh via aplikasi pembaca PDF eksternal tanpa risiko blank screen.
- Pembaruan Spesifikasi Model AI Terkini (Per Oktober 2026):
  * Google Gemini: Mendukung Gemini 3.7 Flash & 3.5 Flash dengan Vision OCR multimodal soal kuis.
  * DeepSeek: Generasi V4 (Flash / Pro) dengan 1M token context window dan penalaran mendalam.
  * Anthropic Claude: Generasi Claude 5.5 (Sonnet 5.5 / Haiku 5.5 / Opus 5.5) dengan verifikasi API key non-token.
  * Alibaba Qwen: Qwen 3.8-Max (Flagship) & Qwen 3.7-Max dengan dual-endpoint failover regional.
  * OpenRouter: Format fleksibel `provider/model` untuk ratusan model terkini.
- Peningkatan Dialog Pembaruan: Menambahkan petunjuk solusi aman untuk instalasi pembaruan over-the-air pada perangkat Android / MIUI / HyperOS.
- Jaminan Zero Overflow & Peningkatan Kestabilan: Pengoptimalan tata letak antarmuka agar selalu bebas dari pesan RenderFlex Overflow.

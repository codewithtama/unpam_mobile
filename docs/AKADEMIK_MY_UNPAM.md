# Fitur Akademik My UNPAM — Catatan Penambahan

Catatan teknis untuk fitur **Akademik** (data My UNPAM native) beserta perbaikan sesi/token, auto-isi login Satu UNPAM, dan The PAMs AI Tools di halaman Akademik.

> Status: `flutter analyze` bersih, 53 test lulus. Alur WebView (SSO, refresh sesi, fetch lewat WebView) **belum diuji di perangkat** — lihat bagian [Pengujian manual](#pengujian-manual).

---

## Ringkasan

| Area | Yang baru |
|---|---|
| Onboarding | Layar **Hubungkan Akun UNPAM** sekali setelah izin aplikasi (bisa dilewati): NIM + password sekali → Mentari login otomatis, Satu UNPAM/My UNPAM terhubung, opsi sidik jari. |
| Navigasi | Tab bottom nav **Akademik** (urutan: Mentari · MyUnpam · Akademik · The PAMs AI) membuka hub grid 6 layanan + status sesi. |
| Halaman | Biodata, Keuangan, Nilai, Jadwal, Presensi, Sertifikat — native, dengan cache offline. |
| Sesi | Token & cookie **Satu UNPAM** dan **My UNPAM** disimpan terpisah; refresh otomatis lewat Satu UNPAM → My UNPAM tanpa OTP selama sesi SSO masih hidup. |
| Request API | Dijalankan dari **WebView tersembunyi** di origin `my.unpam.ac.id` (lolos Cloudflare, memakai token yang sama dengan tab MyUnpam). Dio hanya cadangan. |
| Login SSO | Modal "Verifikasi Satu UNPAM" mengisi NIM + password otomatis (dari login Mentari / biometrik), menekan **Masuk** setelah Cloudflare centang, dan **menutup sendiri** saat sudah masuk My UNPAM. |
| AI | Pill **The PAMs AI Tools** ("Telaah Nilai/Jadwal/…") + **Split-Screen AI** di semua halaman Akademik. |

---

## Alur sesi

Urutan login mengikuti alur resmi kampus:

```
Satu UNPAM (NIM + password) → OTP Telegram → pilih app "My UNPAM" → my.unpam.ac.id/api/loginsso → token My UNPAM
```

### Saat data Akademik diminta

1. `MyUnpamSession.get(path)` → `MyUnpamWebFetcher.get` menjalankan `fetch()` di WebView tersembunyi yang berada di `https://my.unpam.ac.id/`.
   - Token diambil dari `localStorage['access_token']` milik SPA My UNPAM (format `__q_strn|eyJ...`), fallback ke token tersimpan di app.
   - Respons challenge Cloudflare (403 "Just a moment...") → halaman my.unpam dimuat ulang (Chromium menyelesaikan challenge) → request diulang sekali.
2. Jika 401/403/419 → `refreshSession()` (single-flight, request paralel hanya memicu satu refresh) menjalankan `MyUnpamRefresher`:
   1. Buka **Satu UNPAM**. Jika dashboard terbuka (sesi SSO hidup) → auto-klik kartu **My UNPAM** + "Lanjutkan" → token baru ditangkap → divalidasi ke `/api/biodata/mahasiswa`.
   2. Jika Satu UNPAM minta login → coba buka **My UNPAM** langsung sekali.
   3. Jika keduanya minta login → token & cookie kedua sesi dihapus → `SessionExpiredException` → UI menampilkan **Hubungkan Akun** (login + OTP).
3. Refresh tersembunyi **tidak pernah** mengisi login Satu UNPAM otomatis, karena setiap login memicu OTP Telegram.

### Sumber token

- Modal `SsoAuthModal` (login manual).
- Tab **MyUnpam** (WebView upstream): sniffer token di-inject di setiap halaman My UNPAM, sehingga membuka tab ini ikut menyegarkan sesi Akademik.
- WebView fetcher & refresher tersembunyi.

Token Mentari **tidak** pernah disimpan sebagai token My UNPAM (bug lama yang menyebabkan 403 sudah dihapus).

---

## Temuan teknis penting

- **Format token My UNPAM** (dari bundle `my.unpam.ac.id/js/app.*.js`): SPA Vue/Quasar menyimpan JWT via `LocalStorage.set("access_token", ...)` → nilai mentah `__q_strn|eyJ...`. Axios memakai `Authorization: Bearer <token>`; saat 401 SPA `logout` + `localStorage.clear()` + reload.
- **`/api/semester` publik** (200 tanpa token) → tidak bisa dipakai untuk memvalidasi token. Validasi memakai `/api/biodata/mahasiswa`.
- **Endpoint data dijaga Cloudflare**: `/api/biodata/mahasiswa`, `/api/rangkuman-nilai`, `/api/keuangan` menjawab 403 "Just a moment..." untuk klien non-browser. Inilah akar "kemarin bisa, besoknya 403": `cf_clearance` kedaluwarsa / IP berganti. Solusinya request dari dalam WebView (pola yang sama dengan `WebViewDownloadBridge`).
- **User-Agent Dio** dikembalikan ke `PostmanRuntime/7.43.0` (yang dulu berjalan); UA Chrome palsu dengan TLS non-Chrome cenderung dicurigai Cloudflare.
- **Remote punya tag bernama `main`**: `git pull origin main` bisa mengambil tag, bukan branch. Gunakan `git pull origin refs/heads/main`.

---

## Onboarding "Hubungkan Akun UNPAM"

Alur gate: `Persetujuan → Izin → Onboarding (sekali) → Portal`. Login **tidak wajib** — app tetap bisa dipakai saat server UNPAM / OTP Telegram bermasalah.

1. **Akun** — form NIM + password + checkbox "Aktifkan login sidik jari" (jika perangkat mendukung). Kredensial disimpan di memori (`rememberCredentials`); jika sidik jari dicentang, disimpan terenkripsi lewat `BiometricProvider.saveCredentials` dan auto-login diaktifkan.
2. **Hubungkan My UNPAM** — membuka `SsoAuthModal` (isi otomatis + Masuk otomatis, user memasukkan OTP). Bisa **Lewati**.
3. **Selesai** — ringkasan status Mentari, My UNPAM, dan sidik jari.

- "Nanti saja" / selesai → flag `unpam_account_onboarding_done`.
- User lama yang sudah punya token My UNPAM atau kredensial biometrik otomatis dianggap selesai (`AccountOnboardingScreen.shouldShow`).
- Mentari memakai kredensial onboarding untuk auto-login (sekali per sesi, tanpa prompt sidik jari); tanpa itu tetap memakai alur biometrik lama.
- Bisa dibuka ulang dari menu titik-tiga portal → **Hubungkan Akun UNPAM**.

---

## Auto-isi login Satu UNPAM

Prioritas sumber kredensial di `SsoAuthModal`:

1. Kredensial login **Mentari** di sesi app saat ini (`MyUnpamSession.rememberCredentials`, **hanya di memori**, hilang saat app ditutup / `signOut`).
2. **Biometrik** tersimpan → prompt sidik jari (`BiometricProvider.getCredentialsForLogin`).
3. Fallback: hanya NIM (`savedNim`), tanpa submit.

Script `MyUnpamScripts.fillLogin` mengisi field (setter kompatibel React/Vue), menunggu `cf-turnstile-response` terisi, lalu menekan **Masuk** **sekali** (`window.__satuAutoSubmitted`) agar tidak berulang jika password salah.

Modal menutup otomatis begitu token My UNPAM yang belum kedaluwarsa (cek klaim `exp` JWT) tertangkap saat WebView sudah di `my.unpam.ac.id`, dengan fallback 6 detik.

---

## The PAMs AI Tools di Akademik

- Memakai ulang widget upstream `InPageQuickActionPill` dan `MiniAiOverlayPanel` dengan konteks `WebPageContextType.academicScheduleOrGrades` → pill berlabel **"Telaah \<halaman\>"**.
- **Telaah**: membuka Split-Screen dan mengirim ringkasan data halaman ke AI.
- **Tools sheet**: Telaah halaman ini · Buka Split-Screen AI · AI Layar Penuh · Parafrase Akademik.
- Split-Screen bisa di-drag resize (28–78%), preset tinggi, minimize, close, layar penuh.
- Data yang dikirim ke AI dibentuk `PortalAiText` dan **hanya berisi data akademik** (IPK, nilai, jadwal, presensi, tagihan, sertifikat). NIK, alamat, dan nomor HP tidak ikut.

---

## Struktur file

### Baru

| File | Fungsi |
|---|---|
| `lib/core/services/my_unpam_session.dart` | Status sesi, `get()` + refresh single-flight, capture token, cek `exp` JWT, kredensial di memori. |
| `lib/core/services/my_unpam_web_fetcher.dart` | `fetch()` API lewat WebView tersembunyi di origin my.unpam. |
| `lib/core/services/my_unpam_refresher.dart` | Refresh sesi tersembunyi (Satu UNPAM → My UNPAM) + `MyUnpamRefreshHost` (host WebView 1×1). |
| `lib/core/constants/my_unpam_scripts.dart` | JS: token sniffer, deteksi halaman login, navigator Satu UNPAM, `fillLogin`. |
| `lib/core/services/academic_portal_service.dart` | Endpoint Biodata, Nilai, Jadwal, Sertifikat, Presensi + cache. |
| `lib/core/services/finance_service.dart` | Endpoint semester & keuangan + cache. |
| `lib/core/services/portal_ai_text.dart` | Ringkasan data halaman untuk prompt AI. |
| `lib/providers/academic_portal_provider.dart` | State per resource (`PortalResource<T>`). |
| `lib/providers/finance_provider.dart` | State keuangan & pilihan semester. |
| `lib/screens/academic_hub_screen.dart` | Hub Akademik (profil, status sesi, grid layanan). |
| `lib/screens/{student_profile,finance,academic_grades,lecture_schedule,attendance,seminar_certificate}_screen.dart` | Halaman layanan. |
| `lib/widgets/portal_state_views.dart` | `PortalPageScaffold`, loading/error/banner sinkron, `reconnectPortal`. |
| `lib/widgets/portal_ai_assist.dart` | Pill AI + Split-Screen untuk halaman native. |
| `lib/widgets/sso_auth_modal.dart` | Modal login Satu UNPAM → My UNPAM. |
| `lib/screens/account_onboarding_screen.dart` | Onboarding "Hubungkan Akun UNPAM" (3 langkah, bisa dilewati). |
| `lib/models/*_model.dart` | Model Biodata, Nilai, Jadwal, Presensi, Sertifikat, Keuangan. |

### Diubah

| File | Perubahan |
|---|---|
| `lib/main.dart` | Inisialisasi `MyUnpamSession`, refresher, web fetcher, provider; host WebView tersembunyi di `MaterialApp.builder`. |
| `lib/screens/portal_webview_screen.dart` | Tab **Akademik**, sniffer token di tab MyUnpam, simpan kredensial login Mentari ke memori, reset sesi ikut membersihkan sesi & cache portal, UA dari konstanta. |
| `lib/core/constants/api_constants.dart` | URL Satu/My UNPAM, `webViewUserAgent`, key storage sesi & cache. |
| `lib/core/services/storage_service.dart` | Simpan/hapus token & cookie kedua sesi, cache JSON, `clearPortalSessions`, `clearPortalCache`, flag onboarding. |
| `lib/widgets/app_gate.dart`, `lib/screens/permission_gate_screen.dart` | Arahkan ke onboarding setelah izin lengkap. |

### Storage (SharedPreferences)

- Sesi: `satuunpam_bearer_token`, `satuunpam_cookies`, `myunpam_bearer_token`, `myunpam_cookies`
- Cache: `myunpam_cached_{keuangan,semester,semesters_list,biodata,grades,schedule,certificates,attendance_courses}`
- Password **tidak** pernah ditulis ke SharedPreferences (biometrik tetap di secure storage seperti sebelumnya).

---

## Pengujian

### Otomatis

```bash
flutter analyze
flutter test
```

- `test/my_unpam_session_test.dart` — 200, 401 → refresh → retry, Cloudflare 403 → wajib login, refresh single-flight, akun belum terhubung, pemisahan token Satu/My UNPAM, cek `exp`, token kedaluwarsa ditolak, kredensial hanya di memori.
- `test/account_onboarding_test.dart` — kapan onboarding tampil/dilewati, validasi form, kredensial hanya di memori, "Nanti saja".
- `test/portal_ai_assist_test.dart` — pill "Telaah Nilai" tampil, Split-Screen ter-dock lewat Tools sheet, ringkasan sertifikat.
- `test/academic_portal_test.dart`, `test/finance_test.dart` — parsing model & storage.

### Pengujian manual

0. Install bersih → Persetujuan → Izin → **Onboarding**: isi NIM + password (+ sidik jari) → Hubungkan My UNPAM (OTP) → Selesai → Mentari login otomatis → Akademik langsung tampil data. Coba juga "Nanti saja".
1. Login Mentari → tab **Akademik** → **Hubungkan** → NIM & password terisi → Cloudflare centang → Masuk otomatis → OTP Telegram → My UNPAM → **modal menutup sendiri**.
2. Tab **MyUnpam** sudah login → buka **Akademik → Nilai/Biodata** → data muncul dalam beberapa detik.
3. Besoknya / setelah ganti jaringan → buka Nilai → data tetap muncul tanpa OTP.
4. Biometrik aktif, app baru dibuka → Hubungkan → sidik jari → terisi & Masuk otomatis.
5. Password salah → Masuk hanya ditekan sekali.
6. **Reset Sesi & Cache** → halaman Akademik meminta login ulang.
7. Nilai → **Telaah Nilai** → Split-Screen terbuka, AI menjawab berdasarkan data nilai.

Log berguna saat debugging: tag `MyUnpamSession`, `MyUnpamFetchChannel`, `SsoAuthModal`.

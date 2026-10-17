# Pembaruan UNPAM Mobile v1.0.20

Pembaruan UNPAM Mobile v1.0.20:

- **Perbaikan Total Unduhan PDF & Cetak Kartu Ujian (UTS/UAS/KRS/KHS)**:
  * Mengatasi kendala layar hitam teks mentah `%PDF-1.4 1 0 obj` saat mencetak dokumen akademik di portal MyUnpam.
  * Injeksi pendeteksi otomatis aliran PDF mentah (*Raw PDF Stream Sniffer*) pada WebView: jika PDF termuat ke layar, aplikasi secara instan mengekstrak biner dokumen via *same-origin fetch*, mengembalikan layar WebView ke portal, dan membuka dokumen di aplikasi penampil PDF bawaan HP (*Google Drive PDF Viewer*, *WPS Office*, dll).
  * Menambahkan intersepsi klik tombol dan form pengiriman (*button/submit interception*) untuk aksi cetak kartu ujian UTS, UAS, KRS, KHS, dan transkrip nilai.
  * Dukungan resolusi URL relatif ke absolut untuk seluruh tautan unduhan dan cetak akademik.

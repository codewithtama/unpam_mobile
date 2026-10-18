# Pembaruan UNPAM Mobile v1.0.21

Pembaruan UNPAM Mobile v1.0.21:

- **Optimalisasi Performa Buttery-Smooth 120 FPS (Enterprise Grade)**:
  * **Unlock Native 120Hz/90Hz Display Refresh Rate**: Mengonfigurasi `preferredDisplayModeId` langsung di tingkat Android Window Manager (`MainActivity.kt`) agar layar secara otomatis beralih ke frekuensi refresh tertinggi hardware (120 FPS / 90 FPS) tanpa dibatasi (throttled) oleh sistem operasi OEM (Xiaomi HyperOS, Samsung OneUI, ColorOS, OxygenOS).
  * **Akselerasi Perangkat Keras Penuh (Full GPU Hardware Acceleration)**: Menambahkan `android:hardwareAccelerated="true"` dan `android:largeHeap="true"` pada Android Manifest guna mencegah lag, stuttering, dan jeda Garbage Collector (GC pause) saat melakukan navigasi serta interaksi web yang kompleks.
  * **Isolasi Gesture Render Tree (Zero-Jank ValueNotifier)**: Mengganti pemanggilan `setState` global pada event pointer sentuhan (`onPointerMove`) dengan `ValueNotifier<double>` dan `AnimatedBuilder` lokal. Kini animasi tarikan *pull-to-refresh* dirender secara mandiri pada 120 FPS tanpa memicu rendering ulang keseluruhan 4.700 baris widget tree dan WebView.
  * **Platform Channel Bridge Throttling**: Membatasi sinkronisasi posisi scroll JavaScript (`ScrollSyncChannel`) agar hanya mengirim sinyal saat status batas atas (`atTop`) berubah nyata, mengeliminasi ribuan panggilan bridge yang sebelumnya membebani CPU saat scrolling cepat.
  * **Injeksi CSS Akselerasi Hardware WebView**: Menyematkan properti `-webkit-overflow-scrolling: touch`, `scroll-behavior: smooth`, dan `overscroll-behavior-y: contain` pada portal Mentari dan MyUnpam demi pengalaman gulir yang responsif, mulus, dan setara aplikasi korporat papan atas.

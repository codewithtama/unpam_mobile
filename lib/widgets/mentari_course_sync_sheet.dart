import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/user_course_model.dart';
import '../models/course_detail_model.dart';
import '../theme/app_theme.dart';

class MentariCourseSyncSheet extends StatefulWidget {
  final CourseItem course;
  final ValueChanged<CourseDetailResponse> onCourseSynced;

  const MentariCourseSyncSheet({
    super.key,
    required this.course,
    required this.onCourseSynced,
  });

  static Future<bool?> show(
    BuildContext context, {
    required CourseItem course,
    required ValueChanged<CourseDetailResponse> onCourseSynced,
  }) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => MentariCourseSyncSheet(
        course: course,
        onCourseSynced: onCourseSynced,
      ),
    );
  }

  @override
  State<MentariCourseSyncSheet> createState() => _MentariCourseSyncSheetState();
}

class _MentariCourseSyncSheetState extends State<MentariCourseSyncSheet> {
  late final WebViewController _controller;
  String _status = 'Menghubungkan ke sesi aktif Mentari UNPAM...';
  bool _isLoading = true;
  bool _showWebPreview = false;
  bool _hasSynced = false;

  @override
  void initState() {
    super.initState();
    _initWebView();
  }

  void _initWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..addJavaScriptChannel(
        'CourseDetailChannel',
        onMessageReceived: _onChannelMessage,
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageStarted: (_) {
            if (mounted) setState(() => _isLoading = true);
            _injectScripts();
          },
          onPageFinished: (url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
                _status = 'Menjalankan sinkronisasi data kelas...';
              });
            }
            _injectScripts();
            _executeCrawler();
          },
        ),
      )
      ..loadRequest(Uri.parse('https://mentari.unpam.ac.id/'));
  }

  void _injectScripts() {
    // Interceptor untuk menangkap respons fetch atau XHR otomatis
    const script = '''
(function() {
  if (window._unpamDetailHooked) return;
  window._unpamDetailHooked = true;

  function notify(data) {
    try {
      if (window.CourseDetailChannel) {
        window.CourseDetailChannel.postMessage(JSON.stringify(data));
      }
    } catch(e) {}
  }

  // Intercept XHR
  var origOpen = XMLHttpRequest.prototype.open;
  var origSend = XMLHttpRequest.prototype.send;
  XMLHttpRequest.prototype.open = function(method, url) {
    this._url = url;
    return origOpen.apply(this, arguments);
  };
  XMLHttpRequest.prototype.send = function() {
    var self = this;
    this.addEventListener('load', function() {
      try {
        if (self._url && (String(self._url).indexOf('course') !== -1 || String(self._url).indexOf('pertemuan') !== -1)) {
          var j = JSON.parse(self.responseText);
          if (j && (j.data || j.peserta || j.kode_course)) {
            notify({ type: 'course_detail', data: j });
          }
        }
      } catch(e) {}
    });
    return origSend.apply(this, arguments);
  };

  // Intercept Fetch
  var origFetch = window.fetch;
  window.fetch = function(input, init) {
    var url = typeof input === 'string' ? input : (input && input.url ? input.url : '');
    return origFetch.apply(this, arguments).then(function(res) {
      try {
        if (String(url).indexOf('course') !== -1 || String(url).indexOf('pertemuan') !== -1) {
          var clone = res.clone();
          clone.json().then(function(j) {
            if (j && (j.data || j.peserta || j.kode_course)) {
              notify({ type: 'course_detail', data: j });
            }
          }).catch(function() {});
        }
      } catch(e) {}
      return res;
    });
  };
})();
''';
    _controller.runJavaScript(script);
  }

  void _executeCrawler() {
    final kode = widget.course.kodeCourse;
    final id = widget.course.id;

    final crawler = '''
(async function() {
  function log(msg) {
    try {
      CourseDetailChannel.postMessage(JSON.stringify({ type: 'status', message: msg }));
    } catch(e) {}
  }
  function sendDetail(detail) {
    try {
      CourseDetailChannel.postMessage(JSON.stringify({ type: 'course_detail', data: detail }));
    } catch(e) {}
  }

  var kode = '$kode';
  var courseId = '$id';

  // Cari Token
  var token = window._activeBearerToken || null;
  if (!token) {
    [window.localStorage, window.sessionStorage].forEach(function(st) {
      if (!st) return;
      for (var i = 0; i < st.length; i++) {
        var val = st.getItem(st.key(i));
        if (!val) continue;
        try {
          var parsed = JSON.parse(val);
          if (parsed && typeof parsed === 'object') {
            ['access_token', 'token', 'accessToken', 'bearer'].forEach(function(k) {
              if (parsed[k] && typeof parsed[k] === 'string' && parsed[k].length > 20) {
                token = parsed[k].replace(/^Bearer\\s+/i, '').trim();
              }
            });
          }
        } catch(e) {}
        var m = String(val).match(/eyJ[\\w-]+\\.[\\w-]+\\.[\\w-]+/);
        if (m && !token) token = m[0];
      }
    });
  }

  var headers = { 'Accept': 'application/json' };
  if (token) {
    headers['Authorization'] = 'Bearer ' + token;
  }

  log('Mengekstrak data mata kuliah: ' + kode + '...');

  // 1. Coba /api/course/:kode di Mentari
  try {
    var r1 = await fetch('/api/course/' + encodeURIComponent(kode), {
      headers: headers,
      credentials: 'include'
    });
    if (r1.ok) {
      var j1 = await r1.json();
      if (j1 && (j1.data || j1.kode_course || j1.peserta)) {
        log('Berhasil mendapatkan struktur kelas!');
        sendDetail(j1);
        return;
      }
    }
  } catch(e) {}

  // 2. Coba https://sakura.unpam.ac.id/api/course/:kode
  try {
    var r2 = await fetch('https://sakura.unpam.ac.id/api/course/' + encodeURIComponent(kode), {
      headers: headers,
      credentials: 'include'
    });
    if (r2.ok) {
      var j2 = await r2.json();
      if (j2 && (j2.data || j2.kode_course || j2.peserta)) {
        log('Berhasil mendapatkan modul kurikulum!');
        sendDetail(j2);
        return;
      }
    }
  } catch(e) {}

  // 3. Coba menggunakan ID UUID
  if (courseId && courseId.length > 5) {
    try {
      var r3 = await fetch('/api/course/' + encodeURIComponent(courseId), {
        headers: headers,
        credentials: 'include'
      });
      if (r3.ok) {
        var j3 = await r3.json();
        if (j3 && (j3.data || j3.kode_course)) {
          sendDetail(j3);
          return;
        }
      }
    } catch(e) {}
  }

  log('Sesi sedang memeriksa halaman kelas...');
})();
''';
    _controller.runJavaScript(crawler);
  }

  void _onChannelMessage(JavaScriptMessage msg) {
    if (_hasSynced) return;

    try {
      final decoded = jsonDecode(msg.message);
      if (decoded is! Map<String, dynamic>) return;

      final type = decoded['type']?.toString();

      if (type == 'status') {
        final message = decoded['message']?.toString();
        if (message != null && mounted) {
          setState(() => _status = message);
        }
      } else if (type == 'course_detail') {
        final raw = decoded['data'];
        if (raw is Map<String, dynamic>) {
          // Validasi bahwa data memiliki data pertemuan atau peserta
          if (raw['data'] != null || raw['peserta'] != null || raw['kode_course'] != null) {
            _hasSynced = true;
            final courseDetail = CourseDetailResponse.fromJson(raw);
            widget.onCourseSynced(courseDetail);

            if (mounted) {
              setState(() => _status = 'Sinkronisasi berhasil!');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text('Berhasil menyinkronkan 21 pertemuan ${widget.course.namaMataKuliah}!'),
                  backgroundColor: AppTheme.successGreen,
                  duration: const Duration(seconds: 3),
                ),
              );
              Navigator.of(context).pop(true);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing sync channel message: $e');
    }
  }

  void _forceManualFetch() {
    setState(() => _status = 'Mengirim ulang permintaan sinkronisasi...');
    _executeCrawler();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * (_showWebPreview ? 0.85 : 0.42),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      child: Column(
        children: [
          // Drag Handle
          Center(
            child: Container(
              margin: const EdgeInsets.only(top: 12, bottom: 8),
              width: 44,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),

          // Header
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(Icons.sync_rounded, color: AppTheme.primaryLight, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Sinkronisasi Sesi Mentari',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.textDark,
                        ),
                      ),
                      Text(
                        widget.course.namaMataKuliah,
                        style: const TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close_rounded, color: AppTheme.textMuted),
                  onPressed: () => Navigator.of(context).pop(false),
                ),
              ],
            ),
          ),
          const Divider(height: 1, color: AppTheme.cardBorder),

          // Body Content
          Expanded(
            child: Stack(
              children: [
                // Hidden / Visible Webview
                Opacity(
                  opacity: _showWebPreview ? 1.0 : 0.01,
                  child: WebViewWidget(controller: _controller),
                ),

                // Overlay Status UI jika tidak sedang menampilkan web preview
                if (!_showWebPreview)
                  Padding(
                    padding: const EdgeInsets.all(24.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        if (_isLoading)
                          const CircularProgressIndicator(color: AppTheme.primaryLight)
                        else
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: AppTheme.primaryLight.withOpacity(0.1),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.vpn_key_rounded, size: 36, color: AppTheme.primaryLight),
                          ),
                        const SizedBox(height: 16),
                        Text(
                          _status,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: AppTheme.textDark,
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Mengambil data langsung lewat Chromium session untuk melewati proteksi Cloudflare.',
                          textAlign: TextAlign.center,
                          style: TextStyle(fontSize: 12, color: AppTheme.textMuted),
                        ),
                        const SizedBox(height: 20),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            OutlinedButton.icon(
                              onPressed: _forceManualFetch,
                              icon: const Icon(Icons.refresh_rounded, size: 16),
                              label: const Text('Tarik Ulang Data'),
                            ),
                            const SizedBox(width: 10),
                            TextButton.icon(
                              onPressed: () => setState(() => _showWebPreview = true),
                              icon: const Icon(Icons.visibility_rounded, size: 16),
                              label: const Text('Buka Web View'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

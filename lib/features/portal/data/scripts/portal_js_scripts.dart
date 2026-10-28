import 'dart:convert';

/// Kumpulan skrip JavaScript yang diinjeksikan ke dalam WebView Mentari & MyUnpam.
/// Disimpan sebagai konstanta kompilasi statis untuk menghemat alokasi memori Dart VM
/// dan menghindari overhead interpolasi string berulang pada thread UI.
class PortalJsScripts {
  PortalJsScripts._();

  // ──────────────────────────────────────────────────────────────────────────
  // Jadwal Kuliah & Deadline Scraper
  // ──────────────────────────────────────────────────────────────────────────

  /// Skrip ekstraksi jadwal kuliah dari MyUnpam.
  ///
  /// Menggunakan 3 mekanisme:
  /// 1. Proactive Fetch ke REST API `/api/jadwal-kuliah` menggunakan sesi aktif.
  /// 2. Sniffer/Hook pada XHR & Fetch untuk menangkap data respons SPA MyUnpam.
  /// 3. Fallback DOM table scraper dengan dukungan format jam titik & titik dua.
  static const String scheduleExtractor = r'''
    (function() {
      // ─── 1. Hook Network Requests (XHR & Fetch) ──────────────────────
      if (!window.__pamsScheduleHookInstalled) {
        window.__pamsScheduleHookInstalled = true;

        // Hook Fetch
        var origFetch = window.fetch;
        if (origFetch) {
          window.fetch = function() {
            var args = arguments;
            return origFetch.apply(this, args).then(function(response) {
              try {
                var url = (args[0] && (typeof args[0] === 'string' ? args[0] : args[0].url)) || '';
                if (url.indexOf('jadwal-kuliah') !== -1) {
                  response.clone().text().then(function(text) {
                    if (text && window.ScheduleChannel) {
                      window.ScheduleChannel.postMessage(text);
                    }
                  }).catch(function() {});
                }
              } catch(e) {}
              return response;
            });
          };
        }

        // Hook XMLHttpRequest
        var origOpen = XMLHttpRequest.prototype.open;
        var origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function(method, url) {
          this.__pamsUrl = url;
          return origOpen.apply(this, arguments);
        };
        XMLHttpRequest.prototype.send = function() {
          var xhr = this;
          xhr.addEventListener('load', function() {
            try {
              if (xhr.__pamsUrl && xhr.__pamsUrl.indexOf('jadwal-kuliah') !== -1) {
                if (xhr.responseText && window.ScheduleChannel) {
                  window.ScheduleChannel.postMessage(xhr.responseText);
                }
              }
            } catch(e) {}
          });
          return origSend.apply(this, arguments);
        };
      }

      // ─── 2. Proactive Fetch ke API /api/jadwal-kuliah ────────────────
      try {
        var token = null;
        for (var k in localStorage) {
          if (k.toLowerCase().indexOf('token') !== -1) {
            try {
              var val = localStorage.getItem(k);
              if (val && val.indexOf('{') !== -1) {
                var obj = JSON.parse(val);
                token = obj.token || obj.access_token || obj.accessToken || token;
              } else if (val && val.length > 20) {
                token = val;
              }
            } catch(e) {}
          }
        }
        if (!token && window.axios && window.axios.defaults && window.axios.defaults.headers && window.axios.defaults.headers.common) {
          token = window.axios.defaults.headers.common['Authorization'];
        }

        var headers = {
          'Accept': 'application/json, text/plain, */*'
        };
        if (token) {
          headers['Authorization'] = token.startsWith('Bearer ') ? token : ('Bearer ' + token);
        }

        fetch('/api/jadwal-kuliah', {
          method: 'GET',
          headers: headers,
          credentials: 'include'
        }).then(function(r) {
          if (r.ok) return r.text();
          return null;
        }).then(function(text) {
          if (text && window.ScheduleChannel) {
            window.ScheduleChannel.postMessage(text);
          }
        }).catch(function() {});
      } catch(e) {}

      // ─── 3. Fallback: Parse HTML Table DOM ──────────────────────────
      var results = [];
      var dayMap = {
        'senin': 1, 'monday': 1,
        'selasa': 2, 'tuesday': 2,
        'rabu': 3, 'wednesday': 3,
        'kamis': 4, 'thursday': 4,
        "jum'at": 5, 'jumat': 5, 'friday': 5,
        'sabtu': 6, 'saturday': 6,
        'minggu': 7, 'sunday': 7
      };

      function dayIndex(dayStr) {
        var lower = (dayStr || '').toLowerCase().trim();
        return dayMap[lower] || 0;
      }

      var tables = document.querySelectorAll('table');
      for (var t = 0; t < tables.length; t++) {
        var rows = tables[t].querySelectorAll('tr');
        if (rows.length < 2) continue;

        var headers = [];
        var headerRow = rows[0];
        var headerCells = headerRow.querySelectorAll('th, td');
        for (var h = 0; h < headerCells.length; h++) {
          headers.push((headerCells[h].innerText || '').toLowerCase().trim());
        }

        var hasHari = headers.some(function(h) { return h.indexOf('hari') !== -1; });
        var hasJam  = headers.some(function(h) { return h.indexOf('jam') !== -1 || h.indexOf('waktu') !== -1; });
        var hasMk   = headers.some(function(h) {
          return h.indexOf('mata kuliah') !== -1 || h.indexOf('matakuliah') !== -1 || h.indexOf('mk') !== -1 || h.indexOf('nama') !== -1;
        });

        if (!hasHari && !hasJam && !hasMk) continue;

        var colHari = -1, colJam = -1, colJamMulai = -1, colJamSelesai = -1;
        var colKode = -1, colNama = -1, colRuang = -1, colDosen = -1, colKelas = -1;

        for (var i = 0; i < headers.length; i++) {
          var h = headers[i];
          if (colHari < 0 && h.indexOf('hari') !== -1) colHari = i;
          if (colJam < 0 && (h === 'jam' || h === 'waktu' || h.indexOf('jam') !== -1 || h.indexOf('waktu') !== -1)) colJam = i;
          if (colJamMulai < 0 && (h.indexOf('mulai') !== -1 || h.indexOf('start') !== -1)) colJamMulai = i;
          if (colJamSelesai < 0 && (h.indexOf('selesai') !== -1 || h.indexOf('end') !== -1 || h.indexOf('akhir') !== -1)) colJamSelesai = i;
          if (colKode < 0 && (h.indexOf('kode') !== -1 || h === 'mk')) colKode = i;
          if (colNama < 0 && (h.indexOf('mata kuliah') !== -1 || h.indexOf('matakuliah') !== -1 || (h.indexOf('nama') !== -1 && h.indexOf('dosen') === -1))) colNama = i;
          if (colRuang < 0 && (h.indexOf('ruang') !== -1 || h.indexOf('room') !== -1 || h.indexOf('kelas') !== -1 && h.indexOf('nama kelas') === -1)) colRuang = i;
          if (colDosen < 0 && (h.indexOf('dosen') !== -1 || h.indexOf('pengajar') !== -1)) colDosen = i;
          if (colKelas < 0 && (h.indexOf('kelas') !== -1 || h.indexOf('kls') !== -1)) colKelas = i;
        }

        if (colNama < 0 && colKode < 0) continue;

        for (var r = 1; r < rows.length; r++) {
          var cells = rows[r].querySelectorAll('td');
          if (cells.length === 0) continue;

          function cellText(idx) {
            if (idx < 0 || idx >= cells.length) return '';
            return (cells[idx].innerText || '').trim();
          }

          var nama = cellText(colNama);
          var kode = cellText(colKode);
          if (!nama && !kode) continue;

          var hari = cellText(colHari);
          var rawJam = cellText(colJam);
          var jamMulai = colJamMulai >= 0 ? cellText(colJamMulai) : '';
          var jamSelesai = colJamSelesai >= 0 ? cellText(colJamSelesai) : '';

          // Dukung format HH:MM dan format Unpam HH.MM (contoh: 07.40 - 09.20)
          if (rawJam && !jamMulai) {
            var jamMatch = rawJam.match(/(\d{1,2}[:.]\d{2})\s*[-–—]\s*(\d{1,2}[:.]\d{2})/);
            if (jamMatch) {
              jamMulai = jamMatch[1].replace('.', ':');
              jamSelesai = jamMatch[2].replace('.', ':');
            } else {
              var jamParts = rawJam.split(/\s+s\.d\.?\s+|\s+-\s+/i);
              if (jamParts.length >= 2) {
                jamMulai = jamParts[0].trim().replace('.', ':');
                jamSelesai = jamParts[1].trim().replace('.', ':');
              } else {
                jamMulai = rawJam.replace('.', ':');
              }
            }
          }

          var ruang = cellText(colRuang);
          var dosen = cellText(colDosen);
          var kelas = cellText(colKelas);

          results.push({
            kode: kode,
            namaMataKuliah: nama || kode,
            hari: hari,
            jamMulai: jamMulai,
            jamSelesai: jamSelesai,
            ruang: ruang,
            dosen: dosen,
            kelas: kelas,
            hariIndex: dayIndex(hari)
          });
        }

        if (results.length > 0) break;
      }

      if (results.length > 0 && window.ScheduleChannel) {
        window.ScheduleChannel.postMessage(JSON.stringify(results));
      }

      return JSON.stringify(results);
    })();
  ''';

  /// Skrip ekstraksi deadline/tugas dari Mentari LMS.
  ///
  /// Mendeteksi tugas, kuis, ujian, dan forum diskusi baik dari dashboard
  /// timeline, kalender Moodle, maupun halaman kursus `/u-courses/*`.
  /// Dilengkapi Network Hook, SPA Navigation Observer, dan parser tanggal lokal Indonesia.
  static const String deadlineExtractor = r'''
    (function() {
      // ─── 1. Hook Network Requests (XHR & Fetch) untuk Mentari ─────────
      if (!window.__pamsMentariHookInstalled) {
        window.__pamsMentariHookInstalled = true;

        var origFetch = window.fetch;
        if (origFetch) {
          window.fetch = function() {
            var args = arguments;
            return origFetch.apply(this, args).then(function(response) {
              try {
                var url = (args[0] && (typeof args[0] === 'string' ? args[0] : args[0].url)) || '';
                var low = url.toLowerCase();
                if (low.indexOf('calendar') !== -1 || low.indexOf('timeline') !== -1 ||
                    low.indexOf('event') !== -1 || low.indexOf('action_events') !== -1 ||
                    low.indexOf('deadline') !== -1 || low.indexOf('service.php') !== -1) {
                  response.clone().text().then(function(text) {
                    if (text && text.length > 10 && window.DeadlineChannel) {
                      window.DeadlineChannel.postMessage(text);
                    }
                  }).catch(function() {});
                }
              } catch(e) {}
              return response;
            });
          };
        }

        var origOpen = XMLHttpRequest.prototype.open;
        var origSend = XMLHttpRequest.prototype.send;
        XMLHttpRequest.prototype.open = function(method, url) {
          this.__pamsMentariUrl = url;
          return origOpen.apply(this, arguments);
        };
        XMLHttpRequest.prototype.send = function() {
          var xhr = this;
          xhr.addEventListener('load', function() {
            try {
              var u = (xhr.__pamsMentariUrl || '').toLowerCase();
              if (u.indexOf('calendar') !== -1 || u.indexOf('timeline') !== -1 ||
                  u.indexOf('event') !== -1 || u.indexOf('action_events') !== -1 ||
                  u.indexOf('deadline') !== -1 || u.indexOf('service.php') !== -1) {
                if (xhr.responseText && xhr.responseText.length > 10 && window.DeadlineChannel) {
                  window.DeadlineChannel.postMessage(xhr.responseText);
                }
              }
            } catch(e) {}
          });
          return origSend.apply(this, arguments);
        };

        // Pasang listener navigasi SPA Mentari
        var triggerScan = function() {
          setTimeout(function() {
            try {
              var res = scanDomDeadlines();
              if (res && res.length > 0 && window.DeadlineChannel) {
                window.DeadlineChannel.postMessage(JSON.stringify(res));
              }
            } catch(e) {}
          }, 800);
        };

        window.addEventListener('popstate', triggerScan);
        var origPush = history.pushState;
        if (origPush) {
          history.pushState = function() {
            origPush.apply(this, arguments);
            triggerScan();
          };
        }
        var origReplace = history.replaceState;
        if (origReplace) {
          history.replaceState = function() {
            origReplace.apply(this, arguments);
            triggerScan();
          };
        }
      }

      // ─── 2. Parsing Tanggal Multiformat Indonesia & Relatif ────────────
      var months = {
        'jan': 1, 'feb': 2, 'mar': 3, 'apr': 4,
        'mei': 5, 'may': 5, 'jun': 6, 'jul': 7,
        'agu': 8, 'aug': 8, 'sep': 9, 'okt': 10,
        'oct': 10, 'nov': 11, 'des': 12, 'dec': 12
      };

      function parseDate(str) {
        if (!str) return null;
        var s = str.trim().toLowerCase();
        var now = new Date();

        // Ambil jam HH:MM atau HH.MM
        var timeMatch = s.match(/(\\d{1,2})[:.](\\d{2})/);
        var hr = timeMatch ? parseInt(timeMatch[1]) : 23;
        var mn = timeMatch ? parseInt(timeMatch[2]) : 59;

        // 1. Relatif: Hari ini, Besok, Lusa
        if (s.indexOf('hari ini') !== -1) {
          return new Date(now.getFullYear(), now.getMonth(), now.getDate(), hr, mn).toISOString();
        }
        if (s.indexOf('besok') !== -1) {
          var dTom = new Date(now.getTime() + 86400000);
          return new Date(dTom.getFullYear(), dTom.getMonth(), dTom.getDate(), hr, mn).toISOString();
        }
        if (s.indexOf('lusa') !== -1) {
          var dLusa = new Date(now.getTime() + 172800000);
          return new Date(dLusa.getFullYear(), dLusa.getMonth(), dLusa.getDate(), hr, mn).toISOString();
        }

        // 2. ISO 8601 standar
        if (/^\\d{4}-\\d{2}-\\d{2}/.test(s)) {
          var dIso = new Date(s);
          if (!isNaN(dIso.getTime())) return dIso.toISOString();
        }

        // 3. Format teks dengan/tanpa tahun: "30 Oktober 2026, 23:59", "30 Okt, 23:59", "Jumat, 30 Okt 23.59"
        var mText = s.match(/(?:[a-zA-Z]+,\\s*)?(\\d{1,2})\\s+([a-zA-Z]{3,10})(?:\\s+(\\d{4}))?(?:[,\\s]+(\\d{1,2})[:.](\\d{2}))?/);
        if (mText) {
          var day = parseInt(mText[1]);
          var mKey = (mText[2] || '').substring(0, 3);
          if (months[mKey]) {
            var month = months[mKey] - 1;
            var year = mText[3] ? parseInt(mText[3]) : now.getFullYear();
            if (!mText[3] && month < now.getMonth() - 2) year += 1;
            var hVal = mText[4] ? parseInt(mText[4]) : hr;
            var mVal = mText[5] ? parseInt(mText[5]) : mn;
            var dt = new Date(year, month, day, hVal, mVal);
            if (!isNaN(dt.getTime())) return dt.toISOString();
          }
        }

        // 4. Format angka: "30/10/2026 23:59", "30-10-2026 23.59", "30/10 23:59"
        var mNum = s.match(/(\\d{1,2})[\\/\\-](\\d{1,2})(?:[\\/\\-](\\d{4}))?(?:[,\\s]+(\\d{1,2})[:.](\\d{2}))?/);
        if (mNum) {
          var dayN = parseInt(mNum[1]);
          var monthN = parseInt(mNum[2]) - 1;
          var yearN = mNum[3] ? parseInt(mNum[3]) : now.getFullYear();
          if (!mNum[3] && monthN < now.getMonth() - 2) yearN += 1;
          var hNum = mNum[4] ? parseInt(mNum[4]) : hr;
          var mNumVal = mNum[5] ? parseInt(mNum[5]) : mn;
          var dtNum = new Date(yearN, monthN, dayN, hNum, mNumVal);
          if (!isNaN(dtNum.getTime())) return dtNum.toISOString();
        }

        var fallback = new Date(s);
        if (!isNaN(fallback.getTime())) return fallback.toISOString();
        return null;
      }

      function guessType(text) {
        var lower = (text || '').toLowerCase();
        if (lower.indexOf('quiz') !== -1 || lower.indexOf('kuis') !== -1) return 'kuis';
        if (lower.indexOf('ujian') !== -1 || lower.indexOf('exam') !== -1 || lower.indexOf('uts') !== -1 || lower.indexOf('uas') !== -1) return 'ujian';
        if (lower.indexOf('presensi') !== -1 || lower.indexOf('absen') !== -1 || lower.indexOf('kehadiran') !== -1) return 'presensi';
        if (lower.indexOf('tugas') !== -1 || lower.indexOf('assignment') !== -1 || lower.indexOf('upload') !== -1 || lower.indexOf('latihan') !== -1 || lower.indexOf('penugasan') !== -1) return 'tugas';
        return 'lainnya';
      }

      // ─── 3. DOM Extractor Universal Mentari ──────────────────────────
      function scanDomDeadlines() {
        var results = [];
        var seen = {};

        function addDeadline(id, namaTugas, namaMataKuliah, dueDateStr, tipe, url) {
          if (!dueDateStr) return;
          var key = (namaTugas + '|' + dueDateStr).toLowerCase();
          if (seen[key]) return;
          seen[key] = true;
          results.push({
            id: id || key,
            namaTugas: namaTugas,
            namaMataKuliah: namaMataKuliah || 'Mata Kuliah',
            dueDate: dueDateStr,
            tipe: tipe,
            url: url || ''
          });
        }

        // Ambil nama kursus aktif di halaman jika berada di /u-courses/*
        var activeCourse = '';
        var headEl = document.querySelector('h1, h2, .page-header-headings h1, .breadcrumb .active, [data-course-title]');
        if (headEl) activeCourse = headEl.innerText.trim();
        if (!activeCourse) {
          var titleMatch = document.title.match(/^([^|•-]+)/);
          if (titleMatch) activeCourse = titleMatch[1].trim();
        }

        // Pola A: Moodle Timeline, Upcoming Events Widget & Dashboard Cards
        var eventItems = document.querySelectorAll(
          '.event a[href*="/calendar/"], [data-region="event-item"], [data-region="event-list-item"], .timeline-event-list-item, .calendar_event_user, .calendar_event_course, .block-myoverview .card, .timeline-event'
        );
        eventItems.forEach(function(item) {
          var titleEl = item.querySelector('[data-region="event-name"], .card-title, .event-name, a') || item;
          var courseEl = item.querySelector('[data-region="event-course-name"], [data-region="course-name"], .course-name, .card-text');
          var dateEl = item.querySelector('time, [datetime], [data-region="event-date"], .date, .card-footer, .text-muted');

          var title = (titleEl && titleEl.innerText ? titleEl.innerText : '').trim();
          if (!title) return;

          var rawDate = (dateEl && dateEl.getAttribute('datetime')) || (dateEl && dateEl.innerText) || '';
          if (!rawDate) {
            var fullTxt = item.innerText || '';
            var dMatch = fullTxt.match(/(?:deadline|tenggat|due|batas|jatuh tempo|ditutup|tutup|sampai|s\\.d\\.)?:?\\s*([^\\n\\r]+)/i);
            if (dMatch) rawDate = dMatch[1];
          }

          var dueIso = parseDate(rawDate);
          if (!dueIso) {
            var txtMatch = (item.innerText || '').match(/(?:\\d{1,2}\\s+[a-zA-Z]{3,10}(?:\\s+\\d{4})?|\\d{1,2}[\\/\\-]\\d{1,2}|hari ini|besok|lusa)[,\\s]+(?:\\d{1,2}[:.]\\d{2})?/i);
            if (txtMatch) dueIso = parseDate(txtMatch[0]);
          }
          if (!dueIso) return;

          var courseName = (courseEl ? courseEl.innerText.trim() : '') || activeCourse;
          var link = item.querySelector('a[href]');
          var href = link ? link.href : window.location.href;

          addDeadline(href, title, courseName, dueIso, guessType(title), href);
        });

        // Pola B: Mentari Course Activities (Tugas/Kuis di setiap Pertemuan /u-courses/*)
        var activityNodes = document.querySelectorAll(
          '.activity, .activity-item, .modtype_assign, .modtype_quiz, .section-item, .list-group-item, .card, [data-region="activity-card"]'
        );
        activityNodes.forEach(function(node) {
          var nodeText = (node.innerText || '');
          var lowText = nodeText.toLowerCase();

          var isActivity = lowText.indexOf('tugas') !== -1 ||
                           lowText.indexOf('kuis') !== -1 ||
                           lowText.indexOf('quiz') !== -1 ||
                           lowText.indexOf('penugasan') !== -1 ||
                           lowText.indexOf('assignment') !== -1 ||
                           lowText.indexOf('ujian') !== -1 ||
                           lowText.indexOf('uts') !== -1 ||
                           lowText.indexOf('uas') !== -1;
          if (!isActivity) return;

          // Cari tanggal tenggat dalam teks kartu
          var dateMatch = nodeText.match(/(?:deadline|tenggat|batas|due|jatuh tempo|ditutup|tutup|waktu|terakhir|sampai|s\\.d\\.)[:\\s]+([^\\n\\r]+)/i);
          var rawDateStr = dateMatch ? dateMatch[1] : nodeText;
          var dueIso = parseDate(rawDateStr);
          if (!dueIso) {
            var txtM = nodeText.match(/(?:\\d{1,2}\\s+[a-zA-Z]{3,10}(?:\\s+\\d{4})?|\\d{1,2}[\\/\\-]\\d{1,2}|hari ini|besok|lusa)[,\\s]+(?:\\d{1,2}[:.]\\d{2})?/i);
            if (txtM) dueIso = parseDate(txtM[0]);
          }

          // Fallback: jika tanggal tidak tertulis pada kartu tetapi merupakan link tugas aktif,
          // berikan estimasi jatuh tempo 7 hari mendatang agar tugas tetap terdaftar di tracker
          if (!dueIso) {
            dueIso = new Date(Date.now() + 7 * 86400000).toISOString();
          }

          var titleEl = node.querySelector('.activityname, .instancename, .card-title, h4, h5, a') || node;
          var title = (titleEl && titleEl.innerText ? titleEl.innerText : 'Tugas').trim();
          title = title.replace(/\\n.*/g, '');

          var linkEl = node.querySelector('a[href]');
          var linkUrl = linkEl ? linkEl.href : window.location.href;

          addDeadline(linkUrl, title, activeCourse, dueIso, guessType(title), linkUrl);
        });

        // Pola C: Halaman Rincian Pengajuan Tugas (/mod/assign/view.php atau tabel pengumpulan)
        var submissionTables = document.querySelectorAll('.submissionstatustable, table.generaltable, table');
        submissionTables.forEach(function(tbl) {
          var rows = tbl.querySelectorAll('tr');
          var foundDate = '';
          rows.forEach(function(r) {
            var rTxt = (r.innerText || '').toLowerCase();
            if (rTxt.indexOf('batas waktu') !== -1 || rTxt.indexOf('due date') !== -1 ||
                rTxt.indexOf('jatuh tempo') !== -1 || rTxt.indexOf('tenggat') !== -1 ||
                rTxt.indexOf('deadline') !== -1) {
              var cells = r.querySelectorAll('td, th');
              if (cells.length >= 2) {
                foundDate = (cells[1].innerText || '').trim();
              }
            }
          });

          if (foundDate) {
            var dueIso = parseDate(foundDate);
            if (dueIso) {
              var pageH = document.querySelector('h1, h2, .page-header-headings h1') || document.title;
              var tTitle = (typeof pageH === 'string' ? pageH : (pageH.innerText || '')).trim();
              tTitle = tTitle.replace(/[-|•].*/g, '').trim();
              addDeadline(window.location.href, tTitle || 'Tugas Kuliah', activeCourse, dueIso, guessType(tTitle), window.location.href);
            }
          }
        });

        // Pola D: Tabel Umum Berisi Tugas / Kuis
        var generalRows = document.querySelectorAll('table tr');
        generalRows.forEach(function(row) {
          var cells = row.querySelectorAll('td');
          if (cells.length < 2) return;

          var rowText = row.innerText || '';
          var lowRow = rowText.toLowerCase();
          if (lowRow.indexOf('tugas') === -1 && lowRow.indexOf('kuis') === -1 && lowRow.indexOf('quiz') === -1 && lowRow.indexOf('assign') === -1) return;

          var rawDate = '';
          for (var c = 0; c < cells.length; c++) {
            var txt = cells[c].innerText.trim();
            if (/\\d{1,2}\\s+[a-zA-Z]{3}/i.test(txt) || /\\d{1,2}[\\/\\-]\\d{1,2}/.test(txt) || /\\d{4}-\\d{2}-\\d{2}/.test(txt) || /hari ini|besok|lusa/i.test(txt)) {
              rawDate = txt;
              break;
            }
          }

          var dueIso = parseDate(rawDate);
          if (!dueIso) return;

          var link = row.querySelector('a[href]');
          var title = link ? link.innerText.trim() : cells[0].innerText.trim();
          var href = link ? link.href : window.location.href;

          addDeadline(href, title, activeCourse, dueIso, guessType(title), href);
        });

        return results;
      }

      // ─── 4. Eksekusi & Observasi Otomatis ─────────────────────────────
      function runScan() {
        try {
          var results = scanDomDeadlines();
          if (results && results.length > 0 && window.DeadlineChannel) {
            window.DeadlineChannel.postMessage(JSON.stringify(results));
          }
        } catch(e) {}
      }

      runScan();
      setTimeout(runScan, 600);
      setTimeout(runScan, 1600);

      if (!window.__pamsDeadlineObserverInstalled && window.MutationObserver) {
        window.__pamsDeadlineObserverInstalled = true;
        var debounceTimer = null;
        var observer = new MutationObserver(function() {
          if (debounceTimer) clearTimeout(debounceTimer);
          debounceTimer = setTimeout(runScan, 800);
        });
        if (document.body) {
          observer.observe(document.body, { childList: true, subtree: true });
        }
      }

      // Proactive Moodle AJAX Service Call
      try {
        if (window.M && window.M.cfg && window.M.cfg.sesskey) {
          fetch('/lib/ajax/service.php?sesskey=' + window.M.cfg.sesskey + '&info=core_calendar_get_action_events_by_timesort', {
            method: 'POST',
            headers: { 'Content-Type': 'application/json' },
            body: JSON.stringify([{
              index: 0,
              methodname: 'core_calendar_get_action_events_by_timesort',
              args: { limitnum: 50, timesortfrom: Math.floor(Date.now() / 1000) - 86400 }
            }])
          }).then(function(r) { return r.json(); }).then(function(data) {
            if (data && data[0] && data[0].data && data[0].data.events) {
              var evList = data[0].data.events;
              var parsed = evList.map(function(ev) {
                var cName = (ev.course && (ev.course.fullname || ev.course.shortname)) || '';
                return {
                  id: String(ev.id || ''),
                  namaTugas: ev.name || '',
                  namaMataKuliah: cName,
                  dueDate: new Date((ev.timesort || ev.timestart) * 1000).toISOString(),
                  tipe: ev.eventtype || 'tugas',
                  url: ev.url || ''
                };
              });
              if (parsed.length > 0 && window.DeadlineChannel) {
                window.DeadlineChannel.postMessage(JSON.stringify(parsed));
              }
            }
          }).catch(function() {});
        }
      } catch(e) {}

      var immediateResults = scanDomDeadlines();
      return JSON.stringify(immediateResults);
    })();
  ''';


  static const String fpsOptimization = r'''
    (function() {
      try {
        var style = document.getElementById('__unpam_smooth_120fps');
        if (!style) {
          style = document.createElement('style');
          style.id = '__unpam_smooth_120fps';
          style.textContent = `
            html, body {
              -webkit-overflow-scrolling: touch !important;
              scroll-behavior: smooth !important;
              overscroll-behavior-y: contain !important;
            }
            * {
              -webkit-tap-highlight-color: transparent !important;
            }
          `;
          document.head.appendChild(style);
        }
      } catch(e) {}

      var lastAtTop = null;
      function syncScroll() {
        try {
          if (window.ScrollSyncChannel) {
            var atTop = (window.scrollY || document.documentElement.scrollTop || 0) <= 2;
            if (atTop !== lastAtTop) {
              lastAtTop = atTop;
              window.ScrollSyncChannel.postMessage(atTop ? 'true' : 'false');
            }
          }
        } catch(e) {}
      }
      window.removeEventListener('scroll', syncScroll);
      window.addEventListener('scroll', syncScroll, { passive: true });
      syncScroll();
    })();
  ''';

  /// Skrip pencegatan unduhan dokumen PDF, kartu ujian, KRS, dan KHS akademik.
  static const String downloadInterceptor = r'''
    (function() {
      if (window.__campusDownloadInterceptorInstalled) return;
      window.__campusDownloadInterceptorInstalled = true;

      function toAbsoluteUrl(u) {
        try {
          return new URL(u, window.location.href).href;
        } catch(e) {
          return u;
        }
      }

      function isDocumentUrl(u) {
        if (!u || typeof u !== 'string') return false;
        var low = u.toLowerCase().trim();
        if (low.startsWith('blob:')) return true;
        if (low.startsWith('data:application/pdf') ||
            low.startsWith('data:application/octet-stream') ||
            low.startsWith('data:binary/octet-stream')) return true;
        if (low.indexOf('.pdf') !== -1 ||
            low.indexOf('.docx') !== -1 ||
            low.indexOf('.xlsx') !== -1 ||
            low.indexOf('.pptx') !== -1 ||
            low.indexOf('.zip') !== -1 ||
            low.indexOf('.rar') !== -1) return true;
        if (low.indexOf('pluginfile.php') !== -1 ||
            low.indexOf('/mod/resource/view.php') !== -1 ||
            low.indexOf('forcedownload=1') !== -1 ||
            low.indexOf('export=pdf') !== -1 ||
            low.indexOf('format=pdf') !== -1 ||
            low.indexOf('type=pdf') !== -1 ||
            low.indexOf('download=pdf') !== -1 ||
            low.indexOf('output=pdf') !== -1 ||
            low.indexOf('view=pdf') !== -1 ||
            low.indexOf('as=pdf') !== -1 ||
            low.indexOf('cetak=pdf') !== -1 ||
            low.indexOf('cetak=1') !== -1 ||
            low.indexOf('print=1') !== -1 ||
            low.indexOf('export=1') !== -1 ||
            low.indexOf('download=1') !== -1) return true;
        if (low.indexOf('cetak_uts') !== -1 ||
            low.indexOf('cetak_uas') !== -1 ||
            low.indexOf('kartu_uts') !== -1 ||
            low.indexOf('kartu_uas') !== -1 ||
            low.indexOf('kartu_ujian') !== -1 ||
            low.indexOf('kartuujian') !== -1 ||
            low.indexOf('jadwal_ujian/cetak') !== -1 ||
            low.indexOf('cetak_krs') !== -1 ||
            low.indexOf('cetak_khs') !== -1 ||
            low.indexOf('cetak_transkrip') !== -1 ||
            low.indexOf('cetak_kartu') !== -1 ||
            low.indexOf('cetak_tagihan') !== -1 ||
            low.indexOf('cetak_kwitansi') !== -1 ||
            low.indexOf('cetak_spm') !== -1 ||
            low.indexOf('krs_cetak') !== -1 ||
            low.indexOf('khs_cetak') !== -1 ||
            low.indexOf('uts_cetak') !== -1 ||
            low.indexOf('uas_cetak') !== -1 ||
            low.indexOf('/krs/cetak') !== -1 ||
            low.indexOf('/khs/cetak') !== -1 ||
            low.indexOf('/uts/cetak') !== -1 ||
            low.indexOf('/uas/cetak') !== -1 ||
            low.indexOf('/ujian/cetak') !== -1 ||
            low.indexOf('/transkrip/cetak') !== -1 ||
            low.indexOf('/kartu/cetak') !== -1 ||
            low.indexOf('/cetak/') !== -1 ||
            low.indexOf('/print/') !== -1 ||
            low.indexOf('/download/') !== -1) return true;
        return false;
      }

      var originalWindowOpen = window.open;
      window.open = function(url, target, features) {
        if (url) {
          var absUrl = toAbsoluteUrl(url);
          if (isDocumentUrl(absUrl) || isDocumentUrl(url)) {
            if (window.CampusDownloadChannel) {
              window.CampusDownloadChannel.postMessage(absUrl);
              return null;
            }
          }
        }
        return originalWindowOpen ? originalWindowOpen.call(window, url, target, features) : null;
      };

      document.addEventListener('click', function(ev) {
        var el = ev.target;
        while (el && el.tagName !== 'A' && el.tagName !== 'BUTTON' && el.tagName !== 'INPUT' && el !== document.body) {
          el = el.parentElement;
        }
        if (!el || el === document.body) return;

        // 1. Tag <a>
        if (el.tagName === 'A') {
          var href = el.getAttribute('href') || el.href || '';
          var absHref = toAbsoluteUrl(href);
          var downloadAttr = el.getAttribute('download');
          var onclickAttr = el.getAttribute('onclick') || '';
          var text = (el.innerText || el.textContent || '').toLowerCase().trim();

          var isDoc = downloadAttr !== null ||
                      isDocumentUrl(absHref) ||
                      isDocumentUrl(href) ||
                      isDocumentUrl(onclickAttr) ||
                      ((text.indexOf('cetak') !== -1 || text.indexOf('download') !== -1 || text.indexOf('unduh') !== -1 || text.indexOf('print') !== -1) &&
                       (text.indexOf('uts') !== -1 || text.indexOf('uas') !== -1 || text.indexOf('krs') !== -1 || text.indexOf('khs') !== -1 || text.indexOf('kartu') !== -1 || text.indexOf('pdf') !== -1 || text.indexOf('ujian') !== -1));

          if (isDoc && window.CampusDownloadChannel && absHref && !absHref.startsWith('javascript:')) {
            ev.preventDefault();
            ev.stopPropagation();
            window.CampusDownloadChannel.postMessage(absHref);
            return;
          }
        }

        // 2. Tag <button> atau <input type="submit" / "button">
        if (el.tagName === 'BUTTON' || (el.tagName === 'INPUT' && (el.type === 'submit' || el.type === 'button'))) {
          var form = el.form || el.closest('form');
          if (form) {
            return;
          }

          var btnUrl = el.getAttribute('data-url') || el.getAttribute('data-href') || '';
          var absBtnUrl = btnUrl ? toAbsoluteUrl(btnUrl) : '';
          var text = (el.innerText || el.value || '').toLowerCase().trim();

          var isDocBtn = (absBtnUrl && isDocumentUrl(absBtnUrl)) ||
                         ((text.indexOf('cetak') !== -1 || text.indexOf('download') !== -1 || text.indexOf('unduh') !== -1 || text.indexOf('print') !== -1) &&
                          (text.indexOf('uts') !== -1 || text.indexOf('uas') !== -1 || text.indexOf('krs') !== -1 || text.indexOf('khs') !== -1 || text.indexOf('kartu') !== -1 || text.indexOf('pdf') !== -1 || text.indexOf('ujian') !== -1));

          if (isDocBtn && window.CampusDownloadChannel && absBtnUrl) {
            ev.preventDefault();
            ev.stopPropagation();
            window.CampusDownloadChannel.postMessage(absBtnUrl);
            return;
          }
        }
      }, true);
    })();
  ''';

  /// Skrip pendeteksi keberadaan elemen form login pada halaman aktif.
  static const String detectLoginForm = r'''
    (function() {
      var uUrl = window.location.href.toLowerCase();
      var isLoginUrl = uUrl.indexOf('login') !== -1 ||
                       uUrl.indexOf('sso') !== -1 ||
                       uUrl.indexOf('auth') !== -1 ||
                       uUrl === 'https://my.unpam.ac.id/' ||
                       uUrl === 'https://my.unpam.ac.id';

      // 1. Cek token login Mentari (JWT di localStorage)
      var hasMentariToken = false;
      try {
        var acc = window.localStorage.getItem('access');
        hasMentariToken = !!(acc && acc !== 'null' && acc !== 'undefined' && acc !== '""');
      } catch(e) {}

      // 2. Cek indikator akun aktif di Moodle / MyUnpam
      var hasProfileIndicator = hasMentariToken || 
        !!document.querySelector('.usermenu .userbutton, .userpicture, [data-testid="AccountCircleIcon"], [aria-label*="akun" i], [aria-label*="profile" i], .avatar, a[href*="logout" i], a[href*="keluar" i], .user-panel, #user-profile, .brand-text, .navbar-user');

      // 3. Cek form login nyata (wajib ada elemen input password dan username)
      var p = document.querySelector('input[name="password"], input[type="password"], input#password, input[name="pass"], input#pass, input[name*="password" i], input[placeholder*="pass" i], input[placeholder*="sandi" i]');
      var u = document.querySelector('input[name="username"], input#username, input[autocomplete="username"], input[name="user"], input[name="identity"], input#identity, input[name="nim"], input#nim, input[name="user_id"], input#user_id, input[name="email"], input#email, input[name="login"], input[placeholder*="nim" i], input[placeholder*="username" i], input[placeholder*="identitas" i]');
      if (!u && p) {
        var form = p.closest('form');
        if (form) {
          u = form.querySelector('input[type="text"], input[type="email"], input[type="number"], input:not([type])');
        }
      }
      if (!u && p) {
        var allInputs = Array.from(document.querySelectorAll('input'));
        var pIdx = allInputs.indexOf(p);
        if (pIdx > 0) {
          for (var k = pIdx - 1; k >= 0; k--) {
            var typ = (allInputs[k].type || 'text').toLowerCase();
            if (typ === 'text' || typ === 'email' || typ === 'number' || typ === '') {
              u = allInputs[k];
              break;
            }
          }
        }
      }

      var hasLoginForm = !!(u && p);

      return JSON.stringify({
        hasLoginForm: hasLoginForm,
        isLoginUrl: isLoginUrl,
        hasProfileIndicator: hasProfileIndicator
      });
    })();
  ''';

  /// Skrip perekam kredensial login pengguna untuk disimpan ke Biometric Vault.
  static const String loginCapture = r'''
    (function() {
      if (window._unpamBioCaptureAttached) return;
      window._unpamBioCaptureAttached = true;

      var lastTypedNim = '';
      var lastTypedPass = '';
      var successNotified = false;

      function findInputs() {
        var p = document.querySelector('input[type="password"], input[name="password"], input#password, input[name="pass"], input#pass, input[name*="password" i], input[placeholder*="pass" i], input[placeholder*="sandi" i]');
        var u = document.querySelector('input[name="username"], input#username, input[autocomplete="username"], input[name="user"], input[name="identity"], input#identity, input[name="nim"], input#nim, input[name="user_id"], input#user_id, input[name="email"], input#email, input[name="login"], input[placeholder*="nim" i], input[placeholder*="username" i], input[placeholder*="identitas" i]');

        if (!u && p) {
          var container = p.closest('form') || p.closest('[role="form"]') || p.parentElement;
          if (container) {
            u = container.querySelector('input[type="text"], input[type="email"], input[type="number"], input:not([type])');
          }
        }
        if (!u && p) {
          var all = Array.from(document.querySelectorAll('input'));
          var pIndex = all.indexOf(p);
          if (pIndex > 0) {
            for (var i = pIndex - 1; i >= 0; i--) {
              var t = (all[i].type || 'text').toLowerCase();
              if (t === 'text' || t === 'email' || t === 'number' || t === '') {
                u = all[i];
                break;
              }
            }
          }
        }
        return { u: u, p: p };
      }

      function readAndCache() {
        var inputs = findInputs();
        if (inputs.u && inputs.u.value) lastTypedNim = inputs.u.value.trim();
        if (inputs.p && inputs.p.value) lastTypedPass = inputs.p.value.trim();

        if (lastTypedNim && lastTypedPass && window.BiometricCaptureChannel) {
          window.BiometricCaptureChannel.postMessage(JSON.stringify({
            event: 'CREDENTIALS_TYPED',
            nim: lastTypedNim,
            password: lastTypedPass
          }));
        }
      }

      function hasAuthToken() {
        try {
          var acc = window.localStorage.getItem('access');
          if (acc && acc !== 'null' && acc !== 'undefined' && acc !== '""' && acc.length > 20) {
            return true;
          }
        } catch(e) {}
        return false;
      }

      function hasProfileDom() {
        return !!document.querySelector('.usermenu .userbutton, .userpicture, [data-testid="AccountCircleIcon"], [aria-label*="akun" i], [aria-label*="profile" i], .avatar, a[href*="logout" i], a[href*="keluar" i], .user-panel, #user-profile, .brand-text, .navbar-user');
      }

      function notifySuccess() {
        if (successNotified) return;
        readAndCache();
        if (lastTypedNim && lastTypedPass && window.BiometricCaptureChannel) {
          successNotified = true;
          window.BiometricCaptureChannel.postMessage(JSON.stringify({
            event: 'LOGIN_SUCCESS',
            nim: lastTypedNim,
            password: lastTypedPass
          }));
        }
      }

      document.addEventListener('input', readAndCache, true);
      document.addEventListener('change', readAndCache, true);
      document.addEventListener('blur', readAndCache, true);

      function onSubmitOrClick() {
        readAndCache();
        var polls = 0;
        var timer = setInterval(function() {
          polls++;
          if (hasAuthToken() || hasProfileDom()) {
            clearInterval(timer);
            notifySuccess();
          } else if (polls >= 20) {
            clearInterval(timer);
          }
        }, 500);
      }

      document.addEventListener('submit', onSubmitOrClick, true);
      document.addEventListener('click', function(e) {
        var t = e.target;
        if (t && (t.matches('button, button *, input[type="submit"], [role="button"]') || t.closest('button, [role="button"]'))) {
          onSubmitOrClick();
        }
      }, true);

      try {
        var origSet = window.localStorage.setItem;
        window.localStorage.setItem = function(k, v) {
          origSet.apply(this, arguments);
          if ((k === 'access' || k === 'token') && v && v !== 'null' && v.length > 20) {
            setTimeout(notifySuccess, 300);
          }
        };
      } catch(e) {}

      readAndCache();
    })();
  ''';

  /// Membangun skrip pengisian form login otomatis biometrik secara aman.
  static String buildBiometricLoginScript({
    required String nim,
    required String password,
    required bool isMyUnpam,
  }) {
    return '''
      (function(nimVal, passVal, isMyUnpamFlag) {
        function fillInputElement(input, val) {
          if (!input) return false;
          try { input.focus(); } catch(e) {}
          var prevVal = input.value;

          var proto = Object.getPrototypeOf(input);
          var desc = Object.getOwnPropertyDescriptor(proto, 'value');
          if (!desc || !desc.set) {
            desc = Object.getOwnPropertyDescriptor(window.HTMLInputElement.prototype, 'value');
          }
          if (desc && desc.set) {
            desc.set.call(input, val);
          } else {
            input.value = val;
          }

          try { input.setAttribute('value', val); } catch(e) {}

          if (input._valueTracker) {
            input._valueTracker.setValue(prevVal + '_force_react_sync_');
          }

          var eventOptions = { bubbles: true, composed: true, cancelable: true };
          input.dispatchEvent(new Event('input', eventOptions));
          input.dispatchEvent(new Event('change', eventOptions));

          var reactPropsKey = Object.keys(input).find(function(k) { return k.startsWith('__reactProps\$'); });
          if (reactPropsKey && input[reactPropsKey]) {
            var props = input[reactPropsKey];
            if (typeof props.onChange === 'function') {
              try {
                props.onChange({
                  target: input,
                  currentTarget: input,
                  bubbles: true,
                  preventDefault: function() {},
                  stopPropagation: function() {}
                });
              } catch(e) {}
            }
          }
          return true;
        }

        function findUsernameInputs() {
          var list = [];
          var selectors = [
            'input[name="username"]',
            'input#username',
            'input[name="identity"]',
            'input#identity',
            'input[name="nim"]',
            'input#nim',
            'input[name="user_id"]',
            'input#user_id',
            'input[name="userid"]',
            'input#userid',
            'input[name="npm"]',
            'input#npm',
            'input[name="mhs_nim"]',
            'input#mhs_nim',
            'input[name="user"]',
            'input[name="email"]',
            'input#email',
            'input[autocomplete="username"]',
            'input[name="login"]',
            'input[placeholder*="nim" i]',
            'input[placeholder*="username" i]',
            'input[placeholder*="identitas" i]',
            'input[placeholder*="email" i]'
          ];
          selectors.forEach(function(sel) {
            document.querySelectorAll(sel).forEach(function(el) {
              if (!list.includes(el)) list.push(el);
            });
          });

          var passInputs = document.querySelectorAll('input[type="password"], input[name="password"], input#password, input[name="pass"], input#pass, input[name*="password" i]');
          passInputs.forEach(function(passEl) {
            var parentForm = passEl.closest('form');
            if (parentForm) {
              var candidates = parentForm.querySelectorAll('input[type="text"], input[type="email"], input[type="number"], input:not([type])');
              candidates.forEach(function(el) {
                var name = (el.name || '').toLowerCase();
                var id = (el.id || '').toLowerCase();
                var ph = (el.placeholder || '').toLowerCase();
                if (name.includes('search') || id.includes('search') || ph.includes('cari')) return;
                if (name.includes('csrf') || name.includes('token') || name.includes('captcha')) return;
                if (!list.includes(el)) list.push(el);
              });
            }
          });

          return list;
        }

        function findPasswordInputs() {
          var list = [];
          var selectors = [
            'input[name="password"]',
            'input[type="password"]',
            'input#password',
            'input[name="pass"]',
            'input#pass',
            'input[name*="password" i]',
            'input[name*="pass" i]',
            'input[autocomplete="current-password"]',
            'input[autocomplete="password"]',
            'input[placeholder*="pass" i]',
            'input[placeholder*="kata sandi" i]',
            'input[placeholder*="sandi" i]'
          ];
          selectors.forEach(function(sel) {
            document.querySelectorAll(sel).forEach(function(el) {
              if (!list.includes(el)) list.push(el);
            });
          });
          return list;
        }

        var bodyText = (document.body ? (document.body.innerText || document.body.textContent || '') : '').toLowerCase();
        var isRedirectScreen = bodyText.indexOf('konfirmasi redirect') !== -1 ||
                               bodyText.indexOf('lanjutkan ke my unpam') !== -1 ||
                               bodyText.indexOf('apakah anda ingin melanjutkan ke aplikasi berikut') !== -1;
        if (isRedirectScreen) {
          var buttons = Array.from(document.querySelectorAll('a, button, input[type="button"], input[type="submit"], [role="button"], div[role="button"]'));
          var proceedBtn = buttons.find(function(b) {
            var t = (b.innerText || b.value || b.textContent || '').trim().toLowerCase();
            var h = (b.href || '').toLowerCase();
            return t.indexOf('lanjutkan ke my unpam') !== -1 ||
                   (t.indexOf('lanjutkan') !== -1 && t.indexOf('unpam') !== -1) ||
                   t.indexOf('lanjutkan') !== -1 ||
                   h.indexOf('my.unpam.ac.id') !== -1;
          });
          if (proceedBtn) {
            try {
              proceedBtn.focus();
              proceedBtn.click();
              proceedBtn.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
              return JSON.stringify({ status: 'clicked_proceed_button' });
            } catch(e) {}
          }
          window.location.href = 'https://my.unpam.ac.id/';
          return JSON.stringify({ status: 'redirecting_to_login' });
        }

        var uList = findUsernameInputs();
        var pList = findPasswordInputs();

        if (uList.length === 0 || pList.length === 0) {
          var currentUrl = window.location.href.toLowerCase();
          var isAtKnownPortalLogin = currentUrl.indexOf('login') !== -1 ||
                                     currentUrl.indexOf('sso') !== -1 ||
                                     currentUrl.indexOf('auth') !== -1 ||
                                     currentUrl.indexOf('my.unpam.ac.id') !== -1;
          if (!isAtKnownPortalLogin) {
            var targetLogin = isMyUnpamFlag ? 'https://my.unpam.ac.id/' : 'https://mentari.unpam.ac.id/login';
            window.location.href = targetLogin;
            return JSON.stringify({ status: 'redirecting_to_login' });
          }
          return JSON.stringify({ status: 'inputs_not_found', uCount: uList.length, pCount: pList.length });
        }

        uList.forEach(function(u) { fillInputElement(u, nimVal); });
        pList.forEach(function(p) { fillInputElement(p, passVal); });

        setTimeout(function() {
          uList.forEach(function(u) {
            try { u.dispatchEvent(new Event('blur', { bubbles: true, composed: true })); } catch(e) {}
          });
          pList.forEach(function(p) {
            try { p.dispatchEvent(new Event('blur', { bubbles: true, composed: true })); } catch(e) {}
          });

          setTimeout(function() {
            var turnstileInput = document.querySelector('input[name="cf-turnstile-response"]');
            var hasTurnstileWidget = !!(turnstileInput || document.querySelector('iframe[src*="cloudflare"], iframe[src*="turnstile"], .cf-turnstile'));
            var turnstileSolved = turnstileInput ? (turnstileInput.value && turnstileInput.value.length > 10) : false;

            if (hasTurnstileWidget && !turnstileSolved) {
              return;
            }

            var submitBtn = null;
            for (var i = 0; i < pList.length; i++) {
              var form = pList[i].closest('form');
              if (form) {
                submitBtn = form.querySelector('button[type="submit"], input[type="submit"], button#loginbtn, input#loginbtn, .btn-primary, .btn-login, button.btn-block');
                if (submitBtn) break;
              }
            }
            if (!submitBtn) {
              submitBtn = document.querySelector('button[type="submit"], input[type="submit"], button#loginbtn, input#loginbtn, .btn-primary, .btn-login, button.btn-block');
            }
            if (!submitBtn) {
              var allBtns = Array.from(document.querySelectorAll('button, input[type="button"], a.btn, [role="button"]'));
              submitBtn = allBtns.find(function(b) {
                var txt = (b.textContent || b.value || '').trim().toLowerCase();
                return txt === 'masuk' || txt === 'login' || txt === 'log in' || txt === 'sign in';
              });
            }

            if (submitBtn) {
              submitBtn.focus();
              submitBtn.click();
              submitBtn.dispatchEvent(new MouseEvent('click', { bubbles: true, cancelable: true, view: window }));
              var btnPropsKey = Object.keys(submitBtn).find(function(k) { return k.startsWith('__reactProps\$'); });
              if (btnPropsKey && submitBtn[btnPropsKey] && typeof submitBtn[btnPropsKey].onClick === 'function') {
                try {
                  submitBtn[btnPropsKey].onClick({
                    preventDefault: function() {},
                    stopPropagation: function() {},
                    target: submitBtn,
                    currentTarget: submitBtn
                  });
                } catch(e) {}
              }
            } else {
              var form = document.querySelector('form#login, form[action*="login"]') || (pList[0] ? pList[0].closest('form') : null);
              if (form) {
                form.dispatchEvent(new Event('submit', { bubbles: true, cancelable: true }));
                try { form.submit(); } catch(e) {}
              }
            }
          }, 200);
        }, 250);

        return JSON.stringify({
          status: 'filled_and_submitting',
          uCount: uList.length,
          pCount: pList.length
        });
      })(${jsonEncode(nim)}, ${jsonEncode(password)}, $isMyUnpam);
    ''';
  }

  /// Membangun skrip injeksi balasan forum diskusi ke Atto / TinyMCE / Textarea.
  static String buildForumReplyScript(String replyText) {
    return '''
      (function(replyText) {
        var injected = false;

        // 1. Coba Atto Editor (Moodle)
        var attoEl = document.querySelector('.editor_atto_content, [contenteditable="true"]');
        if (attoEl) {
          attoEl.focus();
          attoEl.innerHTML = '<p>' + replyText.replace(/\\n\\n/g, '</p><p>').replace(/\\n/g, '<br>') + '</p>';
          attoEl.dispatchEvent(new Event('input', { bubbles: true }));
          attoEl.dispatchEvent(new Event('change', { bubbles: true }));
          attoEl.scrollIntoView({ behavior: 'smooth', block: 'center' });
          injected = true;
        }

        // 2. Coba TinyMCE
        if (!injected && window.tinymce && window.tinymce.activeEditor) {
          try {
            window.tinymce.activeEditor.setContent('<p>' + replyText.replace(/\\n\\n/g, '</p><p>').replace(/\\n/g, '<br>') + '</p>');
            injected = true;
          } catch(e) {}
        }

        // 3. Coba textarea standar
        if (!injected) {
          var textareas = document.querySelectorAll('textarea');
          for (var i = 0; i < textareas.length; i++) {
            var ta = textareas[i];
            if (ta.offsetParent !== null) {
              ta.focus();
              ta.value = replyText;
              ta.dispatchEvent(new Event('input', { bubbles: true }));
              ta.dispatchEvent(new Event('change', { bubbles: true }));
              ta.scrollIntoView({ behavior: 'smooth', block: 'center' });
              injected = true;
              break;
            }
          }
          if (!injected && textareas.length > 0) {
            textareas[0].focus();
            textareas[0].value = replyText;
            textareas[0].dispatchEvent(new Event('input', { bubbles: true }));
            textareas[0].dispatchEvent(new Event('change', { bubbles: true }));
            textareas[0].scrollIntoView({ behavior: 'smooth', block: 'center' });
            injected = true;
          }
        }

        return injected;
      })(${jsonEncode(replyText)})
    ''';
  }

  /// Skrip pemindaian dan ekstraksi butir soal kuis pilihan ganda dari DOM Moodle LMS.
  static const String extractQuizQuestions = r'''
    (function() {
      var results = [];
      var blocks = document.querySelectorAll('.que, .question, .soal, fieldset, .form-group, .quiz-item');

      if (blocks.length > 0) {
        for (var i = 0; i < blocks.length; i++) {
          var block = blocks[i];
          var radios = block.querySelectorAll('input[type="radio"]');
          if (radios.length === 0) continue;

          var qTextEl = block.querySelector('.qtext, .question-text, .formulation .content, legend, h3, h4');
          var qText = qTextEl ? qTextEl.innerText.trim() : block.innerText.split('\n')[0].trim();
          if (!qText || qText.length < 5) continue;

          var opts = [];
          for (var j = 0; j < radios.length; j++) {
            var r = radios[j];
            var label = block.querySelector('label[for="' + r.id + '"]') || r.closest('label') || r.parentElement;
            var optText = label ? label.innerText.trim() : 'Opsi ' + String.fromCharCode(65 + j);

            r.setAttribute('data-unpam-q', results.length.toString());
            r.setAttribute('data-unpam-opt', j.toString());

            opts.push({
              optionIndex: j,
              optionId: r.id || '',
              radioName: r.name || '',
              optionText: optText
            });
          }

          if (opts.length > 1) {
            results.push({
              index: results.length,
              originalIndex: i,
              questionText: qText,
              options: opts
            });
          }
        }
      }

      if (results.length === 0) {
        var allRadios = document.querySelectorAll('input[type="radio"]');
        var groupMap = {};
        allRadios.forEach(function(r) {
          var name = r.getAttribute('name') || 'default_quiz_group';
          if (!groupMap[name]) groupMap[name] = [];
          groupMap[name].push(r);
        });

        var gIdx = 0;
        for (var gName in groupMap) {
          var list = groupMap[gName];
          if (list.length < 2) continue;
          var parent = list[0].closest('form, div, fieldset') || list[0].parentElement;
          var qText = parent ? parent.innerText.substring(0, 300).trim() : 'Soal #' + (gIdx + 1);

          var opts = [];
          list.forEach(function(r, oIdx) {
            var label = document.querySelector('label[for="' + r.id + '"]') || r.closest('label') || r.parentElement;
            var optText = label ? label.innerText.trim() : 'Opsi ' + String.fromCharCode(65 + oIdx);
            r.setAttribute('data-unpam-q', gIdx.toString());
            r.setAttribute('data-unpam-opt', oIdx.toString());

            opts.push({
              optionIndex: oIdx,
              optionId: r.id || '',
              radioName: gName,
              optionText: optText
            });
          });

          results.push({
            index: gIdx,
            originalIndex: gIdx,
            questionText: qText,
            options: opts
          });
          gIdx++;
        }
      }

      return JSON.stringify(results);
    })()
  ''';

  /// Membangun skrip penandaan/pemilihan opsi jawaban kuis di WebView.
  static String buildHighlightQuizScript({
    required List<Map<String, dynamic>> solutions,
    required bool autoSelect,
  }) {
    return '''
      (function(solutionsJson, autoSelect) {
        var solutions = JSON.parse(solutionsJson);
        var highlighted = 0;

        solutions.forEach(function(sol) {
          var qIdx = sol.index;
          var optIdx = sol.correctOptionIndex;

          var radio = document.querySelector('input[type="radio"][data-unpam-q="' + qIdx + '"][data-unpam-opt="' + optIdx + '"]');
          if (!radio && sol.optionId) {
            radio = document.getElementById(sol.optionId);
          }

          if (radio) {
            if (autoSelect) {
              radio.checked = true;
              radio.dispatchEvent(new Event('change', { bubbles: true }));
              radio.dispatchEvent(new Event('click', { bubbles: true }));
            }

            var container = radio.closest('.form-check, .r0, .r1, label, div.answer, li') || radio.parentElement;
            if (container) {
              container.style.backgroundColor = '#E8F5E9';
              container.style.border = '2px solid #2E7D32';
              container.style.borderRadius = '8px';
              container.style.padding = '8px 12px';
              container.style.margin = '4px 0';
              container.style.transition = 'all 0.3s ease';

              var oldBadge = container.querySelector('.unpam-ai-badge');
              if (!oldBadge) {
                var badge = document.createElement('span');
                badge.className = 'unpam-ai-badge';
                badge.innerText = ' [Rekomendasi The PAMs AI]';
                badge.style.color = '#2E7D32';
                badge.style.fontWeight = 'bold';
                badge.style.fontSize = '12px';
                badge.style.marginLeft = '8px';
                container.appendChild(badge);
              }
              highlighted++;
            }
          }
        });

        return highlighted;
      })(${jsonEncode(jsonEncode(solutions))}, ${autoSelect ? 'true' : 'false'})
    ''';
  }

  /// Skrip pemindaian dan ekstraksi butir kuesioner evaluasi dosen Mentari.
  static const String extractQuestionnaire = r'''
    (function() {
      var results = [];
      var hasFeedback = false;

      // 1. Deteksi Baris Tabel (Format utama di Mentari Portal)
      var rows = document.querySelectorAll('table tbody tr, table tr');
      if (rows.length > 0) {
        for (var i = 0; i < rows.length; i++) {
          var row = rows[i];
          var radios = row.querySelectorAll('input[type="radio"]');
          if (radios.length === 0) continue;

          var cells = row.querySelectorAll('td, th');
          var qNum = (results.length + 1).toString();
          var qText = '';

          if (cells.length >= 2) {
            var col0 = cells[0].innerText.trim();
            if (/^\d+$/.test(col0)) {
              qNum = col0;
            }
            var col1 = cells[1].innerText.trim();
            var jIdx = col1.indexOf('Jawaban');
            if (jIdx !== -1) {
              qText = col1.substring(0, jIdx).trim();
            } else {
              qText = col1;
            }
          } else {
            var rText = row.innerText.trim();
            var jIdx = rText.indexOf('Jawaban');
            if (jIdx !== -1) {
              qText = rText.substring(0, jIdx).trim();
            } else {
              qText = rText.split('\n')[0].trim();
            }
          }

          if (!qText || qText.length < 3) {
            qText = 'Butir Kuesioner #' + qNum;
          }

          var opts = [];
          for (var j = 0; j < radios.length; j++) {
            var r = radios[j];
            var label = row.querySelector('label[for="' + r.id + '"]') || r.closest('label');
            var optText = '';
            if (label) {
              optText = label.innerText.trim();
            } else if (r.parentElement) {
              optText = r.parentElement.innerText.trim();
            }
            if (!optText || optText === 'Jawaban') {
              optText = (r.value && r.value !== 'on') ? r.value : (j === 0 ? 'Ya' : 'Tidak');
            }
            optText = optText.replace(/^Jawaban\s*/i, '').trim();

            r.setAttribute('data-unpam-kues-q', results.length.toString());
            r.setAttribute('data-unpam-kues-opt', j.toString());

            opts.push({
              optionIndex: j,
              optionId: r.id || '',
              radioName: r.name || '',
              optionText: optText,
              value: r.value || ''
            });
          }

          if (opts.length > 0) {
            results.push({
              index: results.length,
              number: qNum,
              questionText: qText,
              options: opts
            });
          }
        }
      }

      // 2. Fallback jika bukan tabel (grouping by radio name)
      if (results.length === 0) {
        var allRadios = document.querySelectorAll('input[type="radio"]');
        var groupMap = {};
        allRadios.forEach(function(r) {
          var name = r.getAttribute('name') || 'kues_default_group';
          if (!groupMap[name]) groupMap[name] = [];
          groupMap[name].push(r);
        });

        var kIdx = 0;
        for (var kName in groupMap) {
          var list = groupMap[kName];
          if (list.length < 2) continue;
          var parent = list[0].closest('tr, .form-group, .card, div.row, fieldset, li') || list[0].parentElement;
          var qText = parent ? parent.innerText.split('\n')[0].trim() : 'Butir Kuesioner #' + (kIdx + 1);

          var opts = [];
          list.forEach(function(r, oIdx) {
            var label = document.querySelector('label[for="' + r.id + '"]') || r.closest('label') || r.parentElement;
            var optText = label ? label.innerText.trim() : (r.value || 'Opsi ' + (oIdx + 1));
            r.setAttribute('data-unpam-kues-q', kIdx.toString());
            r.setAttribute('data-unpam-kues-opt', oIdx.toString());

            opts.push({
              optionIndex: oIdx,
              optionId: r.id || '',
              radioName: kName,
              optionText: optText,
              value: r.value || ''
            });
          });

          results.push({
            index: kIdx,
            number: (kIdx + 1).toString(),
            questionText: qText,
            options: opts
          });
          kIdx++;
        }
      }

      var textareas = document.querySelectorAll('textarea');
      if (textareas.length > 0) {
        hasFeedback = true;
        textareas[0].setAttribute('data-unpam-kues-feedback', '1');
      }

      return JSON.stringify({
        questions: results,
        hasFeedbackField: hasFeedback
      });
    })()
  ''';

  /// Membangun skrip pengisian dan penandaan evaluasi kuesioner.
  static String buildHighlightQuestionnaireScript({
    required List<Map<String, dynamic>> answers,
    required String feedback,
    required bool autoCheck,
  }) {
    final payload = {
      'answers': answers,
      'feedback': feedback,
    };

    return '''
      (function(payloadJson, autoCheck) {
        var payload = JSON.parse(payloadJson);
        var answers = payload.answers || [];
        var feedback = payload.feedback || '';
        var filled = 0;

        answers.forEach(function(item) {
          var qIdx = item.index;
          var optIdx = item.optionIndex;

          var radio = document.querySelector('input[type="radio"][data-unpam-kues-q="' + qIdx + '"][data-unpam-kues-opt="' + optIdx + '"]');
          if (radio) {
            if (autoCheck) {
              radio.checked = true;
              radio.dispatchEvent(new Event('input', { bubbles: true }));
              radio.dispatchEvent(new Event('change', { bubbles: true }));
              radio.dispatchEvent(new Event('click', { bubbles: true }));
            }

            var row = radio.closest('tr, .form-group, .card, div.row, fieldset, li') || radio.parentElement;
            if (row) {
              row.style.backgroundColor = '#E0F2F1';
              row.style.transition = 'background-color 0.3s ease';

              var oldBadge = row.querySelector('.unpam-kues-badge');
              if (!oldBadge) {
                var badge = document.createElement('span');
                badge.className = 'unpam-kues-badge';
                badge.innerText = ' [✓ Terisi Otomatis]';
                badge.style.color = '#00796B';
                badge.style.fontSize = '12px';
                badge.style.fontWeight = 'bold';
                badge.style.marginLeft = '8px';
                var targetEl = row.querySelector('td:nth-child(2), h4, h5, p, label') || row;
                targetEl.appendChild(badge);
              }
            }
            filled++;
          }
        });

        if (feedback && feedback.trim().length > 0) {
          var ta = document.querySelector('textarea[data-unpam-kues-feedback="1"]') || document.querySelector('textarea');
          if (ta) {
            ta.value = feedback;
            ta.dispatchEvent(new Event('input', { bubbles: true }));
            ta.dispatchEvent(new Event('change', { bubbles: true }));
          }
        }

        return filled;
      })(${jsonEncode(jsonEncode(payload))}, ${autoCheck ? 'true' : 'false'})
    ''';
  }

  /// Skrip pemindaian otomatis konteks halaman (Forum, Kuis, Kuesioner, Modul Dokumen, Tabel Akademik).
  static const String contextualPageDetector = r'''
    (function() {
      if (!window.PageContextChannel) return;

      function toAbsoluteUrl(u) {
        try {
          return new URL(u, window.location.href).href;
        } catch(e) {
          return u || '';
        }
      }

      function scanPageContext() {
        try {
          var href = window.location.href || '';
          var lowHref = href.toLowerCase();

          // 0. Guard: Jangan tampilkan konteks di halaman login
          var passInput = document.querySelector('input[type="password"]');
          var hasProfile = !!document.querySelector('.usermenu .userbutton, .userpicture, [data-testid="AccountCircleIcon"], [aria-label*="akun" i], [aria-label*="profile" i], .avatar, a[href*="logout" i], a[href*="keluar" i], .user-panel, #user-profile, .brand-text, .navbar-user');
          if (passInput && passInput.offsetParent !== null && !hasProfile) {
            return {
              type: 'none',
              itemCount: 0,
              label: '',
              selectedText: '',
              documentUrl: '',
              pageUrl: href
            };
          }

          // 1. Prioritas 1: Teks sedang diblok / disorot oleh pengguna
          var sel = window.getSelection ? window.getSelection().toString().trim() : '';
          if (sel && sel.length >= 8) {
            return {
              type: 'selection',
              itemCount: 0,
              label: 'Teks Diblok',
              selectedText: sel.substring(0, 1200),
              documentUrl: '',
              pageUrl: href
            };
          }

          var headingNodes = document.querySelectorAll('h1, h2, h3, h4, .card-title, .page-header-headings, .breadcrumb');
          var headingText = (document.title || '') + ' ';
          for (var h = 0; h < headingNodes.length && h < 12; h++) {
            headingText += (headingNodes[h].innerText || '') + ' ';
          }
          var lowHeading = headingText.toLowerCase();

          // 2. Prioritas 2: Deteksi Kuesioner Dosen vs Kuis Pilihan Ganda
          var allRadios = document.querySelectorAll('input[type="radio"]');
          if (allRadios.length >= 2) {
            var radioGroups = {};
            var likertSignal = 0;
            for (var r = 0; r < allRadios.length; r++) {
              var rad = allRadios[r];
              var gName = rad.getAttribute('name') || ('grp_' + r);
              if (!radioGroups[gName]) radioGroups[gName] = [];
              radioGroups[gName].push(rad);

              var lbl = document.querySelector('label[for="' + rad.id + '"]') || rad.closest('label') || rad.parentElement;
              var lblTxt = lbl ? (lbl.innerText || '').toLowerCase().trim() : '';
              if (lblTxt === 'ya' || lblTxt === 'tidak' ||
                  lblTxt.indexOf('sangat baik') !== -1 ||
                  lblTxt.indexOf('sangat setuju') !== -1 ||
                  lblTxt.indexOf('setuju') !== -1 ||
                  lblTxt.indexOf('kurang baik') !== -1) {
                likertSignal++;
              }
            }

            var groupCount = Object.keys(radioGroups).length;
            var isQuestionnaireKeyword =
              lowHref.indexOf('kuesioner') !== -1 ||
              lowHref.indexOf('kuisioner') !== -1 ||
              lowHref.indexOf('edom') !== -1 ||
              lowHeading.indexOf('kuesioner') !== -1 ||
              lowHeading.indexOf('kuisioner') !== -1 ||
              lowHeading.indexOf('evaluasi dosen') !== -1 ||
              lowHeading.indexOf('angket') !== -1;

            if (groupCount >= 2 && (isQuestionnaireKeyword || likertSignal >= 2)) {
              return {
                type: 'questionnaire',
                itemCount: groupCount,
                label: 'Kuesioner Dosen',
                selectedText: '',
                documentUrl: '',
                pageUrl: href
              };
            }

            var hasQuizDom = !!document.querySelector('.que, .qtext, .quiz-content, .question-container');
            var isQuizKeyword =
              lowHref.indexOf('quiz') !== -1 ||
              lowHref.indexOf('kuis') !== -1 ||
              lowHref.indexOf('latihan') !== -1 ||
              lowHref.indexOf('pretest') !== -1 ||
              lowHref.indexOf('posttest') !== -1 ||
              lowHeading.indexOf('kuis') !== -1 ||
              lowHeading.indexOf('quiz') !== -1 ||
              lowHeading.indexOf('latihan soal') !== -1 ||
              lowHeading.indexOf('pretest') !== -1 ||
              lowHeading.indexOf('posttest') !== -1;

            if (hasQuizDom || (groupCount >= 1 && isQuizKeyword) || groupCount >= 3) {
              var qDomCount = document.querySelectorAll('.que').length;
              var finalQuizCount = qDomCount > 0 ? qDomCount : groupCount;
              return {
                type: 'quiz',
                itemCount: finalQuizCount,
                label: 'Kuis Pilihan Ganda',
                selectedText: '',
                documentUrl: '',
                pageUrl: href
              };
            }
          } else if (document.querySelectorAll('.que, .qtext, .quiz-content').length > 0) {
            var qCount = document.querySelectorAll('.que, .qtext').length || 1;
            return {
              type: 'quiz',
              itemCount: qCount,
              label: 'Kuis Pilihan Ganda',
              selectedText: '',
              documentUrl: '',
              pageUrl: href
            };
          }

          // 3. Prioritas 3: Deteksi Forum Diskusi Perkuliahan
          var hasForumPost = !!document.querySelector('.forumpost, .discussion-content, .post-content, .forum-thread');
          var isForumKeyword =
            lowHref.indexOf('forum') !== -1 ||
            lowHref.indexOf('diskusi') !== -1 ||
            lowHeading.indexOf('forum') !== -1 ||
            lowHeading.indexOf('diskusi') !== -1 ||
            lowHeading.indexOf('topik diskusi') !== -1;
          var hasReplyEditor = !!document.querySelector('textarea, .tox-edit-area, [contenteditable="true"], .editor_atto_content');

          if (hasForumPost || (isForumKeyword && (hasReplyEditor || document.querySelectorAll('.card-body, article').length > 0))) {
            return {
              type: 'forum',
              itemCount: 1,
              label: 'Forum Diskusi',
              selectedText: '',
              documentUrl: '',
              pageUrl: href
            };
          }

          // 4. Prioritas 4: Deteksi Dokumen / Modul PDF / Tombol Cetak Akademik
          var pdfEmbed = document.querySelector('iframe[src*=".pdf" i], embed[type="application/pdf" i], object[data*=".pdf" i]');
          if (pdfEmbed) {
            var embedSrc = pdfEmbed.getAttribute('src') || pdfEmbed.getAttribute('data') || '';
            return {
              type: 'document',
              itemCount: 1,
              label: 'Unduh Modul PDF',
              selectedText: '',
              documentUrl: embedSrc ? toAbsoluteUrl(embedSrc) : '',
              pageUrl: href
            };
          }

          var prevMarked = document.querySelectorAll('[data-unpam-quick-doc-btn="1"]');
          for (var pm = 0; pm < prevMarked.length; pm++) {
            prevMarked[pm].removeAttribute('data-unpam-quick-doc-btn');
          }

          var clickables = document.querySelectorAll('a[href], button, [role="button"], input[type="button"]');
          for (var c = 0; c < clickables.length; c++) {
            var el = clickables[c];
            if (el.offsetParent === null) continue;
            var rawHref = el.getAttribute('href') || el.getAttribute('data-url') || el.getAttribute('data-href') || '';
            var lowUrl = rawHref.toLowerCase().trim();
            var btnTxt = (el.innerText || el.value || el.getAttribute('title') || '').trim();
            var lowTxt = btnTxt.toLowerCase();

            var isDirectDocUrl =
              lowUrl.indexOf('.pdf') !== -1 ||
              lowUrl.indexOf('.docx') !== -1 ||
              lowUrl.indexOf('.pptx') !== -1 ||
              lowUrl.indexOf('pluginfile.php') !== -1 ||
              lowUrl.indexOf('mod_resource') !== -1 ||
              lowUrl.startsWith('blob:');

            var isPrintOrDocBtn =
              (lowTxt.indexOf('cetak') !== -1 || lowTxt.indexOf('unduh') !== -1 || lowTxt.indexOf('download') !== -1) &&
              (lowTxt.indexOf('krs') !== -1 ||
               lowTxt.indexOf('khs') !== -1 ||
               lowTxt.indexOf('jadwal') !== -1 ||
               lowTxt.indexOf('kartu') !== -1 ||
               lowTxt.indexOf('ujian') !== -1 ||
               lowTxt.indexOf('uts') !== -1 ||
               lowTxt.indexOf('uas') !== -1 ||
               lowTxt.indexOf('modul') !== -1 ||
               lowTxt.indexOf('materi') !== -1 ||
               lowTxt.indexOf('transkrip') !== -1 ||
               lowTxt.indexOf('pdf') !== -1);

            if (isDirectDocUrl || isPrintOrDocBtn) {
              var resolvedDocUrl = '';
              if (rawHref && !lowUrl.startsWith('#') && !lowUrl.startsWith('javascript:')) {
                resolvedDocUrl = toAbsoluteUrl(rawHref);
              } else {
                el.setAttribute('data-unpam-quick-doc-btn', '1');
                resolvedDocUrl = '__DOM_CLICK_DOC_BTN__';
              }

              var cleanLabel = 'Unduh Dokumen PDF';
              if (lowTxt.indexOf('krs') !== -1) cleanLabel = 'Cetak KRS';
              else if (lowTxt.indexOf('khs') !== -1) cleanLabel = 'Cetak KHS';
              else if (lowTxt.indexOf('jadwal') !== -1) cleanLabel = 'Cetak Jadwal';
              else if (lowTxt.indexOf('kartu') !== -1 || lowTxt.indexOf('ujian') !== -1) cleanLabel = 'Cetak Kartu Ujian';
              else if (lowTxt.indexOf('transkrip') !== -1) cleanLabel = 'Cetak Transkrip';
              else if (lowTxt.indexOf('modul') !== -1 || lowTxt.indexOf('materi') !== -1) cleanLabel = 'Unduh Modul';
              else if (btnTxt.length >= 4 && btnTxt.length <= 24) cleanLabel = btnTxt;

              return {
                type: 'document',
                itemCount: 1,
                label: cleanLabel,
                selectedText: '',
                documentUrl: resolvedDocUrl,
                pageUrl: href
              };
            }
          }

          // 5. Prioritas 5: Deteksi Halaman Tabel Akademik (Jadwal, KHS, Presensi, Keuangan)
          var tableRows = document.querySelectorAll('table tbody tr, table tr').length;
          if (tableRows >= 2) {
            if (lowHref.indexOf('jadwal') !== -1 || lowHeading.indexOf('jadwal') !== -1) {
              return {
                type: 'academic',
                itemCount: tableRows,
                label: 'Jadwal Kuliah',
                selectedText: '',
                documentUrl: '',
                pageUrl: href
              };
            }
            if (lowHref.indexOf('khs') !== -1 || lowHeading.indexOf('khs') !== -1 || lowHeading.indexOf('hasil studi') !== -1) {
              return {
                type: 'academic',
                itemCount: tableRows,
                label: 'KHS & Nilai',
                selectedText: '',
                documentUrl: '',
                pageUrl: href
              };
            }
            if (lowHref.indexOf('transkrip') !== -1 || lowHeading.indexOf('transkrip') !== -1) {
              return {
                type: 'academic',
                itemCount: tableRows,
                label: 'Transkrip Nilai',
                selectedText: '',
                documentUrl: '',
                pageUrl: href
              };
            }
            if (lowHref.indexOf('presensi') !== -1 || lowHref.indexOf('absensi') !== -1 || lowHeading.indexOf('presensi') !== -1 || lowHeading.indexOf('kehadiran') !== -1) {
              return {
                type: 'academic',
                itemCount: tableRows,
                label: 'Presensi Kuliah',
                selectedText: '',
                documentUrl: '',
                pageUrl: href
              };
            }
          }

          return {
            type: 'none',
            itemCount: 0,
            label: '',
            selectedText: '',
            documentUrl: '',
            pageUrl: href
          };
        } catch(e) {
          return {
            type: 'none',
            itemCount: 0,
            label: '',
            selectedText: '',
            documentUrl: '',
            pageUrl: window.location.href || ''
          };
        }
      }

      function emitIfChanged(force) {
        var ctx = scanPageContext();
        var sig = JSON.stringify(ctx);
        if (force || window.__unpamLastContextSig !== sig) {
          window.__unpamLastContextSig = sig;
          window.PageContextChannel.postMessage(sig);
        }
      }

      emitIfChanged(true);

      if (!window.__unpamContextDetectorAttached) {
        window.__unpamContextDetectorAttached = true;
        var debounceTimer = null;
        function scheduleCheck(delayMs) {
          if (debounceTimer) clearTimeout(debounceTimer);
          debounceTimer = setTimeout(function() {
            emitIfChanged(false);
          }, delayMs || 320);
        }

        document.addEventListener('selectionchange', function() {
          scheduleCheck(180);
        }, { passive: true });

        window.addEventListener('popstate', function() {
          scheduleCheck(250);
        }, { passive: true });

        window.addEventListener('hashchange', function() {
          scheduleCheck(250);
        }, { passive: true });

        try {
          var obs = new MutationObserver(function() {
            scheduleCheck(380);
          });
          obs.observe(document.documentElement || document.body, {
            childList: true,
            subtree: true
          });
        } catch(e) {}
      }
    })();
  ''';
}

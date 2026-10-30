## POST /cdn-cgi/rum

**Origin:** https://mentari.unpam.ac.id
**Observed calls:** 6
**Observed statuses:** 204
**Average duration:** 31ms

### Sample request

```json
{
  "startTime": 1793348968760,
  "pageloadId": "ddb7d723-4bf5-4bf2-8d5c-2f9605d0f7b1",
  "n": 19,
  "eventType": 1,
  "nt": "soft-navigation",
  "location": "https://mentari.unpam.ac.id/",
  "referrer": "https://mentari.unpam.ac.id/u-courses/KALENDER-AKADEMIK-20261",
  "versions": {
    "fl": "2024.11.0",
    "js": "2026.10.1",
    "timings": 1
  },
  "bi": {
    "be": "Blink",
    "bev": "156",
    "bv": "156",
    "ov": "11"
  },
  "siteToken": "7828be224af24c7dadf90c672eb15ccf",
  "st": 2
}
```

### Sample response

```json
""
```

---

## POST /g/collect

**Origin:** https://www.google-analytics.com
**Observed calls:** 1
**Observed statuses:** 204
**Average duration:** 41ms

### Sample request

```json
"en=page_view&_et=8351&dl=https%3A%2F%2Fmentari.unpam.ac.id%2Fu-courses%2F20261-04SIFE001-22SIF0183\r\nen=page_view&_et=1161&dr=https%3A%2F%2Fmentari.unpam.ac.id%2Fu-courses%2F20261-04SIFE001-22SIF0183\r\nen=page_view&_et=1402&dl=https%3A%2F%2Fmentari.unpam.ac.id%2Fu-courses%2FKALENDER-AKADEMIK-20261\r\nen=page_view&_et=1528&dr=https%3A%2F%2Fmentari.unpam.ac.id%2Fu-courses%2FKALENDER-AKADEMIK-20261"
```

### Sample response

```json
"net::ERR_ABORTED"
```

---

## GET /api/user-course/{token}

**Origin:** https://mentari.unpam.ac.id
**Observed calls:** 1
**Observed statuses:** 200
**Average duration:** 836ms

### Sample request

```json
null
```

### Sample response

```json
{
  "kode_course": "20261-04SIFE001-22SIF0183",
  "coursename": "[3] PEMROGRAMAN BERORIENTASI OBYEK (JAVA II) # 04SIFE001 (Sabtu) [E-1]",
  "haveAction": false,
  "content_type": "COURSE",
  "peserta": [
    {
      "nim": "241011750027",
      "nama_mahasiswa": "AGUN SAIFUL FAJAR",
      "alamat_email": "a**********l@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "221011700683",
      "nama_mahasiswa": "AKMALUDDIN DIANDI",
      "alamat_email": "a************4@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750005",
      "nama_mahasiswa": "ALLYA ROHALI",
      "alamat_email": "a*************6@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750184",
      "nama_mahasiswa": "AMAR MAHMUDI",
      "alamat_email": "m*************5@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750024",
      "nama_mahasiswa": "ANDREANSYAH",
      "alamat_email": "t********8@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750262",
      "nama_mahasiswa": "ARIEF ALIFIAN",
      "alamat_email": "a**************7@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "221011750180",
      "nama_mahasiswa": "ASEP MISBAHUDIN",
      "alamat_email": "a**********2@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750202",
      "nama_mahasiswa": "BOBI REGIELMA GINTING",
      "alamat_email": "b*****************5@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750055",
      "nama_mahasiswa": "CECEP RUKMANA",
      "alamat_email": "c*************a@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "231011750319",
      "nama_mahasiswa": "DEZWAL IENOE ATHALLAH",
      "alamat_email": "d*********3@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750041",
      "nama_mahasiswa": "DIMAS ALFA PRATAMA",
      "alamat_email": "d***************a@l*********.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750035",
      "nama_mahasiswa": "EKA YUSI AYUNA",
      "alamat_email": "e*************3@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750033",
      "nama_mahasiswa": "FANDI AHMAD",
      "alamat_email": "f*********9@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750034",
      "nama_mahasiswa": "FARHAN AHDIAN",
      "alamat_email": "f*************2@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750004",
      "nama_mahasiswa": "FARHAN GEMILANG",
      "alamat_email": "f**********4@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "221011750165",
      "nama_mahasiswa": "FARIZ NURRAHIM",
      "alamat_email": "f*************2@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750147",
      "nama_mahasiswa": "FAUZAN ADITYA",
      "alamat_email": "f************2@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750158",
      "nama_mahasiswa": "FAUZI FALENTINO SAPUTRA",
      "alamat_email": "f*****************6@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "221011750016",
      "nama_mahasiswa": "INDRA KOSASIH",
      "alamat_email": "i*************8@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750283",
      "nama_mahasiswa": "INTAN PUTRI HAMUMPUNI",
      "alamat_email": "i*************i@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750218",
      "nama_mahasiswa": "IPRANSA TURNIP",
      "alamat_email": "i***********p@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750243",
      "nama_mahasiswa": "ISTIFA ZAHRA",
      "alamat_email": "i************6@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750223",
      "nama_mahasiswa": "LULU FAUZIA",
      "alamat_email": "l*********4@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750057",
      "nama_mahasiswa": "MIA HARMIATI",
      "alamat_email": "m*********8@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750032",
      "nama_mahasiswa": "MUHAMAD ALAWI",
      "alamat_email": "m***********5@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750140",
      "nama_mahasiswa": "MUHAMAD HASBI",
      "alamat_email": "h*********3@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "221011750037",
      "nama_mahasiswa": "MUHAMAD NURRIDWAN",
      "alamat_email": "M************7@G****.COM",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "221011700649",
      "nama_mahasiswa": "MUHAMMAD ILHAM",
      "alamat_email": "m****************5@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750090",
      "nama_mahasiswa": "MUKHAMMAD QAIDAL GHURRAL MUHAJJALIN",
      "alamat_email": "m**************l@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750061",
      "nama_mahasiswa": "NABILA AMANDA PUTRI JOHAN",
      "alamat_email": "n*************j@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750123",
      "nama_mahasiswa": "NADA ADZANI RAMADHANU",
      "alamat_email": "a*********a@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750191",
      "nama_mahasiswa": "NAILA RAISYA",
      "alamat_email": "n********o@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "221011700778",
      "nama_mahasiswa": "PAVIANTO YURAS OKTORA",
      "alamat_email": "o*******p@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750115",
      "nama_mahasiswa": "RENALDI FIRMANSHYAH ARDANI",
      "alamat_email": "r*************h@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750022",
      "nama_mahasiswa": "RIFKI FIRMANSYAH",
      "alamat_email": "p****************5@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750007",
      "nama_mahasiswa": "RISYAD RAMADHAN",
      "alamat_email": "r*********1@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750248",
      "nama_mahasiswa": "ROZI DIAN OKTAVIAN",
      "alamat_email": "r*******n@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750165",
      "nama_mahasiswa": "SITI MUTHMAINNAH NURDZAKIYYAH",
      "alamat_email": "m********7@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750037",
      "nama_mahasiswa": "SOFI AMALIA",
      "alamat_email": "s***********0@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750189",
      "nama_mahasiswa": "TASYA PUTRI AMANDA",
      "alamat_email": "t*****************9@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750008",
      "nama_mahasiswa": "VICKY SUKAMTO",
      "alamat_email": "v*************3@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750193",
      "nama_mahasiswa": "VIKA SYAHKIRINA",
      "alamat_email": "v***************8@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750036",
      "nama_mahasiswa": "VIKKA PUTRI HERLIAN",
      "alamat_email": "v************4@g****.com",
      "no_hp_mahasiswa": "-"
    },
    {
      "nim": "241011750144",
      "nama_mahasiswa": "YEIRA JUNIA NATHANAEL",
      "alamat_email": "j******a@g****.com",
      "no_hp_mahasiswa": "-"
    }
  ],
  "data": [
    {
      "kode_section": "GENERAL",
      "sort": 1,
      "nama_section": "General",
      "nama_pertemuan": null,
      "sub_section": [
        {
          "id": "7b9ccf01-6f58-4936-b03a-ec621f58e021",
          "tipe": "LINK",
          "kode_template": "RPS",
          "sort": 1,
          "judul": "RPS",
          "konten": "Mahasiswa mampu mengetahui konsep dasar pemrograman berorientasi object (PBO) dalam melakukan transformasi data menjadi informasi, serta mahasiswa mampu melakukan pengembangan aplikasi berbasis desktop dan web",
          "link": "https://sakura.unpam.ac.id/api/file/603fbd5b-e1e2-4bde-98f1-4940d2f84e74",
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_1",
      "sort": 2,
      "nama_section": "Pertemuan 1",
      "nama_pertemuan": "Pertemuan 1",
      "sub_section": [
        {
          "id": "a8ad0755-6a13-4ce0-bd0a-f7bf4bd1d290",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "260dc014-d404-4cd7-966d-057147463b69",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": "https://sakura.unpam.ac.id/api/file/6ba0c256-7fa7-46b5-abf5-99627e54b8d3",
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "d5100dc1-5af7-4d3c-a7ab-c9400c2f3159",
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": "https://sakura.unpam.ac.id/api/file/149eeb48-61d9-4160-9c77-c9bb036df236",
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "5cb30d31-61e1-4e38-9464-df585480b53b",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_2",
      "sort": 3,
      "nama_section": "Pertemuan 2",
      "nama_pertemuan": "Pertemuan 2",
      "sub_section": [
        {
          "id": "dac26117-75dc-45ce-b7f7-cf02aa0fe73e",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "f212ce8b-2f47-42b6-9f4d-29f7d6f7d883",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": "https://sakura.unpam.ac.id/api/file/be93e591-9141-4d49-8a1a-7e8d21fd6b2c",
          "file": null,
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "438736ad-26b1-4678-81b1-0ecc0c104a5d",
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": "https://sakura.unpam.ac.id/api/file/7b01190d-992a-42fd-b51f-750814fff87a",
          "file": null,
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "3b092223-e97a-4a36-8967-fc194a2349f1",
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "<p>P2 Tugas Pizza Order </p>",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-14T13:19:50.078Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "23687471-f67b-4bdc-9a06-0333b2ef4ca4",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_3",
      "sort": 4,
      "nama_section": "Pertemuan 3",
      "nama_pertemuan": "Pertemuan 3",
      "sub_section": [
        {
          "id": "052c5420-8de9-4f9f-a8b6-61e61665bb52",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "b139d1b3-ecd1-4650-8cde-68c831588ed9",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": "https://sakura.unpam.ac.id/api/file/7fda5fe2-2c45-40d6-bdb8-9321e090424e",
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "31b22ba9-43d4-4427-90b7-e16764952985",
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": "https://sakura.unpam.ac.id/api/file/05e1442e-33ab-428b-92d9-ccac975d4fad",
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": "bc9442fe-26c2-4e81-b21e-8b9b2456498c",
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "<p>Bekerja dengan jComboBox dan jListBox </p>",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-07T15:15:00.622Z"
        },
        {
          "id": "6689c4c5-32a8-4659-ac35-c1414ce74a72",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "7199c283-b802-463b-8b7f-66fb94c4adc4",
          "tipe": "QUESIONER",
          "kode_template": "KUESIONER",
          "sort": 99,
          "judul": "Kuesioner",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-07T23:44:22.040Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_4",
      "sort": 5,
      "nama_section": "Pertemuan 4",
      "nama_pertemuan": "Pertemuan 4",
      "sub_section": [
        {
          "id": "229f9cce-311c-4a47-b52b-ef9c154f908d",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "da0516e1-8e5f-4b9e-a176-dd02a1fdbf5e",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": "https://sakura.unpam.ac.id/api/file/753f5246-4953-448f-ab52-e8882d6f3f57",
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "d5f2b669-3a52-4889-8a7d-66c022923488",
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": "https://sakura.unpam.ac.id/api/file/cd414f78-3daf-4d83-9f00-558f1e66f2e1",
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "6cc38509-edaf-4efd-a69f-ff953dcdea26",
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "<p>P4 Bidang Datar dengan ShowInputDialog </p>",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-22T14:52:19.527Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "111da8b1-9540-4e5f-9c14-b27deb98d123",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_5",
      "sort": 6,
      "nama_section": "Pertemuan 5",
      "nama_pertemuan": "Pertemuan 5",
      "sub_section": [
        {
          "id": "ccd76ee0-6b18-47fe-9594-6580074fe19b",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "f41c7160-57b3-495d-95a2-d608d711c6f2",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "46eaf893-40c8-4395-a824-6af646bad894",
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "2deafe99-efe8-438d-a984-03bd41b7260c",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_6",
      "sort": 7,
      "nama_section": "Pertemuan 6",
      "nama_pertemuan": "Pertemuan 6",
      "sub_section": [
        {
          "id": "63c9c6cf-dad5-403d-8bbe-7576df72856c",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "a26b649c-85a0-462d-9326-cc41a39a6a51",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": "https://sakura.unpam.ac.id/api/file/ae367bed-6223-410b-9aba-261329b5518f",
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "f621a44b-5ae2-49bc-82df-a1cf7becc174",
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": "https://sakura.unpam.ac.id/api/file/bdb2ac88-105d-4f56-916e-d12665ce5ed8",
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": "6d94db64-ddbd-4766-9204-19b0923668f5",
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "<p>P6 Bekerja dengan Menu dan PopUp Menu</p>",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-21T12:38:38.388Z"
        },
        {
          "id": "eaaf9d9c-3433-403c-af85-b784880e985a",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "136d4148-b225-4b61-be17-818fc9e0b6a8",
          "tipe": "QUESIONER",
          "kode_template": "KUESIONER",
          "sort": 99,
          "judul": "Kuesioner",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-21T13:01:32.218Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_7",
      "sort": 8,
      "nama_section": "Pertemuan 7",
      "nama_pertemuan": "Pertemuan 7",
      "sub_section": [
        {
          "id": "0505ef64-87a5-4e60-b28f-55b601f45280",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "24234099-47bf-4b40-b3fd-f63f7b968845",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "e9ce3eeb-25ba-4a24-a8bf-a09a9009adf0",
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "b9f63a7a-99d3-4676-b1f2-da97f6dd54ff",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_8",
      "sort": 9,
      "nama_section": "Pertemuan 8",
      "nama_pertemuan": "Pertemuan 8",
      "sub_section": [
        {
          "id": "63c83e3b-45d4-4c1e-85d9-d18094b91855",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "5fd5a2f1-4d45-43fe-8ffc-4b37e8b746ca",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "5c795dc2-1d8a-427f-8cb5-18cc88898559",
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "df417f19-7f32-420b-9980-ac5f7f55ab92",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_9",
      "sort": 10,
      "nama_section": "Pertemuan 9",
      "nama_pertemuan": "Pertemuan 9",
      "sub_section": [
        {
          "id": "bf0255bd-a7d5-43fc-995d-3e3059bee574",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "29a54789-28a7-4ec6-aca0-bea213d23582",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "1231c6c4-6a8b-4223-b1f0-a0fb744235b4",
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": "32373eaf-5a04-4a6f-9323-a987f9acbe18",
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "<p>P9 Bekerja dengan Image Icon </p>",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-10-05T12:11:22.026Z"
        },
        {
          "id": "dad731e4-ac4f-4d7f-9b3f-7ecc2110bec6",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_10",
      "sort": 11,
      "nama_section": "Pertemuan 10",
      "nama_pertemuan": "Pertemuan 10",
      "sub_section": [
        {
          "id": "efbdd74e-6f8e-421d-bf58-a0bba3cbadfa",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "9dc9760c-1810-4467-b178-9868a5ee6c96",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "93d93b28-2d2e-48da-9b87-1b6b14dde94d",
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": "0aeca17a-5554-4e0b-bab1-15dbc61da760",
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "<p>P10 Java Database </p>",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-10-12T14:56:31.607Z"
        },
        {
          "id": "1ff40c65-8a69-4de4-81f2-6eeec985c4e7",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_11",
      "sort": 13,
      "nama_section": "Pertemuan 11",
      "nama_pertemuan": "Pertemuan 11",
      "sub_section": [
        {
          "id": "7c657c59-0718-423b-9d95-798b40ce2de5",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "58f6fd3e-8a44-4079-9978-cdc2608c09c6",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "5f4ac427-6712-4d6e-b75d-f21f199aa772",
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": "a09326d5-a764-4b04-83d8-4019d6015052",
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "<p>P11 Table, Record, Column JDBC </p>",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-10-26T13:32:55.964Z"
        },
        {
          "id": "2a7bb7ce-eb51-4a78-9f91-ad6b7db1fc5a",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_12",
      "sort": 14,
      "nama_section": "Pertemuan 12",
      "nama_pertemuan": "Pertemuan 12",
      "sub_section": [
        {
          "id": "198ad45c-e180-4c67-9de2-4e9058f36692",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "8e90e5f7-0eeb-42ab-886b-5db441038e64",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "71074e8e-5d82-49f1-ae2a-b35a6fedde46",
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": "5c0b4c13-ae3c-42fc-8511-c6e5005dc2f0",
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "<p>P12 Structured Query Language </p>",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-10-26T13:44:45.649Z"
        },
        {
          "id": "90b2d7c7-ecca-4f52-87b1-e96e1e2336ac",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_13",
      "sort": 15,
      "nama_section": "Pertemuan 13",
      "nama_pertemuan": null,
      "sub_section": [
        {
          "id": "28f33744-eb34-45fe-a593-2fd567efed07",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "85eb5482-e7e6-40af-9d6e-ff84ff523269",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "5b369637-61f3-4e79-a107-29d8513e51c9",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_14",
      "sort": 16,
      "nama_section": "Pertemuan 14",
      "nama_pertemuan": null,
      "sub_section": [
        {
          "id": "4db8a7a4-8871-43e0-a1da-d2191376bc30",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "d5d12d4e-4723-49f6-a697-b7e85083b269",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "be284859-485f-4557-8f5a-b8903eab1ae7",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_15",
      "sort": 17,
      "nama_section": "Pertemuan 15",
      "nama_pertemuan": null,
      "sub_section": [
        {
          "id": "4809f109-5793-4213-a1f6-937a7708fce0",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "5c4978bd-d222-47bf-96b2-e26bcc47cb5c",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "fd5261a1-cedb-4613-b521-f7bb392889c3",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_16",
      "sort": 18,
      "nama_section": "Pertemuan 16",
      "nama_pertemuan": null,
      "sub_section": [
        {
          "id": "42b68356-3bb3-484e-bee2-cc6d9957d794",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "47ac3ed3-f650-4d11-856d-171ff5600d60",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "93cbb0ff-549f-442e-b297-21ab720e3a9e",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_17",
      "sort": 19,
      "nama_section": "Pertemuan 17",
      "nama_pertemuan": null,
      "sub_section": [
        {
          "id": "60eacd98-3741-4bf2-885e-4d9d5a174c73",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "a36dd406-d579-4443-8fad-823e8954a693",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "500850c0-5ca7-4c5d-b65e-cfe1fdd3e91b",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_18",
      "sort": 20,
      "nama_section": "Pertemuan 18",
      "nama_pertemuan": null,
      "sub_section": [
        {
          "id": "fc8f9ed7-6b59-487e-addd-7971e8aaf19a",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": "c56363f2-60cc-4e2b-b0fa-0b2b1d46012f",
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "1dfaaa51-ded5-41eb-ae13-7f7988efb312",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_19",
      "sort": 21,
      "nama_section": "Pertemuan 19",
      "nama_pertemuan": null,
      "sub_section": [
        {
          "id": "9a220c86-a084-476e-827f-a47c4b9782e4",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "d46e85f1-c6c5-43ac-acad-383a6c85d228",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_20",
      "sort": 22,
      "nama_section": "Pertemuan 20",
      "nama_pertemuan": null,
      "sub_section": [
        {
          "id": "ce7dd065-2868-4666-9686-59881256fcdc",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "be91e689-5a65-4d51-a2a6-c9b830d8da5b",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Silakan selesaikan \"Pretest\" terlebih dahulu",
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    },
    {
      "kode_section": "PERTEMUAN_21",
      "sort": 23,
      "nama_section": "Pertemuan 21",
      "nama_pertemuan": null,
      "sub_section": [
        {
          "id": "72044150-12ac-4eff-9aa2-065c54b46f9c",
          "tipe": "QUIZ",
          "kode_template": "PRE_TEST",
          "sort": 1,
          "judul": "Pretest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": true,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "BUKU_ISBN",
          "sort": 2,
          "judul": "Buku ISBN",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "VIDEO_AJAR",
          "sort": 3,
          "judul": "Video Ajar",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "POWER_POINT",
          "sort": 4,
          "judul": "Power Point",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "ARTIKEL_RISET",
          "sort": 5,
          "judul": "Artikel Riset",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "RESOURCE",
          "kode_template": "MATERI_LAINNYA",
          "sort": 6,
          "judul": "Materi Lainnya",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "ASSIGNMENT",
          "kode_template": "PENUGASAN_TERSTRUKTUR",
          "sort": 7,
          "judul": "Penugasan Terstruktur",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "LINK",
          "kode_template": "LINK_VCON",
          "sort": 8,
          "judul": "LINK VCON",
          "konten": "<p>Berikut adalah Link VCON untuk Pertemuan ini</p>",
          "link": "https://meet.google.com",
          "file": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-03-02T06:36:02.089Z"
        },
        {
          "id": null,
          "tipe": "FORUM",
          "kode_template": "FORUM_DISKUSI",
          "sort": 9,
          "judul": "Forum Diskusi",
          "konten": "",
          "link": null,
          "file": null,
          "completion": false,
          "haveAction": false,
          "warningAlert": "Soal forum diskusi belum tersedia, silahkan menghubungi dosen pengampu mata kuliah",
          "createdAt": "2024-10-30T07:36:02.089Z"
        },
        {
          "id": "0e9c37a3-a1f7-44bb-a7d0-0f0cb05f8ecb",
          "tipe": "QUIZ",
          "kode_template": "POST_TEST",
          "sort": 9,
          "judul": "Posttest",
          "konten": "<p>QUIZ</p>",
          "link": null,
          "file": null,
          "setting_quiz": {
            "tipe_quiz": "MULTIPLE_CHOICE",
            "one_page_per_question": true,
            "duration": 60,
            "shuffle_soal": false,
            "shuffle_jawaban": true
          },
          "setting_availability": null,
          "completion": false,
          "haveAction": false,
          "createdAt": "2026-09-06T13:01:22.259Z"
        }
      ],
      "createdAt": "2024-05-28T08:01:35.436Z"
    }
  ]
}
```
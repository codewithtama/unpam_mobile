import '../../models/academic_grades_model.dart';
import '../../models/attendance_model.dart';
import '../../models/finance_model.dart';
import '../../models/lecture_schedule_model.dart';
import '../../models/seminar_certificate_model.dart';
import '../../models/student_biodata_model.dart';

class PortalAiText {
  static String biodata(StudentBiodata? b) {
    if (b == null) return '';
    return [
      'Nama: ${b.namaMahasiswa}',
      'NIM: ${b.nim}',
      'Program studi: ${b.programStudi?.namaProdi ?? '-'} (${b.programStudi?.fakultas?.namaFakultas ?? '-'})',
      'Semester: ${b.semester ?? '-'}, kelas ${b.idKelas ?? '-'}, ${b.shift?.namaShift ?? '-'}',
      'IPK berjalan: ${b.ipkSemesterBerjalan ?? '-'}, total SKS: ${b.sksSemesterBerjalan ?? '-'}',
      'Status: ${b.statusMahasiswa?.namaStatusMahasiswa ?? '-'}',
    ].join('\n');
  }

  static String grades(AcademicGradesResponse? g) {
    if (g == null) return '';
    final buffer = StringBuffer()
      ..writeln('IPK: ${g.ipk}')
      ..writeln(
          'SKS lulus: ${g.mutu?.totalSksPassed ?? '-'} dari ${g.mutu?.totalSksTaken ?? '-'} SKS diambil');
    g.groupedBySemester.forEach((semester, courses) {
      buffer.writeln(
          '\nSemester $semester (IPS ${g.calculateSemesterGpa(semester).toStringAsFixed(2)}, ${g.calculateSemesterSks(semester)} SKS):');
      for (final c in courses) {
        buffer.writeln('- ${c.snama} (${c.sks} SKS): ${c.fgrade}');
      }
    });
    return buffer.toString();
  }

  static String schedule(LectureScheduleResponse? s) {
    if (s == null) return '';
    final buffer = StringBuffer();
    if (s.semester != null) buffer.writeln('Semester: ${s.semester!.namaSemesterRegistrasi}');
    s.groupedByDay.forEach((day, items) {
      buffer.writeln('\n$day:');
      for (final i in items) {
        buffer.writeln(
            '- ${i.timeRange} ${i.namaMataKuliah} | ${i.lecturerDisplayName} | ${i.isOnline ? 'Daring' : i.locationRoom}');
      }
    });
    return buffer.toString();
  }

  static String attendance(
    List<AttendanceCourseItem>? courses,
    List<AttendanceMeetingItem>? Function(AttendanceCourseItem course) meetingsOf,
  ) {
    if (courses == null) return '';
    final buffer = StringBuffer();
    if (courses.isNotEmpty) buffer.writeln('Semester: ${courses.first.namaSemesterRegistrasi}');
    for (final c in courses) {
      final meetings = meetingsOf(c);
      if (meetings == null) {
        buffer.writeln('- ${c.namaMataKuliah} (${c.sks} SKS): detail presensi belum dibuka');
      } else {
        final s = AttendanceSummary(meetings);
        buffer.writeln(
            '- ${c.namaMataKuliah}: hadir ${s.attended}, absen ${s.absent}, belum ${s.upcoming} dari ${s.total} pertemuan (${s.percentage.toStringAsFixed(0)}%)');
      }
    }
    return buffer.toString();
  }

  static String certificates(List<SeminarCertificateItem>? items) {
    if (items == null) return '';
    if (items.isEmpty) return 'Belum ada riwayat seminar atau sertifikat.';
    return items
        .map((c) =>
            '- ${c.namaEvent} (${c.jenisEvent ?? '-'}, ${c.formattedDate}): ${c.isVerified ? 'sertifikat terverifikasi' : 'belum terverifikasi'}')
        .join('\n');
  }

  static String finance(FinanceResponse? f) {
    if (f == null) return '';
    final unpaid = [...f.billings, ...f.otherBillings, ...f.spBillings].where((b) => !b.isPaid);
    final buffer = StringBuffer()
      ..writeln('Semester: ${f.semester?.namaSemesterRegistrasi ?? '-'}')
      ..writeln('Total tagihan: ${f.formatCurrency(f.totalBillingAmount)}')
      ..writeln('Sudah dibayar: ${f.formatCurrency(f.totalPaidAmount)}')
      ..writeln('Sisa tagihan: ${f.formatCurrency(f.totalUnpaidAmount)}');
    if (unpaid.isNotEmpty) {
      buffer.writeln('\nTagihan belum lunas:');
      for (final b in unpaid) {
        buffer.writeln('- ${b.keterangan}: ${b.formattedTotal}');
      }
    }
    return buffer.toString();
  }
}

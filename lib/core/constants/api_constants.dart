class ApiConstants {
  // Base URLs
  static const String mentariBaseUrl = 'https://mentari.unpam.ac.id/api';
  static const String sakuraBaseUrl = 'https://sakura.unpam.ac.id/api';

  // Endpoints Mentari
  static const String userCourses = '/user-course';
  static const String login = '/auth/login';

  // Endpoints Sakura
  static String courseDetail(String kodeCourse) => '/course/$kodeCourse';
  static String fileDownload(String fileUuid) => '$sakuraBaseUrl/file/$fileUuid';

  // Demo Credentials & Mahasiswa Default (Dimas Alfa Pratama - 04SIFE001)
  static const String defaultNim = '241011750041';
  static const String defaultNama = 'DIMAS ALFA PRATAMA';
  static const String defaultKelas = '04SIFE001';
  static const String defaultSemester = '20261';

  // Mock Asset Paths for Offline Demo
  static const String mockUserCoursesPath = 'assets/mock/user_courses.json';
  static const String mockCourseDetailPath = 'assets/mock/course_detail_jaringan_komputer.json';

  // Storage Keys
  static const String tokenKey = 'unpam_bearer_token';
  static const String nimKey = 'unpam_student_nim';
  static const String studentNameKey = 'unpam_student_name';
  static const String useMockKey = 'unpam_use_mock_data';
}

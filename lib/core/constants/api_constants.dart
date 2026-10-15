class ApiConstants {
  static const String mentariBaseUrl = 'https://mentari.unpam.ac.id/api';
  static const String sakuraBaseUrl = 'https://sakura.unpam.ac.id/api';

  static const String userCourses = '/user-course';
  static const String login = '/auth/login';

  static String courseDetail(String kodeCourse) => '/course/$kodeCourse';
  static String fileDownload(String fileUuid) => '$sakuraBaseUrl/file/$fileUuid';

  static const String tokenKey = 'unpam_bearer_token';
  static const String nimKey = 'unpam_student_nim';
  static const String studentNameKey = 'unpam_student_name';
  static const String geminiApiKey = 'unpam_gemini_api_key';
}

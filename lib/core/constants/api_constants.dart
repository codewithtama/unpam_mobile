class ApiConstants {
  static const String mentariBaseUrl = 'https://mentari.unpam.ac.id';

  static const String tokenKey = 'unpam_bearer_token';
  static const String cookiesKey = 'unpam_cookies';

  static const String webViewUserAgent =
      'Mozilla/5.0 (Linux; Android 13; SM-S918B) AppleWebKit/537.36 (KHTML, like Gecko) Chrome/128.0.6613.127 Mobile Safari/537.36';

  static const String satuUnpamBaseUrl = 'https://satu.unpam.ac.id';
  static const String myUnpamBaseUrl = 'https://my.unpam.ac.id';
  static const String satuUnpamTokenKey = 'satuunpam_bearer_token';
  static const String satuUnpamCookiesKey = 'satuunpam_cookies';
  static const String myUnpamTokenKey = 'myunpam_bearer_token';
  static const String myUnpamCookiesKey = 'myunpam_cookies';
  static const String myUnpamCachedKeuanganKey = 'myunpam_cached_keuangan';
  static const String myUnpamCachedSemesterKey = 'myunpam_cached_semester';
  static const String myUnpamCachedSemestersListKey = 'myunpam_cached_semesters_list';
  static const String myUnpamCachedBiodataKey = 'myunpam_cached_biodata';
  static const String myUnpamCachedGradesKey = 'myunpam_cached_grades';
  static const String myUnpamCachedScheduleKey = 'myunpam_cached_schedule';
  static const String myUnpamCachedCertificatesKey = 'myunpam_cached_certificates';
  static const String myUnpamCachedAttendanceCoursesKey = 'myunpam_cached_attendance_courses';

  static const List<String> myUnpamCacheKeys = [
    myUnpamCachedKeuanganKey,
    myUnpamCachedSemesterKey,
    myUnpamCachedSemestersListKey,
    myUnpamCachedBiodataKey,
    myUnpamCachedGradesKey,
    myUnpamCachedScheduleKey,
    myUnpamCachedCertificatesKey,
    myUnpamCachedAttendanceCoursesKey,
  ];

  static const String userAgreementKey = 'unpam_user_agreement_accepted';
  static const String accountOnboardingDoneKey = 'unpam_account_onboarding_done';
  static const String biometricAutoLoginEnabledKey = 'unpam_biometric_auto_login_enabled';
  static const String biometricPromptDismissedKey = 'unpam_biometric_prompt_dismissed';
  static const String secureNimKey = 'unpam_secure_nim';
  static const String securePasswordKey = 'unpam_secure_password';

  // AI Configuration Keys
  static const String activeAiModelKey = 'unpam_active_ai_model';
  static const String geminiApiKey = 'unpam_gemini_api_key';
  static const String deepseekApiKey = 'unpam_deepseek_api_key';
  static const String claudeApiKey = 'unpam_claude_api_key';
  static const String qwenApiKey = 'unpam_qwen_api_key';
  static const String openaiApiKey = 'unpam_openai_api_key';
  static const String openrouterApiKey = 'unpam_openrouter_api_key';

  // Schedule & Deadline Tracker Keys
  static const String scheduleCacheKey = 'unpam_schedule_cache_v1';
  static const String deadlineCacheKey = 'unpam_deadline_cache_v1';
  static const String scheduleLastSyncKey = 'unpam_schedule_last_sync';
  static const String deadlineLastSyncKey = 'unpam_deadline_last_sync';
  static const String scheduledReminderIdsKey = 'unpam_scheduled_reminder_ids';
}

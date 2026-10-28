class ApiConstants {
  static const String mentariBaseUrl = 'https://mentari.unpam.ac.id';

  static const String tokenKey = 'unpam_bearer_token';
  static const String cookiesKey = 'unpam_cookies';
  static const String userAgreementKey = 'unpam_user_agreement_accepted';
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

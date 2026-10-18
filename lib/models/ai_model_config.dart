enum AiProviderType {
  gemini,
  deepseek,
  claude,
  qwen,
  openai,
  openrouter,
  freeCloud,
}

class AiModelOption {
  final String id;
  final String name;
  final String shortName;
  final String description;
  final AiProviderType provider;
  final bool supportsVision;
  final String defaultModelId;
  final String apiKeyDocsUrl;

  const AiModelOption({
    required this.id,
    required this.name,
    required this.shortName,
    required this.description,
    required this.provider,
    required this.supportsVision,
    required this.defaultModelId,
    required this.apiKeyDocsUrl,
  });

  static const List<AiModelOption> availableModels = [
    AiModelOption(
      id: 'free_cloud',
      name: 'The PAMs Cloud AI (Gratis)',
      shortName: 'Cloud AI',
      description: 'Bebas kuota, tanpa API key. Cepat untuk tanya jawab umum, diskusi & tugas perkuliahan.',
      provider: AiProviderType.freeCloud,
      supportsVision: false,
      defaultModelId: 'openai-fast',
      apiKeyDocsUrl: '',
    ),
    AiModelOption(
      id: 'gemini',
      name: 'Google Gemini 3.7 Flash / 3.5 Pro',
      shortName: 'Gemini 3.7',
      description: 'Flagship Google terbaru (Okt 2026) dengan Vision OCR ultra-cepat untuk screenshot soal kuis & penalaran multimodal.',
      provider: AiProviderType.gemini,
      supportsVision: true,
      defaultModelId: 'gemini-3.7-flash',
      apiKeyDocsUrl: 'https://aistudio.google.com/app/apikey',
    ),
    AiModelOption(
      id: 'deepseek',
      name: 'DeepSeek V4 (Flash / Pro / R2)',
      shortName: 'DeepSeek V4',
      description: 'Generasi V4 & R2 terbaru dengan 1M token context, penalaran mendalam untuk algoritma, coding, matematika & logika.',
      provider: AiProviderType.deepseek,
      supportsVision: false,
      defaultModelId: 'deepseek-v4-flash',
      apiKeyDocsUrl: 'https://platform.deepseek.com/api_keys',
    ),
    AiModelOption(
      id: 'claude',
      name: 'Anthropic Claude Sonnet 5.5 / Opus 5.5',
      shortName: 'Claude 5.5',
      description: 'Generasi 5.5 terkini dengan penalaran akademik multi-step terbaik, analisis jurnal & Vision OCR.',
      provider: AiProviderType.claude,
      supportsVision: true,
      defaultModelId: 'claude-sonnet-5-5',
      apiKeyDocsUrl: 'https://console.anthropic.com/settings/keys',
    ),
    AiModelOption(
      id: 'qwen',
      name: 'Alibaba Qwen 3.8-Max / 3.7-Max',
      shortName: 'Qwen 3.8',
      description: 'Flagship terbaru Alibaba Cloud Model Studio (Okt 2026) dengan kecakapan analitis & multibahasa tingkat lanjut.',
      provider: AiProviderType.qwen,
      supportsVision: false,
      defaultModelId: 'qwen3.8-max',
      apiKeyDocsUrl: 'https://dashscope.console.aliyun.com/',
    ),
    AiModelOption(
      id: 'openai',
      name: 'OpenAI GPT-5.5 / o4-mini',
      shortName: 'GPT-5.5',
      description: 'Model flagship terbaru OpenAI dengan penalaran o4-series & pemahaman Vision multimodal presisi tinggi.',
      provider: AiProviderType.openai,
      supportsVision: true,
      defaultModelId: 'gpt-5.5-mini',
      apiKeyDocsUrl: 'https://platform.openai.com/api-keys',
    ),
    AiModelOption(
      id: 'openrouter',
      name: 'OpenRouter (All-in-One Hub 2026)',
      shortName: 'OpenRouter',
      description: 'Satu API Key untuk ratusan model terbaru (DeepSeek V4, Claude 5.5, Gemini 3.7, GPT-5.5, Qwen 3.8).',
      provider: AiProviderType.openrouter,
      supportsVision: true,
      defaultModelId: 'deepseek/deepseek-v4-flash',
      apiKeyDocsUrl: 'https://openrouter.ai/keys',
    ),
  ];

  static AiModelOption getById(String id) {
    return availableModels.firstWhere(
      (m) => m.id == id,
      orElse: () => availableModels.first, // Fallback to free_cloud
    );
  }
}

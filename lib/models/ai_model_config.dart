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
      name: 'The PAMs Cloud AI',
      shortName: 'Cloud AI',
      description: 'Bebas kuota, tanpa API key. Cepat untuk tanya jawab umum & tugas perkuliahan.',
      provider: AiProviderType.freeCloud,
      supportsVision: false,
      defaultModelId: 'openai-fast',
      apiKeyDocsUrl: '',
    ),
    AiModelOption(
      id: 'gemini',
      name: 'Google Gemini 3.7 / 3.5 Flash',
      shortName: 'Gemini',
      description: 'Model Google terbaru dengan Vision OCR canggih untuk screenshot soal kuis & kecepatan ultra tinggi.',
      provider: AiProviderType.gemini,
      supportsVision: true,
      defaultModelId: 'gemini-3.7-flash',
      apiKeyDocsUrl: 'https://aistudio.google.com/app/apikey',
    ),
    AiModelOption(
      id: 'deepseek',
      name: 'DeepSeek V4 (Flash / Pro)',
      shortName: 'DeepSeek',
      description: 'Generasi V4 terbaru dengan 1M token context, penalaran mendalam untuk coding, matematika & logika.',
      provider: AiProviderType.deepseek,
      supportsVision: false,
      defaultModelId: 'deepseek-v4-flash',
      apiKeyDocsUrl: 'https://platform.deepseek.com/api_keys',
    ),
    AiModelOption(
      id: 'claude',
      name: 'Anthropic Claude Sonnet 5.5 / Opus 5.5',
      shortName: 'Claude',
      description: 'Generasi 5.5 terkini dengan penalaran multi-step terbaik, analisis jurnal & pemahaman konteks luas.',
      provider: AiProviderType.claude,
      supportsVision: true,
      defaultModelId: 'claude-sonnet-5-5',
      apiKeyDocsUrl: 'https://console.anthropic.com/settings/keys',
    ),
    AiModelOption(
      id: 'qwen',
      name: 'Alibaba Qwen 3.8-Max / 3.7-Max',
      shortName: 'Qwen',
      description: 'Flagship terbaru Alibaba Cloud Model Studio dengan kecakapan komprehensif & multibahasa.',
      provider: AiProviderType.qwen,
      supportsVision: false,
      defaultModelId: 'qwen3.8-max',
      apiKeyDocsUrl: 'https://dashscope.console.aliyun.com/',
    ),
    AiModelOption(
      id: 'openai',
      name: 'OpenAI GPT-4o / GPT-4o-mini',
      shortName: 'ChatGPT',
      description: 'Model serbaguna dari OpenAI dengan pemahaman multimodal yang akurat.',
      provider: AiProviderType.openai,
      supportsVision: true,
      defaultModelId: 'gpt-4o-mini',
      apiKeyDocsUrl: 'https://platform.openai.com/api-keys',
    ),
    AiModelOption(
      id: 'openrouter',
      name: 'OpenRouter (All-in-One Hub)',
      shortName: 'OpenRouter',
      description: 'Satu API Key untuk ratusan model dengan format provider/model (DeepSeek V4, Claude 5.5, Gemini 3.7).',
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

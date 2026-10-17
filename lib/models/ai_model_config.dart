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
      name: 'UNPAM Cloud AI',
      shortName: 'Cloud AI',
      description: 'Bebas kuota, tanpa API key. Cepat untuk tanya jawab umum & tugas perkuliahan.',
      provider: AiProviderType.freeCloud,
      supportsVision: false,
      defaultModelId: 'openai-fast',
      apiKeyDocsUrl: '',
    ),
    AiModelOption(
      id: 'gemini',
      name: 'Google Gemini 2.5 Flash',
      shortName: 'Gemini',
      description: 'Vision OCR canggih untuk screenshot soal kuis & kecepatan respons tinggi.',
      provider: AiProviderType.gemini,
      supportsVision: true,
      defaultModelId: 'gemini-2.5-flash',
      apiKeyDocsUrl: 'https://aistudio.google.com/app/apikey',
    ),
    AiModelOption(
      id: 'deepseek',
      name: 'DeepSeek-V3 / R1 (Reasoner)',
      shortName: 'DeepSeek',
      description: 'Penalaran mendalam (deep thinking), sangat unggul untuk coding, matematika & logika.',
      provider: AiProviderType.deepseek,
      supportsVision: false,
      defaultModelId: 'deepseek-chat',
      apiKeyDocsUrl: 'https://platform.deepseek.com/api_keys',
    ),
    AiModelOption(
      id: 'claude',
      name: 'Anthropic Claude 3.5 Sonnet',
      shortName: 'Claude',
      description: 'Penulisan esai akademis bernalar tinggi, analisis jurnal & pemahaman konteks luas.',
      provider: AiProviderType.claude,
      supportsVision: true,
      defaultModelId: 'claude-3-5-sonnet-20241022',
      apiKeyDocsUrl: 'https://console.anthropic.com/settings/keys',
    ),
    AiModelOption(
      id: 'qwen',
      name: 'Alibaba Qwen 2.5 (72B / Coder)',
      shortName: 'Qwen',
      description: 'Model terdepan berbahasa Indonesia & multibahasa dari Alibaba Cloud.',
      provider: AiProviderType.qwen,
      supportsVision: false,
      defaultModelId: 'qwen-plus',
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
      description: 'Satu API Key untuk ratusan model sekaligus (Claude, DeepSeek R1, Llama 3.3, Qwen).',
      provider: AiProviderType.openrouter,
      supportsVision: true,
      defaultModelId: 'deepseek/deepseek-r1:free',
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

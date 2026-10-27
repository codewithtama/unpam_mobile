enum ParaphraseMode {
  academic,
  humanizer,
  concise,
  expansive,
}

extension ParaphraseModeExtension on ParaphraseMode {
  String get title {
    switch (this) {
      case ParaphraseMode.academic:
        return 'Akademis & Baku';
      case ParaphraseMode.humanizer:
        return 'Lugas & Alami';
      case ParaphraseMode.concise:
        return 'Ringkas & Padat';
      case ParaphraseMode.expansive:
        return 'Ekspansif & Analitis';
    }
  }

  String get description {
    switch (this) {
      case ParaphraseMode.academic:
        return 'Gaya penulisan formal ilmiah PUEBI/KBBI untuk makalah, laporan, dan jurnal.';
      case ParaphraseMode.humanizer:
        return 'Gaya bertutur natural mahasiswa orisinal untuk menghindari pola kaku bot dan detektor plagiasi.';
      case ParaphraseMode.concise:
        return 'Memangkas kalimat bertele-tele dan menyaring esensi poin kunci secara tajam.';
      case ParaphraseMode.expansive:
        return 'Memperdalam narasi argumen dengan penjelasan konseptual dan contoh kontekstual.';
    }
  }
}

class ParaphraseResult {
  final String originalText;
  final String paraphrasedText;
  final ParaphraseMode mode;
  final int originalWordCount;
  final int resultWordCount;
  final String? citationAdvice;

  const ParaphraseResult({
    required this.originalText,
    required this.paraphrasedText,
    required this.mode,
    required this.originalWordCount,
    required this.resultWordCount,
    this.citationAdvice,
  });

  static int countWords(String text) {
    final clean = text.trim();
    if (clean.isEmpty) return 0;
    return clean.split(RegExp(r'\s+')).where((s) => s.isNotEmpty).length;
  }
}

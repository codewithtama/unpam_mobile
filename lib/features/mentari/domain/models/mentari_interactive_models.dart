class MentariParticipantModel {
  final String nim;
  final String namaMahasiswa;
  final String alamatEmail;
  final String noHpMahasiswa;

  const MentariParticipantModel({
    required this.nim,
    required this.namaMahasiswa,
    this.alamatEmail = '-',
    this.noHpMahasiswa = '-',
  });

  String get initials {
    final parts = namaMahasiswa
        .trim()
        .split(RegExp(r'\s+'))
        .where((w) => w.isNotEmpty)
        .toList();
    if (parts.isEmpty) return 'M';
    if (parts.length == 1) {
      return parts.first.substring(0, parts.first.length >= 2 ? 2 : 1).toUpperCase();
    }
    return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
  }

  factory MentariParticipantModel.fromJson(Map<String, dynamic> json) {
    return MentariParticipantModel(
      nim: (json['nim'] ?? '').toString().trim(),
      namaMahasiswa: (json['nama_mahasiswa'] ?? json['nama'] ?? 'Mahasiswa').toString().trim(),
      alamatEmail: (json['alamat_email'] ?? json['email'] ?? '-').toString().trim(),
      noHpMahasiswa: (json['no_hp_mahasiswa'] ?? json['no_hp'] ?? '-').toString().trim(),
    );
  }

  Map<String, dynamic> toJson() => {
        'nim': nim,
        'nama_mahasiswa': namaMahasiswa,
        'alamat_email': alamatEmail,
        'no_hp_mahasiswa': noHpMahasiswa,
      };
}

class MentariQuizOptionModel {
  final String id;
  final String label;
  final String text;

  const MentariQuizOptionModel({
    required this.id,
    required this.label,
    required this.text,
  });

  factory MentariQuizOptionModel.fromJson(Map<String, dynamic> json, {int index = 0}) {
    const labels = ['A', 'B', 'C', 'D', 'E'];
    final defaultLabel = index < labels.length ? labels[index] : '${index + 1}';
    return MentariQuizOptionModel(
      id: (json['id'] ?? json['kode'] ?? defaultLabel).toString(),
      label: (json['label'] ?? json['kode'] ?? defaultLabel).toString(),
      text: (json['jawaban'] ?? json['teks'] ?? json['text'] ?? json['konten'] ?? '').toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'label': label,
        'text': text,
      };
}

class MentariQuizQuestionModel {
  final String id;
  final int number;
  final String questionText;
  final List<MentariQuizOptionModel> options;
  final String? selectedOptionId;
  final String? aiRecommendedOptionId;
  final String? aiExplanation;

  const MentariQuizQuestionModel({
    required this.id,
    required this.number,
    required this.questionText,
    required this.options,
    this.selectedOptionId,
    this.aiRecommendedOptionId,
    this.aiExplanation,
  });

  MentariQuizQuestionModel copyWith({
    String? selectedOptionId,
    String? aiRecommendedOptionId,
    String? aiExplanation,
  }) {
    return MentariQuizQuestionModel(
      id: id,
      number: number,
      questionText: questionText,
      options: options,
      selectedOptionId: selectedOptionId ?? this.selectedOptionId,
      aiRecommendedOptionId: aiRecommendedOptionId ?? this.aiRecommendedOptionId,
      aiExplanation: aiExplanation ?? this.aiExplanation,
    );
  }

  static String stripHtml(String raw) {
    return raw
        .replaceAll(RegExp(r'<[^>]*>'), ' ')
        .replaceAll('&nbsp;', ' ')
        .replaceAll('&amp;', '&')
        .replaceAll('&quot;', '"')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();
  }

  factory MentariQuizQuestionModel.fromJson(Map<String, dynamic> json, {int index = 0}) {
    final rawQ = (json['pertanyaan'] ??
            json['soal'] ??
            json['question'] ??
            json['konten'] ??
            json['text'] ??
            'Pertanyaan ${index + 1}')
        .toString();

    final rawOpts = json['pilihan'] ??
        json['jawaban_list'] ??
        json['options'] ??
        json['answers'] ??
        const [];

    final parsedOptions = <MentariQuizOptionModel>[];
    if (rawOpts is List) {
      for (var i = 0; i < rawOpts.length; i++) {
        final item = rawOpts[i];
        if (item is Map<String, dynamic>) {
          parsedOptions.add(MentariQuizOptionModel.fromJson(item, index: i));
        } else if (item != null) {
          const labels = ['A', 'B', 'C', 'D', 'E'];
          final lbl = i < labels.length ? labels[i] : '${i + 1}';
          parsedOptions.add(MentariQuizOptionModel(
            id: lbl,
            label: lbl,
            text: stripHtml(item.toString()),
          ));
        }
      }
    }

    return MentariQuizQuestionModel(
      id: (json['id'] ?? 'q_${index + 1}').toString(),
      number: (json['nomor'] as num?)?.toInt() ?? (index + 1),
      questionText: stripHtml(rawQ),
      options: parsedOptions,
      selectedOptionId: json['selected_option_id']?.toString(),
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nomor': number,
        'pertanyaan': questionText,
        'options': options.map((o) => o.toJson()).toList(),
        if (selectedOptionId != null) 'selected_option_id': selectedOptionId,
      };
}

class MentariForumPostModel {
  final String id;
  final String authorName;
  final String authorNim;
  final String content;
  final DateTime createdAt;
  final bool isLecturer;

  const MentariForumPostModel({
    required this.id,
    required this.authorName,
    required this.authorNim,
    required this.content,
    required this.createdAt,
    this.isLecturer = false,
  });

  factory MentariForumPostModel.fromJson(Map<String, dynamic> json) {
    final rawDate = (json['createdAt'] ?? json['created_at'] ?? json['tanggal'] ?? '').toString();
    final dt = DateTime.tryParse(rawDate) ?? DateTime.now();
    final rawContent = (json['konten'] ?? json['pesan'] ?? json['content'] ?? json['message'] ?? '').toString();

    return MentariForumPostModel(
      id: (json['id'] ?? DateTime.now().millisecondsSinceEpoch).toString(),
      authorName: (json['nama_user'] ?? json['nama_mahasiswa'] ?? json['author'] ?? 'Mahasiswa').toString(),
      authorNim: (json['nim'] ?? json['username'] ?? '').toString(),
      content: MentariQuizQuestionModel.stripHtml(rawContent),
      createdAt: dt,
      isLecturer: json['is_dosen'] == true || json['role']?.toString().toLowerCase() == 'dosen',
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'nama_user': authorName,
        'nim': authorNim,
        'konten': content,
        'createdAt': createdAt.toIso8601String(),
        'is_dosen': isLecturer,
      };
}

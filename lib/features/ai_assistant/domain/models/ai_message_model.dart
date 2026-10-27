import 'dart:typed_data';

enum AiMessageType { text, quiz, summary, discussionDraft }

class QuizItem {
  final String question;
  final List<String> options;
  final int correctIndex;
  final String explanation;
  int? userSelectedIndex;

  QuizItem({
    required this.question,
    required this.options,
    required this.correctIndex,
    required this.explanation,
    this.userSelectedIndex,
  });

  bool get isAnswered => userSelectedIndex != null;
  bool get isCorrect => userSelectedIndex == correctIndex;

  factory QuizItem.fromJson(Map<String, dynamic> json) {
    final opts = (json['options'] as List<dynamic>?)
            ?.map((e) => e.toString())
            .toList() ??
        [];
    return QuizItem(
      question: json['question']?.toString() ?? '',
      options: opts,
      correctIndex: json['correctIndex'] is int ? json['correctIndex'] as int : 0,
      explanation: json['explanation']?.toString() ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'question': question,
      'options': options,
      'correctIndex': correctIndex,
      'explanation': explanation,
    };
  }
}

class AiMessage {
  final String id;
  final String content;
  final bool isUser;
  final DateTime timestamp;
  final AiMessageType type;
  final List<QuizItem>? quizItems;
  final String? relatedCourseName;
  final Uint8List? imageBytes;

  AiMessage({
    required this.id,
    required this.content,
    required this.isUser,
    required this.timestamp,
    this.type = AiMessageType.text,
    this.quizItems,
    this.relatedCourseName,
    this.imageBytes,
  });
}

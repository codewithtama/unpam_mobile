import 'mentari_module_model.dart';

class MentariSectionModel {
  final int id;
  final String name;
  final int sectionNumber;
  final String summary;
  final List<MentariModuleModel> modules;
  final bool visible;

  const MentariSectionModel({
    required this.id,
    required this.name,
    required this.sectionNumber,
    required this.summary,
    required this.modules,
    this.visible = true,
  });

  bool get isPertemuan =>
      name.toLowerCase().contains('pertemuan') ||
      name.toLowerCase().contains('minggu') ||
      name.toLowerCase().contains('sesi') ||
      sectionNumber > 0;

  int get completedModulesCount =>
      modules.where((m) => m.isCompleted).length;

  double get completionProgress =>
      modules.isEmpty ? 0.0 : completedModulesCount / modules.length;

  factory MentariSectionModel.fromJson(Map<String, dynamic> json) {
    final rawModules = json['modules'] as List<dynamic>? ?? [];
    final modules = rawModules
        .whereType<Map<String, dynamic>>()
        .map((m) => MentariModuleModel.fromJson(m))
        .toList();

    final rawName = (json['name'] ?? '').toString().trim();
    int sNum = int.tryParse(json['section']?.toString() ?? '0') ?? 0;
    if (sNum == 0 && rawName.isNotEmpty) {
      final match = RegExp(r'(?:pertemuan|sesi|minggu)\s*(\d+)', caseSensitive: false)
          .firstMatch(rawName);
      if (match != null) {
        sNum = int.tryParse(match.group(1) ?? '0') ?? 0;
      }
    }

    return MentariSectionModel(
      id: int.tryParse(json['id']?.toString() ?? '0') ?? 0,
      name: rawName.isNotEmpty ? rawName : (sNum > 0 ? 'Pertemuan $sNum' : 'Informasi Umum & Silabus'),
      sectionNumber: sNum,
      summary: (json['summary'] ?? '').toString().trim(),
      modules: modules,
      visible: json['visible'] == null || json['visible'] == 1 || json['visible'] == true,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'sectionNumber': sectionNumber,
        'summary': summary,
        'visible': visible,
        'modules': modules.map((m) => m.toJson()).toList(),
      };
}


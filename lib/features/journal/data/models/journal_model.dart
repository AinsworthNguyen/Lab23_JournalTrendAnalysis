import '../../domain/entities/journal.dart';

class JournalModel extends Journal {
  const JournalModel({
    required super.id,
    required super.displayName,
    required super.worksCount,
    required super.citedByCount,
    super.type = 'journal',
    super.homepageUrl,
    super.publisher,
  });

  factory JournalModel.fromJson(Map<String, dynamic> json) {
    final fullId = json['id'] as String? ?? '';
    final cleanedId = fullId.split('/').last;
    final rawType = json['type'] as String? ?? 'journal';
    final name = json['display_name'] as String? ?? 'Unknown Venue';
    final lowerName = name.toLowerCase();

    final isConf = rawType == 'conference' ||
        lowerName.contains('conference') ||
        lowerName.contains('proceedings') ||
        lowerName.contains('symposium') ||
        lowerName.contains('workshop') ||
        lowerName.contains('congress') ||
        lowerName.contains('proc.') ||
        lowerName.contains('neurips') ||
        lowerName.contains('cvpr') ||
        lowerName.contains('icml') ||
        lowerName.contains('aaai') ||
        lowerName.contains('ijcai') ||
        lowerName.contains('ieee/cvf');

    return JournalModel(
      id: cleanedId,
      displayName: name,
      worksCount: json['works_count'] as int? ?? 0,
      citedByCount: json['cited_by_count'] as int? ?? 0,
      type: isConf ? 'conference' : (rawType == 'conference' ? 'conference' : 'journal'),
      homepageUrl: json['homepage_url'] as String?,
      publisher: json['publisher'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'works_count': worksCount,
      'cited_by_count': citedByCount,
      'type': type,
      'homepage_url': homepageUrl,
      'publisher': publisher,
    };
  }

  factory JournalModel.fromDbMap(Map<dynamic, dynamic> map) {
    final name = map['display_name'] as String? ?? '';
    final rawType = map['type'] as String? ?? 'journal';
    final lowerName = name.toLowerCase();

    final isConf = rawType == 'conference' ||
        lowerName.contains('conference') ||
        lowerName.contains('proceedings') ||
        lowerName.contains('symposium') ||
        lowerName.contains('workshop') ||
        lowerName.contains('congress') ||
        lowerName.contains('proc.') ||
        lowerName.contains('neurips') ||
        lowerName.contains('cvpr') ||
        lowerName.contains('icml') ||
        lowerName.contains('aaai') ||
        lowerName.contains('ijcai') ||
        lowerName.contains('ieee/cvf');

    return JournalModel(
      id: map['id'] as String? ?? '',
      displayName: name,
      worksCount: map['works_count'] as int? ?? 0,
      citedByCount: map['cited_by_count'] as int? ?? 0,
      type: isConf ? 'conference' : (rawType == 'conference' ? 'conference' : 'journal'),
      homepageUrl: map['homepage_url'] as String?,
      publisher: map['publisher'] as String?,
    );
  }
}

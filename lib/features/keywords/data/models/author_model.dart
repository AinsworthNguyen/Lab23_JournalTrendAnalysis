import '../../domain/entities/author.dart';

class AuthorModel extends Author {
  const AuthorModel({
    required super.id,
    required super.displayName,
    required super.worksCount,
    required super.citedByCount,
    super.lastKnownInstitution,
  });

  factory AuthorModel.fromJson(Map<String, dynamic> json) {
    final fullId = json['id'] as String? ?? '';
    final cleanedId = fullId.split('/').last;

    String? institution;
    final lastKnownInstitutionJson =
        json['last_known_institution'] as Map<String, dynamic>?;
    if (lastKnownInstitutionJson != null) {
      institution = lastKnownInstitutionJson['display_name'] as String?;
    }

    return AuthorModel(
      id: cleanedId,
      displayName: json['display_name'] as String? ?? 'Unknown Author',
      worksCount: json['works_count'] as int? ?? 0,
      citedByCount: json['cited_by_count'] as int? ?? 0,
      lastKnownInstitution: institution,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'display_name': displayName,
      'works_count': worksCount,
      'cited_by_count': citedByCount,
      'last_known_institution': lastKnownInstitution,
    };
  }

  factory AuthorModel.fromDbMap(Map<dynamic, dynamic> map) {
    return AuthorModel(
      id: map['id'] as String? ?? '',
      displayName: map['display_name'] as String? ?? '',
      worksCount: map['works_count'] as int? ?? 0,
      citedByCount: map['cited_by_count'] as int? ?? 0,
      lastKnownInstitution: map['last_known_institution'] as String?,
    );
  }
}

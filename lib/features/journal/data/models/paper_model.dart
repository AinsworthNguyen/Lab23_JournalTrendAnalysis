import '../../domain/entities/paper.dart';

class PaperModel extends Paper {
  const PaperModel({
    required super.id,
    required super.title,
    required super.publicationYear,
    required super.citationCount,
    super.doi,
    required super.authors,
    required super.concepts,
    super.abstractText,
    super.journalName,
    required super.isOpenAccess,
  });

  factory PaperModel.fromJson(Map<String, dynamic> json) {
    // Reconstruct abstract from inverted index
    final invertedIndex =
        json['abstract_inverted_index'] as Map<String, dynamic>?;
    final abstractText = _reconstructAbstract(invertedIndex);

    // Extract authors
    final authorsList = <String>[];
    final authorships = json['authorships'] as List<dynamic>?;
    if (authorships != null) {
      for (final authorship in authorships) {
        if (authorship is Map<String, dynamic>) {
          final author = authorship['author'];
          if (author is Map<String, dynamic>) {
            final name = author['display_name'] as String?;
            if (name != null) {
              authorsList.add(name);
            }
          }
        }
      }
    }

    // Extract concepts
    final conceptsList = <String>[];
    final concepts = json['concepts'] as List<dynamic>?;
    if (concepts != null) {
      for (final concept in concepts) {
        if (concept is Map<String, dynamic>) {
          final name = concept['display_name'] as String?;
          if (name != null) {
            conceptsList.add(name);
          }
        }
      }
    }

    // Extract journal name
    String? journalName;
    final primaryLocation = json['primary_location'] as Map<String, dynamic>?;
    if (primaryLocation != null) {
      final source = primaryLocation['source'] as Map<String, dynamic>?;
      if (source != null) {
        journalName = source['display_name'] as String?;
      }
    }

    // Extract open access
    bool isOpenAccess = false;
    final openAccessJson = json['open_access'] as Map<String, dynamic>?;
    if (openAccessJson != null) {
      isOpenAccess = openAccessJson['is_oa'] as bool? ?? false;
    }

    // Clean OpenAlex ID
    final fullId = json['id'] as String? ?? '';
    final cleanedId = fullId.split('/').last;

    return PaperModel(
      id: cleanedId,
      title: json['title'] as String? ?? 'Untitled Paper',
      publicationYear: json['publication_year'] as int? ?? 0,
      citationCount: json['cited_by_count'] as int? ?? 0,
      doi: json['doi'] as String?,
      authors: authorsList,
      concepts: conceptsList,
      abstractText: abstractText,
      journalName: journalName,
      isOpenAccess: isOpenAccess,
    );
  }

  static String? _reconstructAbstract(Map<String, dynamic>? invertedIndex) {
    if (invertedIndex == null || invertedIndex.isEmpty) return null;
    final List<MapEntry<int, String>> words = [];
    invertedIndex.forEach((word, positionsList) {
      if (positionsList is List) {
        for (final pos in positionsList) {
          if (pos is int) {
            words.add(MapEntry(pos, word));
          }
        }
      }
    });
    words.sort((a, b) => a.key.compareTo(b.key));
    return words.map((entry) => entry.value).join(' ');
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'title': title,
      'publication_year': publicationYear,
      'cited_by_count': citationCount,
      'doi': doi,
      'authors': authors,
      'concepts': concepts,
      'abstractText': abstractText,
      'journalName': journalName,
      'isOpenAccess': isOpenAccess,
    };
  }

  factory PaperModel.fromDbMap(Map<dynamic, dynamic> map) {
    return PaperModel(
      id: map['id'] as String? ?? '',
      title: map['title'] as String? ?? '',
      publicationYear: map['publication_year'] as int? ?? 0,
      citationCount: map['cited_by_count'] as int? ?? 0,
      doi: map['doi'] as String?,
      authors: List<String>.from(map['authors'] ?? []),
      concepts: List<String>.from(map['concepts'] ?? []),
      abstractText: map['abstractText'] as String?,
      journalName: map['journalName'] as String?,
      isOpenAccess: map['isOpenAccess'] as bool? ?? false,
    );
  }
}

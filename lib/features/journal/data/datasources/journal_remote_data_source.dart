import 'package:injectable/injectable.dart';
import '../../../../core/network/api_client.dart';
import '../models/paper_model.dart';
import '../models/journal_model.dart';

abstract class JournalRemoteDataSource {
  Future<List<PaperModel>> getPapersForTopic(
    String conceptId, {
    int page = 1,
    String? searchQuery,
  });
  Future<PaperModel> getPaperDetails(String paperId);
  Future<List<JournalModel>> getTopJournals(String conceptId, {String? searchQuery});
  Future<JournalModel> getJournalDetails(String journalId);
  Future<String> getTopJournalName(String conceptId);
  Future<PaperModel?> getMostInfluentialPaper(String conceptId);
  Future<List<JournalModel>> searchSources(String query, {String? type});
}

@LazySingleton(as: JournalRemoteDataSource)
class JournalRemoteDataSourceImpl implements JournalRemoteDataSource {
  final ApiClient _apiClient;

  JournalRemoteDataSourceImpl(this._apiClient);

  @override
  Future<List<PaperModel>> getPapersForTopic(
    String conceptId, {
    int page = 1,
    String? searchQuery,
  }) async {
    final filter = conceptId.startsWith('T')
        ? 'topics.id:$conceptId,primary_location.source.type:journal|conference,publication_year:>2020,publication_year:<2026'
        : 'concepts.id:$conceptId,primary_location.source.type:journal|conference,publication_year:>2020,publication_year:<2026';
    final queryParams = <String, dynamic>{
      'filter': filter,
      'page': page,
      'per_page': 20,
    };
    if (searchQuery != null && searchQuery.trim().isNotEmpty) {
      queryParams['search'] = searchQuery;
    } else {
      queryParams['sort'] = 'publication_year:desc';
    }

    final response = await _apiClient.get('/works', queryParameters: queryParams);
    final results = response['results'] as List<dynamic>? ?? [];
    return results
        .map((json) => PaperModel.fromJson(json as Map<String, dynamic>))
        .toList();
  }

  @override
  Future<PaperModel> getPaperDetails(String paperId) async {
    final response = await _apiClient.get('/works/$paperId');
    return PaperModel.fromJson(response as Map<String, dynamic>);
  }

  String _getConceptNameFromId(String conceptId) {
    switch (conceptId) {
      case 'C41008148':
        return 'Computer Science';
      case 'C154945302':
        return 'Artificial Intelligence';
      case 'C119857082':
        return 'Machine Learning';
      case 'C2522767166':
        return 'Data Science';
      case 'C121332964':
        return 'Physics';
      case 'C33923547':
        return 'Mathematics';
      case 'C86803240':
        return 'Biology';
      case 'C71924100':
        return 'Medicine';
      case 'C185592680':
        return 'Chemistry';
      default:
        return '';
    }
  }

  bool _isJournalRelevant(Map<String, dynamic> json, String conceptName) {
    final topics = json['topics'] as List<dynamic>? ?? [];
    if (topics.isEmpty) return true; // Fallback if no topics
    
    final nameLower = conceptName.toLowerCase();
    if (nameLower.isEmpty) return true;

    final List<String> allowedFields = [];
    if (nameLower.contains('computer') ||
        nameLower.contains('intelligence') ||
        nameLower.contains('machine learning') ||
        nameLower.contains('data science')) {
      allowedFields.addAll(['computer science', 'artificial intelligence', 'software', 'hardware', 'information systems', 'computational']);
    } else if (nameLower.contains('math')) {
      allowedFields.add('mathematics');
    } else if (nameLower.contains('physics')) {
      allowedFields.add('physics');
    } else if (nameLower.contains('chemistry')) {
      allowedFields.add('chemistry');
    } else if (nameLower.contains('medicine') || nameLower.contains('health')) {
      allowedFields.addAll(['medicine', 'health', 'clinical', 'surgery']);
    } else if (nameLower.contains('biology') || nameLower.contains('genetic')) {
      allowedFields.addAll(['agricultural and biological sciences', 'biochemistry, genetics and molecular biology', 'neuroscience', 'immunology']);
    }

    for (final t in topics) {
      final topicMap = t as Map<String, dynamic>;
      final topicName = (topicMap['display_name'] as String? ?? '').toLowerCase();
      final fieldName = (topicMap['field']?['display_name'] as String? ?? '').toLowerCase();
      final subfieldName = (topicMap['subfield']?['display_name'] as String? ?? '').toLowerCase();

      for (final allowed in allowedFields) {
        if (topicName.contains(allowed) || fieldName.contains(allowed) || subfieldName.contains(allowed)) {
          return true;
        }
      }

      if (topicName.contains(nameLower) || fieldName.contains(nameLower) || subfieldName.contains(nameLower)) {
        return true;
      }
    }
    return false;
  }

  @override
  Future<List<JournalModel>> getTopJournals(String conceptId, {String? searchQuery}) async {
    try {
      final filter = conceptId.startsWith('T')
          ? 'topics.id:$conceptId,publication_year:<2026'
          : 'concepts.id:$conceptId,publication_year:<2026';
      final queryParams = <String, dynamic>{
        'filter': filter,
        'group_by': 'primary_location.source.id',
      };
      if (searchQuery != null && searchQuery.trim().isNotEmpty) {
        queryParams['search'] = searchQuery.trim();
      }
      final response = await _apiClient.get('/works', queryParameters: queryParams);
      final results = response['group_by'] as List<dynamic>? ?? [];
      
      final sourceIdsList = <String>[];
      final countsMap = <String, int>{};
      
      for (final item in results) {
        final map = item as Map<String, dynamic>;
        final fullId = map['key'] as String? ?? '';
        final displayName = map['key_display_name'] as String? ?? '';
        final lowerName = displayName.toLowerCase();
        
        if (fullId.isEmpty ||
            lowerName.isEmpty ||
            lowerName.contains('arxiv') ||
            lowerName.contains('zenodo') ||
            lowerName.contains('ssrn') ||
            lowerName.contains('figshare') ||
            lowerName.contains('pubmed') ||
            lowerName.contains('biorxiv') ||
            lowerName.contains('medrxiv') ||
            lowerName.contains('research square') ||
            lowerName.contains('hal (') ||
            lowerName.contains('osf') ||
            lowerName.contains('preprints') ||
            lowerName.contains('eprints') ||
            lowerName.contains('dissco') ||
            lowerName.contains('nifs') ||
            lowerName.contains('biodiversity') ||
            lowerName.contains('osti oai') ||
            lowerName.contains('repository')) {
          continue;
        }
        
        final cleanedId = fullId.split('/').last;
        sourceIdsList.add(cleanedId);
        countsMap[cleanedId] = map['count'] as int? ?? 0;
        if (sourceIdsList.length >= 25) break;
      }
      
      if (sourceIdsList.isNotEmpty) {
        final idsParam = sourceIdsList.join('|');
        final detailsResponse = await _apiClient.get('/sources', queryParameters: {
          'filter': 'openalex:$idsParam',
          'per_page': 25,
        });
        final detailResults = detailsResponse['results'] as List<dynamic>? ?? [];
        
        final conceptName = _getConceptNameFromId(conceptId);
        final journals = detailResults.map((json) {
          final map = json as Map<String, dynamic>;
          final type = map['type'] as String? ?? '';
          if (type == 'repository' || type == 'metadata') {
            return null;
          }
          
          if (!_isJournalRelevant(map, conceptName)) {
            return null;
          }
          
          final model = JournalModel.fromJson(map);
          return JournalModel(
            id: model.id,
            displayName: model.displayName,
            worksCount: countsMap[model.id] ?? model.worksCount,
            citedByCount: model.citedByCount,
            type: model.type,
            homepageUrl: model.homepageUrl,
            publisher: model.publisher,
          );
        })
        .whereType<JournalModel>()
        .toList();
        
        journals.sort((a, b) => b.worksCount.compareTo(a.worksCount));
        return journals.take(10).toList();
      }
    } catch (_) {}
    return [];
  }

  @override
  Future<List<JournalModel>> searchSources(String query, {String? type}) async {
    try {
      final searchAcronymMap = {
        'neurips': 'Neural Information Processing Systems',
        'nips': 'Neural Information Processing Systems',
        'cvpr': 'Computer Vision and Pattern Recognition',
        'icml': 'International Conference on Machine Learning',
        'iccv': 'International Conference on Computer Vision',
        'eccv': 'European Conference on Computer Vision',
        'aaai': 'AAAI Conference on Artificial Intelligence',
        'ijcai': 'International Joint Conference on Artificial Intelligence',
        'iclr': 'International Conference on Learning Representations',
      };
      final lower = query.toLowerCase().trim();
      final searchTerm = searchAcronymMap[lower] ?? query;

      final queryParams = <String, dynamic>{
        'search': searchTerm,
        'per_page': 30,
        'filter': 'type:journal|conference|book series',
      };

      final response = await _apiClient.get('/sources', queryParameters: queryParams);
      final results = response['results'] as List<dynamic>? ?? [];
      final models = results
          .map((json) => JournalModel.fromJson(json as Map<String, dynamic>))
          .toList();

      if (type != null && type != 'all') {
        return models.where((m) => m.type == type).toList();
      }
      return models;
    } catch (_) {
      return [];
    }
  }

  @override
  Future<JournalModel> getJournalDetails(String journalId) async {
    final response = await _apiClient.get('/sources/$journalId');
    return JournalModel.fromJson(response as Map<String, dynamic>);
  }

  @override
  Future<String> getTopJournalName(String conceptId) async {
    try {
      final filter = conceptId.startsWith('T')
          ? 'topics.id:$conceptId,publication_year:<2026'
          : 'concepts.id:$conceptId,publication_year:<2026';
      final queryParams = <String, dynamic>{
        'filter': '$filter,primary_location.source.type:journal|conference',
        'group_by': 'primary_location.source.id',
      };
      final response = await _apiClient.get('/works', queryParameters: queryParams);
      final results = response['group_by'] as List<dynamic>? ?? [];
      
      for (final item in results) {
        final map = item as Map<String, dynamic>;
        final displayName = map['key_display_name'] as String? ?? '';
        final lowerName = displayName.toLowerCase();
        
        // Skip preprints and repository platforms to get actual journals/conferences
        if (lowerName.isEmpty ||
            lowerName.contains('arxiv') ||
            lowerName.contains('zenodo') ||
            lowerName.contains('ssrn') ||
            lowerName.contains('figshare') ||
            lowerName.contains('pubmed') ||
            lowerName.contains('biorxiv') ||
            lowerName.contains('medrxiv') ||
            lowerName.contains('research square') ||
            lowerName.contains('hal (') ||
            lowerName.contains('osf') ||
            lowerName.contains('preprints') ||
            lowerName.contains('eprints') ||
            lowerName.contains('repository')) {
          continue;
        }
        return displayName;
      }
    } catch (_) {}
    return 'N/A';
  }

  @override
  Future<PaperModel?> getMostInfluentialPaper(String conceptId) async {
    try {
      final filter = conceptId.startsWith('T')
          ? 'topics.id:$conceptId,publication_year:<2026'
          : 'concepts.id:$conceptId,publication_year:<2026';
      final queryParams = <String, dynamic>{
        'filter': '$filter,primary_location.source.type:journal|conference',
        'sort': 'cited_by_count:desc',
        'per_page': 1,
      };
      final response = await _apiClient.get('/works', queryParameters: queryParams);
      final results = response['results'] as List<dynamic>? ?? [];
      if (results.isNotEmpty) {
        return PaperModel.fromJson(results.first as Map<String, dynamic>);
      }
    } catch (_) {}
    return null;
  }
}

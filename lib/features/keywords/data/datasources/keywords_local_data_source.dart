import 'package:hive/hive.dart';
import 'package:injectable/injectable.dart';
import '../models/trend_model.dart';
import '../models/keyword_model.dart';
import '../models/author_model.dart';
import '../../../journal/data/models/paper_model.dart';
import '../../../journal/data/models/journal_model.dart';

abstract class KeywordsLocalDataSource {
  Future<void> cachePublicationTrends(
    String conceptId,
    List<PublicationTrendModel> trends,
  );
  Future<List<PublicationTrendModel>> getPublicationTrends(String conceptId);

  Future<void> cacheCitationTrends(
    String conceptId,
    List<CitationTrendModel> trends,
  );
  Future<List<CitationTrendModel>> getCitationTrends(String conceptId);

  Future<void> cacheTopKeywords(String conceptId, List<KeywordModel> keywords);
  Future<List<KeywordModel>> getTopKeywords(String conceptId);

  Future<void> cacheEmergingKeywords(
    String conceptId,
    List<KeywordModel> keywords,
  );
  Future<List<KeywordModel>> getEmergingKeywords(String conceptId);

  Future<void> cacheTopAuthors(String conceptId, List<AuthorModel> authors);
  Future<List<AuthorModel>> getTopAuthors(String conceptId);

  Future<void> cacheTopJournals(String conceptId, List<JournalModel> journals);
  Future<List<JournalModel>> getTopJournals(String conceptId);

  Future<void> cachePapers(String conceptId, List<PaperModel> papers);
  Future<List<PaperModel>> getPapers(String conceptId);

  Future<void> clearCache();
}

@LazySingleton(as: KeywordsLocalDataSource)
class KeywordsLocalDataSourceImpl implements KeywordsLocalDataSource {
  final Box _box;

  KeywordsLocalDataSourceImpl(@Named('analyticsBox') this._box);

  @override
  Future<void> cachePublicationTrends(
    String conceptId,
    List<PublicationTrendModel> trends,
  ) async {
    final listMap = trends.map((t) => t.toJson()).toList();
    await _box.put('trends_$conceptId', listMap);
  }

  @override
  Future<List<PublicationTrendModel>> getPublicationTrends(
    String conceptId,
  ) async {
    final list = _box.get('trends_$conceptId') as List<dynamic>?;
    if (list == null) return [];
    return list
        .map(
          (json) =>
              PublicationTrendModel.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();
  }

  @override
  Future<void> cacheCitationTrends(
    String conceptId,
    List<CitationTrendModel> trends,
  ) async {
    final listMap = trends.map((t) => t.toJson()).toList();
    await _box.put('citations_$conceptId', listMap);
  }

  @override
  Future<List<CitationTrendModel>> getCitationTrends(String conceptId) async {
    final list = _box.get('citations_$conceptId') as List<dynamic>?;
    if (list == null) return [];
    return list
        .map(
          (json) =>
              CitationTrendModel.fromJson(Map<String, dynamic>.from(json)),
        )
        .toList();
  }

  @override
  Future<void> cacheTopKeywords(
    String conceptId,
    List<KeywordModel> keywords,
  ) async {
    final listMap = keywords.map((k) => k.toJson()).toList();
    await _box.put('keywords_$conceptId', listMap);
  }

  @override
  Future<List<KeywordModel>> getTopKeywords(String conceptId) async {
    final list = _box.get('keywords_$conceptId') as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((json) => KeywordModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<void> cacheEmergingKeywords(
    String conceptId,
    List<KeywordModel> keywords,
  ) async {
    final listMap = keywords.map((k) => k.toJson()).toList();
    await _box.put('emerging_$conceptId', listMap);
  }

  @override
  Future<List<KeywordModel>> getEmergingKeywords(String conceptId) async {
    final list = _box.get('emerging_$conceptId') as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((json) => KeywordModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<void> cacheTopAuthors(
    String conceptId,
    List<AuthorModel> authors,
  ) async {
    final listMap = authors.map((a) => a.toJson()).toList();
    await _box.put('authors_$conceptId', listMap);
  }

  @override
  Future<List<AuthorModel>> getTopAuthors(String conceptId) async {
    final list = _box.get('authors_$conceptId') as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((json) => AuthorModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<void> cacheTopJournals(
    String conceptId,
    List<JournalModel> journals,
  ) async {
    final listMap = journals.map((j) => j.toJson()).toList();
    await _box.put('journals_$conceptId', listMap);
  }

  @override
  Future<List<JournalModel>> getTopJournals(String conceptId) async {
    final list = _box.get('journals_$conceptId') as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((json) => JournalModel.fromJson(Map<String, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<void> cachePapers(String conceptId, List<PaperModel> papers) async {
    final listMap = papers.map((p) => p.toJson()).toList();
    await _box.put('papers_$conceptId', listMap);
  }

  @override
  Future<List<PaperModel>> getPapers(String conceptId) async {
    final list = _box.get('papers_$conceptId') as List<dynamic>?;
    if (list == null) return [];
    return list
        .map((json) => PaperModel.fromDbMap(Map<dynamic, dynamic>.from(json)))
        .toList();
  }

  @override
  Future<void> clearCache() async {
    await _box.clear();
  }
}

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/constants/mock_data.dart';
import '../../domain/entities/keyword.dart';
import '../../domain/entities/trend.dart';
import '../../domain/repositories/keyword_repository.dart';
import '../datasources/keywords_remote_data_source.dart';
import '../datasources/keywords_local_data_source.dart';
import '../models/trend_model.dart';
import '../models/keyword_model.dart';

@LazySingleton(as: KeywordRepository)
class KeywordRepositoryImpl implements KeywordRepository {
  final KeywordsRemoteDataSource _remoteDataSource;
  final KeywordsLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  KeywordRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, List<Keyword>>> getTopKeywords(
    String conceptId,
  ) async {
    final hasConnection = await _networkInfo.isConnected;

    if (hasConnection) {
      try {
        final remoteKeywords = await _remoteDataSource.getTopKeywords(
          conceptId,
        );
        if (remoteKeywords.isNotEmpty) {
          await _localDataSource.cacheTopKeywords(conceptId, remoteKeywords);
          return Right(remoteKeywords);
        }
      } catch (_) {}
    }

    try {
      final localKeywords = await _localDataSource.getTopKeywords(conceptId);
      if (localKeywords.isNotEmpty) {
        return Right(localKeywords);
      }

      final extracted = await _extractKeywordsFromCache(
        conceptId,
        isEmerging: false,
      );
      if (extracted.isNotEmpty) {
        await _localDataSource.cacheTopKeywords(conceptId, extracted);
        return Right(extracted);
      }
    } catch (_) {}

    return const Right(MockData.mockTopKeywords);
  }

  @override
  Future<Either<Failure, List<Keyword>>> getEmergingKeywords(
    String conceptId,
  ) async {
    final hasConnection = await _networkInfo.isConnected;

    if (hasConnection) {
      try {
        final remoteKeywords = await _remoteDataSource.getEmergingKeywords(
          conceptId,
        );
        if (remoteKeywords.isNotEmpty) {
          await _localDataSource.cacheEmergingKeywords(
            conceptId,
            remoteKeywords,
          );
          return Right(remoteKeywords);
        }
      } catch (_) {}
    }

    try {
      final localKeywords = await _localDataSource.getEmergingKeywords(
        conceptId,
      );
      if (localKeywords.isNotEmpty) {
        return Right(localKeywords);
      }

      final extracted = await _extractKeywordsFromCache(
        conceptId,
        isEmerging: true,
      );
      if (extracted.isNotEmpty) {
        await _localDataSource.cacheEmergingKeywords(conceptId, extracted);
        return Right(extracted);
      }
    } catch (_) {}

    return const Right(MockData.mockEmergingKeywords);
  }

  @override
  Future<Either<Failure, List<PublicationTrend>>> getPublicationTrends(
    String conceptId,
  ) async {
    final hasConnection = await _networkInfo.isConnected;

    if (hasConnection) {
      try {
        final publicationTrends = await _remoteDataSource.getPublicationTrends(
          conceptId,
        );

        if (publicationTrends.isNotEmpty) {
          await _localDataSource.cachePublicationTrends(
            conceptId,
            publicationTrends,
          );
          return Right(publicationTrends);
        }
      } catch (_) {}
    }

    try {
      final localTrends = await _localDataSource.getPublicationTrends(
        conceptId,
      );
      if (localTrends.isNotEmpty) {
        return Right(localTrends);
      }

      final extracted = await _extractPubTrendsFromCache(conceptId);
      if (extracted.isNotEmpty) {
        await _localDataSource.cachePublicationTrends(conceptId, extracted);
        return Right(extracted);
      }
    } catch (_) {}

    return const Right(MockData.mockPublicationTrends);
  }

  @override
  Future<Either<Failure, List<CitationTrend>>> getCitationTrends(
    String conceptId,
  ) async {
    final hasConnection = await _networkInfo.isConnected;

    if (hasConnection) {
      try {
        final conceptData = await _remoteDataSource.getConceptTrends(conceptId);
        final countsByYear =
            conceptData['counts_by_year'] as List<dynamic>? ?? [];

        if (countsByYear.isNotEmpty) {
          final citationTrends = countsByYear.map((item) {
            final map = item as Map<String, dynamic>;
            return CitationTrendModel(
              year: map['year'] as int? ?? 0,
              count: map['cited_by_count'] as int? ?? 0,
            );
          }).toList();

          await _localDataSource.cacheCitationTrends(conceptId, citationTrends);
          return Right(citationTrends);
        }
      } catch (_) {}
    }

    try {
      final localTrends = await _localDataSource.getCitationTrends(conceptId);
      if (localTrends.isNotEmpty) {
        return Right(localTrends);
      }

      final extracted = await _extractCitTrendsFromCache(conceptId);
      if (extracted.isNotEmpty) {
        await _localDataSource.cacheCitationTrends(conceptId, extracted);
        return Right(extracted);
      }
    } catch (_) {}

    return const Right(MockData.mockCitationTrends);
  }

  // Helper extraction methods
  Future<List<KeywordModel>> _extractKeywordsFromCache(
    String conceptId, {
    required bool isEmerging,
  }) async {
    try {
      final papers = await _localDataSource.getPapers(conceptId);
      if (papers.isEmpty) return [];

      final keywordCounts = <String, int>{};
      for (final p in papers) {
        for (final c in p.concepts) {
          final cleanConcept = c.trim();
          if (cleanConcept.isEmpty) continue;
          // Exclude generic/redundant concept name
          if (cleanConcept.toLowerCase() == 'computer science') continue;
          keywordCounts[cleanConcept] = (keywordCounts[cleanConcept] ?? 0) + 1;
        }
      }

      final list = keywordCounts.entries.map((e) {
        return KeywordModel(
          id: e.key.toLowerCase().replaceAll(' ', '_'),
          displayName: e.key,
          level: isEmerging ? 3 : 2,
          worksCount: e.value,
        );
      }).toList();

      list.sort((a, b) => b.worksCount.compareTo(a.worksCount));

      if (isEmerging) {
        // Emerging: skip the top 5 main terms, take next 10 lesser frequent but relevant ones
        return list.skip(5).take(10).toList();
      } else {
        return list.take(15).toList();
      }
    } catch (_) {
      return [];
    }
  }

  Future<List<PublicationTrendModel>> _extractPubTrendsFromCache(
    String conceptId,
  ) async {
    try {
      final papers = await _localDataSource.getPapers(conceptId);
      if (papers.isEmpty) return [];

      final yearCounts = <int, int>{};
      for (final p in papers) {
        if (p.publicationYear > 0) {
          yearCounts[p.publicationYear] =
              (yearCounts[p.publicationYear] ?? 0) + 1;
        }
      }

      final list = yearCounts.entries.map((e) {
        return PublicationTrendModel(year: e.key, count: e.value);
      }).toList();

      list.sort((a, b) => a.year.compareTo(b.year));
      return list;
    } catch (_) {
      return [];
    }
  }

  Future<List<CitationTrendModel>> _extractCitTrendsFromCache(
    String conceptId,
  ) async {
    try {
      final papers = await _localDataSource.getPapers(conceptId);
      if (papers.isEmpty) return [];

      final yearCounts = <int, int>{};
      for (final p in papers) {
        if (p.publicationYear > 0) {
          yearCounts[p.publicationYear] =
              (yearCounts[p.publicationYear] ?? 0) + p.citationCount;
        }
      }

      final list = yearCounts.entries.map((e) {
        return CitationTrendModel(year: e.key, count: e.value);
      }).toList();

      list.sort((a, b) => a.year.compareTo(b.year));
      return list;
    } catch (_) {
      return [];
    }
  }
}

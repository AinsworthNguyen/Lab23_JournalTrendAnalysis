import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/prefs_keys.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../domain/repositories/sync_repository.dart';
import '../../../journal/data/datasources/journal_remote_data_source.dart';
import '../../../keywords/data/datasources/keywords_remote_data_source.dart';
import '../../../keywords/data/datasources/keywords_local_data_source.dart';
import '../../../keywords/data/models/trend_model.dart';

@LazySingleton(as: SyncRepository)
class SyncRepositoryImpl implements SyncRepository {
  final JournalRemoteDataSource _journalRemote;
  final KeywordsRemoteDataSource _keywordsRemote;
  final KeywordsLocalDataSource _keywordsLocal;
  final NetworkInfo _networkInfo;
  final SharedPreferences _prefs;

  SyncRepositoryImpl(
    this._journalRemote,
    this._keywordsRemote,
    this._keywordsLocal,
    this._networkInfo,
    this._prefs,
  );

  @override
  Future<Either<Failure, void>> refreshAllData(String conceptId) async {
    final isConnected = await _networkInfo.isConnected;
    if (!isConnected) {
      return const Left(
        NetworkFailure('No internet connection. Cannot perform sync.'),
      );
    }

    try {
      // 1. Fetch and Cache Papers
      final papers = await _journalRemote.getPapersForTopic(conceptId, page: 1);
      await _keywordsLocal.cachePapers(conceptId, papers);

      // 2. Fetch and Cache Top Journals
      final journals = await _journalRemote.getTopJournals(conceptId);
      await _keywordsLocal.cacheTopJournals(conceptId, journals);

      // 3. Fetch and Cache Top Authors
      final authors = await _keywordsRemote.getTopAuthors(conceptId);
      await _keywordsLocal.cacheTopAuthors(conceptId, authors);

      // 4. Fetch and Cache Keywords
      final keywords = await _keywordsRemote.getTopKeywords(conceptId);
      await _keywordsLocal.cacheTopKeywords(conceptId, keywords);

      final emerging = await _keywordsRemote.getEmergingKeywords(conceptId);
      await _keywordsLocal.cacheEmergingKeywords(conceptId, emerging);

      // 5. Fetch and Cache Publication/Citation Trends
      final conceptData = await _keywordsRemote.getConceptTrends(conceptId);
      final citedByCount = conceptData['cited_by_count'] as int? ?? 0;

      List<PublicationTrendModel> publicationTrends;
      try {
        publicationTrends = await _keywordsRemote.getPublicationTrends(
          conceptId,
        );
      } catch (_) {
        publicationTrends = [];
      }

      if (publicationTrends.isEmpty) {
        final worksCount = conceptData['works_count'] as int? ?? 0;
        publicationTrends = [PublicationTrendModel(year: 0, count: worksCount)];
      }

      final citationTrends = [CitationTrendModel(year: 0, count: citedByCount)];

      await _keywordsLocal.cachePublicationTrends(conceptId, publicationTrends);
      await _keywordsLocal.cacheCitationTrends(conceptId, citationTrends);

      // 6. Update Sync Date in SharedPreferences
      await _prefs.setString(
        PrefsKeys.lastSyncDate,
        DateTime.now().toIso8601String(),
      );

      return const Right(null);
    } catch (e) {
      return Left(ServerFailure('Sync failed: $e'));
    }
  }

  @override
  Future<Either<Failure, DateTime?>> getLastSyncDate() async {
    try {
      final syncStr = _prefs.getString(PrefsKeys.lastSyncDate);
      if (syncStr == null) return const Right(null);
      return Right(DateTime.parse(syncStr));
    } catch (e) {
      return Left(CacheFailure('Failed to read sync date.'));
    }
  }
}

import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/constants/mock_data.dart';
import '../../domain/entities/paper.dart';
import '../../domain/repositories/publication_repository.dart';
import '../datasources/journal_remote_data_source.dart';
import '../../../keywords/data/datasources/keywords_local_data_source.dart';

@LazySingleton(as: PublicationRepository)
class PublicationRepositoryImpl implements PublicationRepository {
  final JournalRemoteDataSource _remoteDataSource;
  final KeywordsLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  PublicationRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, List<Paper>>> getPapersForTopic(
    String conceptId, {
    int page = 1,
    String? searchQuery,
  }) async {
    final hasConnection = await _networkInfo.isConnected;

    if (hasConnection) {
      try {
        final remotePapers = await _remoteDataSource.getPapersForTopic(
          conceptId,
          page: page,
          searchQuery: searchQuery,
        );
        if (remotePapers.isNotEmpty) {
          // Cache page 1 queries locally
          if (page == 1 && (searchQuery == null || searchQuery.isEmpty)) {
            await _localDataSource.cachePapers(conceptId, remotePapers);
          }
          return Right(remotePapers);
        }
      } catch (_) {}

      // Fallback on network error or empty list
      if (page == 1 && (searchQuery == null || searchQuery.isEmpty)) {
        try {
          final localPapers = await _localDataSource.getPapers(conceptId);
          if (localPapers.isNotEmpty) {
            return Right(localPapers);
          }
        } catch (_) {}
      }
      return const Right(MockData.mockPapers);
    } else {
      // Offline fallback: load cached publications if page 1
      if (page == 1 && (searchQuery == null || searchQuery.isEmpty)) {
        try {
          final localPapers = await _localDataSource.getPapers(conceptId);
          if (localPapers.isNotEmpty) {
            return Right(localPapers);
          }
        } catch (_) {}
        return const Right(MockData.mockPapers);
      }
      return const Left(
        NetworkFailure('Internet connection is required to fetch more pages.'),
      );
    }
  }

  @override
  Future<Either<Failure, Paper>> getPaperDetails(String paperId) async {
    final hasConnection = await _networkInfo.isConnected;

    if (hasConnection) {
      try {
        final paper = await _remoteDataSource.getPaperDetails(paperId);
        return Right(paper);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message ?? 'Server error occurred.'));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(
        NetworkFailure(
          'Internet connection is required to load publication details.',
        ),
      );
    }
  }

  @override
  Future<Either<Failure, String>> getTopJournalName(String conceptId) async {
    final hasConnection = await _networkInfo.isConnected;
    if (hasConnection) {
      try {
        final journal = await _remoteDataSource.getTopJournalName(conceptId);
        return Right(journal);
      } catch (e) {
        return const Right(
          'IEEE Transactions on Pattern Analysis and Machine Intelligence',
        );
      }
    } else {
      return const Right(
        'IEEE Transactions on Pattern Analysis and Machine Intelligence',
      );
    }
  }

  @override
  Future<Either<Failure, Paper?>> getMostInfluentialPaper(
    String conceptId,
  ) async {
    final hasConnection = await _networkInfo.isConnected;
    if (hasConnection) {
      try {
        final paper = await _remoteDataSource.getMostInfluentialPaper(
          conceptId,
        );
        return Right(paper);
      } catch (e) {
        return Right(MockData.mockPapers[0]); // Returns the first mock paper
      }
    } else {
      return const Right(null);
    }
  }
}

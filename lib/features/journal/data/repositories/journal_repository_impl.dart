import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/constants/mock_data.dart';
import '../../domain/entities/journal.dart';
import '../../domain/repositories/journal_repository.dart';
import '../datasources/journal_remote_data_source.dart';
import '../../../keywords/data/datasources/keywords_local_data_source.dart';

@LazySingleton(as: JournalRepository)
class JournalRepositoryImpl implements JournalRepository {
  final JournalRemoteDataSource _remoteDataSource;
  final KeywordsLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  JournalRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, List<Journal>>> getTopJournals(String conceptId) async {
    final hasConnection = await _networkInfo.isConnected;

    if (hasConnection) {
      try {
        final remoteJournals = await _remoteDataSource.getTopJournals(conceptId);
        if (remoteJournals.isNotEmpty) {
          await _localDataSource.cacheTopJournals(conceptId, remoteJournals);
          return Right(remoteJournals);
        }
      } catch (_) {}

      // Fallback to cache on network/server error or empty remote list
      try {
        final localJournals = await _localDataSource.getTopJournals(conceptId);
        if (localJournals.isNotEmpty) {
          return Right(localJournals);
        }
      } catch (_) {}
      return const Right(MockData.mockJournals);
    } else {
      try {
        final localJournals = await _localDataSource.getTopJournals(conceptId);
        if (localJournals.isNotEmpty) {
          return Right(localJournals);
        }
      } catch (_) {}
      return const Right(MockData.mockJournals);
    }
  }

  @override
  Future<Either<Failure, Journal>> getJournalDetails(String journalId) async {
    final hasConnection = await _networkInfo.isConnected;

    if (hasConnection) {
      try {
        final journal = await _remoteDataSource.getJournalDetails(journalId);
        return Right(journal);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message ?? 'Server error occurred.'));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return Left(ServerFailure('No internet connection available.'));
    }
  }

  @override
  Future<Either<Failure, List<Journal>>> searchSources(String query, {String? type}) async {
    final hasConnection = await _networkInfo.isConnected;
    if (hasConnection) {
      try {
        final results = await _remoteDataSource.searchSources(query, type: type);
        return Right(results);
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(NetworkFailure('Không có kết nối mạng'));
    }
  }
}

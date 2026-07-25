import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/network/network_info.dart';
import '../../../../core/constants/mock_data.dart';
import '../../domain/entities/author.dart';
import '../../domain/repositories/author_repository.dart';
import '../datasources/keywords_remote_data_source.dart';
import '../datasources/keywords_local_data_source.dart';

@LazySingleton(as: AuthorRepository)
class AuthorRepositoryImpl implements AuthorRepository {
  final KeywordsRemoteDataSource _remoteDataSource;
  final KeywordsLocalDataSource _localDataSource;
  final NetworkInfo _networkInfo;

  AuthorRepositoryImpl(
    this._remoteDataSource,
    this._localDataSource,
    this._networkInfo,
  );

  @override
  Future<Either<Failure, List<Author>>> getTopAuthors(String conceptId) async {
    final hasConnection = await _networkInfo.isConnected;

    if (hasConnection) {
      try {
        final remoteAuthors = await _remoteDataSource.getTopAuthors(conceptId);
        if (remoteAuthors.isNotEmpty) {
          await _localDataSource.cacheTopAuthors(conceptId, remoteAuthors);
          return Right(remoteAuthors);
        }
      } catch (_) {}

      // Fallback to cache on network/server error or empty remote results
      try {
        final localAuthors = await _localDataSource.getTopAuthors(conceptId);
        if (localAuthors.isNotEmpty) {
          return Right(localAuthors);
        }
      } catch (_) {}
      return const Right(MockData.mockAuthors);
    } else {
      try {
        final localAuthors = await _localDataSource.getTopAuthors(conceptId);
        if (localAuthors.isNotEmpty) {
          return Right(localAuthors);
        }
      } catch (_) {}
      return const Right(MockData.mockAuthors);
    }
  }

  @override
  Future<Either<Failure, Author>> getAuthorDetails(String authorId) async {
    final hasConnection = await _networkInfo.isConnected;

    if (hasConnection) {
      try {
        final author = await _remoteDataSource.getAuthorDetails(authorId);
        return Right(author);
      } on ServerException catch (e) {
        return Left(ServerFailure(e.message ?? 'Server error occurred.'));
      } catch (e) {
        return Left(ServerFailure(e.toString()));
      }
    } else {
      return const Left(
        NetworkFailure(
          'Internet connection is required to load author details.',
        ),
      );
    }
  }
}

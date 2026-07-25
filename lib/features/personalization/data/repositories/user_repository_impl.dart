import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/exceptions.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/utils/name_generator.dart';
import '../../domain/entities/user_preferences.dart';
import '../../domain/repositories/user_repository.dart';
import '../datasources/personalization_local_data_source.dart';
import '../models/user_preferences_model.dart';

@LazySingleton(as: UserRepository)
class UserRepositoryImpl implements UserRepository {
  final PersonalizationLocalDataSource _localDataSource;

  UserRepositoryImpl(this._localDataSource);

  @override
  Future<Either<Failure, UserPreferences>> getUserPreferences() async {
    try {
      final preferences = await _localDataSource.getUserPreferences();
      return Right(preferences);
    } on CacheException catch (e) {
      return Left(
        CacheFailure(e.message ?? 'Failed to read user preferences.'),
      );
    }
  }

  @override
  Future<Either<Failure, void>> saveUserPreferences(
    UserPreferences preferences,
  ) async {
    try {
      final model = UserPreferencesModel.fromEntity(preferences);
      await _localDataSource.saveUserPreferences(model);
      return const Right(null);
    } on CacheException catch (e) {
      return Left(
        CacheFailure(e.message ?? 'Failed to save user preferences.'),
      );
    }
  }

  @override
  Future<Either<Failure, String>> generateRandomName() async {
    try {
      final name = NameGenerator.generateRandomName();
      return Right(name);
    } catch (e) {
      return Left(CacheFailure('Failed to generate random name: $e'));
    }
  }
}

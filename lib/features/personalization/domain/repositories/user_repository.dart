import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/user_preferences.dart';

abstract class UserRepository {
  Future<Either<Failure, UserPreferences>> getUserPreferences();
  Future<Either<Failure, void>> saveUserPreferences(
    UserPreferences preferences,
  );
  Future<Either<Failure, String>> generateRandomName();
}

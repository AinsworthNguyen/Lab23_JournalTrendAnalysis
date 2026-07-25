import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/author.dart';

abstract class AuthorRepository {
  Future<Either<Failure, List<Author>>> getTopAuthors(String conceptId, {String? searchQuery});
  Future<Either<Failure, Author>> getAuthorDetails(String authorId);
}

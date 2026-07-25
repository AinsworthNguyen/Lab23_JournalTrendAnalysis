import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/author.dart';
import '../repositories/author_repository.dart';

@lazySingleton
class GetTopAuthorsUseCase implements UseCase<List<Author>, String> {
  final AuthorRepository _repository;

  GetTopAuthorsUseCase(this._repository);

  @override
  Future<Either<Failure, List<Author>>> call(String params, {String? searchQuery}) {
    return _repository.getTopAuthors(params, searchQuery: searchQuery);
  }
}

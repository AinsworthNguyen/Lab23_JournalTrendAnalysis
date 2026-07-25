import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/journal.dart';
import '../repositories/journal_repository.dart';

@lazySingleton
class GetJournalRankingUseCase implements UseCase<List<Journal>, String> {
  final JournalRepository _repository;

  GetJournalRankingUseCase(this._repository);

  @override
  Future<Either<Failure, List<Journal>>> call(String params, {String? searchQuery}) {
    return _repository.getTopJournals(params, searchQuery: searchQuery);
  }
}

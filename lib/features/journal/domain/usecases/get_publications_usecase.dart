import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/paper.dart';
import '../repositories/publication_repository.dart';

class GetPublicationsParams {
  final String conceptId;
  final int page;
  final String? searchQuery;

  const GetPublicationsParams({
    required this.conceptId,
    required this.page,
    this.searchQuery,
  });
}

@lazySingleton
class GetPublicationsUseCase
    implements UseCase<List<Paper>, GetPublicationsParams> {
  final PublicationRepository _repository;

  GetPublicationsUseCase(this._repository);

  @override
  Future<Either<Failure, List<Paper>>> call(GetPublicationsParams params) {
    return _repository.getPapersForTopic(
      params.conceptId,
      page: params.page,
      searchQuery: params.searchQuery,
    );
  }

  Future<Either<Failure, String>> getTopJournalName(String conceptId) {
    return _repository.getTopJournalName(conceptId);
  }

  Future<Either<Failure, Paper?>> getMostInfluentialPaper(String conceptId) {
    return _repository.getMostInfluentialPaper(conceptId);
  }
}

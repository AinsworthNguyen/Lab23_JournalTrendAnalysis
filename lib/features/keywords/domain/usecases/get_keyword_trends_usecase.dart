import 'package:dartz/dartz.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/error/failures.dart';
import '../../../../core/usecases/usecase.dart';
import '../entities/trend.dart';
import '../repositories/keyword_repository.dart';

@lazySingleton
class GetKeywordTrendsUseCase
    implements UseCase<List<PublicationTrend>, String> {
  final KeywordRepository _repository;

  GetKeywordTrendsUseCase(this._repository);

  @override
  Future<Either<Failure, List<PublicationTrend>>> call(String params) {
    return _repository.getPublicationTrends(params);
  }
}

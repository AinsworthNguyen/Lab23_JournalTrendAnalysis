import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/keyword.dart';
import '../entities/trend.dart';

abstract class KeywordRepository {
  Future<Either<Failure, List<Keyword>>> getTopKeywords(String conceptId);
  Future<Either<Failure, List<Keyword>>> getEmergingKeywords(String conceptId);
  Future<Either<Failure, List<PublicationTrend>>> getPublicationTrends(
    String conceptId,
  );
  Future<Either<Failure, List<CitationTrend>>> getCitationTrends(
    String conceptId,
  );
}

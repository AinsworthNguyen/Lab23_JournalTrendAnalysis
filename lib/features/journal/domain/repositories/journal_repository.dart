import 'package:dartz/dartz.dart';
import '../../../../core/error/failures.dart';
import '../entities/journal.dart';

abstract class JournalRepository {
  Future<Either<Failure, List<Journal>>> getTopJournals(String conceptId);
  Future<Either<Failure, Journal>> getJournalDetails(String journalId);
  Future<Either<Failure, List<Journal>>> searchSources(String query, {String? type});
}

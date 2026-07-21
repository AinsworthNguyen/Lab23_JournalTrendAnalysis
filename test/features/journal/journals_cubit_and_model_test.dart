import 'package:flutter_test/flutter_test.dart';
import 'package:dartz/dartz.dart';
import 'package:journal_trend_analysis/core/error/failures.dart';
import 'package:journal_trend_analysis/core/usecases/usecase.dart';
import 'package:journal_trend_analysis/features/journal/data/models/journal_model.dart';
import 'package:journal_trend_analysis/features/journal/domain/entities/journal.dart';
import 'package:journal_trend_analysis/features/journal/domain/repositories/journal_repository.dart';
import 'package:journal_trend_analysis/features/journal/domain/usecases/get_journal_ranking_usecase.dart';
import 'package:journal_trend_analysis/features/journal/presentation/blocs/journals_cubit.dart';
import 'package:journal_trend_analysis/features/personalization/domain/entities/user_preferences.dart';
import 'package:journal_trend_analysis/features/personalization/domain/usecases/get_user_preferences_usecase.dart';

class FakeGetJournalRankingUseCase implements GetJournalRankingUseCase {
  final List<Journal> journals;
  FakeGetJournalRankingUseCase(this.journals);

  @override
  Future<Either<Failure, List<Journal>>> call(String conceptId) async {
    return Right(journals);
  }
}

class FakeGetUserPreferencesUseCase implements GetUserPreferencesUseCase {
  final UserPreferences prefs;
  FakeGetUserPreferencesUseCase(this.prefs);

  @override
  Future<Either<Failure, UserPreferences>> call(NoParams params) async {
    return Right(prefs);
  }
}

class FakeJournalRepository implements JournalRepository {
  @override
  Future<Either<Failure, Journal>> getJournalDetails(String journalId) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Journal>>> getTopJournals(String conceptId) async {
    throw UnimplementedError();
  }

  @override
  Future<Either<Failure, List<Journal>>> searchSources(String query, {String? type}) async {
    return const Right([]);
  }
}

void main() {
  final tJournalList = [
    const Journal(
      id: 's1',
      displayName: 'IEEE Conference on Computer Vision and Pattern Recognition',
      worksCount: 1500,
      citedByCount: 45000,
      type: 'conference',
      publisher: 'IEEE',
    ),
    const Journal(
      id: 's2',
      displayName: 'Journal of Machine Learning Research',
      worksCount: 800,
      citedByCount: 30000,
      type: 'journal',
      publisher: 'JMLR',
    ),
  ];

  final tUserPrefs = const UserPreferences(
    fullName: 'Test User',
    email: 'test@example.com',
    photoUrl: '',
    interestConceptId: 'C41008148',
    interestConceptName: 'Computer Science',
    role: 'user',
    isBlocked: false,
  );

  group('JournalModel & Entity Parsing Tests', () {
    test('should correctly parse conference type from OpenAlex JSON', () {
      final json = {
        'id': 'https://openalex.org/S4306420000',
        'display_name': 'NeurIPS Conference',
        'works_count': 2500,
        'cited_by_count': 60000,
        'type': 'conference',
        'publisher': 'NeurIPS',
      };

      final model = JournalModel.fromJson(json);

      expect(model.id, equals('S4306420000'));
      expect(model.displayName, equals('NeurIPS Conference'));
      expect(model.type, equals('conference'));
      expect(model.isConference, isTrue);
    });

    test('should correctly default to journal type when type is omitted', () {
      final json = {
        'id': 'https://openalex.org/S100',
        'display_name': 'Nature AI',
        'works_count': 1200,
        'cited_by_count': 50000,
      };

      final model = JournalModel.fromJson(json);

      expect(model.type, equals('journal'));
      expect(model.isConference, isFalse);
    });
  });

  group('JournalsCubit Tests', () {
    late JournalsCubit cubit;

    setUp(() {
      cubit = JournalsCubit(
        getJournalRanking: FakeGetJournalRankingUseCase(tJournalList),
        getUserPreferences: FakeGetUserPreferencesUseCase(tUserPrefs),
        journalRepository: FakeJournalRepository(),
      );
    });

    test('loadJournals should emit loaded state with all journals and filteredJournals', () async {
      cubit.loadJournals();
      await Future.delayed(Duration.zero);

      expect(cubit.state.journals.length, equals(2));
      expect(cubit.state.filteredJournals.length, equals(2));
      expect(cubit.state.isLoading, isFalse);
    });

    test('setTypeFilter to conference should filter only conference items', () async {
      cubit.loadJournals();
      await Future.delayed(Duration.zero);

      cubit.setTypeFilter('conference');

      expect(cubit.state.selectedTypeFilter, equals('conference'));
      expect(cubit.state.filteredJournals.length, equals(1));
      expect(cubit.state.filteredJournals.first.isConference, isTrue);
    });
  });
}

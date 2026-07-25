import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';

import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../journal/domain/entities/paper.dart';
import '../../../journal/domain/usecases/get_publications_usecase.dart';
import '../../../keywords/domain/usecases/get_citation_trends_usecase.dart';
import '../../../keywords/domain/usecases/get_keyword_trends_usecase.dart';
import '../../../keywords/domain/usecases/get_top_authors_usecase.dart';
import '../../../personalization/domain/entities/user_preferences.dart';
import '../../../personalization/domain/usecases/get_user_preferences_usecase.dart';
import '../../../personalization/domain/usecases/save_user_preferences_usecase.dart';
import '../../domain/usecases/get_last_sync_date_usecase.dart';
import '../../domain/usecases/refresh_all_data_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  DashboardBloc({
    required final GetUserPreferencesUseCase getUserPreferences,
    required final SaveUserPreferencesUseCase saveUserPreferences,
    required final RefreshAllDataUseCase refreshAllData,
    required final GetLastSyncDateUseCase getLastSyncDate,
    required final GetPublicationsUseCase getPublications,
    required final GetKeywordTrendsUseCase getKeywordTrends,
    required final GetCitationTrendsUseCase getCitationTrends,
    required final GetTopAuthorsUseCase getTopAuthors,
  })  : _getUserPreferences = getUserPreferences,
        _saveUserPreferences = saveUserPreferences,
        _refreshAllData = refreshAllData,
        _getLastSyncDate = getLastSyncDate,
        _getPublications = getPublications,
        _getKeywordTrends = getKeywordTrends,
        _getCitationTrends = getCitationTrends,
        _getTopAuthors = getTopAuthors,
        super(DashboardInitial()) {
    on<LoadDashboard>(_onLoadDashboard);
    on<SyncDashboard>(_onSyncDashboard);
    on<SelectConceptEvent>(_onSelectConcept);
  }

  final GetUserPreferencesUseCase _getUserPreferences;
  final SaveUserPreferencesUseCase _saveUserPreferences;
  final RefreshAllDataUseCase _refreshAllData;
  final GetLastSyncDateUseCase _getLastSyncDate;
  final GetPublicationsUseCase _getPublications;
  final GetKeywordTrendsUseCase _getKeywordTrends;
  final GetCitationTrendsUseCase _getCitationTrends;
  final GetTopAuthorsUseCase _getTopAuthors;

  Future<void> _onLoadDashboard(
    final LoadDashboard event,
    final Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    try {
      // 1. Get user preferences
      final prefResult = await _getUserPreferences(const NoParams());
      UserPreferences? prefs;
      prefResult.fold((final failure) => null, (final p) => prefs = p);

      if (prefs == null) {
        emit(
          const DashboardFailure(
            'User preferences not configured. Please complete setup.',
          ),
        );
        return;
      }

      final String conceptId = prefs!.interestConceptId;

      // 2. Fetch last sync date
      DateTime? lastSync;
      final syncDateResult = await _getLastSyncDate(const NoParams());
      syncDateResult.fold((_) => null, (final date) => lastSync = date);

      // 3. Load papers (cache or remote)
      List<Paper> papers = <Paper>[];
      final papersResult = await _getPublications(
        GetPublicationsParams(conceptId: conceptId, page: 1),
      );
      papersResult.fold((_) => null, (final list) => papers = List<Paper>.from(list));

      // 4. Load trends and compute total publications across all time
      int totalPublications = 0;
      int activeYear = 0;
      final trendsResult = await _getKeywordTrends(conceptId);
      trendsResult.fold((_) => null, (final trends) {
        if (trends.isNotEmpty) {
          int maxCount = -1;
          for (final t in trends) {
            totalPublications += t.count;
            if (t.count > maxCount) {
              maxCount = t.count;
              activeYear = t.year;
            }
          }
        }
      });

      // 5. Load citation trends and compute total citations across all time
      int totalCitations = 0;
      final citationsResult = await _getCitationTrends(conceptId);
      citationsResult.fold((_) => null, (final citations) {
        if (citations.isNotEmpty) {
          for (final c in citations) {
            totalCitations += c.count;
          }
        }
      });

      // Compute average citations over all time
      final double avgCitations = totalPublications == 0
          ? 0.0
          : totalCitations / totalPublications;

      // 6. Load top authors
      String topAuthorName = 'N/A';
      final authorsResult = await _getTopAuthors(conceptId);
      authorsResult.fold((_) => null, (final authors) {
        if (authors.isNotEmpty) {
          topAuthorName = authors.first.displayName;
        }
      });

      // Find most influential paper
      String mostInfluentialPaper = 'N/A';
      final bestPaperResult = await _getPublications.getMostInfluentialPaper(
        conceptId,
      );
      bestPaperResult.fold((_) => null, (final paper) {
        if (paper != null) {
          mostInfluentialPaper = paper.title;
        }
      });

      // Top Journal name
      String topJournal = 'N/A';
      final topJournalResult = await _getPublications.getTopJournalName(
        conceptId,
      );
      topJournalResult.fold((_) => null, (final name) {
        topJournal = name;
      });

      emit(
        DashboardLoaded(
          name: prefs!.fullName,
          interest: prefs!.interestConceptName,
          conceptId: conceptId,
          lastSync: lastSync,
          totalPublications: totalPublications,
          avgCitations: avgCitations,
          totalCitations: totalCitations,
          activeYear: activeYear,
          topJournal: topJournal,
          topAuthor: topAuthorName,
          mostInfluentialPaper: mostInfluentialPaper,
          papers: papers,
          isSyncing: false,
        ),
      );
    } on Exception catch (e, stack) {
      AppLogger.e('DashboardBloc Load Error', e, stack);
      emit(DashboardFailure('Failed to load dashboard: $e'));
    }
  }

  Future<void> _onSyncDashboard(
    final SyncDashboard event,
    final Emitter<DashboardState> emit,
  ) async {
    final DashboardState currentState = state;
    if (currentState is! DashboardLoaded) return;

    emit(currentState.copyWith(isSyncing: true));

    try {
      final syncResult = await _refreshAllData(currentState.conceptId);

      await syncResult.fold(
        (final failure) async {
          emit(DashboardFailure(failure.message));
          add(LoadDashboard());
        },
        (final _) async {
          add(LoadDashboard());
        },
      );
    } on Exception catch (e, stack) {
      AppLogger.e('DashboardBloc Sync Error', e, stack);
      emit(DashboardFailure('Sync failed: $e'));
      add(LoadDashboard());
    }
  }

  Future<void> _onSelectConcept(
    final SelectConceptEvent event,
    final Emitter<DashboardState> emit,
  ) async {
    try {
      final prefResult = await _getUserPreferences(const NoParams());
      UserPreferences? prefs;
      prefResult.fold((_) => null, (final p) => prefs = p);

      if (prefs != null) {
        final UserPreferences updatedPrefs = UserPreferences(
          fullName: prefs!.fullName,
          email: prefs!.email,
          photoUrl: prefs!.photoUrl,
          interestConceptId: event.conceptId,
          interestConceptName: event.conceptName,
        );

        final saveResult = await _saveUserPreferences(updatedPrefs);
        await saveResult.fold(
          (final failure) async {
            emit(DashboardFailure(failure.message));
          },
          (final _) async {
            add(LoadDashboard());
          },
        );
      }
    } on Exception catch (e, stack) {
      AppLogger.e('DashboardBloc SelectConcept Error', e, stack);
      emit(DashboardFailure('Failed to select concept: $e'));
    }
  }
}

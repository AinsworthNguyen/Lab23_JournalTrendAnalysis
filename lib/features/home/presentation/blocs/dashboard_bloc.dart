import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../../../core/utils/app_logger.dart';
import '../../../personalization/domain/entities/user_preferences.dart';
import '../../../personalization/domain/usecases/get_user_preferences_usecase.dart';
import '../../../personalization/domain/usecases/save_user_preferences_usecase.dart';
import '../../../journal/domain/entities/paper.dart';
import '../../../journal/domain/usecases/get_publications_usecase.dart';
import '../../../keywords/domain/usecases/get_keyword_trends_usecase.dart';
import '../../../keywords/domain/usecases/get_citation_trends_usecase.dart';
import '../../../keywords/domain/usecases/get_top_authors_usecase.dart';
import '../../domain/usecases/refresh_all_data_usecase.dart';
import '../../domain/usecases/get_last_sync_date_usecase.dart';
import 'dashboard_event.dart';
import 'dashboard_state.dart';

@injectable
class DashboardBloc extends Bloc<DashboardEvent, DashboardState> {
  final GetUserPreferencesUseCase _getUserPreferences;
  final SaveUserPreferencesUseCase _saveUserPreferences;
  final RefreshAllDataUseCase _refreshAllData;
  final GetLastSyncDateUseCase _getLastSyncDate;
  final GetPublicationsUseCase _getPublications;
  final GetKeywordTrendsUseCase _getKeywordTrends;
  final GetCitationTrendsUseCase _getCitationTrends;
  final GetTopAuthorsUseCase _getTopAuthors;

  DashboardBloc({
    required GetUserPreferencesUseCase getUserPreferences,
    required SaveUserPreferencesUseCase saveUserPreferences,
    required RefreshAllDataUseCase refreshAllData,
    required GetLastSyncDateUseCase getLastSyncDate,
    required GetPublicationsUseCase getPublications,
    required GetKeywordTrendsUseCase getKeywordTrends,
    required GetCitationTrendsUseCase getCitationTrends,
    required GetTopAuthorsUseCase getTopAuthors,
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

  Future<void> _onLoadDashboard(
    LoadDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    emit(DashboardLoading());

    try {
      // 1. Get user preferences
      final prefResult = await _getUserPreferences(const NoParams());
      UserPreferences? prefs;
      prefResult.fold(
        (failure) => null,
        (p) => prefs = p,
      );

      if (prefs == null) {
        emit(const DashboardFailure('User preferences not configured. Please complete setup.'));
        return;
      }

      final conceptId = prefs!.interestConceptId;

      // 2. Fetch last sync date
      DateTime? lastSync;
      final syncDateResult = await _getLastSyncDate(const NoParams());
      syncDateResult.fold((_) => null, (date) => lastSync = date);

      // 3. Load papers (cache or remote)
      List<Paper> papers = [];
      final papersResult = await _getPublications(
        GetPublicationsParams(conceptId: conceptId, page: 1),
      );
      papersResult.fold((_) => null, (list) => papers = List<Paper>.from(list));

      // 4. Load trends and compute total publications across all time
      int totalPublications = 0;
      int activeYear = 0;
      final trendsResult = await _getKeywordTrends(conceptId);
      trendsResult.fold((_) => null, (trends) {
        if (trends.isNotEmpty) {
          var maxCount = -1;
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
      citationsResult.fold((_) => null, (citations) {
        if (citations.isNotEmpty) {
          for (final c in citations) {
            totalCitations += c.count;
          }
        }
      });

      // Compute average citations over all time
      final avgCitations = totalPublications == 0
          ? 0.0
          : totalCitations / totalPublications;

      // 6. Load top authors
      String topAuthorName = 'N/A';
      final authorsResult = await _getTopAuthors(conceptId);
      authorsResult.fold((_) => null, (authors) {
        if (authors.isNotEmpty) {
          topAuthorName = authors.first.displayName;
        }
      });

      // Find most influential paper
      String mostInfluentialPaper = 'N/A';
      final bestPaperResult = await _getPublications.getMostInfluentialPaper(conceptId);
      bestPaperResult.fold((_) => null, (paper) {
        if (paper != null) {
          mostInfluentialPaper = paper.title;
        }
      });

      // Top Journal name
      String topJournal = 'N/A';
      final topJournalResult = await _getPublications.getTopJournalName(conceptId);
      topJournalResult.fold((_) => null, (name) {
        topJournal = name;
      });

      emit(DashboardLoaded(
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
      ));
    } catch (e, stack) {
      AppLogger.e('DashboardBloc Load Error', e, stack);
      emit(DashboardFailure('Failed to load dashboard: $e'));
    }
  }

  Future<void> _onSyncDashboard(
    SyncDashboard event,
    Emitter<DashboardState> emit,
  ) async {
    final currentState = state;
    if (currentState is! DashboardLoaded) return;

    emit(currentState.copyWith(isSyncing: true));

    try {
      final syncResult = await _refreshAllData(currentState.conceptId);

      await syncResult.fold(
        (failure) async {
          emit(DashboardFailure(failure.message));
          // Recover to loaded state
          add(LoadDashboard());
        },
        (_) async {
          add(LoadDashboard());
        },
      );
    } catch (e, stack) {
      AppLogger.e('DashboardBloc Sync Error', e, stack);
      emit(DashboardFailure('Sync failed: $e'));
      add(LoadDashboard());
    }
  }

  Future<void> _onSelectConcept(
    SelectConceptEvent event,
    Emitter<DashboardState> emit,
  ) async {
    try {
      final prefResult = await _getUserPreferences(const NoParams());
      UserPreferences? prefs;
      prefResult.fold((_) => null, (p) => prefs = p);

      if (prefs != null) {
        final updatedPrefs = UserPreferences(
          fullName: prefs!.fullName,
          email: prefs!.email,
          photoUrl: prefs!.photoUrl,
          interestConceptId: event.conceptId,
          interestConceptName: event.conceptName,
          role: prefs!.role,
          isBlocked: prefs!.isBlocked,
        );

        final saveResult = await _saveUserPreferences(updatedPrefs);
        await saveResult.fold(
          (failure) async {
            emit(DashboardFailure(failure.message));
          },
          (_) async {
            add(LoadDashboard());
          },
        );
      }
    } catch (e, stack) {
      AppLogger.e('DashboardBloc SelectConcept Error', e, stack);
      emit(DashboardFailure('Failed to select concept: $e'));
    }
  }
}

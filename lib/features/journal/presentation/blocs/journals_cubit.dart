import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../personalization/domain/usecases/get_user_preferences_usecase.dart';
import '../../domain/entities/journal.dart';
import '../../domain/usecases/get_journal_ranking_usecase.dart';
import '../../../../core/usecases/usecase.dart';

class JournalsState {
  final List<Journal> journals;
  final bool isLoading;
  final String? errorMessage;

  const JournalsState({
    required this.journals,
    required this.isLoading,
    this.errorMessage,
  });

  factory JournalsState.initial() {
    return const JournalsState(journals: [], isLoading: false);
  }

  JournalsState copyWith({
    List<Journal>? journals,
    bool? isLoading,
    String? errorMessage,
  }) {
    return JournalsState(
      journals: journals ?? this.journals,
      isLoading: isLoading ?? this.isLoading,
      errorMessage: errorMessage,
    );
  }
}

@injectable
class JournalsCubit extends Cubit<JournalsState> {
  final GetJournalRankingUseCase _getJournalRanking;
  final GetUserPreferencesUseCase _getUserPreferences;

  JournalsCubit({
    required GetJournalRankingUseCase getJournalRanking,
    required GetUserPreferencesUseCase getUserPreferences,
  }) : _getJournalRanking = getJournalRanking,
       _getUserPreferences = getUserPreferences,
       super(JournalsState.initial());

  void loadJournals() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final prefResult = await _getUserPreferences(const NoParams());
    prefResult.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (prefs) async {
        final result = await _getJournalRanking(prefs.interestConceptId);
        result.fold(
          (failure) => emit(
            state.copyWith(isLoading: false, errorMessage: failure.message),
          ),
          (journalsList) {
            emit(state.copyWith(journals: journalsList, isLoading: false));
          },
        );
      },
    );
  }
}

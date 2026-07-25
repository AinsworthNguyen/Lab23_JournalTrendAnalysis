import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../personalization/domain/usecases/get_user_preferences_usecase.dart';
import '../../domain/entities/paper.dart';
import '../../domain/usecases/get_publications_usecase.dart';
import '../../../../core/usecases/usecase.dart';

class PublicationsState {
  final List<Paper> papers;
  final int page;
  final bool hasReachedMax;
  final bool isLoading;
  final String searchQuery;
  final String? errorMessage;

  const PublicationsState({
    required this.papers,
    required this.page,
    required this.hasReachedMax,
    required this.isLoading,
    required this.searchQuery,
    this.errorMessage,
  });

  factory PublicationsState.initial() {
    return const PublicationsState(
      papers: [],
      page: 1,
      hasReachedMax: false,
      isLoading: false,
      searchQuery: '',
    );
  }

  PublicationsState copyWith({
    List<Paper>? papers,
    int? page,
    bool? hasReachedMax,
    bool? isLoading,
    String? searchQuery,
    String? errorMessage,
  }) {
    return PublicationsState(
      papers: papers ?? this.papers,
      page: page ?? this.page,
      hasReachedMax: hasReachedMax ?? this.hasReachedMax,
      isLoading: isLoading ?? this.isLoading,
      searchQuery: searchQuery ?? this.searchQuery,
      errorMessage: errorMessage,
    );
  }
}

@injectable
class PublicationsCubit extends Cubit<PublicationsState> {
  final GetPublicationsUseCase _getPublications;
  final GetUserPreferencesUseCase _getUserPreferences;

  PublicationsCubit({
    required GetPublicationsUseCase getPublications,
    required GetUserPreferencesUseCase getUserPreferences,
  }) : _getPublications = getPublications,
       _getUserPreferences = getUserPreferences,
       super(PublicationsState.initial());

  void loadInitialPapers() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final prefResult = await _getUserPreferences(const NoParams());
    prefResult.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (prefs) async {
        final params = GetPublicationsParams(
          conceptId: prefs.interestConceptId,
          page: 1,
          searchQuery: state.searchQuery,
        );
        final result = await _getPublications(params);
        result.fold(
          (failure) => emit(
            state.copyWith(isLoading: false, errorMessage: failure.message),
          ),
          (papersList) {
            emit(
              state.copyWith(
                papers: papersList,
                page: 1,
                hasReachedMax: papersList.length < 20,
                isLoading: false,
              ),
            );
          },
        );
      },
    );
  }

  void loadNextPage() async {
    if (state.isLoading || state.hasReachedMax) return;

    emit(state.copyWith(isLoading: true));

    final prefResult = await _getUserPreferences(const NoParams());
    prefResult.fold(
      (failure) =>
          emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (prefs) async {
        final nextPage = state.page + 1;
        final params = GetPublicationsParams(
          conceptId: prefs.interestConceptId,
          page: nextPage,
          searchQuery: state.searchQuery,
        );
        final result = await _getPublications(params);
        result.fold(
          (failure) => emit(
            state.copyWith(isLoading: false, errorMessage: failure.message),
          ),
          (papersList) {
            emit(
              state.copyWith(
                papers: List.from(state.papers)..addAll(papersList),
                page: nextPage,
                hasReachedMax: papersList.length < 20,
                isLoading: false,
              ),
            );
          },
        );
      },
    );
  }

  void search(String query) {
    emit(
      state.copyWith(
        searchQuery: query,
        papers: [],
        page: 1,
        hasReachedMax: false,
      ),
    );
    loadInitialPapers();
  }
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../personalization/domain/usecases/get_user_preferences_usecase.dart';
import '../../domain/entities/journal.dart';
import '../../domain/repositories/journal_repository.dart';
import '../../domain/usecases/get_journal_ranking_usecase.dart';
import '../../../../core/usecases/usecase.dart';

class JournalsState {
  final List<Journal> journals;
  final List<Journal> filteredJournals;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;
  final String selectedTypeFilter; // 'all', 'journal', 'conference'
  final String searchQuery;

  const JournalsState({
    required this.journals,
    required this.filteredJournals,
    required this.isLoading,
    this.isSearching = false,
    this.errorMessage,
    this.selectedTypeFilter = 'all',
    this.searchQuery = '',
  });

  factory JournalsState.initial() {
    return const JournalsState(
      journals: [],
      filteredJournals: [],
      isLoading: false,
      isSearching: false,
      selectedTypeFilter: 'all',
      searchQuery: '',
    );
  }

  JournalsState copyWith({
    List<Journal>? journals,
    List<Journal>? filteredJournals,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
    String? selectedTypeFilter,
    String? searchQuery,
  }) {
    return JournalsState(
      journals: journals ?? this.journals,
      filteredJournals: filteredJournals ?? this.filteredJournals,
      isLoading: isLoading ?? this.isLoading,
      isSearching: isSearching ?? this.isSearching,
      errorMessage: errorMessage,
      selectedTypeFilter: selectedTypeFilter ?? this.selectedTypeFilter,
      searchQuery: searchQuery ?? this.searchQuery,
    );
  }
}

@injectable
class JournalsCubit extends Cubit<JournalsState> {
  final GetJournalRankingUseCase _getJournalRanking;
  final GetUserPreferencesUseCase _getUserPreferences;
  final JournalRepository _journalRepository;

  Timer? _debounceTimer;

  JournalsCubit({
    required GetJournalRankingUseCase getJournalRanking,
    required GetUserPreferencesUseCase getUserPreferences,
    required JournalRepository journalRepository,
  })  : _getJournalRanking = getJournalRanking,
        _getUserPreferences = getUserPreferences,
        _journalRepository = journalRepository,
        super(JournalsState.initial());

  void loadJournals() async {
    emit(state.copyWith(isLoading: true, errorMessage: null));

    final prefResult = await _getUserPreferences(const NoParams());
    prefResult.fold(
      (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
      (prefs) async {
        final result = await _getJournalRanking(prefs.interestConceptId);
        result.fold(
          (failure) => emit(state.copyWith(isLoading: false, errorMessage: failure.message)),
          (journalsList) {
            emit(state.copyWith(
              journals: journalsList,
              filteredJournals: _applyFilters(journalsList, state.selectedTypeFilter, state.searchQuery),
              isLoading: false,
            ));
          },
        );
      },
    );
  }

  void setTypeFilter(String filter) {
    emit(state.copyWith(
      selectedTypeFilter: filter,
      filteredJournals: _applyFilters(state.journals, filter, state.searchQuery),
    ));
    if (state.searchQuery.trim().isNotEmpty) {
      searchSources(state.searchQuery);
    }
  }

  void searchSources(String query, {Duration debounceDuration = const Duration(milliseconds: 600)}) {
    _debounceTimer?.cancel();
    
    // Instantly filter local journals so user sees immediate results while typing
    final localFiltered = _applyFilters(state.journals, state.selectedTypeFilter, query, isSearchResult: false);
    emit(state.copyWith(
      searchQuery: query,
      filteredJournals: localFiltered,
      isSearching: false,
    ));

    if (query.trim().isEmpty) {
      return;
    }

    _debounceTimer = Timer(debounceDuration, () async {
      emit(state.copyWith(isSearching: true));
      final typeParam = state.selectedTypeFilter == 'all' ? null : state.selectedTypeFilter;
      final result = await _journalRepository.searchSources(query, type: typeParam);
      result.fold(
        (failure) {
          emit(state.copyWith(
            isSearching: false,
            filteredJournals: _applyFilters(state.journals, state.selectedTypeFilter, query, isSearchResult: false),
          ));
        },
        (searchResult) {
          if (searchResult.isNotEmpty) {
            emit(state.copyWith(
              isSearching: false,
              filteredJournals: _applyFilters(searchResult, state.selectedTypeFilter, query, isSearchResult: true),
            ));
          } else {
            emit(state.copyWith(
              isSearching: false,
              filteredJournals: _applyFilters(state.journals, state.selectedTypeFilter, query, isSearchResult: false),
            ));
          }
        },
      );
    });
  }

  List<Journal> _applyFilters(List<Journal> list, String filter, String query, {bool isSearchResult = false}) {
    return list.where((j) {
      final matchesType = filter == 'all' ||
          (filter == 'conference' && j.isConference) ||
          (filter == 'journal' && !j.isConference);
      
      if (isSearchResult) {
        return matchesType;
      }

      final matchesQuery = query.isEmpty ||
          j.displayName.toLowerCase().contains(query.toLowerCase());
      return matchesType && matchesQuery;
    }).toList();
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

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
  final List<Journal> searchResults;
  final List<Journal> filteredJournals;
  final bool isLoading;
  final bool isSearching;
  final String? errorMessage;
  final String selectedTypeFilter; // 'all', 'journal', 'conference'
  final String searchQuery;

  const JournalsState({
    required this.journals,
    this.searchResults = const [],
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
      searchResults: [],
      filteredJournals: [],
      isLoading: false,
      isSearching: false,
      selectedTypeFilter: 'all',
      searchQuery: '',
    );
  }

  JournalsState copyWith({
    List<Journal>? journals,
    List<Journal>? searchResults,
    List<Journal>? filteredJournals,
    bool? isLoading,
    bool? isSearching,
    String? errorMessage,
    String? selectedTypeFilter,
    String? searchQuery,
  }) {
    return JournalsState(
      journals: journals ?? this.journals,
      searchResults: searchResults ?? this.searchResults,
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
            final baseList = state.searchResults.isNotEmpty ? state.searchResults : journalsList;
            final isSearch = state.searchResults.isNotEmpty;
            emit(state.copyWith(
              journals: journalsList,
              filteredJournals: _applyFilters(baseList, state.selectedTypeFilter, state.searchQuery, isSearchResult: isSearch),
              isLoading: false,
            ));
          },
        );
      },
    );
  }

  void setTypeFilter(String filter) {
    final baseList = state.searchResults.isNotEmpty ? state.searchResults : state.journals;
    final isSearch = state.searchResults.isNotEmpty;

    emit(state.copyWith(
      selectedTypeFilter: filter,
      filteredJournals: _applyFilters(baseList, filter, state.searchQuery, isSearchResult: isSearch),
    ));
  }

  void searchSources(String query, {Duration debounceDuration = const Duration(milliseconds: 600)}) {
    _debounceTimer?.cancel();
    
    if (query.trim().isEmpty) {
      emit(state.copyWith(
        searchQuery: '',
        searchResults: const [],
        filteredJournals: _applyFilters(state.journals, state.selectedTypeFilter, '', isSearchResult: false),
        isSearching: false,
      ));
      return;
    }

    // Instantly filter local journals so user sees immediate results while typing
    final baseList = state.searchResults.isNotEmpty ? state.searchResults : state.journals;
    final localFiltered = _applyFilters(baseList, state.selectedTypeFilter, query, isSearchResult: state.searchResults.isNotEmpty);
    emit(state.copyWith(
      searchQuery: query,
      filteredJournals: localFiltered,
      isSearching: false,
    ));

    _debounceTimer = Timer(debounceDuration, () async {
      emit(state.copyWith(isSearching: true));
      final result = await _journalRepository.searchSources(query, type: null);
      result.fold(
        (failure) {
          emit(state.copyWith(
            isSearching: false,
          ));
        },
        (searchResult) {
          if (searchResult.isNotEmpty) {
            emit(state.copyWith(
              isSearching: false,
              searchResults: searchResult,
              filteredJournals: _applyFilters(searchResult, state.selectedTypeFilter, query, isSearchResult: true),
            ));
          } else {
            emit(state.copyWith(
              isSearching: false,
              searchResults: const [],
              filteredJournals: _applyFilters(state.journals, state.selectedTypeFilter, query, isSearchResult: false),
            ));
          }
        },
      );
    });
  }

  static const Map<String, List<String>> _acronymKeywords = {
    'neurips': ['neural information processing systems', 'neurips', 'nips'],
    'nips': ['neural information processing systems', 'neurips', 'nips'],
    'cvpr': ['computer vision and pattern recognition', 'cvpr'],
    'icml': ['machine learning', 'icml'],
    'iccv': ['computer vision', 'iccv'],
    'eccv': ['computer vision', 'eccv'],
    'aaai': ['artificial intelligence', 'aaai'],
    'ijcai': ['artificial intelligence', 'ijcai'],
    'iclr': ['learning representations', 'iclr'],
    'kdd': ['knowledge discovery', 'kdd'],
    'acl': ['computational linguistics', 'acl'],
    'emnlp': ['empirical methods', 'emnlp'],
  };

  List<Journal> _applyFilters(List<Journal> list, String filter, String query, {bool isSearchResult = false}) {
    return list.where((j) {
      final matchesType = filter == 'all' ||
          (filter == 'conference' && j.isConference) ||
          (filter == 'journal' && !j.isConference);
      
      if (!matchesType) return false;
      if (isSearchResult || query.trim().isEmpty) return true;

      final lowerQuery = query.toLowerCase().trim();
      final lowerName = j.displayName.toLowerCase();

      // Direct substring match
      if (lowerName.contains(lowerQuery)) return true;

      // Acronym / alias prefix matching (e.g. 'neuri', 'neurip' for 'neurips')
      for (final entry in _acronymKeywords.entries) {
        final acronym = entry.key;
        if (acronym.startsWith(lowerQuery) || lowerQuery.startsWith(acronym)) {
          for (final kw in entry.value) {
            if (lowerName.contains(kw)) {
              return true;
            }
          }
        }
      }

      return false;
    }).toList();
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/usecases/usecase.dart';
import '../../domain/usecases/search_topics_usecase.dart';
import '../../domain/usecases/get_recent_searches_usecase.dart';
import '../../domain/usecases/save_search_query_usecase.dart';
import '../../domain/usecases/clear_recent_searches_usecase.dart';

abstract class SearchState {}
class SearchInitial extends SearchState {}
class SearchLoading extends SearchState {}
class SearchSuggestionsLoaded extends SearchState {
  final List<Map<String, String>> results;
  SearchSuggestionsLoaded(this.results);
}
class SearchHistoryLoaded extends SearchState {
  final List<String> history;
  SearchHistoryLoaded(this.history);
}
class SearchFailure extends SearchState {
  final String message;
  SearchFailure(this.message);
}

@injectable
class SearchCubit extends Cubit<SearchState> {
  final SearchTopicsUseCase _searchTopics;
  final GetRecentSearchesUseCase _getRecentSearches;
  final SaveSearchQueryUseCase _saveSearchQuery;
  final ClearRecentSearchesUseCase _clearRecentSearches;

  Timer? _debounceTimer;

  SearchCubit({
    required SearchTopicsUseCase searchTopics,
    required GetRecentSearchesUseCase getRecentSearches,
    required SaveSearchQueryUseCase saveSearchQuery,
    required ClearRecentSearchesUseCase clearRecentSearches,
  })  : _searchTopics = searchTopics,
        _getRecentSearches = getRecentSearches,
        _saveSearchQuery = saveSearchQuery,
        _clearRecentSearches = clearRecentSearches,
        super(SearchInitial());

  void loadSearchHistory() async {
    final result = await _getRecentSearches(const NoParams());
    result.fold(
      (failure) => emit(SearchFailure(failure.message)),
      (history) => emit(SearchHistoryLoaded(history)),
    );
  }

  void search(String query, {Duration debounceDuration = const Duration(milliseconds: 600)}) {
    _debounceTimer?.cancel();
    if (query.trim().isEmpty) {
      loadSearchHistory();
      return;
    }

    _debounceTimer = Timer(debounceDuration, () async {
      emit(SearchLoading());
      final result = await _searchTopics(query);
      result.fold(
        (failure) => emit(SearchFailure(failure.message)),
        (results) => emit(SearchSuggestionsLoaded(results)),
      );
    });
  }

  void selectQuery(String query) async {
    await _saveSearchQuery(query);
    loadSearchHistory();
  }

  void clearHistory() async {
    await _clearRecentSearches(const NoParams());
    emit(SearchHistoryLoaded(const []));
  }

  @override
  Future<void> close() {
    _debounceTimer?.cancel();
    return super.close();
  }
}

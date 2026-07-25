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
  SearchSuggestionsLoaded(this.results);
  final List<Map<String, String>> results;
}

class SearchHistoryLoaded extends SearchState {
  SearchHistoryLoaded(this.history);
  final List<String> history;
}

class SearchFailure extends SearchState {
  SearchFailure(this.message);
  final String message;
}

@injectable
class SearchCubit extends Cubit<SearchState> {
  SearchCubit({
    required final SearchTopicsUseCase searchTopics,
    required final GetRecentSearchesUseCase getRecentSearches,
    required final SaveSearchQueryUseCase saveSearchQuery,
    required final ClearRecentSearchesUseCase clearRecentSearches,
  })  : _searchTopics = searchTopics,
        _getRecentSearches = getRecentSearches,
        _saveSearchQuery = saveSearchQuery,
        _clearRecentSearches = clearRecentSearches,
        super(SearchInitial());

  final SearchTopicsUseCase _searchTopics;
  final GetRecentSearchesUseCase _getRecentSearches;
  final SaveSearchQueryUseCase _saveSearchQuery;
  final ClearRecentSearchesUseCase _clearRecentSearches;

  Future<void> loadSearchHistory() async {
    final result = await _getRecentSearches(const NoParams());
    result.fold(
      (final failure) => emit(SearchFailure(failure.message)),
      (final history) => emit(SearchHistoryLoaded(history)),
    );
  }

  Future<void> search(final String query) async {
    if (query.trim().isEmpty) {
      await loadSearchHistory();
      return;
    }

    emit(SearchLoading());
    final result = await _searchTopics(query);
    result.fold(
      (final failure) => emit(SearchFailure(failure.message)),
      (final results) => emit(SearchSuggestionsLoaded(results)),
    );
  }

  Future<void> selectQuery(final String query) async {
    await _saveSearchQuery(query);
    await loadSearchHistory();
  }

  Future<void> clearHistory() async {
    await _clearRecentSearches(const NoParams());
    emit(SearchHistoryLoaded(const <String>[]));
  }
}

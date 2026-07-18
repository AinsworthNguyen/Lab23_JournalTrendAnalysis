// GENERATED CODE - DO NOT MODIFY BY HAND

// **************************************************************************
// InjectableConfigGenerator
// **************************************************************************

// ignore_for_file: type=lint
// coverage:ignore-file

// ignore_for_file: no_leading_underscores_for_library_prefixes
import 'package:connectivity_plus/connectivity_plus.dart' as _i895;
import 'package:get_it/get_it.dart' as _i174;
import 'package:hive/hive.dart' as _i979;
import 'package:injectable/injectable.dart' as _i526;
import 'package:shared_preferences/shared_preferences.dart' as _i460;

import 'core/firebase/firebase_analytics_service.dart' as _i1013;
import 'core/firebase/firebase_auth_service.dart' as _i943;
import 'core/firebase/firebase_crashlytics_service.dart' as _i203;
import 'core/firebase/firebase_messaging_service.dart' as _i278;
import 'core/firebase/firebase_remote_config_service.dart' as _i790;
import 'core/firebase/firebase_storage_service.dart' as _i173;
import 'core/network/api_client.dart' as _i871;
import 'core/network/network_info.dart' as _i75;
import 'core/utils/pdf_report_service.dart' as _i732;
import 'features/home/data/datasources/search_local_data_source.dart' as _i987;
import 'features/home/data/repositories/search_repository_impl.dart' as _i1043;
import 'features/home/data/repositories/sync_repository_impl.dart' as _i899;
import 'features/home/domain/repositories/search_repository.dart' as _i227;
import 'features/home/domain/repositories/sync_repository.dart' as _i669;
import 'features/home/domain/usecases/clear_recent_searches_usecase.dart'
    as _i975;
import 'features/home/domain/usecases/get_last_sync_date_usecase.dart' as _i895;
import 'features/home/domain/usecases/get_recent_searches_usecase.dart'
    as _i141;
import 'features/home/domain/usecases/refresh_all_data_usecase.dart' as _i413;
import 'features/home/domain/usecases/save_search_query_usecase.dart' as _i393;
import 'features/home/domain/usecases/search_topics_usecase.dart' as _i515;
import 'features/home/presentation/blocs/dashboard_bloc.dart' as _i129;
import 'features/home/presentation/blocs/search_cubit.dart' as _i466;
import 'features/journal/data/datasources/journal_remote_data_source.dart'
    as _i187;
import 'features/journal/data/repositories/journal_repository_impl.dart'
    as _i780;
import 'features/journal/data/repositories/publication_repository_impl.dart'
    as _i543;
import 'features/journal/domain/repositories/journal_repository.dart' as _i246;
import 'features/journal/domain/repositories/publication_repository.dart'
    as _i791;
import 'features/journal/domain/usecases/get_journal_details_usecase.dart'
    as _i668;
import 'features/journal/domain/usecases/get_journal_ranking_usecase.dart'
    as _i70;
import 'features/journal/domain/usecases/get_publication_details_usecase.dart'
    as _i795;
import 'features/journal/domain/usecases/get_publications_usecase.dart'
    as _i740;
import 'features/journal/presentation/blocs/journals_cubit.dart' as _i83;
import 'features/journal/presentation/blocs/publications_cubit.dart' as _i141;
import 'features/keywords/data/datasources/keywords_local_data_source.dart'
    as _i1029;
import 'features/keywords/data/datasources/keywords_remote_data_source.dart'
    as _i192;
import 'features/keywords/data/repositories/author_repository_impl.dart'
    as _i634;
import 'features/keywords/data/repositories/keyword_repository_impl.dart'
    as _i342;
import 'features/keywords/domain/repositories/author_repository.dart' as _i795;
import 'features/keywords/domain/repositories/keyword_repository.dart' as _i235;
import 'features/keywords/domain/usecases/get_author_details_usecase.dart'
    as _i197;
import 'features/keywords/domain/usecases/get_citation_trends_usecase.dart'
    as _i486;
import 'features/keywords/domain/usecases/get_emerging_keywords_usecase.dart'
    as _i941;
import 'features/keywords/domain/usecases/get_keyword_trends_usecase.dart'
    as _i1023;
import 'features/keywords/domain/usecases/get_top_authors_usecase.dart'
    as _i460;
import 'features/keywords/domain/usecases/get_top_keywords_usecase.dart'
    as _i885;
import 'features/personalization/data/datasources/personalization_local_data_source.dart'
    as _i329;
import 'features/personalization/data/repositories/user_repository_impl.dart'
    as _i327;
import 'features/personalization/domain/repositories/user_repository.dart'
    as _i56;
import 'features/personalization/domain/usecases/generate_random_name_usecase.dart'
    as _i305;
import 'features/personalization/domain/usecases/get_user_preferences_usecase.dart'
    as _i417;
import 'features/personalization/domain/usecases/save_user_preferences_usecase.dart'
    as _i473;
import 'features/personalization/presentation/blocs/auth_bloc.dart' as _i442;
import 'features/personalization/presentation/blocs/personalization_bloc.dart'
    as _i1044;
import 'features/profile/data/repositories/report_repository_impl.dart'
    as _i947;
import 'features/profile/domain/repositories/report_repository.dart' as _i517;
import 'features/profile/presentation/blocs/notification_cubit.dart' as _i30;
import 'features/profile/presentation/blocs/report_cubit.dart' as _i997;
import 'features/profile/presentation/blocs/theme_cubit.dart' as _i986;
import 'injection_container.dart' as _i809;

extension GetItInjectableX on _i174.GetIt {
// initializes the registration of main-scope dependencies inside of GetIt
  Future<_i174.GetIt> init({
    String? environment,
    _i526.EnvironmentFilter? environmentFilter,
  }) async {
    final gh = _i526.GetItHelper(
      this,
      environment,
      environmentFilter,
    );
    final registerModule = _$RegisterModule();
    await gh.factoryAsync<_i460.SharedPreferences>(
      () => registerModule.prefs,
      preResolve: true,
    );
    gh.lazySingleton<_i732.PDFReportService>(() => _i732.PDFReportService());
    gh.lazySingleton<_i871.ApiClient>(() => registerModule.apiClient);
    gh.lazySingleton<_i895.Connectivity>(() => registerModule.connectivity);
    gh.lazySingleton<_i943.IFirebaseAuthService>(
        () => _i943.FirebaseAuthService());
    gh.lazySingleton<_i1013.IFirebaseAnalyticsService>(
        () => _i1013.FirebaseAnalyticsService());
    gh.lazySingleton<_i173.IFirebaseStorageService>(
        () => _i173.FirebaseStorageService());
    gh.lazySingleton<_i192.KeywordsRemoteDataSource>(
        () => _i192.KeywordsRemoteDataSourceImpl(gh<_i871.ApiClient>()));
    gh.lazySingleton<_i517.ReportRepository>(() => _i947.ReportRepositoryImpl(
          pdfReportService: gh<_i732.PDFReportService>(),
          storageService: gh<_i173.IFirebaseStorageService>(),
          analyticsService: gh<_i1013.IFirebaseAnalyticsService>(),
        ));
    gh.lazySingleton<_i986.ThemeCubit>(
        () => _i986.ThemeCubit(gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i979.Box<dynamic>>(
      () => registerModule.searchBox,
      instanceName: 'searchBox',
    );
    gh.lazySingleton<_i329.PersonalizationLocalDataSource>(() =>
        _i329.PersonalizationLocalDataSourceImpl(
            gh<_i460.SharedPreferences>()));
    gh.lazySingleton<_i278.IFirebaseMessagingService>(
        () => _i278.FirebaseMessagingService());
    gh.lazySingleton<_i203.IFirebaseCrashlyticsService>(
        () => _i203.FirebaseCrashlyticsService());
    gh.lazySingleton<_i987.SearchLocalDataSource>(() =>
        _i987.SearchLocalDataSourceImpl(
            gh<_i979.Box<dynamic>>(instanceName: 'searchBox')));
    gh.lazySingleton<_i790.IFirebaseRemoteConfigService>(
        () => _i790.FirebaseRemoteConfigService());
    gh.lazySingleton<_i515.SearchTopicsUseCase>(
        () => _i515.SearchTopicsUseCase(gh<_i871.ApiClient>()));
    gh.lazySingleton<_i979.Box<dynamic>>(
      () => registerModule.analyticsBox,
      instanceName: 'analyticsBox',
    );
    gh.lazySingleton<_i187.JournalRemoteDataSource>(
        () => _i187.JournalRemoteDataSourceImpl(gh<_i871.ApiClient>()));
    gh.lazySingleton<_i1029.KeywordsLocalDataSource>(() =>
        _i1029.KeywordsLocalDataSourceImpl(
            gh<_i979.Box<dynamic>>(instanceName: 'analyticsBox')));
    gh.factory<_i997.ReportCubit>(
        () => _i997.ReportCubit(gh<_i517.ReportRepository>()));
    gh.lazySingleton<_i227.SearchRepository>(
        () => _i1043.SearchRepositoryImpl(gh<_i987.SearchLocalDataSource>()));
    gh.lazySingleton<_i75.NetworkInfo>(
        () => _i75.NetworkInfoImpl(gh<_i895.Connectivity>()));
    gh.lazySingleton<_i791.PublicationRepository>(
        () => _i543.PublicationRepositoryImpl(
              gh<_i187.JournalRemoteDataSource>(),
              gh<_i1029.KeywordsLocalDataSource>(),
              gh<_i75.NetworkInfo>(),
            ));
    gh.lazySingleton<_i56.UserRepository>(() =>
        _i327.UserRepositoryImpl(gh<_i329.PersonalizationLocalDataSource>()));
    gh.lazySingleton<_i795.AuthorRepository>(() => _i634.AuthorRepositoryImpl(
          gh<_i192.KeywordsRemoteDataSource>(),
          gh<_i1029.KeywordsLocalDataSource>(),
          gh<_i75.NetworkInfo>(),
        ));
    gh.factory<_i442.AuthBloc>(() => _i442.AuthBloc(
          authService: gh<_i943.IFirebaseAuthService>(),
          analyticsService: gh<_i1013.IFirebaseAnalyticsService>(),
        ));
    gh.lazySingleton<_i246.JournalRepository>(() => _i780.JournalRepositoryImpl(
          gh<_i187.JournalRemoteDataSource>(),
          gh<_i1029.KeywordsLocalDataSource>(),
          gh<_i75.NetworkInfo>(),
        ));
    gh.lazySingleton<_i235.KeywordRepository>(() => _i342.KeywordRepositoryImpl(
          gh<_i192.KeywordsRemoteDataSource>(),
          gh<_i1029.KeywordsLocalDataSource>(),
          gh<_i75.NetworkInfo>(),
        ));
    gh.factory<_i30.NotificationCubit>(
        () => _i30.NotificationCubit(gh<_i278.IFirebaseMessagingService>()));
    gh.lazySingleton<_i669.SyncRepository>(() => _i899.SyncRepositoryImpl(
          gh<_i187.JournalRemoteDataSource>(),
          gh<_i192.KeywordsRemoteDataSource>(),
          gh<_i1029.KeywordsLocalDataSource>(),
          gh<_i75.NetworkInfo>(),
          gh<_i460.SharedPreferences>(),
        ));
    gh.lazySingleton<_i975.ClearRecentSearchesUseCase>(
        () => _i975.ClearRecentSearchesUseCase(gh<_i227.SearchRepository>()));
    gh.lazySingleton<_i141.GetRecentSearchesUseCase>(
        () => _i141.GetRecentSearchesUseCase(gh<_i227.SearchRepository>()));
    gh.lazySingleton<_i393.SaveSearchQueryUseCase>(
        () => _i393.SaveSearchQueryUseCase(gh<_i227.SearchRepository>()));
    gh.lazySingleton<_i895.GetLastSyncDateUseCase>(
        () => _i895.GetLastSyncDateUseCase(gh<_i669.SyncRepository>()));
    gh.lazySingleton<_i413.RefreshAllDataUseCase>(
        () => _i413.RefreshAllDataUseCase(gh<_i669.SyncRepository>()));
    gh.lazySingleton<_i668.GetJournalDetailsUseCase>(
        () => _i668.GetJournalDetailsUseCase(gh<_i246.JournalRepository>()));
    gh.lazySingleton<_i70.GetJournalRankingUseCase>(
        () => _i70.GetJournalRankingUseCase(gh<_i246.JournalRepository>()));
    gh.factory<_i466.SearchCubit>(() => _i466.SearchCubit(
          searchTopics: gh<_i515.SearchTopicsUseCase>(),
          getRecentSearches: gh<_i141.GetRecentSearchesUseCase>(),
          saveSearchQuery: gh<_i393.SaveSearchQueryUseCase>(),
          clearRecentSearches: gh<_i975.ClearRecentSearchesUseCase>(),
        ));
    gh.lazySingleton<_i486.GetCitationTrendsUseCase>(
        () => _i486.GetCitationTrendsUseCase(gh<_i235.KeywordRepository>()));
    gh.lazySingleton<_i941.GetEmergingKeywordsUseCase>(
        () => _i941.GetEmergingKeywordsUseCase(gh<_i235.KeywordRepository>()));
    gh.lazySingleton<_i1023.GetKeywordTrendsUseCase>(
        () => _i1023.GetKeywordTrendsUseCase(gh<_i235.KeywordRepository>()));
    gh.lazySingleton<_i885.GetTopKeywordsUseCase>(
        () => _i885.GetTopKeywordsUseCase(gh<_i235.KeywordRepository>()));
    gh.lazySingleton<_i305.GenerateRandomNameUseCase>(
        () => _i305.GenerateRandomNameUseCase(gh<_i56.UserRepository>()));
    gh.lazySingleton<_i417.GetUserPreferencesUseCase>(
        () => _i417.GetUserPreferencesUseCase(gh<_i56.UserRepository>()));
    gh.lazySingleton<_i473.SaveUserPreferencesUseCase>(
        () => _i473.SaveUserPreferencesUseCase(gh<_i56.UserRepository>()));
    gh.lazySingleton<_i740.GetPublicationsUseCase>(
        () => _i740.GetPublicationsUseCase(gh<_i791.PublicationRepository>()));
    gh.lazySingleton<_i795.GetPublicationDetailsUseCase>(() =>
        _i795.GetPublicationDetailsUseCase(gh<_i791.PublicationRepository>()));
    gh.lazySingleton<_i197.GetAuthorDetailsUseCase>(
        () => _i197.GetAuthorDetailsUseCase(gh<_i795.AuthorRepository>()));
    gh.lazySingleton<_i460.GetTopAuthorsUseCase>(
        () => _i460.GetTopAuthorsUseCase(gh<_i795.AuthorRepository>()));
    gh.factory<_i83.JournalsCubit>(() => _i83.JournalsCubit(
          getJournalRanking: gh<_i70.GetJournalRankingUseCase>(),
          getUserPreferences: gh<_i417.GetUserPreferencesUseCase>(),
        ));
    gh.factory<_i129.DashboardBloc>(() => _i129.DashboardBloc(
          getUserPreferences: gh<_i417.GetUserPreferencesUseCase>(),
          saveUserPreferences: gh<_i473.SaveUserPreferencesUseCase>(),
          refreshAllData: gh<_i413.RefreshAllDataUseCase>(),
          getLastSyncDate: gh<_i895.GetLastSyncDateUseCase>(),
          getPublications: gh<_i740.GetPublicationsUseCase>(),
          getKeywordTrends: gh<_i1023.GetKeywordTrendsUseCase>(),
          getCitationTrends: gh<_i486.GetCitationTrendsUseCase>(),
          getTopAuthors: gh<_i460.GetTopAuthorsUseCase>(),
        ));
    gh.factory<_i141.PublicationsCubit>(() => _i141.PublicationsCubit(
          getPublications: gh<_i740.GetPublicationsUseCase>(),
          getUserPreferences: gh<_i417.GetUserPreferencesUseCase>(),
        ));
    gh.factory<_i1044.PersonalizationBloc>(() => _i1044.PersonalizationBloc(
          getUserPreferences: gh<_i417.GetUserPreferencesUseCase>(),
          saveUserPreferences: gh<_i473.SaveUserPreferencesUseCase>(),
          generateRandomName: gh<_i305.GenerateRandomNameUseCase>(),
        ));
    return this;
  }
}

class _$RegisterModule extends _i809.RegisterModule {}

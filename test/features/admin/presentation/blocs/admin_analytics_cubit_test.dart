import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:journal_trend_analysis/core/firebase/firebase_user_service.dart';
import 'package:journal_trend_analysis/features/admin/presentation/blocs/admin_analytics_cubit.dart';

class MockFirebaseUserService extends Mock implements IFirebaseUserService {}

void main() {
  late MockFirebaseUserService mockUserService;
  late AdminAnalyticsCubit cubit;

  const testSummary = AppAnalyticsSummary(
    totalUsers: 150,
    activeUsersThisWeek: 42,
    totalPdfExports: 88,
    totalViews: 1200,
  );

  setUp(() {
    mockUserService = MockFirebaseUserService();
    cubit = AdminAnalyticsCubit(mockUserService);
  });

  tearDown(() {
    cubit.close();
  });

  group('AdminAnalyticsCubit', () {
    test('initial state is AdminAnalyticsInitial', () {
      expect(cubit.state, isA<AdminAnalyticsInitial>());
    });

    test('loadSummary emits AdminAnalyticsLoading then AdminAnalyticsLoaded on success', () async {
      when(() => mockUserService.getAnalyticsSummary())
          .thenAnswer((_) async => testSummary);

      final expectedStates = [
        isA<AdminAnalyticsLoading>(),
        isA<AdminAnalyticsLoaded>(),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadSummary();

      final loadedState = cubit.state as AdminAnalyticsLoaded;
      expect(loadedState.summary.totalUsers, equals(150));
      expect(loadedState.summary.activeUsersThisWeek, equals(42));
      expect(loadedState.summary.totalPdfExports, equals(88));
      expect(loadedState.summary.totalViews, equals(1200));
    });

    test('loadSummary emits AdminAnalyticsLoading then AdminAnalyticsError on exception', () async {
      when(() => mockUserService.getAnalyticsSummary())
          .thenThrow(Exception('Firestore connection failed'));

      final expectedStates = [
        isA<AdminAnalyticsLoading>(),
        isA<AdminAnalyticsError>(),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      await cubit.loadSummary();

      final errorState = cubit.state as AdminAnalyticsError;
      expect(errorState.message, contains('Firestore connection failed'));
    });
  });
}

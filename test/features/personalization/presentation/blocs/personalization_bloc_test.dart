import 'package:dartz/dartz.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/core/error/failures.dart';
import 'package:journal_trend_analysis/core/usecases/usecase.dart';
import 'package:journal_trend_analysis/features/personalization/domain/entities/user_preferences.dart';
import 'package:journal_trend_analysis/features/personalization/domain/usecases/generate_random_name_usecase.dart';
import 'package:journal_trend_analysis/features/personalization/domain/usecases/get_user_preferences_usecase.dart';
import 'package:journal_trend_analysis/features/personalization/domain/usecases/save_user_preferences_usecase.dart';
import 'package:journal_trend_analysis/features/personalization/presentation/blocs/personalization_bloc.dart';
import 'package:journal_trend_analysis/features/personalization/presentation/blocs/personalization_event.dart';
import 'package:journal_trend_analysis/features/personalization/presentation/blocs/personalization_state.dart';
import 'package:mocktail/mocktail.dart';

class MockGetUserPreferencesUseCase extends Mock
    implements GetUserPreferencesUseCase {}

class MockSaveUserPreferencesUseCase extends Mock
    implements SaveUserPreferencesUseCase {}

class MockGenerateRandomNameUseCase extends Mock
    implements GenerateRandomNameUseCase {}

void main() {
  late PersonalizationBloc bloc;
  late MockGetUserPreferencesUseCase mockGetUserPreferences;
  late MockSaveUserPreferencesUseCase mockSaveUserPreferences;
  late MockGenerateRandomNameUseCase mockGenerateRandomName;

  setUpAll(() {
    registerFallbackValue(const NoParams());
    registerFallbackValue(
      const UserPreferences(
        fullName: '',
        email: '',
        photoUrl: '',
        interestConceptId: '',
        interestConceptName: '',
      ),
    );
  });

  setUp(() {
    mockGetUserPreferences = MockGetUserPreferencesUseCase();
    mockSaveUserPreferences = MockSaveUserPreferencesUseCase();
    mockGenerateRandomName = MockGenerateRandomNameUseCase();

    bloc = PersonalizationBloc(
      getUserPreferences: mockGetUserPreferences,
      saveUserPreferences: mockSaveUserPreferences,
      generateRandomName: mockGenerateRandomName,
    );
  });

  tearDown(() {
    bloc.close();
  });

  group('PersonalizationBloc Tests', () {
    test('initial state should be PersonalizationInitial', () {
      expect(bloc.state, equals(PersonalizationInitial()));
    });

    const testPrefs = UserPreferences(
      fullName: 'Quantum Researcher',
      email: '',
      photoUrl: '',
      interestConceptId: 'C12345',
      interestConceptName: 'Quantum Computing',
    );

    test(
      'should emit [PersonalizationLoading, PersonalizationLoaded] when LoadUserPreferences is added successfully',
      () async {
        when(
          () => mockGetUserPreferences(any()),
        ).thenAnswer((_) async => const Right(testPrefs));

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            PersonalizationLoading(),
            const PersonalizationLoaded(preferences: testPrefs),
          ]),
        );

        bloc.add(LoadUserPreferences());
        await expectation;
      },
    );

    test(
      'should emit [PersonalizationLoading, PersonalizationLoaded(null)] when LoadUserPreferences fails',
      () async {
        when(
          () => mockGetUserPreferences(any()),
        ).thenAnswer((_) async => const Left(CacheFailure('Cache fail')));

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            PersonalizationLoading(),
            const PersonalizationLoaded(preferences: null),
          ]),
        );

        bloc.add(LoadUserPreferences());
        await expectation;
      },
    );

    test(
      'should emit [PersonalizationLoading, PersonalizationLoaded(generatedName)] when GenerateRandomNameEvent is added successfully',
      () async {
        when(
          () => mockGenerateRandomName(any()),
        ).thenAnswer((_) async => const Right('Dr. Random'));

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([
            PersonalizationLoading(),
            const PersonalizationLoaded(generatedName: 'Dr. Random'),
          ]),
        );

        bloc.add(GenerateRandomNameEvent());
        await expectation;
      },
    );

    test(
      'should emit [PersonalizationLoading, PersonalizationSuccess] when SavePreferencesEvent is added successfully',
      () async {
        when(
          () => mockSaveUserPreferences(any()),
        ).thenAnswer((_) async => const Right(null));

        final expectation = expectLater(
          bloc.stream,
          emitsInOrder([PersonalizationLoading(), PersonalizationSuccess()]),
        );

        bloc.add(const SavePreferencesEvent(testPrefs));
        await expectation;
      },
    );
  });
}

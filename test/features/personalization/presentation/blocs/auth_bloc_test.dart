import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/core/firebase/firebase_auth_service.dart';
import 'package:journal_trend_analysis/core/firebase/firebase_analytics_service.dart';
import 'package:journal_trend_analysis/features/personalization/presentation/blocs/auth_bloc.dart';
import 'package:journal_trend_analysis/features/personalization/presentation/blocs/auth_event.dart';
import 'package:journal_trend_analysis/features/personalization/presentation/blocs/auth_state.dart';
import 'package:mocktail/mocktail.dart';

class MockFirebaseAuthService extends Mock implements IFirebaseAuthService {}

class MockFirebaseAnalyticsService extends Mock
    implements IFirebaseAnalyticsService {}

class MockUser extends Mock implements firebase_auth.User {}

class MockUserCredential extends Mock implements firebase_auth.UserCredential {}

void main() {
  late AuthBloc authBloc;
  late MockFirebaseAuthService mockAuthService;
  late MockFirebaseAnalyticsService mockAnalyticsService;
  late MockUser mockUser;
  late MockUserCredential mockUserCredential;

  setUp(() {
    mockAuthService = MockFirebaseAuthService();
    mockAnalyticsService = MockFirebaseAnalyticsService();
    mockUser = MockUser();
    mockUserCredential = MockUserCredential();

    when(() => mockAuthService.isBypassed).thenReturn(false);

    authBloc = AuthBloc(
      authService: mockAuthService,
      analyticsService: mockAnalyticsService,
    );
  });

  tearDown(() {
    authBloc.close();
  });

  group('AuthBloc Tests', () {
    test('initial state should be AuthInitial', () {
      expect(authBloc.state, equals(AuthInitial()));
    });

    test(
      'should emit Authenticated when AuthCheckRequested is added and user is signed in',
      () async {
        when(() => mockAuthService.currentUser).thenReturn(mockUser);

        final expectation = expectLater(
          authBloc.stream,
          emitsInOrder([Authenticated(mockUser)]),
        );

        authBloc.add(AuthCheckRequested());
        await expectation;
      },
    );

    test(
      'should emit Unauthenticated when AuthCheckRequested is added and user is null',
      () async {
        when(() => mockAuthService.currentUser).thenReturn(null);

        final expectation = expectLater(
          authBloc.stream,
          emitsInOrder([Unauthenticated()]),
        );

        authBloc.add(AuthCheckRequested());
        await expectation;
      },
    );

    test(
      'should emit [Authenticating, Authenticated] when SignInRequested is added successfully',
      () async {
        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenAnswer((_) async => mockUserCredential);
        when(() => mockUserCredential.user).thenReturn(mockUser);
        when(() => mockAnalyticsService.logLogin()).thenAnswer((_) async => {});

        final expectation = expectLater(
          authBloc.stream,
          emitsInOrder([Authenticating(), Authenticated(mockUser)]),
        );

        authBloc.add(SignInRequested());
        await expectation;

        verify(() => mockAnalyticsService.logLogin()).called(1);
      },
    );

    test(
      'should emit [Authenticating, AuthError] when SignInRequested fails',
      () async {
        when(
          () => mockAuthService.signInWithGoogle(),
        ).thenThrow(Exception('Google Sign-In Failed'));

        final expectation = expectLater(
          authBloc.stream,
          emitsInOrder([
            Authenticating(),
            const AuthError('Exception: Google Sign-In Failed'),
          ]),
        );

        authBloc.add(SignInRequested());
        await expectation;
      },
    );

    test(
      'should emit [Authenticating, Unauthenticated] when SignOutRequested is added successfully',
      () async {
        when(() => mockAuthService.signOut()).thenAnswer((_) async => {});
        when(
          () => mockAnalyticsService.logLogout(),
        ).thenAnswer((_) async => {});

        final expectation = expectLater(
          authBloc.stream,
          emitsInOrder([Authenticating(), Unauthenticated()]),
        );

        authBloc.add(SignOutRequested());
        await expectation;

        verify(() => mockAnalyticsService.logLogout()).called(1);
      },
    );
    test(
      'should emit [Authenticating, Authenticated] when BypassSignInRequested is added successfully',
      () async {
        when(() => mockAuthService.signInBypass()).thenAnswer((_) async => {});
        when(() => mockAnalyticsService.logLogin()).thenAnswer((_) async => {});

        final expectation = expectLater(
          authBloc.stream,
          emitsInOrder([Authenticating(), const Authenticated()]),
        );

        authBloc.add(BypassSignInRequested());
        await expectation;

        verify(() => mockAnalyticsService.logLogin()).called(1);
      },
    );
  });
}

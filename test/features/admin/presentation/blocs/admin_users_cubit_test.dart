import 'dart:async';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:journal_trend_analysis/core/firebase/firebase_user_service.dart';
import 'package:journal_trend_analysis/features/admin/presentation/blocs/admin_users_cubit.dart';

class MockFirebaseUserService extends Mock implements IFirebaseUserService {}

void main() {
  late MockFirebaseUserService mockUserService;
  late AdminUsersCubit cubit;
  late StreamController<List<AdminUserModel>> streamController;

  final testUsers = [
    const AdminUserModel(
      uid: 'uid-1',
      fullName: 'Alice Admin',
      email: 'alice@admin.com',
      photoUrl: '',
      role: 'admin',
      isBlocked: false,
    ),
    const AdminUserModel(
      uid: 'uid-2',
      fullName: 'Bob User',
      email: 'bob@user.com',
      photoUrl: '',
      role: 'user',
      isBlocked: true,
    ),
    const AdminUserModel(
      uid: 'uid-3',
      fullName: 'Charlie Researcher',
      email: 'charlie@lab.com',
      photoUrl: '',
      role: 'user',
      isBlocked: false,
    ),
  ];

  setUp(() {
    mockUserService = MockFirebaseUserService();
    streamController = StreamController<List<AdminUserModel>>();
    when(() => mockUserService.watchAllUsers())
        .thenAnswer((_) => streamController.stream);
    cubit = AdminUsersCubit(mockUserService);
  });

  tearDown(() {
    streamController.close();
    cubit.close();
  });

  group('AdminUsersCubit', () {
    test('initial state is AdminUsersInitial', () {
      expect(cubit.state, isA<AdminUsersInitial>());
    });

    test('startWatching emits AdminUsersLoading then AdminUsersLoaded on stream event', () async {
      final expectedStates = [
        isA<AdminUsersLoading>(),
        isA<AdminUsersLoaded>(),
      ];

      expectLater(cubit.stream, emitsInOrder(expectedStates));

      cubit.startWatching();
      streamController.add(testUsers);

      await pumpEventQueue();

      final loadedState = cubit.state as AdminUsersLoaded;
      expect(loadedState.totalCount, equals(3));
      expect(loadedState.activeCount, equals(2));
      expect(loadedState.blockedCount, equals(1));
      expect(loadedState.adminCount, equals(1));
    });

    test('search filters users correctly by name and email', () async {
      cubit.startWatching();
      streamController.add(testUsers);
      await pumpEventQueue();

      // Search by name
      cubit.search('Bob');
      var loadedState = cubit.state as AdminUsersLoaded;
      expect(loadedState.filteredUsers.length, equals(1));
      expect(loadedState.filteredUsers.first.fullName, equals('Bob User'));

      // Search by email
      cubit.search('charlie@lab.com');
      loadedState = cubit.state as AdminUsersLoaded;
      expect(loadedState.filteredUsers.length, equals(1));
      expect(loadedState.filteredUsers.first.fullName, equals('Charlie Researcher'));
    });

    test('setFilter filters users by status (active/blocked/admin)', () async {
      cubit.startWatching();
      streamController.add(testUsers);
      await pumpEventQueue();

      // Filter active
      cubit.setFilter('active');
      var loadedState = cubit.state as AdminUsersLoaded;
      expect(loadedState.filteredUsers.length, equals(2));

      // Filter blocked
      cubit.setFilter('blocked');
      loadedState = cubit.state as AdminUsersLoaded;
      expect(loadedState.filteredUsers.length, equals(1));
      expect(loadedState.filteredUsers.first.uid, equals('uid-2'));

      // Filter admin
      cubit.setFilter('admin');
      loadedState = cubit.state as AdminUsersLoaded;
      expect(loadedState.filteredUsers.length, equals(1));
      expect(loadedState.filteredUsers.first.uid, equals('uid-1'));
    });

    test('blockUser delegates to IFirebaseUserService.blockUser', () async {
      when(() => mockUserService.blockUser('uid-3'))
          .thenAnswer((_) async {});

      await cubit.blockUser('uid-3');

      verify(() => mockUserService.blockUser('uid-3')).called(1);
    });

    test('unblockUser delegates to IFirebaseUserService.unblockUser', () async {
      when(() => mockUserService.unblockUser('uid-2'))
          .thenAnswer((_) async {});

      await cubit.unblockUser('uid-2');

      verify(() => mockUserService.unblockUser('uid-2')).called(1);
    });
  });
}

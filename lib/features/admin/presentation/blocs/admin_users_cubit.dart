import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/firebase/firebase_user_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

abstract class AdminUsersState {}

class AdminUsersInitial extends AdminUsersState {}

class AdminUsersLoading extends AdminUsersState {}

class AdminUsersLoaded extends AdminUsersState {
  final List<AdminUserModel> allUsers;
  final List<AdminUserModel> filteredUsers;
  final String searchQuery;
  final String filterStatus; // 'all' | 'active' | 'blocked' | 'admin'

  AdminUsersLoaded({
    required this.allUsers,
    required this.filteredUsers,
    this.searchQuery = '',
    this.filterStatus = 'all',
  });

  int get totalCount => allUsers.length;
  int get activeCount => allUsers.where((u) => !u.isBlocked).length;
  int get blockedCount => allUsers.where((u) => u.isBlocked).length;
  int get adminCount => allUsers.where((u) => u.isAdmin).length;
}

class AdminUsersError extends AdminUsersState {
  final String message;
  AdminUsersError(this.message);
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

@injectable
class AdminUsersCubit extends Cubit<AdminUsersState> {
  final IFirebaseUserService _userService;
  StreamSubscription<List<AdminUserModel>>? _subscription;

  AdminUsersCubit(this._userService) : super(AdminUsersInitial());

  void startWatching() {
    emit(AdminUsersLoading());
    _subscription?.cancel();
    _subscription = _userService.watchAllUsers().listen(
      (users) {
        if (state is AdminUsersLoaded) {
          final current = state as AdminUsersLoaded;
          emit(AdminUsersLoaded(
            allUsers: users,
            filteredUsers: _applyFilter(users, current.searchQuery, current.filterStatus),
            searchQuery: current.searchQuery,
            filterStatus: current.filterStatus,
          ));
        } else {
          emit(AdminUsersLoaded(
            allUsers: users,
            filteredUsers: users,
          ));
        }
      },
      onError: (e) => emit(AdminUsersError(e.toString())),
    );
  }

  void search(String query) {
    if (state is! AdminUsersLoaded) return;
    final current = state as AdminUsersLoaded;
    emit(AdminUsersLoaded(
      allUsers: current.allUsers,
      filteredUsers: _applyFilter(current.allUsers, query, current.filterStatus),
      searchQuery: query,
      filterStatus: current.filterStatus,
    ));
  }

  void setFilter(String status) {
    if (state is! AdminUsersLoaded) return;
    final current = state as AdminUsersLoaded;
    emit(AdminUsersLoaded(
      allUsers: current.allUsers,
      filteredUsers: _applyFilter(current.allUsers, current.searchQuery, status),
      searchQuery: current.searchQuery,
      filterStatus: status,
    ));
  }

  Future<void> blockUser(String uid) async {
    await _userService.blockUser(uid);
  }

  Future<void> unblockUser(String uid) async {
    await _userService.unblockUser(uid);
  }

  Future<void> seedData() async {
    await _userService.seedSampleData();
    startWatching();
  }

  List<AdminUserModel> _applyFilter(
    List<AdminUserModel> users,
    String query,
    String status,
  ) {
    var result = users;
    if (query.trim().isNotEmpty) {
      final q = query.toLowerCase();
      result = result.where((u) =>
          u.fullName.toLowerCase().contains(q) ||
          u.email.toLowerCase().contains(q)).toList();
    }
    switch (status) {
      case 'active':
        result = result.where((u) => !u.isBlocked).toList();
        break;
      case 'blocked':
        result = result.where((u) => u.isBlocked).toList();
        break;
      case 'admin':
        result = result.where((u) => u.isAdmin).toList();
        break;
    }
    return result;
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

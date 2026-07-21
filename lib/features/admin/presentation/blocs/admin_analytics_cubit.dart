import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/firebase/firebase_user_service.dart';

// ─── State ────────────────────────────────────────────────────────────────────

abstract class AdminAnalyticsState {}

class AdminAnalyticsInitial extends AdminAnalyticsState {}

class AdminAnalyticsLoading extends AdminAnalyticsState {}

class AdminAnalyticsLoaded extends AdminAnalyticsState {
  final AppAnalyticsSummary summary;
  AdminAnalyticsLoaded(this.summary);
}

class AdminAnalyticsError extends AdminAnalyticsState {
  final String message;
  AdminAnalyticsError(this.message);
}

// ─── Cubit ────────────────────────────────────────────────────────────────────

@injectable
class AdminAnalyticsCubit extends Cubit<AdminAnalyticsState> {
  final IFirebaseUserService _userService;

  AdminAnalyticsCubit(this._userService) : super(AdminAnalyticsInitial());

  Future<void> loadSummary() async {
    emit(AdminAnalyticsLoading());
    try {
      final summary = await _userService.getAnalyticsSummary();
      emit(AdminAnalyticsLoaded(summary));
    } catch (e) {
      emit(AdminAnalyticsError(e.toString()));
    }
  }
}

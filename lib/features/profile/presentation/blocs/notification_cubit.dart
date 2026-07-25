import 'dart:async';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import '../../../../core/firebase/firebase_messaging_service.dart';
import '../../../../core/utils/app_logger.dart';

@injectable
class NotificationCubit extends Cubit<List<RemoteMessage>> {
  final IFirebaseMessagingService _messagingService;
  StreamSubscription<RemoteMessage>? _subscription;

  NotificationCubit(this._messagingService) : super(const []) {
    _init();
  }

  void _init() {
    _subscription = _messagingService.onMessageReceived.listen((
      RemoteMessage message,
    ) {
      AppLogger.i(
        'New push notification received: ${message.notification?.title}',
      );
      final updatedList = List<RemoteMessage>.from(state)..insert(0, message);
      emit(updatedList);
    });
  }

  Future<void> fetchTokenAndLog() async {
    final token = await _messagingService.getFcmToken();
    if (token != null) {
      AppLogger.i('FCM Registration Token: $token');
    }
  }

  void clearNotifications() {
    emit(const []);
  }

  @override
  Future<void> close() {
    _subscription?.cancel();
    return super.close();
  }
}

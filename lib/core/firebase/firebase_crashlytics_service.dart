import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:injectable/injectable.dart';

abstract class IFirebaseCrashlyticsService {
  Future<void> recordError(final dynamic exception, final StackTrace? stack);
  Future<void> forceCrash();
}

@LazySingleton(as: IFirebaseCrashlyticsService)
class FirebaseCrashlyticsService implements IFirebaseCrashlyticsService {
  FirebaseCrashlyticsService() : _crashlytics = FirebaseCrashlytics.instance;

  final FirebaseCrashlytics _crashlytics;

  @override
  Future<void> recordError(
    final dynamic exception,
    final StackTrace? stack,
  ) async {
    await _crashlytics.recordError(exception, stack);
  }

  @override
  Future<void> forceCrash() async {
    _crashlytics.crash();
  }
}

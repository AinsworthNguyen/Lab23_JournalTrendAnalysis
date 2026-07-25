import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:injectable/injectable.dart';

abstract class IFirebaseRemoteConfigService {
  Future<void> initialize();
  int getInt(final String key);
  String getString(final String key);
  Future<void> setInt(final String key, final int value);
  Future<bool> fetchAndActivate();
}

@LazySingleton(as: IFirebaseRemoteConfigService)
class FirebaseRemoteConfigService implements IFirebaseRemoteConfigService {
  FirebaseRemoteConfigService() : _remoteConfig = FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;
  final Map<String, int> _localOverrides = {};

  @override
  Future<void> initialize() async {
    try {
      await _remoteConfig.setDefaults(const {
        'max_journals_limit': 10,
        'max_keywords_limit': 10,
      });
      await _remoteConfig.setConfigSettings(RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 40),
        minimumFetchInterval: const Duration(minutes: 5),
      ));
    } catch (_) {}
  }

  @override
  int getInt(final String key) {
    if (_localOverrides.containsKey(key)) {
      return _localOverrides[key]!;
    }
    try {
      final val = _remoteConfig.getInt(key);
      return val != 0 ? val : 10;
    } catch (_) {
      return 10;
    }
  }

  @override
  String getString(final String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (_) {
      return '';
    }
  }

  @override
  Future<void> setInt(final String key, final int value) async {
    _localOverrides[key] = value;
  }

  @override
  Future<bool> fetchAndActivate() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } on Exception catch (_) {
      return false;
    }
  }
}

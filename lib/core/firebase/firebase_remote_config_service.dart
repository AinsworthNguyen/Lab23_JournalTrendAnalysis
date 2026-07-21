import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:injectable/injectable.dart';

abstract class IFirebaseRemoteConfigService {
  Future<void> initialize();
  int getInt(String key);
  String getString(String key);
  Future<void> setInt(String key, int value);
  Future<bool> fetchAndActivate();
}

@LazySingleton(as: IFirebaseRemoteConfigService)
class FirebaseRemoteConfigService implements IFirebaseRemoteConfigService {
  final FirebaseRemoteConfig _remoteConfig;
  final Map<String, int> _localOverrides = {};

  FirebaseRemoteConfigService() : _remoteConfig = FirebaseRemoteConfig.instance;

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
  int getInt(String key) {
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
  String getString(String key) {
    try {
      return _remoteConfig.getString(key);
    } catch (_) {
      return '';
    }
  }

  @override
  Future<void> setInt(String key, int value) async {
    _localOverrides[key] = value;
  }

  @override
  Future<bool> fetchAndActivate() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } catch (_) {
      return false;
    }
  }
}

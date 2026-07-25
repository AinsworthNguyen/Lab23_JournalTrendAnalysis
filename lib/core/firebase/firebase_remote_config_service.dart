import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:injectable/injectable.dart';

abstract class IFirebaseRemoteConfigService {
  Future<void> initialize();
  int getInt(final String key);
  String getString(final String key);
  Future<bool> fetchAndActivate();
}

@LazySingleton(as: IFirebaseRemoteConfigService)
class FirebaseRemoteConfigService implements IFirebaseRemoteConfigService {
  FirebaseRemoteConfigService() : _remoteConfig = FirebaseRemoteConfig.instance;

  final FirebaseRemoteConfig _remoteConfig;

  @override
  Future<void> initialize() async {
    final Map<String, dynamic> defaults = const <String, dynamic>{
      'max_journals_limit': 10,
      'max_keywords_limit': 10,
    };
    await _remoteConfig.setDefaults(defaults);
    await _remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 40),
        minimumFetchInterval: const Duration(minutes: 5),
      ),
    );
  }

  @override
  int getInt(final String key) => _remoteConfig.getInt(key);

  @override
  String getString(final String key) => _remoteConfig.getString(key);

  @override
  Future<bool> fetchAndActivate() async {
    try {
      return await _remoteConfig.fetchAndActivate();
    } on Exception catch (_) {
      return false;
    }
  }
}

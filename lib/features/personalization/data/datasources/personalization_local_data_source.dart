import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/prefs_keys.dart';
import '../../../../core/error/exceptions.dart';
import '../models/user_preferences_model.dart';

abstract class PersonalizationLocalDataSource {
  Future<UserPreferencesModel> getUserPreferences();
  Future<void> saveUserPreferences(UserPreferencesModel preferences);
  Future<void> clearUserPreferences();
}

@LazySingleton(as: PersonalizationLocalDataSource)
class PersonalizationLocalDataSourceImpl implements PersonalizationLocalDataSource {
  final SharedPreferences _sharedPreferences;

  PersonalizationLocalDataSourceImpl(this._sharedPreferences);

  @override
  Future<UserPreferencesModel> getUserPreferences() async {
    final name = _sharedPreferences.getString(PrefsKeys.fullName);
    final email = _sharedPreferences.getString(PrefsKeys.email) ?? '';
    final photoUrl = _sharedPreferences.getString(PrefsKeys.photoUrl) ?? '';
    var conceptId = _sharedPreferences.getString(PrefsKeys.interestConceptId);
    final conceptName = _sharedPreferences.getString(PrefsKeys.interestConceptName);

    if (name != null && conceptId != null && conceptName != null) {
      // Migrating legacy/invalid OpenAlex concept IDs to new verified ones
      const migrations = {
        'C111900269': 'C41008148',    // Computer Science
        'C94389079': 'C2522767166',   // Data Science
        'C157449867': 'C15744967',    // Psychology
        'C19165224': 'C138885662',    // Philosophy
        'C142362112': 'C192562407',   // Materials Science
      };

      if (migrations.containsKey(conceptId)) {
        final newId = migrations[conceptId]!;
        await _sharedPreferences.setString(PrefsKeys.interestConceptId, newId);
        conceptId = newId;
      }

      final role = _sharedPreferences.getString('KEY_USER_ROLE') ?? 'admin';

      return UserPreferencesModel(
        fullName: name,
        email: email,
        photoUrl: photoUrl,
        interestConceptId: conceptId,
        interestConceptName: conceptName,
        role: role,
      );
    } else {
      throw CacheException('No user preferences found.');
    }
  }

  @override
  Future<void> saveUserPreferences(UserPreferencesModel preferences) async {
    try {
      await _sharedPreferences.setString(PrefsKeys.fullName, preferences.fullName);
      await _sharedPreferences.setString(PrefsKeys.email, preferences.email);
      await _sharedPreferences.setString(PrefsKeys.photoUrl, preferences.photoUrl);
      await _sharedPreferences.setString(PrefsKeys.interestConceptId, preferences.interestConceptId);
      await _sharedPreferences.setString(PrefsKeys.interestConceptName, preferences.interestConceptName);
    } catch (e) {
      throw CacheException('Failed to save user preferences: $e');
    }
  }

  @override
  Future<void> clearUserPreferences() async {
    try {
      await _sharedPreferences.remove(PrefsKeys.fullName);
      await _sharedPreferences.remove(PrefsKeys.email);
      await _sharedPreferences.remove(PrefsKeys.photoUrl);
      await _sharedPreferences.remove(PrefsKeys.interestConceptId);
      await _sharedPreferences.remove(PrefsKeys.interestConceptName);
      await _sharedPreferences.remove(PrefsKeys.lastSyncDate);
    } catch (e) {
      throw CacheException('Failed to clear user preferences: $e');
    }
  }
}

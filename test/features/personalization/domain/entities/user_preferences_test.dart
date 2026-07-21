import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/features/personalization/domain/entities/user_preferences.dart';
import 'package:journal_trend_analysis/features/personalization/data/models/user_preferences_model.dart';

void main() {
  group('UserPreferences & UserPreferencesModel', () {
    const userPrefs = UserPreferences(
      fullName: 'John Admin',
      email: 'admin@example.com',
      photoUrl: 'https://example.com/photo.jpg',
      interestConceptId: 'C41008148',
      interestConceptName: 'Computer Science',
      role: 'admin',
      isBlocked: false,
    );

    const normalUserPrefs = UserPreferences(
      fullName: 'Jane User',
      email: 'user@example.com',
      photoUrl: '',
      interestConceptId: 'C2522767166',
      interestConceptName: 'Data Science',
      role: 'user',
      isBlocked: true,
    );

    test('isAdmin getter returns true for admin role and false for user role', () {
      expect(userPrefs.isAdmin, isTrue);
      expect(normalUserPrefs.isAdmin, isFalse);
    });

    test('UserPreferencesModel.fromJson parses role and isBlocked correctly', () {
      final json = {
        'fullName': 'John Admin',
        'email': 'admin@example.com',
        'photoUrl': 'https://example.com/photo.jpg',
        'interestConceptId': 'C41008148',
        'interestConceptName': 'Computer Science',
        'role': 'admin',
        'isBlocked': false,
      };

      final model = UserPreferencesModel.fromJson(json);

      expect(model.role, equals('admin'));
      expect(model.isBlocked, isFalse);
      expect(model.isAdmin, isTrue);
    });

    test('UserPreferencesModel.fromJson defaults role to user and isBlocked to false when missing', () {
      final legacyJson = {
        'fullName': 'Legacy User',
        'email': 'legacy@example.com',
        'photoUrl': '',
        'interestConceptId': 'C15744967',
        'interestConceptName': 'Psychology',
      };

      final model = UserPreferencesModel.fromJson(legacyJson);

      expect(model.role, equals('user'));
      expect(model.isBlocked, isFalse);
      expect(model.isAdmin, isFalse);
    });

    test('UserPreferencesModel.toJson includes role and isBlocked', () {
      final model = UserPreferencesModel.fromEntity(userPrefs);
      final json = model.toJson();

      expect(json['role'], equals('admin'));
      expect(json['isBlocked'], isFalse);
    });
  });
}

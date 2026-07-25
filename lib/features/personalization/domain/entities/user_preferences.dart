import 'package:equatable/equatable.dart';

class UserPreferences extends Equatable {
  final String fullName;
  final String email;
  final String photoUrl;
  final String interestConceptId;
  final String interestConceptName;
  final String role;       // "user" | "admin"
  final bool isBlocked;    // admin can block/unblock accounts

  const UserPreferences({
    required this.fullName,
    required this.email,
    required this.photoUrl,
    required this.interestConceptId,
    required this.interestConceptName,
    this.role = 'user',
    this.isBlocked = false,
  });

  bool get isAdmin => role == 'admin';

  @override
  List<Object?> get props => [
        fullName,
        email,
        photoUrl,
        interestConceptId,
        interestConceptName,
        role,
        isBlocked,
      ];
}


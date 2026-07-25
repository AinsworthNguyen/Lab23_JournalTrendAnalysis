import 'package:equatable/equatable.dart';

class UserPreferences extends Equatable {
  final String fullName;
  final String email;
  final String photoUrl;
  final String interestConceptId;
  final String interestConceptName;

  const UserPreferences({
    required this.fullName,
    required this.email,
    required this.photoUrl,
    required this.interestConceptId,
    required this.interestConceptName,
  });

  @override
  List<Object?> get props => [
    fullName,
    email,
    photoUrl,
    interestConceptId,
    interestConceptName,
  ];
}

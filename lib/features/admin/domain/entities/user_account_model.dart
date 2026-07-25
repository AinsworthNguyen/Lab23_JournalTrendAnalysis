class UserAccountModel {
  final String uid;
  final String displayName;
  final String email;
  final String role;
  final String interestConcept;
  final int totalSearches;
  final int totalBookmarks;
  final DateTime joinedDate;
  final bool isActive;

  const UserAccountModel({
    required this.uid,
    required this.displayName,
    required this.email,
    required this.role,
    required this.interestConcept,
    required this.totalSearches,
    required this.totalBookmarks,
    required this.joinedDate,
    required this.isActive,
  });
}

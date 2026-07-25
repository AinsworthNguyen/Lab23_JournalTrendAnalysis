enum ActivityType { search, exportPdf, login, updatePreference, viewPublication }

class UserActivityLog {
  final String id;
  final String userName;
  final String userEmail;
  final ActivityType type;
  final String actionTitle;
  final String details;
  final DateTime timestamp;
  final String platform;
  final String status;

  const UserActivityLog({
    required this.id,
    required this.userName,
    required this.userEmail,
    required this.type,
    required this.actionTitle,
    required this.details,
    required this.timestamp,
    required this.platform,
    required this.status,
  });
}

class AdminAccounts {
  AdminAccounts._();

  static const Set<String> emails = {
    'ndv6060@gmail.com',
  };

  static bool isAdminEmail(String? email) {
    return email != null && emails.contains(email.trim().toLowerCase());
  }

  static String roleForEmail(String? email) {
    return isAdminEmail(email) ? 'admin' : 'user';
  }
}

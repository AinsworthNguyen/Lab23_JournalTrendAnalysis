import 'package:flutter_test/flutter_test.dart';
import 'package:journal_trend_analysis/core/constants/admin_accounts.dart';

void main() {
  group('AdminAccounts', () {
    test('recognizes ndv6060@gmail.com as admin email', () {
      expect(AdminAccounts.isAdminEmail('ndv6060@gmail.com'), isTrue);
      expect(AdminAccounts.isAdminEmail(' NDV6060@gmail.com '), isTrue);
      expect(AdminAccounts.roleForEmail('ndv6060@gmail.com'), equals('admin'));
    });

    test('uses user role for non-admin emails', () {
      expect(AdminAccounts.isAdminEmail('researcher@example.com'), isFalse);
      expect(AdminAccounts.roleForEmail('researcher@example.com'), equals('user'));
    });
  });
}

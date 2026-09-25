import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Admin Credentials & Security Permission Tests', () {
    setUp(() {
      SharedPreferences.setMockInitialValues({});
    });

    test('Default login succeeds with admin and 123456', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(adminProvider.notifier);
      final success = await notifier.login('admin', '123456');

      expect(success, isTrue);
      expect(container.read(adminProvider).isAuthenticated, isTrue);
      expect(container.read(adminProvider).currentUser?.name, 'admin');
    });

    test('Login fails with incorrect password', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(adminProvider.notifier);
      final success = await notifier.login('admin', 'wrong_pass');

      expect(success, isFalse);
      expect(container.read(adminProvider).isAuthenticated, isFalse);
    });

    test('Credential change fails without correct previous password permission', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(adminProvider.notifier);

      // Verify permission check returns false for incorrect current password
      final isPermitted = await notifier.verifyCurrentPassword('wrong_previous_pass');
      expect(isPermitted, isFalse);

      // Attempt to change credentials with wrong previous password
      final changeSuccess = await notifier.changeCredentials(
        currentPassword: 'wrong_previous_pass',
        newUsername: 'new_admin',
        newPassword: 'new_secret_password',
      );
      expect(changeSuccess, isFalse);

      // Ensure credentials were not changed in persistent storage
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('admin_username'), isNull);
      expect(prefs.getString('admin_password'), isNull);

      // Old credentials must still work
      final oldLoginSuccess = await notifier.login('admin', '123456');
      expect(oldLoginSuccess, isTrue);
    });

    test('Credential change succeeds with correct previous password permission and updates future logins', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(adminProvider.notifier);

      // Verify permission check returns true for correct current password (123456)
      final isPermitted = await notifier.verifyCurrentPassword('123456');
      expect(isPermitted, isTrue);

      // Change credentials with correct previous password
      final changeSuccess = await notifier.changeCredentials(
        currentPassword: '123456',
        newUsername: 'haseeb_admin',
        newPassword: 'MyNewPassword#2026',
      );
      expect(changeSuccess, isTrue);

      // Verify SharedPreferences updated
      final prefs = await SharedPreferences.getInstance();
      expect(prefs.getString('admin_username'), 'haseeb_admin');
      expect(prefs.getString('admin_password'), 'MyNewPassword#2026');

      // Old password should now fail
      final oldLogin = await notifier.login('admin', '123456');
      expect(oldLogin, isFalse);

      // New credentials must now succeed
      final newLogin = await notifier.login('haseeb_admin', 'MyNewPassword#2026');
      expect(newLogin, isTrue);
      expect(container.read(adminProvider).isAuthenticated, isTrue);
      expect(container.read(adminProvider).currentUser?.name, 'haseeb_admin');
    });

    test('Username can be updated without changing password if new password is blank', () async {
      final container = ProviderContainer();
      addTearDown(container.dispose);

      final notifier = container.read(adminProvider.notifier);

      final changeSuccess = await notifier.changeCredentials(
        currentPassword: '123456',
        newUsername: 'only_username_changed',
        newPassword: null,
      );
      expect(changeSuccess, isTrue);

      // Password remains 123456
      final login = await notifier.login('only_username_changed', '123456');
      expect(login, isTrue);
    });
  });
}

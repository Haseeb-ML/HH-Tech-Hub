import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:software_house_erp/features/administration/shared/providers/admin_provider.dart';

class MockPathProviderPlatform extends Fake
    with MockPlatformInterfaceMixin
    implements PathProviderPlatform {
  @override
  Future<String?> getApplicationDocumentsPath() async {
    return Directory.systemTemp.path;
  }

  @override
  Future<String?> getDownloadsPath() async {
    return Directory.systemTemp.path;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();
  PathProviderPlatform.instance = MockPathProviderPlatform();

  group('Admin Credentials & Security Permission Tests', () {
    late ProviderContainer container;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      await Future.delayed(const Duration(milliseconds: 50));
    });

    tearDown(() {
      // Avoid disposing container to keep database connection open across tests
    });

    test('Default login succeeds with admin and 123456', () async {
      final notifier = container.read(adminProvider.notifier);
      final success = await notifier.login('admin', '123456');

      expect(success, isTrue);
      expect(container.read(adminProvider).isAuthenticated, isTrue);
    });

    test('Login fails with incorrect password', () async {
      final notifier = container.read(adminProvider.notifier);
      final success = await notifier.login('admin', 'wrong_pass');

      expect(success, isFalse);
    });

    test('Credential change fails without correct previous password permission', () async {
      final notifier = container.read(adminProvider.notifier);

      final isPermitted = await notifier.verifyCurrentPassword('wrong_previous_pass');
      expect(isPermitted, isFalse);

      final changeSuccess = await notifier.changeCredentials(
        currentPassword: 'wrong_previous_pass',
        newUsername: 'new_admin',
        newPassword: 'new_secret_password',
      );
      expect(changeSuccess, isFalse);
    });

    test('Credential change succeeds with correct previous password permission and updates future logins', () async {
      final notifier = container.read(adminProvider.notifier);

      final isPermitted = await notifier.verifyCurrentPassword('123456');
      expect(isPermitted, isTrue);

      final changeSuccess = await notifier.changeCredentials(
        currentPassword: '123456',
        newUsername: 'haseeb_admin',
        newPassword: 'MyNewPassword#2026',
      );
      expect(changeSuccess, isTrue);

      final oldLogin = await notifier.login('admin', '123456');
      expect(oldLogin, isFalse);

      final newLogin = await notifier.login('haseeb_admin', 'MyNewPassword#2026');
      expect(newLogin, isTrue);
    });
  });
}

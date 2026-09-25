import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:path_provider_platform_interface/path_provider_platform_interface.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';
import 'package:software_house_erp/core/auth/data/auth_local_repository.dart';
import 'package:software_house_erp/core/auth/models/app_permissions.dart';
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

  group('Role Validation on Login Tests', () {
    late ProviderContainer container;

    setUpAll(() async {
      SharedPreferences.setMockInitialValues({});
      container = ProviderContainer();
      // Let initial async tasks settle
      await Future.delayed(const Duration(milliseconds: 100));

      // Provision HR user fixture specifically for testing role validation
      final authRepo = container.read(authLocalRepositoryProvider);
      await authRepo.initializeSchemaAndSeedDefaults();
      await authRepo.saveCustomRole(const UserRole(
        id: 'test_role_hr',
        roleName: 'HR Manager',
        description: 'Test HR',
        isActive: true,
        permissions: {},
      ));
      final existingHr = await authRepo.findUserByIdentifier('hr');
      if (existingHr != null) {
        await authRepo.resetPassword(existingHr.id, 'hr123');
        await authRepo.updateUser(existingHr.copyWith(role: 'HR Manager', isActive: true));
      } else {
        await authRepo.createUser(
          fullName: 'HR Manager',
          username: 'hr',
          email: 'hr@hhtech.com',
          password: 'hr123',
          role: 'HR Manager',
        );
      }
    });

    tearDownAll(() {
      container.dispose();
    });

    test('1. Selecting HR Manager with Admin credentials MUST fail with role mismatch', () async {
      final notifier = container.read(adminProvider.notifier);

      // Attempt login selecting HR Manager but typing admin credentials
      final success = await notifier.login(
        'admin',
        '123456',
        selectedRole: 'HR Manager',
      );

      expect(success, isFalse);
      expect(container.read(adminProvider).isAuthenticated, isFalse);
      expect(container.read(adminProvider).authErrorMessage, contains('Role Mismatch'));
      expect(container.read(adminProvider).authErrorMessage, contains('Super Admin'));
    });

    test('2. Selecting Super Admin with Admin credentials MUST succeed', () async {
      final notifier = container.read(adminProvider.notifier);

      final success = await notifier.login(
        'admin',
        '123456',
        selectedRole: 'Super Admin',
      );

      expect(success, isTrue);
      expect(container.read(adminProvider).isAuthenticated, isTrue);
      expect(container.read(adminProvider).currentUser?.role, 'Super Admin');

      // Logout to test next case cleanly
      await notifier.logout();
      expect(container.read(adminProvider).isAuthenticated, isFalse);
    });

    test('3. Selecting HR Manager with HR credentials MUST succeed with HR role', () async {
      final notifier = container.read(adminProvider.notifier);

      final success = await notifier.login(
        'hr',
        'hr123',
        selectedRole: 'HR Manager',
      );

      expect(success, isTrue);
      expect(container.read(adminProvider).isAuthenticated, isTrue);
      expect(container.read(adminProvider).currentUser?.role, contains('HR'));

      // Logout to test next case cleanly
      await notifier.logout();
      expect(container.read(adminProvider).isAuthenticated, isFalse);
    });

    test('4. Selecting Super Admin with HR credentials MUST fail with access denied', () async {
      final notifier = container.read(adminProvider.notifier);

      final success = await notifier.login(
        'hr',
        'hr123',
        selectedRole: 'Super Admin',
      );

      expect(success, isFalse);
      expect(container.read(adminProvider).isAuthenticated, isFalse);
      expect(container.read(adminProvider).authErrorMessage, contains('Access Denied'));
    });

    test('5. Upserting user hrr to HR Manager role and logging in with 123456 MUST succeed', () async {
      final authRepo = container.read(authLocalRepositoryProvider);
      final notifier = container.read(adminProvider.notifier);

      // Create or upsert user 'hrr' with role 'HR Manager' and password '123456'
      await authRepo.createUser(
        fullName: 'HR Manager',
        username: 'hrr',
        email: 'hrr@hhtech.com',
        password: '123456',
        role: 'HR Manager',
      );

      // Now attempt login with selectedRole: 'HR Manager', username: 'hrr', password: '123456'
      final success = await notifier.login(
        'hrr',
        '123456',
        selectedRole: 'HR Manager',
      );

      expect(success, isTrue);
      expect(container.read(adminProvider).isAuthenticated, isTrue);
      expect(container.read(adminProvider).currentUser?.username, 'hrr');
      expect(container.read(adminProvider).currentUser?.role, 'HR Manager');

      await notifier.logout();
    });
  });
}


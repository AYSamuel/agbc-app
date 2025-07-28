import 'package:flutter_test/flutter_test.dart';
import 'package:grace_portal/models/user_model.dart';

void main() {
  group('AuthService Dependencies', () {
    test('should have UserModel available', () {
      // Test that UserModel can be created (testing a dependency of AuthService)
      final user = UserModel(
        id: 'test-id',
        displayName: 'Test User',
        email: 'test@example.com',
        role: UserRole.member,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        isActive: true,
        emailVerified: true,
        departments: [],
      );
      
      expect(user.id, 'test-id');
      expect(user.displayName, 'Test User');
      expect(user.email, 'test@example.com');
      expect(user.role, UserRole.member);
      expect(user.isActive, true);
    });

    test('should have UserRole enum values', () {
      // Test that UserRole enum has expected values
      expect(UserRole.values.contains(UserRole.admin), true);
      expect(UserRole.values.contains(UserRole.pastor), true);
      expect(UserRole.values.contains(UserRole.worker), true);
      expect(UserRole.values.contains(UserRole.member), true);
    });
  });
}
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:car_maintenance_center/providers/role_provider.dart';

void main() {
  test('Verify default simulated user role is admin', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final currentRole = container.read(roleProvider);
    expect(currentRole, UserRole.admin);
  });
}

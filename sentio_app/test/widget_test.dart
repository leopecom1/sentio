import 'package:flutter_test/flutter_test.dart';
import 'package:sentio_app/providers/app_provider.dart';

void main() {
  test('AppProvider initializes correctly', () {
    final provider = AppProvider();
    expect(provider.isAuthenticated, false);
    expect(provider.profile, null);
    expect(provider.checkins, isEmpty);
    expect(provider.journalEntries, isEmpty);
  });
}

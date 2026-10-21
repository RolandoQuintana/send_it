import 'package:flutter_test/flutter_test.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:send_it/services/contacts_access_service.dart';

void main() {
  test('maps iOS permission states', () {
    ContactsAccess map(PermissionStatus s) =>
        ContactsAccessService.fromPermissionStatus(s);

    expect(map(PermissionStatus.granted), ContactsAccess.granted);
    expect(map(PermissionStatus.limited), ContactsAccess.limited);
    expect(map(PermissionStatus.denied), ContactsAccess.notDetermined);
    expect(map(PermissionStatus.permanentlyDenied), ContactsAccess.denied);
    expect(map(PermissionStatus.restricted), ContactsAccess.denied);
    expect(ContactsAccess.limited.canRead, isTrue);
    expect(ContactsAccess.notDetermined.canRead, isFalse);
  });
}

import 'package:flutter_contacts/flutter_contacts.dart';
import 'package:permission_handler/permission_handler.dart';

/// Contacts permission, as the app cares about it.
enum ContactsAccess {
  /// Full access.
  granted,

  /// iOS 18 limited access: only the contacts the user shared.
  limited,

  /// Never asked. The iOS prompt can still be shown.
  notDetermined,

  /// Denied or restricted. Only Settings can change it.
  denied;

  bool get canRead => this == granted || this == limited;
}

/// Reads and requests Contacts access without ever prompting on its own:
/// the iOS prompt only comes from [request], after the pre-prompt.
class ContactsAccessService {
  ContactsAccessService._();

  static Future<ContactsAccess> status() async =>
      fromPermissionStatus(await Permission.contacts.status);

  static Future<ContactsAccess> request() async =>
      fromPermissionStatus(await Permission.contacts.request());

  static Future<List<Contact>> load() => FlutterContacts.getContacts(
        withProperties: true,
        withPhoto: true,
      );

  static Future<bool> openSettings() => openAppSettings();

  /// On iOS, permission_handler reports "never asked" as [PermissionStatus.denied]
  /// and a real denial as [PermissionStatus.permanentlyDenied].
  static ContactsAccess fromPermissionStatus(PermissionStatus status) =>
      switch (status) {
        PermissionStatus.granted ||
        PermissionStatus.provisional =>
          ContactsAccess.granted,
        PermissionStatus.limited => ContactsAccess.limited,
        PermissionStatus.denied => ContactsAccess.notDetermined,
        PermissionStatus.permanentlyDenied ||
        PermissionStatus.restricted =>
          ContactsAccess.denied,
      };
}

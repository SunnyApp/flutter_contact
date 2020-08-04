import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contact_example/contacts_list_page.dart';
import 'package:logging/logging.dart';
import 'package:logging_config/logging_config.dart';
import 'package:permission_handler/permission_handler.dart';

void main() {
  configureLogging(LogConfig.root(Level.INFO));
  runApp(ContactsExampleApp());
}

class ContactsExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ContactListPage(),
      routes: <String, WidgetBuilder>{
        '/add': (BuildContext context) => AddContactPage(),
        '/contactsList': (BuildContext context) => ContactListPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  @override
  void initState() {
    super.initState();
    _askPermissions();
  }

  Future<void> _askPermissions() async {
    final permissionStatus = await _getContactPermission();
    if (permissionStatus != PermissionStatus.granted) {
      _handleInvalidPermissions(permissionStatus);
    }
  }

  Future<PermissionStatus> _getContactPermission() async {
    final status = await Permission.contacts.status;
    if (!status.isGranted && !status.isPermanentlyDenied) {
      final result = await Permission.contacts.request();
      return result ?? PermissionStatus.undetermined;
    } else {
      return status;
    }
  }

  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      throw PlatformException(
          code: 'PERMISSION_DENIED',
          message: 'Access to location data denied',
          details: null);
    } else if (permissionStatus == PermissionStatus.restricted) {
      throw PlatformException(
          code: 'PERMISSION_DISABLED',
          message: 'Location data is not available on device',
          details: null);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts Plugin Example')),
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            RaisedButton(
              child: const Text('Contacts list'),
              onPressed: () => Navigator.pushNamed(context, '/contactsList'),
            ),
            RaisedButton(
              child: const Text('Native Contacts picker'),
              onPressed: () =>
                  Navigator.pushNamed(context, '/nativeContactPicker'),
            ),
          ],
        ),
      ),
    );
  }
}

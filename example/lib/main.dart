import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contact_example/people_list_page.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:logging/logging.dart';
import 'package:logging_config/logging_config.dart';
import 'package:permission_handler/permission_handler.dart';

import 'add_contact_page.dart';

void main() {
  configureLogging(LogConfig.root(Level.INFO));
  runApp(ContactsExampleApp());
}

class ContactsExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      routes: <String, WidgetBuilder>{
        '/': (context) => const HomePage(),
        '/add': (BuildContext context) => AddContactPage(),
        '/contactsList': (BuildContext context) => PeopleListPage(),
      },
    );
  }
}

class HomePage extends StatefulWidget {
  @override
  _HomePageState createState() => _HomePageState();

  const HomePage();
}

class _HomePageState extends State<HomePage> {
  bool _hasPermission;
  @override
  void initState() {
    super.initState();
    _askPermissions();
  }

  Future<void> _askPermissions() async {
    PermissionStatus permissionStatus;
    while (permissionStatus != PermissionStatus.granted) {
      try {
        permissionStatus = await _getContactPermission();
        if (permissionStatus != PermissionStatus.granted) {
          _hasPermission = false;
          _handleInvalidPermissions(permissionStatus);
        } else {
          _hasPermission = true;
        }
      } catch (e) {
        if (await showPlatformDialog(
            context: context,
            builder: (context) {
              return PlatformAlertDialog(
                title: Text('Contact Permissions'),
                content: Text(
                    'We are having problems retrieving permissions.  Would you like to '
                    'open the app settings to fix?'),
                actions: [
                  PlatformDialogAction(
                    child: Text('Close'),
                    onPressed: () {
                      Navigator.pop(context, false);
                    },
                  ),
                  PlatformDialogAction(
                    child: Text('Settings'),
                    onPressed: () {
                      Navigator.pop(context, true);
                    },
                  ),
                ],
              );
            })) {
          await openAppSettings();
        }
      }
    }

    await Navigator.of(context).pushReplacementNamed('/contactsList');
  }

  Future<PermissionStatus> _getContactPermission() async {
    final status = await Permission.contacts.status;
    if (!status.isGranted) {
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
      body: _hasPermission == null
          ? Center(child: PlatformCircularProgressIndicator())
          : SafeArea(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: <Widget>[
                  RaisedButton(
                    child: const Text('Contacts list'),
                    onPressed: () =>
                        Navigator.pushNamed(context, '/contactsList'),
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

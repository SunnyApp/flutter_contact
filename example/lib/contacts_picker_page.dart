import 'package:flutter/material.dart';
import 'package:flutter_contact/contacts.dart';

class ContactPickerPage extends StatefulWidget {
  @override
  _ContactPickerPageState createState() => _ContactPickerPageState();
}

class _ContactPickerPageState extends State<ContactPickerPage> {
  Contact _contact;

  @override
  void initState() {
    super.initState();
  }

  Future<void> _pickContact() async {
    try {
//      final Contact contact = await Contacts.openDeviceContactPicker(
//          iOSLocalizedLabels: iOSLocalizedLabels);
//      setState(() {
//        _contact = contact;
//      });
    } catch (e) {
      print(e.toString());
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Contacts Picker Example')),
      body: SafeArea(
          child: Column(
        children: <Widget>[
          RaisedButton(
            child: const Text('Pick a contact'),
            onPressed: _pickContact,
          ),
          if (_contact != null)
            Text('Contact selected: ${_contact.displayName}'),
        ],
      )),
    );
  }
}

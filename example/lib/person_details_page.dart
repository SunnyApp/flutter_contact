import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:flutter_contact_example/tiles.dart';
import 'package:flutter_contact_example/update_person_page.dart';

import 'extensions.dart';

class PersonDetailsPage extends StatefulWidget {
  PersonDetailsPage(
      {required this.contact,
      required this.onContactDeviceSave,
      required this.contactService});

  final Contact contact;
  final Function(Contact contact) onContactDeviceSave;
  final ContactService contactService;

  @override
  _PersonDetailsPageState createState() => _PersonDetailsPageState();
}

class _PersonDetailsPageState extends State<PersonDetailsPage> {
  late Contact _contact;

  @override
  void initState() {
    super.initState();
    _contact = widget.contact;
  }

  Future _openExistingContactOnDevice(BuildContext context) async {
    var contact =
        await widget.contactService.openContactEditForm(_contact.identifier);
    if (contact != null) {
      widget.onContactDeviceSave(contact);
    }
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_contact.displayName ?? ''),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () async {
              final res = await widget.contactService.deleteContact(_contact);
              if (res) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.edit),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UpdatePersonPage(
                  contact: _contact,
                ),
              ),
            ),
          ),
          IconButton(
              icon: Icon(Icons.contact_page),
              onPressed: () => _openExistingContactOnDevice(context)),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            ListTile(
              title: Text('Contact Id: ${_contact.identifier}'),
            ),
            ListTile(
              title:
                  Text('Linked Id: ${_contact.unifiedContactId ?? 'Unknown'}'),
            ),
            ListTile(
              title: Text('Last Updated'),
              trailing: Text(_contact.lastModified?.format() ?? 'Unknown'),
            ),
            ListTile(
              title: Text('Name'),
              trailing: Text(_contact.givenName ?? ''),
            ),
            ListTile(
              title: Text('Middle name'),
              trailing: Text(_contact.middleName ?? ''),
            ),
            ListTile(
              title: Text('Family name'),
              trailing: Text(_contact.familyName ?? ''),
            ),
            ListTile(
              title: Text('Prefix'),
              trailing: Text(_contact.prefix ?? ''),
            ),
            ListTile(
              title: Text('Suffix'),
              trailing: Text(_contact.suffix ?? ''),
            ),
            for (final d in (_contact.dates))
              ListTile(
                title: Text(d.label ?? ''),
                trailing: Text(d.date?.format() ?? ''),
              ),
            ListTile(
              title: Text('Company'),
              trailing: Text(_contact.company ?? ''),
            ),
            ListTile(
              title: Text('Job'),
              trailing: Text(_contact.jobTitle ?? ''),
            ),
            AddressesTile(_contact.postalAddresses),
            ItemsTile('Phones', _contact.phones, () async {
              _contact = await Contacts.updateContact(_contact);
              setState(() {});
              widget.onContactDeviceSave(_contact);
            }),
            ItemsTile('Emails', _contact.emails, () async {
              _contact = await Contacts.updateContact(_contact);
              setState(() {});
              widget.onContactDeviceSave(_contact);
            })
          ],
        ),
      ),
    );
  }
}

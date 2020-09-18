import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:flutter_contact_example/tiles.dart';
import 'package:flutter_contact_example/update_person_page.dart';

import 'extensions.dart';

class PersonDetailsPage extends StatelessWidget {
  PersonDetailsPage(this._contact,
      {this.onContactDeviceSave, @required this.contactService});

  final Contact _contact;
  final Function(Contact) onContactDeviceSave;
  final ContactService contactService;

  Future _openExistingContactOnDevice(BuildContext context) async {
    var contact = await contactService.openContactEditForm(_contact.identifier);
    if (onContactDeviceSave != null) {
      onContactDeviceSave(contact);
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
              final res = await contactService.deleteContact(_contact);
              if (res) {
                Navigator.pop(context, true);
              }
            },
          ),
          IconButton(
            icon: Icon(Icons.update),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UpdatePersonPage(
                  contact: _contact,
                ),
              ),
            ),
          ),
          IconButton(
              icon: Icon(Icons.edit),
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
            for (final d in (_contact.dates ?? <ContactDate>[]))
              ListTile(
                title: Text(d.label),
                trailing: Text(d.date.format()),
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
            ItemsTile('Phones', _contact.phones),
            ItemsTile('Emails', _contact.emails)
          ],
        ),
      ),
    );
  }
}

import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:flutter_contact_example/main.dart';
import 'package:flutter_contact_example/update_contact_page.dart';

import 'items_tile.dart';

class ContactDetailsPage extends StatefulWidget {
  ContactDetailsPage(this._contact, this._groups);
  final Contact _contact;
  final Iterable<Group> _groups;

  @override
  _ContactDetailsPageState createState() => _ContactDetailsPageState();
}

class _ContactDetailsPageState extends State<ContactDetailsPage> {
  Contact _contact;

  @override
  void initState() {
    super.initState();
    _contact = widget._contact;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget._contact.displayName ?? ""),
        actions: <Widget>[
//          IconButton(
//            icon: Icon(Icons.share),
//            onPressed: () => shareVCFCard(context, contact: _contact),
//          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => Contacts.deleteContact(widget._contact),
          ),
          IconButton(
            icon: Icon(Icons.update),
            onPressed: () async {
              await Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => UpdateContactsPage(
                    contact: widget._contact,
                  ),
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            if (widget._contact.hasAvatar == true)
              Container(
                height: 120,
                decoration: BoxDecoration(image: DecorationImage(image: MemoryImage(widget._contact.avatar))),
              ),
            ListTile(
              title: Text("Name"),
              trailing: Text(widget._contact.givenName ?? ""),
            ),
            ListTile(
              title: Text("Middle name"),
              trailing: Text(widget._contact.middleName ?? ""),
            ),
            ListTile(
              title: Text("Family name"),
              trailing: Text(widget._contact.familyName ?? ""),
            ),
            ListTile(
              title: Text("Prefix"),
              trailing: Text(widget._contact.prefix ?? ""),
            ),
            ListTile(
              title: Text("Suffix"),
              trailing: Text(widget._contact.suffix ?? ""),
            ),
            ListTile(
              title: Text("Company"),
              trailing: Text(widget._contact.company ?? ""),
            ),
            ListTile(
              title: Text("Job"),
              trailing: Text(widget._contact.jobTitle ?? ""),
            ),
            ListTile(
              title: Text("Note"),
              trailing: Text(widget._contact.note ?? ""),
            ),
            AddressesTile(widget._contact.postalAddresses),
            ItemsTile(widget._contact, "Phones", widget._contact.phones, onChange),
            ItemsTile(widget._contact, "Social Profiles", widget._contact.socialProfiles, onChange),
            DatesTile(widget._contact, widget._contact.dates, onChange),
            ItemsTile(widget._contact, "URLs", widget._contact.urls, onChange),
            ItemsTile(widget._contact, "Emails", widget._contact.emails, onChange),
            GroupsTile(widget._groups)
          ],
        ),
      ),
    );
  }

  onChange() async {
    final refreshed = await Contacts.getContact(_contact.identifier);
    setState(() {
      this._contact = refreshed;
    });
  }
}

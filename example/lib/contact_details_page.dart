import 'dart:typed_data';

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
  bool _avatarZoomed = false;
  double _avatarSize = 150.0;
  Uint8List _avatarData;

  @override
  void initState() {
    super.initState();
    _contact = widget._contact;
    Future.value(_contact.getOrFetchAvatar()).then((_) {
      setState(() {
        if (mounted) {
          _avatarData = _;
        }
      });
    });
  }

  _toggleAvatarSize(BuildContext context) {
    setState(() {
      if (!_avatarZoomed) {
        _avatarSize = MediaQuery.of(context).size.width;
        _avatarZoomed = true;
      } else {
        _avatarZoomed = false;
        _avatarSize = 150.0;
      }
    });
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
              GestureDetector(
                key: Key("contact-avatar-${_contact.identifier}"),
                onTap: () => _toggleAvatarSize(context),
                child: AnimatedContainer(
                  width: _avatarSize,
                  height: _avatarSize,
                  child: Container(
                    width: _avatarSize,
                    height: _avatarSize,
                    decoration: BoxDecoration(
                      image: DecorationImage(fit: BoxFit.cover, image: MemoryImage(_avatarData ?? [])),
                    ),
                  ),
                  duration: Duration(milliseconds: 300),
                ),
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
            GroupsTile(groups: widget._groups)
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

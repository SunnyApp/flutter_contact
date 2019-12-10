import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contact/contact.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:flutter_contact/group.dart';
import 'package:flutter_contact_example/contact_details_page.dart';
import 'package:flutter_contact_example/contact_events_page.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

void main() => runApp(ContactsExampleApp());

class ContactsExampleApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: ContactListPage(),
      routes: <String, WidgetBuilder>{'/add': (BuildContext context) => AddContactPage()},
    );
  }
}

class ContactListPage extends StatefulWidget {
  @override
  _ContactListPageState createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  Iterable<Contact> _contacts;
  List<Group> _groups;
  List<ContactEvent> _events = [];

  bool _isPermissionInvalid = false;

  @override
  initState() {
    super.initState();
    Contacts.configureLogs(level: Level.FINER);
    refreshContacts();
    Contacts.contactEvents.forEach((event) {
      setState(() {
        _events.add(event);
      });
    });
  }

  refreshContacts() async {
    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      var contacts = await Contacts.streamContacts(withHiResPhoto: false).toList();
      var groups = await Contacts.getGroups();
      setState(() {
        _contacts = contacts;
        _groups = groups.toList();
      });
    } else {
      setState(() {
        _isPermissionInvalid = true;
      });
      _handleInvalidPermissions(permissionStatus);
    }
  }

  updateContact() async {
    Contact ninja = _contacts.toList().firstWhere((contact) => contact.familyName.startsWith("Ninja"));
    ninja.avatar = null;
    await Contacts.updateContact(ninja);

    refreshContacts();
  }

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await PermissionHandler().checkPermissionStatus(PermissionGroup.contacts);
    if (permission != PermissionStatus.granted && permission != PermissionStatus.disabled) {
      Map<PermissionGroup, PermissionStatus> permissionStatus =
          await PermissionHandler().requestPermissions([PermissionGroup.contacts]);
      return permissionStatus[PermissionGroup.contacts] ?? PermissionStatus.unknown;
    } else {
      return permission;
    }
  }

  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      throw PlatformException(code: "PERMISSION_DENIED", message: "Access to location data denied", details: null);
    } else if (permissionStatus == PermissionStatus.disabled) {
      throw PlatformException(
        code: "PERMISSION_DISABLED",
        message: "Location data is not available on device",
        details: null,
      );
    }
  }

  int get _contactCount => _contacts?.length ?? 0;

  int get _groupCount => _groups?.length ?? 0;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts Plugin Example'),
        leading: IconButton(
          icon: const Icon(Icons.assessment),
          onPressed: _viewEvents,
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshContacts,
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed("/add").then((_) {
            refreshContacts();
          });
        },
      ),
      body: SafeArea(
        child: _contacts != null
            ? ListView.builder(
                itemCount: _contactCount + _groupCount,
                itemBuilder: (BuildContext context, int index) {
                  if (index >= _contactCount) {
                    Group g = _groups[index - _contactCount];
                    return ListTile(
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) => GroupDetailsPage(
                                  g,
                                  g.contacts.map(
                                    (contactId) => _contacts.firstWhere((contact) => contact.identifier == contactId),
                                  ),
                                )));
                      },
                      title: Text(g.name ?? "No Name"),
                    );
                  } else {
                    Contact c = _contacts?.elementAt(index);
                    return ListTile(
                      onTap: () async {
                        // Test loading the contact by id
                        final loadedContact = await Contacts.getContact(
                          c.identifier,
                          withThumbnails: true,
                          withHiResPhoto: true,
                        );
                        await Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) =>
                                ContactDetailsPage(loadedContact, _groupsForContact(c.identifier))));
                        setState(() {});
                      },
                      leading: (c.avatar != null && c.avatar.isNotEmpty)
                          ? CircleAvatar(backgroundImage: MemoryImage(c.avatar))
                          : CircleAvatar(child: Text(c.initials())),
                      title: Text(c.displayName ?? ""),
                    );
                  }
                },
              )
            : _isPermissionInvalid
                ? Center(
                    child: ListTile(
                    title: Text("Invalid Permissions",
                        style: TextStyle(
                          color: Colors.red,
                          fontSize: 25,
                          fontWeight: FontWeight.bold,
                        )),
                    subtitle:
                        Text("This demo should request permissions when it starts. If you're seeing this message, "
                            "you may need to reset your permission settings"),
                  ))
                : Center(
                    child: CircularProgressIndicator(),
                  ),
      ),
    );
  }

  _viewEvents() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ContactEventsPage(events: _events)));
  }

  Iterable<Group> _groupsForContact(String contactId) {
    return _groups?.where((group) => group.contacts.contains(contactId));
  }
}

class GroupDetailsPage extends StatelessWidget {
  GroupDetailsPage(this._group, this._contacts);

  final Group _group;
  final Iterable<Contact> _contacts;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_group.name ?? "No Name"),
      ),
      body: SafeArea(
        child: ListView(
          children: _contacts
              .map((c) => ListTile(
                  leading: (c.avatar != null && c.avatar.isNotEmpty)
                      ? CircleAvatar(backgroundImage: MemoryImage(c.avatar))
                      : CircleAvatar(child: Text(c.initials())),
                  title: Text(c.displayName ?? "")))
              .toList(),
        ),
      ),
    );
  }
}

class AddressesTile extends StatelessWidget {
  AddressesTile(this._addresses);

  final Iterable<PostalAddress> _addresses;

  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(title: Text("Addresses")),
        Column(
          children: _addresses
              .map((a) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          title: Text("Street"),
                          trailing: Text(a.street ?? ""),
                        ),
                        ListTile(
                          title: Text("Postcode"),
                          trailing: Text(a.postcode ?? ""),
                        ),
                        ListTile(
                          title: Text("City"),
                          trailing: Text(a.city ?? ""),
                        ),
                        ListTile(
                          title: Text("Region"),
                          trailing: Text(a.region ?? ""),
                        ),
                        ListTile(
                          title: Text("Country"),
                          trailing: Text(a.country ?? ""),
                        ),
                      ],
                    ),
                  ))
              .toList(),
        ),
      ],
    );
  }
}

class GroupsTile extends StatelessWidget {
  GroupsTile(this._groups);

  final Iterable<Group> _groups;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(title: Text("Groups")),
        Column(
          children: _groups
              .map(
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListTile(
                    title: Text(i.name ?? ""),
                    trailing: Text("Total: ${i.contacts.length}"),
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

class AddContactPage extends StatefulWidget {
  @override
  State<StatefulWidget> createState() => _AddContactPageState();
}

class _AddContactPageState extends State<AddContactPage> {
  Contact contact = Contact();
  PostalAddress address = PostalAddress(label: "Home");
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add a contact"),
        actions: <Widget>[
          FlatButton(
            onPressed: () {
              _formKey.currentState.save();
              contact.postalAddresses = [address];
              Contacts.addContact(contact);
              Navigator.of(context).pop();
            },
            child: Icon(Icons.save, color: Colors.white),
          )
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                decoration: const InputDecoration(labelText: 'First name'),
                onSaved: (v) => contact.givenName = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Middle name'),
                onSaved: (v) => contact.middleName = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Last name'),
                onSaved: (v) => contact.familyName = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Prefix'),
                onSaved: (v) => contact.prefix = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Suffix'),
                onSaved: (v) => contact.suffix = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone'),
                onSaved: (v) => contact.phones = [Item(label: "mobile", value: v)],
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'E-mail'),
                onSaved: (v) => contact.emails = [Item(label: "work", value: v)],
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Company'),
                onSaved: (v) => contact.company = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Job'),
                onSaved: (v) => contact.jobTitle = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Note'),
                onSaved: (v) => contact.note = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Street'),
                onSaved: (v) => address.street = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'City'),
                onSaved: (v) => address.city = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Region'),
                onSaved: (v) => address.region = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Postal code'),
                onSaved: (v) => address.postcode = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Country'),
                onSaved: (v) => address.country = v,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

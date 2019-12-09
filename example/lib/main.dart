import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contact/contact.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:flutter_contact/group.dart';
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
      var contacts = await Contacts.getContacts(withHiResPhoto: false);
      var groups = await Contacts.getGroups();
//      var contacts = await ContactsService.getContactsForPhone("8554964652");
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
      throw new PlatformException(code: "PERMISSION_DENIED", message: "Access to location data denied", details: null);
    } else if (permissionStatus == PermissionStatus.disabled) {
      throw new PlatformException(
          code: "PERMISSION_DISABLED", message: "Location data is not available on device", details: null);
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
                        Navigator.of(context).push(MaterialPageRoute(
                            builder: (BuildContext context) =>
                                ContactDetailsPage(loadedContact, _groupsForContact(c.identifier))));
                      },
                      leading: (c.avatar != null && c.avatar.length > 0)
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

class ContactDetailsPage extends StatelessWidget {
  ContactDetailsPage(this._contact, this._groups);
  final Contact _contact;
  final Iterable<Group> _groups;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_contact.displayName ?? ""),
        actions: <Widget>[
//          IconButton(
//            icon: Icon(Icons.share),
//            onPressed: () => shareVCFCard(context, contact: _contact),
//          ),
          IconButton(
            icon: Icon(Icons.delete),
            onPressed: () => Contacts.deleteContact(_contact),
          ),
          IconButton(
            icon: Icon(Icons.update),
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => UpdateContactsPage(
                  contact: _contact,
                ),
              ),
            ),
          ),
        ],
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            if (_contact.hasAvatar == true)
              Container(
                height: 120,
                decoration: BoxDecoration(image: DecorationImage(image: MemoryImage(_contact.avatar))),
              ),
            ListTile(
              title: Text("Name"),
              trailing: Text(_contact.givenName ?? ""),
            ),
            ListTile(
              title: Text("Middle name"),
              trailing: Text(_contact.middleName ?? ""),
            ),
            ListTile(
              title: Text("Family name"),
              trailing: Text(_contact.familyName ?? ""),
            ),
            ListTile(
              title: Text("Prefix"),
              trailing: Text(_contact.prefix ?? ""),
            ),
            ListTile(
              title: Text("Suffix"),
              trailing: Text(_contact.suffix ?? ""),
            ),
            ListTile(
              title: Text("Company"),
              trailing: Text(_contact.company ?? ""),
            ),
            ListTile(
              title: Text("Job"),
              trailing: Text(_contact.jobTitle ?? ""),
            ),
            ListTile(
              title: Text("Note"),
              trailing: Text(_contact.note ?? ""),
            ),
            AddressesTile(_contact.postalAddresses),
            ItemsTile("Phones", _contact.phones),
            ItemsTile("Social Profiles", _contact.socialProfiles),
            ItemsTile("Dates", _contact.dates.map((d) => Item(label: d.label, value: d.date.toString()))),
            ItemsTile("URLs", _contact.urls),
            ItemsTile("Emails", _contact.emails),
            GroupsTile(_groups)
          ],
        ),
      ),
    );
  }
}

class ContactEventsPage extends StatelessWidget {
  final Iterable<ContactEvent> events;

  const ContactEventsPage({Key key, this.events}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Events"),
        automaticallyImplyLeading: true,
      ),
      body: SafeArea(
        child: ListView(
          children: <Widget>[
            if (events.isEmpty) Card(child: ListTile(title: Text("No events.  Try saving a contact on your device"))),
            for (final event in events)
              Card(
                child: ListTile(
                  title: Text("${event.runtimeType}"),
                ),
              )
          ],
        ),
      ),
    );
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
                  leading: (c.avatar != null && c.avatar.length > 0)
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

class ItemsTile extends StatelessWidget {
  ItemsTile(this._title, this._items);
  final Iterable<Item> _items;
  final String _title;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(title: Text(_title)),
        Column(
          children: _items
              .map(
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListTile(
                    title: Text(i.label ?? ""),
                    trailing: Text(i.value ?? ""),
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

class UpdateContactsPage extends StatefulWidget {
  UpdateContactsPage({@required this.contact});
  final Contact contact;
  @override
  _UpdateContactsPageState createState() => _UpdateContactsPageState();
}

class _UpdateContactsPageState extends State<UpdateContactsPage> {
  Contact contact;
  PostalAddress address = PostalAddress(label: "Home");
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  @override
  void initState() {
    super.initState();
    contact = widget.contact;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Update Contact"),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.save,
              color: Colors.white,
            ),
            onPressed: () async {
              _formKey.currentState.save();
              contact.postalAddresses = [address];
              await Contacts.updateContact(contact).then((_) {
                Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => ContactListPage()));
              });
            },
          ),
        ],
      ),
      body: Container(
        padding: EdgeInsets.all(12.0),
        child: Form(
          key: _formKey,
          child: ListView(
            children: <Widget>[
              TextFormField(
                initialValue: contact.givenName ?? "",
                decoration: const InputDecoration(labelText: 'First name'),
                onSaved: (v) => contact.givenName = v,
              ),
              TextFormField(
                initialValue: contact.middleName ?? "",
                decoration: const InputDecoration(labelText: 'Middle name'),
                onSaved: (v) => contact.middleName = v,
              ),
              TextFormField(
                initialValue: contact.familyName ?? "",
                decoration: const InputDecoration(labelText: 'Last name'),
                onSaved: (v) => contact.familyName = v,
              ),
              TextFormField(
                initialValue: contact.prefix ?? "",
                decoration: const InputDecoration(labelText: 'Prefix'),
                onSaved: (v) => contact.prefix = v,
              ),
              TextFormField(
                initialValue: contact.suffix ?? "",
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
                initialValue: contact.company ?? "",
                decoration: const InputDecoration(labelText: 'Company'),
                onSaved: (v) => contact.company = v,
              ),
              TextFormField(
                initialValue: contact.jobTitle ?? "",
                decoration: const InputDecoration(labelText: 'Job'),
                onSaved: (v) => contact.jobTitle = v,
              ),
              TextFormField(
                initialValue: contact.note ?? "",
                decoration: const InputDecoration(labelText: 'Note'),
                onSaved: (v) => contact.note = v,
              ),
              TextFormField(
                initialValue: address.street ?? "",
                decoration: const InputDecoration(labelText: 'Street'),
                onSaved: (v) => address.street = v,
              ),
              TextFormField(
                initialValue: address.city ?? "",
                decoration: const InputDecoration(labelText: 'City'),
                onSaved: (v) => address.city = v,
              ),
              TextFormField(
                initialValue: address.region ?? "",
                decoration: const InputDecoration(labelText: 'Region'),
                onSaved: (v) => address.region = v,
              ),
              TextFormField(
                initialValue: address.postcode ?? "",
                decoration: const InputDecoration(labelText: 'Postal code'),
                onSaved: (v) => address.postcode = v,
              ),
              TextFormField(
                initialValue: address.country ?? "",
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

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contact/contact.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:flutter_contact/group.dart';
import 'package:flutter_contact_example/contact_details_page.dart';
import 'package:flutter_contact_example/contact_events_page.dart';
import 'package:flutter_contact_example/main_search.dart';
import 'package:logging/logging.dart';
import 'package:permission_handler/permission_handler.dart';

export 'package:sunny_dart/sunny_dart.dart';

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
  Iterable<Group> _groups;
  final List<ContactEvent> _events = [];

  PagingList<Contact> _contacts;

  bool useNativeForms = true;
  bool _isPermissionInvalid = false;
  SearchDelegate<Contact> _delegate;
  StreamSubscription _eventSub;

  @override
  void initState() {
    super.initState();
    Contacts.configureLogs(level: Level.FINER);
    refreshContacts();
    _delegate = ContactSearchDelegate(() => useNativeForms);
  }

  @override
  void dispose() {
    _eventSub.cancel();
    super.dispose();
  }

  Future refreshContacts() async {
    PermissionStatus permissionStatus = await _getContactPermission();
    if (permissionStatus == PermissionStatus.granted) {
      var groups = await Contacts.getGroups();

      final contacts = Contacts.listContacts(
        sortBy: ContactSortOrder.firstName(),
        withHiResPhoto: false,
        withThumbnails: true,
      );
      await contacts.length;
      _contacts = contacts;

      setState(() {
        _groups = groups.toList();
      });
    } else {
      setState(() {
        _isPermissionInvalid = true;
      });
      _handleInvalidPermissions(permissionStatus);
    }
  }

  Future toggleNativeForms() async {
    setState(() {
      if (useNativeForms == true) {
        useNativeForms = false;
      } else {
        useNativeForms = true;
      }
    });
  }

  Future<PermissionStatus> _getContactPermission() async {
    PermissionStatus permission = await PermissionHandler().checkPermissionStatus(PermissionGroup.contacts);
    if (permission != PermissionStatus.granted && permission != PermissionStatus.neverAskAgain) {
      Map<PermissionGroup, PermissionStatus> permissionStatus =
          await PermissionHandler().requestPermissions([PermissionGroup.contacts]);
      return permissionStatus[PermissionGroup.contacts] ?? PermissionStatus.unknown;
    } else {
      _eventSub ??= Contacts.contactEvents.listen(
          (event) {
            setState(() {
              _events.add(event);
            });
          },
          cancelOnError: true,
          onError: (err) {
            print("Error in contact event subscription: $err");
          });
      return permission;
    }
  }

  void _handleInvalidPermissions(PermissionStatus permissionStatus) {
    if (permissionStatus == PermissionStatus.denied) {
      throw PlatformException(code: "PERMISSION_DENIED", message: "Access to location data denied", details: null);
    } else if (permissionStatus == PermissionStatus.denied) {
      throw PlatformException(
        code: "PERMISSION_DISABLED",
        message: "Location data is not available on device",
        details: null,
      );
    }
  }

  int get _contactCount => _contacts?.lengthOrEmpty ?? 0;
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Contacts ${_contactCount > 0 ? '($_contactCount)' : ''}'),
        leading: IconButton(
          icon: const Icon(Icons.assessment),
          onPressed: _viewEvents,
        ),
        actions: <Widget>[
          IconButton(
            icon: const Icon(Icons.perm_device_information),
            color: useNativeForms ? Colors.white : Colors.grey,
            onPressed: toggleNativeForms,
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: refreshContacts,
          ),
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () {
              showSearch<Contact>(context: context, delegate: _delegate);
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () async {
          if (useNativeForms) {
            try {
              final insertResult = await Contacts.openContactInsertForm();
              if (insertResult != null) {
                await refreshContacts();
                setState(() {});
              }
            } catch (e) {
              print(e);
            }
          } else {
            await Navigator.of(context).pushNamed("/add").then((_) {
              refreshContacts();
            });
          }
        },
      ),
      body: SafeArea(
        child: _contacts != null
            ? ListView.builder(
                primary: true,
                itemBuilder: (context, index) {
                  return PagingListIndexBuilder<Contact>(
                    name: "contact-list",
                    index: index,
                    itemBuilder: (context, idx, contact) {
                      return ContactListTile(
                        key: IndexKey("contact-tile", index),
                        useNativeForms: useNativeForms,
                        contact: contact,
                        onRecordUpdated: (contact) async {
                          await refreshContacts();
                          setState(() {});
                        },
                        groups: () => _groupsForContact(contact.identifier),
                      );
                    },
                    list: _contacts,
                  );
                },
                itemCount: _contactCount,
                itemExtent: 50,
              )
            : _isPermissionInvalid
                ? Center(
                    child: ListTile(
                    title: Text(
                      "Invalid Permissions",
                      style: TextStyle(
                        color: Colors.red,
                        fontSize: 25,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle:
                        Text("This demo should request permissions when it starts. If you're seeing this message, "
                            "you may need to reset your permission settings"),
                  ))
                : const Center(
                    child: CircularProgressIndicator(),
                  ),
      ),
    );
  }

  void _viewEvents() {
    Navigator.push(context, MaterialPageRoute(builder: (context) => ContactEventsPage(events: _events)));
  }

  Iterable<Group> _groupsForContact(String contactId) {
    return _groups?.where((group) => group.contacts.contains(contactId));
  }
}

typedef Provider<T> = T Function();

class IndexKey extends ValueKey {
  final String list;
  final int index;
  const IndexKey(this.list, this.index) : super("$list-$index");
}

class ContactListTile extends StatelessWidget {
  final Contact contact;
  final Provider<Iterable<Group>> groups;
  final bool useNativeForms;
  final ValueChanged<Contact> onRecordUpdated;
  const ContactListTile(
      {Key key, this.contact, this.groups, @required this.useNativeForms, @required this.onRecordUpdated})
      : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListTile(
      onTap: () async {
        if (useNativeForms) {
          final result = await Contacts.openContactEditForm(contact.identifier);
          if (result != null) {
            onRecordUpdated?.call(result);
          }
        } else {
          // Test loading the contact by id
          final loadedContact = await Contacts.getContact(
            contact.identifier,
            withThumbnails: true,
            withHiResPhoto: true,
          );
          await Navigator.of(context)
              .push(MaterialPageRoute(builder: (BuildContext context) => ContactDetailsPage(loadedContact, groups())));
        }
      },
      leading: (contact.avatar != null && contact.avatar.isNotEmpty)
          ? CircleAvatar(backgroundImage: MemoryImage(contact.avatar))
          : CircleAvatar(child: Text(contact.initials())),
      title: Text(contact.displayName ?? ""),
    );
  }
}

class GroupDetailsPage extends StatelessWidget {
  const GroupDetailsPage({@required this.group});

  final Group group;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        appBar: AppBar(
          title: Text(group.name ?? "No Name"),
        ),
        body: SafeArea(
          child: FutureBuilder<Iterable<Contact>>(
            builder: (context, snapshot) => ListView(
              children: (snapshot.data ?? [])
                  .map((c) => ListTile(
                      leading: (c.avatar != null && c.avatar.isNotEmpty)
                          ? CircleAvatar(backgroundImage: MemoryImage(c.avatar))
                          : CircleAvatar(child: Text(c.initials())),
                      title: Text(c.displayName ?? "")))
                  .toList(),
            ),
            future: Contacts.streamContacts().where((contact) => group.contacts.contains(contact.identifier)).toList(),
          ),
        ));
  }
}

class AddressesTile extends StatelessWidget {
  const AddressesTile(this._addresses);

  final Iterable<PostalAddress> _addresses;

  @override
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
  const GroupsTile({@required this.groups});

  final Iterable<Group> groups;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(title: Text("Groups")),
        Column(
          children: groups
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

typedef ItemBuilder<T> = Widget Function(BuildContext context, int index, T item);

class PagingListIndexBuilder<T> extends StatelessWidget {
  final int index;
  final PagingList<T> list;
  final ItemBuilder<T> itemBuilder;
  final String name;

  PagingListIndexBuilder({@required this.index, @required this.list, @required this.itemBuilder, @required this.name})
      : super(key: Key("list-builder-$name-$index"));

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<T>(
      key: IndexKey("$name-future", index),
      future: Future.value(list.get(index)),
      builder: (context, snapshot) {
        if (snapshot.hasData) {
          return itemBuilder(context, index, snapshot.data);
        } else if (snapshot.hasError) {
          return Text("${snapshot.error}");
        } else {
          return const SizedBox(
            height: 0,
            width: 0,
          );
        }
      },
    );
  }
}

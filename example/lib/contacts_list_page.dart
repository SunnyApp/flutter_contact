import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:logging/logging.dart';
import 'package:logging_config/logging_config.dart';
import 'package:sunny_dart/sunny_dart.dart';

class ContactListPage extends StatefulWidget {
  @override
  _ContactListPageState createState() => _ContactListPageState();
}

class _ContactListPageState extends State<ContactListPage> {
  ContactService _contactService;
  List<Contact> _contacts;
  bool _loading;
  @override
  void initState() {
    super.initState();
    configureLogging(LogConfig.root(Level.INFO, handler: LoggingHandler.dev()));
    _contactService = UnifiedContacts;
    refreshContacts();
    _loading = false;
  }

  Future<void> refreshContacts([bool showIndicator = true]) async {
    if (showIndicator) {
      setState(() {
        _loading = true;
      });
    }
    final contacts = _contactService.listContacts(
        withUnifyInfo: true,
        withThumbnails: true,
        withHiResPhoto: false,
        sortBy: ContactSortOrder.firstName());
    final tmp = <Contact>[];
    while (await contacts.moveNext()) {
      tmp.add(await contacts.current);
    }
    setState(() {
      if (showIndicator) {
        _loading = false;
      }
      _contacts = tmp;
    });
  }

  Future updateContact() async {
    final ninja = _contacts
        .toList()
        .firstWhere((contact) => contact.familyName.startsWith('Ninja'));
    ninja.avatar = null;
    await _contactService.updateContact(ninja);

    await refreshContacts();
  }

  Future _openContactForm() async {
    final contact = await Contacts.openContactInsertForm();
    if (contact != null) {
      await refreshContacts();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Contacts Plugin Example',
        ),
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.create),
            onPressed: _openContactForm,
          ),
          IconButton(
            icon: _contactService.isAggregate
                ? Icon(Icons.people)
                : Icon(Icons.person),
            onPressed: () {
              setState(() {
                if (_contactService.isAggregate) {
                  _contactService = SingleContacts;
                } else {
                  _contactService = UnifiedContacts;
                }
              });
              refreshContacts(true);
            },
          )
        ],
      ),
      floatingActionButton: FloatingActionButton(
        child: Icon(Icons.add),
        onPressed: () {
          Navigator.of(context).pushNamed('/add').then((_) {
            refreshContacts(false);
          });
        },
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await refreshContacts();
        },
        child: CustomScrollView(
          physics: AlwaysScrollableScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: AnimatedSwitcher(
                duration: Duration(milliseconds: 300),
                child: _loading == true
                    ? Padding(
                        padding: const EdgeInsets.all(10),
                        child: Center(
                          child: CircularProgressIndicator(),
                        ),
                      )
                    : const SizedBox(),
              ),
            ),
            ...?_contacts?.map((contact) {
              return SliverToBoxAdapter(
                child: ListTile(
                  onTap: () async {
                    final res = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (BuildContext context) {
                      return PersonDetailsPage(
                        contact,
                        onContactDeviceSave: contactOnDeviceHasBeenUpdated,
                        contactService: _contactService,
                      );
                    }));
                    if (res != null) {
                      await refreshContacts();
                    }
                  },
                  leading: (contact.avatar != null && contact.avatar.isNotEmpty)
                      ? CircleAvatar(
                          backgroundImage: MemoryImage(contact.avatar))
                      : CircleAvatar(child: Text(contact.initials())),
                  title: Text(contact.displayName ?? ''),
                  trailing: (contact.linkedContactIds?.length ?? 0) < 2
                      ? null
                      : InputChip(
                          avatar: CircleAvatar(
                              child:
                                  Text('${contact.linkedContactIds.length}')),
                          label: Text('Linked'),
                        ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  void contactOnDeviceHasBeenUpdated(Contact contact) {
    if (contact == null) return;
    setState(() {
      var id = _contacts.indexWhere((c) => c.identifier == contact.identifier);
      _contacts[id] = contact;
    });
  }
}

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
                builder: (context) => UpdateContactsPage(
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

class AddressesTile extends StatelessWidget {
  AddressesTile(this._addresses);

  final Iterable<PostalAddress> _addresses;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(title: Text('Addresses')),
        Column(
          children: _addresses
              .map((a) => Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 16.0),
                    child: Column(
                      children: <Widget>[
                        ListTile(
                          title: Text('Street'),
                          trailing: Text(a.street ?? ''),
                        ),
                        ListTile(
                          title: Text('Postcode'),
                          trailing: Text(a.postcode ?? ''),
                        ),
                        ListTile(
                          title: Text('City'),
                          trailing: Text(a.city ?? ''),
                        ),
                        ListTile(
                          title: Text('Region'),
                          trailing: Text(a.region ?? ''),
                        ),
                        ListTile(
                          title: Text('Country'),
                          trailing: Text(a.country ?? ''),
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
                    title: Text(i.label ?? ''),
                    trailing: Text(i.value ?? ''),
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
  PostalAddress address = PostalAddress(label: 'Home');
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Add a contact'),
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
                onSaved: (v) => contact.phones = [
                  if (v != null && v.isNotEmpty) Item(label: 'mobile', value: v)
                ],
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'E-mail'),
                onSaved: (v) => contact.emails = [
                  if (v != null && v.isNotEmpty) Item(label: 'work', value: v)
                ],
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
  PostalAddress address;
  Item email;
  Item phone;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    contact = widget.contact;
    address = contact.postalAddresses.firstOrNull();
    if (address == null) {
      address = PostalAddress(label: 'home');
      contact.postalAddresses.add(address);
    }

    email = contact.emails.firstOrNull();
    if (email == null) {
      email = Item(label: 'home');
      contact.emails.add(email);
    }

    phone = contact.phones.firstOrNull();
    if (phone == null) {
      phone = Item(label: 'home');
      contact.phones.add(phone);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Update Contact'),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.save,
              color: Colors.white,
            ),
            onPressed: () async {
              _formKey.currentState.save();
              await Contacts.updateContact(contact);
              await Navigator.of(context).pushReplacement(
                  MaterialPageRoute(builder: (context) => ContactListPage()));
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
                initialValue: contact.givenName ?? '',
                decoration: const InputDecoration(labelText: 'First name'),
                onSaved: (v) => contact.givenName = v,
              ),
              TextFormField(
                initialValue: contact.middleName ?? '',
                decoration: const InputDecoration(labelText: 'Middle name'),
                onSaved: (v) => contact.middleName = v,
              ),
              TextFormField(
                initialValue: contact.familyName ?? '',
                decoration: const InputDecoration(labelText: 'Last name'),
                onSaved: (v) => contact.familyName = v,
              ),
              TextFormField(
                initialValue: contact.prefix ?? '',
                decoration: const InputDecoration(labelText: 'Prefix'),
                onSaved: (v) => contact.prefix = v,
              ),
              TextFormField(
                initialValue: contact.suffix ?? '',
                decoration: const InputDecoration(labelText: 'Suffix'),
                onSaved: (v) => contact.suffix = v,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'Phone'),
                initialValue: phone.value,
                onSaved: (v) => phone.value = v,
                keyboardType: TextInputType.phone,
              ),
              TextFormField(
                decoration: const InputDecoration(labelText: 'E-mail'),
                initialValue: email.value,
                onSaved: (v) => email.value = v,
                keyboardType: TextInputType.emailAddress,
              ),
              TextFormField(
                initialValue: contact.company ?? '',
                decoration: const InputDecoration(labelText: 'Company'),
                onSaved: (v) => contact.company = v,
              ),
              TextFormField(
                initialValue: contact.jobTitle ?? '',
                decoration: const InputDecoration(labelText: 'Job'),
                onSaved: (v) => contact.jobTitle = v,
              ),
              TextFormField(
                initialValue: address.street ?? '',
                decoration: const InputDecoration(labelText: 'Street'),
                onSaved: (v) => address.street = v,
              ),
              TextFormField(
                initialValue: address.city ?? '',
                decoration: const InputDecoration(labelText: 'City'),
                onSaved: (v) => address.city = v,
              ),
              TextFormField(
                initialValue: address.region ?? '',
                decoration: const InputDecoration(labelText: 'Region'),
                onSaved: (v) => address.region = v,
              ),
              TextFormField(
                initialValue: address.postcode ?? '',
                decoration: const InputDecoration(labelText: 'Postal code'),
                onSaved: (v) => address.postcode = v,
              ),
              TextFormField(
                initialValue: address.country ?? '',
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

extension DateComponentsFormat on DateComponents {
  String format() {
    return [year, month, day].where((d) => d != null).join('-');
  }
}

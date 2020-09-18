import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:flutter_contact_example/person_details_page.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';
import 'package:full_text_search/full_text_search.dart';
import 'package:logging/logging.dart';
import 'package:logging_config/logging_config.dart';
import 'package:sunny_dart/sunny_dart.dart';

class PeopleListPage extends StatefulWidget {
  @override
  _PeopleListPageState createState() => _PeopleListPageState();
}

class _PeopleListPageState extends State<PeopleListPage> {
  ContactService _contactService;
  List<Contact> _contacts;
  bool _loading;
  String searchTerm;

  String _searchTerm;

  @override
  void initState() {
    super.initState();
    configureLogging(LogConfig.root(Level.INFO, handler: LoggingHandler.dev()));
    _contactService = UnifiedContacts;
    refreshContacts();
    _loading = false;
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> refreshContacts([bool showIndicator = true]) async {
    if (showIndicator) {
      setState(() {
        _loading = true;
      });
    }
    List<Contact> _newList;
    if (_searchTerm.isNotNullOrBlank) {
      _newList = [
        ...await FullTextSearch<Contact>.ofStream(
          term: _searchTerm,
          items: _contactService.streamContacts(),
          tokenize: (contact) {
            return [
              contact.givenName,
              contact.familyName,
              ...contact.phones
                  .expand((number) => tokenizePhoneNumber(number.value)),
            ].whereNotBlank();
          },
          ignoreCase: true,
          isMatchAll: true,
          isStartsWith: true,
        ).execute().thenMap((results) => results.result)
      ];
    } else {
      final contacts = _contactService.listContacts(
          withUnifyInfo: true,
          withThumbnails: true,
          withHiResPhoto: false,
          sortBy: ContactSortOrder.firstName());
      var tmp = <Contact>[];
      while (await contacts.moveNext()) {
        tmp.add(await contacts.current);
      }
      _newList = tmp;
    }
    setState(() {
      if (showIndicator) {
        _loading = false;
      }
      _contacts = _newList;
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
            SliverToBoxAdapter(
              key: Key('searchBox'),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: PlatformTextField(
                    cupertino: (context, platform) => CupertinoTextFieldData(
                      placeholder: 'Search',
                    ),
                    material: (context, platform) => MaterialTextFieldData(
                      decoration: InputDecoration(hintText: 'Search'),
                    ),
                    onChanged: (term) async {
                      _searchTerm = term;
                      await refreshContacts(false);
                    },
                  ),
                ),
              ),
            ),
            ...?_contacts?.map((contact) {
              return SliverToBoxAdapter(
                child: ListTile(
                  onTap: () async {
                    final _contact =
                        await _contactService.getContact(contact.identifier);
                    final res = await Navigator.of(context).push(
                        MaterialPageRoute(builder: (BuildContext context) {
                      return PersonDetailsPage(
                        _contact,
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

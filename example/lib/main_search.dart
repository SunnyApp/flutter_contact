import 'package:flutter/material.dart';
import 'package:flutter_contact/contact.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:flutter_contact_example/main.dart';

class ContactSearchDelegate extends SearchDelegate<Contact> {
  final bool Function() useNativeForms;

  ContactSearchDelegate(this.useNativeForms);

  @override
  List<Widget> buildActions(BuildContext context) {
    return [];
  }

  @override
  Widget buildLeading(BuildContext context) {
    return null;
  }

  @override
  Widget buildResults(BuildContext context) {
    if (query.isNotEmpty != true)
      return ListTile(
        subtitle: Text("Enter a search term"),
      );
    return const SizedBox(
      width: 0,
      height: 0,
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    if (query.isNotEmpty != true)
      return Center(heightFactor: 8, child: Text("Search for contacts"));
    final results =
        Contacts.listContacts(query: this.query, withHiResPhoto: false);
    return FutureBuilder<int>(
      builder: (BuildContext context, snapshot) {
        final length = snapshot.data;
        if (length == null)
          return const Center(child: CircularProgressIndicator());
        if (length != null && length == 0) {
          return const ListTile(title: Text("No results found"));
        }
        return ListView.builder(
          itemBuilder: (context, item) {
            if (item == 0) {
              return ListTile(title: Text("Result: $length"));
            }
            return PagingListIndexBuilder<Contact>(
              index: item - 1,
              list: results,
              name: "search-results",
              itemBuilder: (context, idx, contact) {
                return ContactListTile(
                  useNativeForms: useNativeForms(),
                  key: IndexKey("search-tile", item),
                  contact: contact,
                  onRecordUpdated: (contact) {
                    this.buildResults(context);
                  },
                  groups: () => [],
                );
              },
            );
          },
          itemCount: length + 1,
          itemExtent: 60,
        );
      },
      future: Future.value(results.length),
    );
  }
}

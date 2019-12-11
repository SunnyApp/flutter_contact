import 'package:flutter/material.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:flutter_contact_example/update_item_page.dart';

class ItemsTile extends StatelessWidget {
  ItemsTile(this.contact, this._title, this._items, this.onChange);

  final List<Item> _items;
  final String _title;
  final Contact contact;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(
          title: Text(_title),
          trailing: IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final item = await showModalBottomSheet<Item>(
                  context: context,
                  builder: (context) {
                    return UpdateItemPage(type: _title);
                  });

              if (item != null && !_items.contains(item)) {
                _items.add(item);
                await Contacts.updateContact(contact);
                onChange?.call();
              }
            },
          ),
        ),
        Column(
          children: _items
              .map(
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListTile(
                    onLongPress: () async {
                      _items.remove(i);
                      await Contacts.updateContact(contact);
                      onChange?.call();
                    },
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

class DatesTile extends StatelessWidget {
  DatesTile(this.contact, this._items, this.onChange);

  final List<ContactDate> _items;
  final Contact contact;
  final VoidCallback onChange;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(
          title: Text("Dates"),
          trailing: IconButton(
            icon: Icon(Icons.add),
            onPressed: () async {
              final item = await showModalBottomSheet<Item>(
                  context: context,
                  builder: (context) {
                    return UpdateItemPage(type: "Dates");
                  });

              if (item != null && !_items.contains(item)) {
                _items.add(ContactDate(
                    label: item.label,
                    date: DateComponents.fromJson(item.value)));
                await Contacts.updateContact(contact);
                onChange?.call();
              }
            },
          ),
        ),
        Column(
          children: _items
              .map(
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListTile(
                    title: Text(i.label ?? ""),
                    trailing: Text(i.date?.toString() ?? ""),
                    onLongPress: () async {
                      _items.remove(i);
                      await Contacts.updateContact(contact);
                      onChange?.call();
                    },
                  ),
                ),
              )
              .toList(),
        ),
      ],
    );
  }
}

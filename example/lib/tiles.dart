import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:flutter_platform_widgets/flutter_platform_widgets.dart';

class ItemsTile extends StatefulWidget {
  ItemsTile(this._title, this._items, this.onChange);

  final Iterable<Item> _items;
  final String _title;
  final VoidCallback onChange;

  @override
  _ItemsTileState createState() => _ItemsTileState();
}

class _ItemsTileState extends State<ItemsTile> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        ListTile(title: Text(widget._title)),
        Column(
          children: widget._items
              .map(
                (i) => Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ListTile(
                    title: Text(i.label ?? ''),
                    trailing: Text(i.value ?? ''),
                    onTap: () async {
                      /// Pop something to edit label
                      final newLabel = await showPlatformDialog<String>(
                          context: context,
                          builder: (context) {
                            return EditLabelPage(label: i.label ?? 'No Label');
                          });

                      setState(() {
                        i.label = newLabel;
                      });
                      widget.onChange.call();
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

class EditLabelPage extends StatefulWidget {
  final String label;

  const EditLabelPage({Key? key, required this.label}) : super(key: key);

  @override
  _EditLabelPageState createState() => _EditLabelPageState();
}

class _EditLabelPageState extends State<EditLabelPage> {
  late TextEditingController _controller;

  @override
  void initState() {
    super.initState();
    _controller = TextEditingController(text: widget.label);
  }

  @override
  void dispose() {
    super.dispose();
    _controller.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return PlatformAlertDialog(
      title: Text('Edit Label'),
      content: Column(
        children: [
          PlatformTextField(
            controller: _controller,
          ),
        ],
      ),
      actions: [
        PlatformDialogAction(
            onPressed: () {
              Navigator.pop(context, _controller.text);
            },
            child: Text('Save')),
        PlatformDialogAction(
          onPressed: () {
            Navigator.pop(context);
          },
          child: Text('Cancel'),
        )
      ],
    );
  }
}

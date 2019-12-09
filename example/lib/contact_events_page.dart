import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_contact/contacts.dart';

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

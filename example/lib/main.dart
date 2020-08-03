import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_phone_state/extensions_static.dart';
import 'package:flutter_phone_state/flutter_phone_state.dart';

void main() {
  runApp(MyApp());
}

///
/// The example app has the ability to initiate a call from within the app; otherwise, it lists all
/// calls with their state
///
class MyApp extends StatefulWidget {
  @override
  _MyAppState createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  List<RawPhoneEvent> _rawEvents;
  List<PhoneCallEvent> _phoneEvents;

  /// The result of the user typing
  String _phoneNumber;

  @override
  void initState() {
    super.initState();
    _phoneEvents = _accumulate(FlutterPhoneState.phoneCallEvents);
    _rawEvents = _accumulate(FlutterPhoneState.rawPhoneEvents);
  }

  List<R> _accumulate<R>(Stream<R> input) {
    final items = <R>[];
    input.forEach((item) {
      if (item != null) {
        setState(() {
          items.add(item);
        });
      }
    });
    return items;
  }

  /// Extracts a list of phone calls from the accumulated events
  Iterable<PhoneCall> get _completedCalls =>
      Map.fromEntries(_phoneEvents.reversed.map((PhoneCallEvent event) {
        return MapEntry(event.call.id, event.call);
      })).values.where((c) => c.isComplete).toList();

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        appBar: AppBar(
          title: const Text('Phone Call State Example App'),
        ),
        body: ListView(
          padding: EdgeInsets.all(10),
          children: [
            Row(children: [
              Flexible(
                  flex: 1,
                  child: TextField(
                    onChanged: (v) => _phoneNumber = v,
                    decoration: InputDecoration(labelText: "Phone number"),
                  )),
              MaterialButton(
                onPressed: () => _initiateCall(),
                child: Text("Make Call", style: TextStyle(color: Colors.white)),
                color: Colors.blue,
              ),
            ]),
            verticalSpace,
            _title("Current Calls"),
            for (final call in FlutterPhoneState.activeCalls)
              _CallCard(phoneCall: call),
            if (FlutterPhoneState.activeCalls.isEmpty)
              Center(child: Text("No Active Calls")),
            _title("Call History"),
            for (final call in _completedCalls)
              _CallCard(
                phoneCall: call,
              ),
            if (_completedCalls.isEmpty)
              Center(child: Text("No Completed Calls")),
            verticalSpace,
            _title("Raw Event History"),
            if (_rawEvents.isNotEmpty)
              Padding(
                padding: EdgeInsets.all(10),
                child: Table(
                  children: [
                    TableRow(children: [
                      Text(
                        "id",
                        style: listHeaderStyle,
                        maxLines: 1,
                      ),
                      Text("number", style: listHeaderStyle),
                      Text("event", style: listHeaderStyle),
                    ]),
                    for (final event in _rawEvents)
                      TableRow(children: [
                        _cell(truncate(event.id, 8)),
                        _cell(event.phoneNumber),
                        _cell(value(event.type)),
                      ]),
                  ],
                ),
              ),
            if (_rawEvents.isEmpty) Center(child: Text("No Raw Events")),
          ],
        ),
      ),
    );
  }

  Widget _cell(text) {
    return Padding(
        padding: EdgeInsets.all(5),
        child: Text(
          text?.toString() ?? '-',
          maxLines: 1,
        ));
  }

  Widget _title(text) {
    return Padding(
        padding: EdgeInsets.only(bottom: 10, top: 5),
        child: Text(text?.toString() ?? '-', maxLines: 1, style: headerStyle));
  }

  _initiateCall() {
    if (_phoneNumber?.isNotEmpty == true) {
      setState(() {
        FlutterPhoneState.startPhoneCall(_phoneNumber);
      });
    }
  }
}

class _CallCard extends StatelessWidget {
  final PhoneCall phoneCall;

  const _CallCard({Key key, this.phoneCall}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
          dense: true,
          leading: Icon(
              phoneCall.isOutbound ? Icons.arrow_upward : Icons.arrow_downward),
          title: Text(
            "+${phoneCall.phoneNumber ?? "Unknown number"}: ${value(phoneCall.status)}",
            overflow: TextOverflow.visible,
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (phoneCall.id?.isNotEmpty == true)
                Text("id: ${truncate(phoneCall.id, 12)}"),
              for (final event in phoneCall.events)
                Text(
                  "- ${value(event.status) ?? "-"}",
                  maxLines: 1,
                ),
            ],
          ),
          trailing: FutureBuilder<PhoneCall>(
            builder: (context, snap) {
              if (snap.hasData && snap.data?.isComplete == true) {
                return Text("${phoneCall.duration?.inSeconds ?? '?'}s");
              } else {
                return CircularProgressIndicator();
              }
            },
            future: Future.value(phoneCall.done),
          )),
    );
  }
}

const headerStyle = TextStyle(fontSize: 18, fontWeight: FontWeight.bold);
const listHeaderStyle = TextStyle(fontWeight: FontWeight.bold);
const verticalSpace = SizedBox(height: 10);

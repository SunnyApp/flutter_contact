import 'package:flutter/material.dart';
import 'package:flutter_contact/contacts.dart';

class UpdateItemPage extends StatefulWidget {
  const UpdateItemPage({@required this.type, this.item});

  final String type;
  final Item item;

  @override
  _UpdateItemPageState createState() => _UpdateItemPageState();
}

class _UpdateItemPageState extends State<UpdateItemPage> {
  Item item;
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    item = Item(label: widget.item?.label, value: widget.item?.value);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Add/Edit ${widget.type}"),
        actions: <Widget>[
          IconButton(
            icon: Icon(
              Icons.save,
              color: Colors.white,
            ),
            onPressed: () async {
              _formKey.currentState.save();
              Navigator.pop(context, item);
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
                initialValue: item.label ?? "",
                decoration: const InputDecoration(labelText: 'Label'),
                onSaved: (v) => item.label = v,
              ),
              TextFormField(
                initialValue: item.value ?? "",
                decoration: const InputDecoration(labelText: 'Value'),
                onSaved: (v) => item.value = v,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

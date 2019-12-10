import 'dart:math';

import 'package:flutter/services.dart';
import 'package:flutter_contact/contact.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import 'flutter_contact_test.dart';

/// Class that assists in mocking and tracking calls
class ContactsMocks {
  final List<MethodCall> _log;
  final Map<String, dynamic> _data;

  ContactsMocks({Map<String, dynamic> data, List<MethodCall> log})
      : _data = data = {},
        _log = log ?? [] {
    _mockMethods = <String, RawMethodHandler>{
      "getContacts": _getContacts,
      "updateContact": _updateContact,
      "getContact": _getContact,
      "addContact": _addContact,
      "deleteContact": _deleteContact,
    };
  }

  Map<String, RawMethodHandler> _mockMethods;

  MethodHandler get handler => (MethodCall call) async {
        addLog(call);
        final handle = _mockMethods[call.method];
        if (handle == null) throw "No mock provided for ${call.method}";
        return handle(call.arguments);
      };

  addLog(MethodCall log) => _log.add(log);

  Future<dynamic> _getContacts(args) async {
    final offset = args["offset"] ?? 0;
    final limit = args["limit"] ?? 50;
    final allItems = [..._data.values];
    if (allItems.length > offset) {
      return allItems.sublist(offset, min(allItems.length, offset + limit));
    } else {
      return [];
    }
  }

  operator [](String key) {
    return _mockMethods[key];
  }

  Future<dynamic> _getContact(args) async {
    final id = args["identifier"];
    if (id == null) return null;
    return _data[id];
  }

  Future<dynamic> _updateContact(args) async {
    final id = args["identifier"] as String;
    if (id == null) return null;
    _data[id] = args;
    return _data;
  }

  Future<dynamic> _deleteContact(args) async {
    final id = args["identifier"];
    if (id == null) return null;
    _data.remove(id);
    return true;
  }

  Future<dynamic> _addContact(args) async {
    final id = Uuid().v4();
    args["identifier"] = id;
    _data[id] = args;
    return _data;
  }

  void clear() {
    _log.clear();
    _data.clear();
  }

  void expectMethodCall(String name, [dynamic arguments]) {
    expect(_log, invokedMethod(name));
  }

  void addContact(Contact contact) {
    if (contact.identifier?.isNotEmpty != true) {
      contact.identifier = Uuid().v4();
    }
    _data[contact.identifier] = contact.toMap();
  }
}

invokedMethod(String methodName) => InvokedMethod(methodName);

class InvokedMethod extends Matcher {
  final String methodName;
  final arguments;

  InvokedMethod(this.methodName, [this.arguments]);

  @override
  Description describe(Description description) {
    return description;
  }

  @override
  bool matches(final item, Map matchState) {
    final i = item as List<MethodCall>;
    return i.any((call) => call.method == methodName);
  }
}

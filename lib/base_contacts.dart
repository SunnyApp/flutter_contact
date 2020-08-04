import 'dart:async';
import 'dart:typed_data';

import 'package:equatable/equatable.dart';
import 'package:flutter/services.dart';
import 'package:flutter_contact/paging_iterable.dart';
import 'package:logging/logging.dart';
import 'package:logging_config/logging_config.dart';
import 'package:sunny_dart/sunny_dart.dart';

import 'contact.dart';
import 'contact_events.dart';
import 'group.dart';

final _log = Logger("contactsService");

const _kidentifier = "identifier";
const _kwithThumbnails = "withThumbnails";
const _kphotoHighResolution = "photoHighResolution";

abstract class FormsContract {
  /// Opens a native edit form for the contact with [identifier].  This can be a
  /// simple string, but you can also provide a [ContactKeys] instance
  Future<Contact> openContactEditForm(identifier);

  /// Opens a native insert form with [data] preloaded
  Future<Contact> openContactInsertForm(Contact data);
}

abstract class ContactsContract implements FormsContract {
  Stream<Contact> streamContacts(
      {String query,
      bool phoneQuery,
      int bufferSize = 20,
      bool withThumbnails = true,
      bool withHiResPhoto = true,
      bool withUnifyInfo = false,
      ContactSortOrder sortBy});

  Future<int> getTotalContacts({String query, bool phoneQuery});

  PagingList<Contact> listContacts({
    String query,
    bool phoneQuery,
    int bufferSize = 20,
    bool withThumbnails = true,
    bool withHiResPhoto = true,
    bool withUnifyInfo = false,
    ContactSortOrder sortBy,
  });

  void configureLogs({Level level, LoggingHandler onLog});

  Future<Contact> getContact(String identifier,
      {bool withThumbnails = true,
      bool withUnifyInfo = true,
      bool withHiResPhoto = true});

  Future<Uint8List> getContactImage(String identifier);

  Future<Contact> addContact(Contact contact);

  Future<bool> deleteContact(Contact contact);

  Future<Contact> updateContact(Contact contact);

  Future<Iterable<Group>> getGroups();

  Stream<ContactEvent> get contactEvents;
}

const kwithThumbnails = 'withThumbnails';
const kwithUnifyInfo = 'withUnifyInfo';
const kphotoHighResolution = 'photoHighResolution';
const klimit = 'limit';
const ksortBy = 'sortBy';
const koffset = 'offset';
const kquery = 'query';
const kphoneQuery = 'phoneQuery';
const kids = 'ids';

PageGenerator<Contact> _defaultPageGenerator(
        ContactService _service,
        String query,
        bool phoneQuery,
        bool withThumbnails,
        bool withHiResPhoto,
        bool withUnifyInfo,
        ContactSortOrder sortBy) =>
    (int limit, int offset) async {
      final List page = await _service.channel.invokeMethod('getContacts', {
        kquery: query,
        klimit: limit,
        ksortBy: sortBy?._value ?? _service.defaultSort._value,
        koffset: offset,
        kphoneQuery: phoneQuery,
        kwithUnifyInfo: withUnifyInfo,
        kwithThumbnails: withThumbnails,
        kphotoHighResolution: withHiResPhoto,
      });

      return [
        ...page.whereNotNull().map((_) => Contact.fromMap(_, _service.mode))
      ];
    };

class ContactFormService extends ContactService implements FormsContract {
  ContactFormService(
      MethodChannel channel, EventChannel events, ContactMode mode)
      : super(channel, events, mode);
}

class ContactService implements ContactsContract {
  final MethodChannel channel;
  final EventChannel events;
  final ContactMode mode;

  ContactSortOrder _defaultSort = ContactSortOrder.displayName();
  set defaultSort(ContactSortOrder order) {
    assert(order != null);
    _defaultSort = order;
  }

  ContactSortOrder get defaultSort => _defaultSort;

  ContactService(this.channel, this.events, this.mode) : assert(mode != null);

  @override
  Future<Contact> openContactInsertForm([Contact data]) async {
    final map =
        await channel.invokeMethod('openContactInsertForm', data?.toMap());
    if (map["success"] == true) {
      final contact = Contact.of(map["contact"] ?? <String, dynamic>{}, mode);
      _log.info("Saved contact: ${contact.identifier}");
      return contact;
    } else {
      _log.info("Contact form was not saved: ${map["code"] ?? 'unknown'}");
      return null;
    }
  }

  @override
  Future<Contact> openContactEditForm(dynamic identifier) async {
    final contactKey = ContactKeys.of(mode, identifier);
    final map = await channel.invokeMethod(
        'openContactEditForm', {"identifier": contactKey.toMap()});
    if (map["success"] == true) {
      final contact = Contact.of(map["contact"] ?? <String, dynamic>{}, mode);
      _log.info("Saved contact: ${contact.identifier}");
      return contact;
    } else {
      _log.info("Contact form was not saved: ${map["code"] ?? 'unknown'}");
      return null;
    }
  }

  /// Fetches all contacts, or when specified, the contacts with a name
  /// matching [query].  The stream terminates once the items are all iterated.
  @override
  Stream<Contact> streamContacts({
    String query,
    bool phoneQuery,
    bool withThumbnails = true,
    bool withHiResPhoto = true,
    bool withUnifyInfo = false,
    int bufferSize = 20,
    ContactSortOrder sortBy,
  }) {
    final stream = PagingStream<Contact>(
      pageGenerator: _defaultPageGenerator(
        this,
        query,
        phoneQuery,
        withThumbnails,
        withHiResPhoto,
        withUnifyInfo,
        sortBy ?? defaultSort,
      ),
      bufferSize: bufferSize,
    );
    return stream;
  }

  bool get isAggregate => mode == ContactMode.unified;

  @override
  Future<Uint8List> getContactImage(identifier) async {
    if (identifier == null) return null;

    final data = await channel.invokeMethod('getContactImage',
        {'identifier': ContactKeys.of(mode, identifier).toMap()});
    return data as Uint8List;
  }

  @override
  Future<int> getTotalContacts({
    String query,
    bool phoneQuery,
  }) {
    return channel.invokeMethod('getTotalContacts', {
      kquery: query,
      kphoneQuery: phoneQuery,
    });
  }

  @override
  PagingList<Contact> listContacts(
      {String query,
      bool phoneQuery,
      bool withThumbnails = true,
      bool withHiResPhoto = true,
      bool withUnifyInfo = false,
      int bufferSize = 20,
      ContactSortOrder sortBy}) {
    final list = PagingList<Contact>(
      pageGenerator: _defaultPageGenerator(
        this,
        query,
        phoneQuery,
        withThumbnails,
        withHiResPhoto,
        withUnifyInfo,
        sortBy ?? defaultSort,
      ),
      bufferSize: bufferSize,
      length: getTotalContacts(query: query, phoneQuery: phoneQuery),
    );
    return list;
  }

  /// Configures logging.  FlutterPhoneState uses the [logging] plugin.
  @override
  void configureLogs({Level level, LoggingHandler onLog}) {
    configureLogging(LogConfig(
        logLevels: {"contactsService": level},
        handler: onLog ?? LoggingHandler.dev()));
  }

  /// Retrieves a single contact by identifier
  @override
  Future<Contact> getContact(identifier,
      {bool withThumbnails = true,
      bool withHiResPhoto = true,
      bool withUnifyInfo = true}) async {
    final _keys = ContactKeys.of(mode, identifier);
    final fromChannel =
        await channel.invokeMethod('getContact', <String, dynamic>{
      _kidentifier: _keys,
      _kwithThumbnails: withThumbnails,
      kwithUnifyInfo: withUnifyInfo,
      _kphotoHighResolution: withHiResPhoto,
    });
    if (fromChannel == null) return null;
    return Contact.fromMap(fromChannel, mode);
  }

  /// Adds the [contact] to the device contact list - returns the saved contact, so you can access the [identifier]
  @override
  Future<Contact> addContact(Contact contact) async {
    final map = await channel.invokeMethod('addContact', contact.toMap());
    return Contact.fromMap(map, mode);
  }

  /// Deletes the [contact] if it has a valid identifier
  @override
  Future<bool> deleteContact(Contact contact) =>
      channel.invokeMethod('deleteContact', contact.toMap());

  /// Updates the [contact] if it has a valid identifier
  @override
  Future<Contact> updateContact(Contact contact) async {
    final map = await channel.invokeMethod('updateContact', contact.toMap());
    return Contact.fromMap(map ?? {}, mode);
  }

  /// Updates the [contact] if it has a valid identifier
  @override
  Future<Iterable<Group>> getGroups() async {
    Iterable groups = await channel.invokeMethod('getGroups', {});
    return groups.map((g) => Group.fromMap(g));
  }

  Stream<dynamic> _eventStream;

  @override
  Stream<ContactEvent> get contactEvents {
    _eventStream ??= events.receiveBroadcastStream();
    return _eventStream.map((final input) {
      if (input is! Map) {
        _log.severe("Invalid contact event.  Not passing through");
        return null;
      }

      final dyn = (input as Map).cast<String, dynamic>();

      try {
        String eventType = dyn["event"] as String;
        ContactEvent event;
        switch (eventType) {
          case "contacts-changed":
            event = ContactsChangedEvent();
            break;
          default:
            print("Unable to determine type");
            event = UnknownContactEvent(dyn);
            break;
        }
        _log.fine("Contact service event: $event");
        return event;
      } catch (e, stack) {
        _log.severe("Error building event: $e", e, stack);
        return null;
      }
    }).where((event) => event != null);
  }
}

class ContactSortOrder extends Equatable {
  final String _value;

  const ContactSortOrder.lastName() : _value = "lastName";
  const ContactSortOrder.displayName() : _value = "displayName";
  const ContactSortOrder.firstName() : _value = "firstName";

  @override
  List<Object> get props => [_value];
}

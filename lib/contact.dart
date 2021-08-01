import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart'
    hide IterableExtension, IterableNullableExtension;
import 'package:dartxx/dartxx.dart';
import 'package:equatable/equatable.dart';
import 'package:flexidate/flexidate.dart';
import 'package:flutter_contact/single_contacts.dart';
import 'package:flutter_contact/unified_contacts.dart';
import 'package:logging/logging.dart';

final flutterContactLog = Logger('flutterContact');

enum ContactMode { single, unified }

ContactMode? contactModeOf(dyn) {
  if (dyn == null) return null;
  switch (dyn.toString()) {
    case 'single':
      return ContactMode.single;
    case 'unified':
      return ContactMode.unified;
    default:
      return null;
  }
}

///
/// Because you can be dealing with linked contacts (unified) or individual contacts,
/// we use this object to be able to track what sort of contact you're dealing with,
/// and what keys can be used to find, reference, or update it.
// ignore: must_be_immutable
class ContactKeys extends Equatable {
  ContactMode? mode;
  String? identifier;
  String? singleContactId;
  String? unifiedContactId;
  Map<String, String> otherKeys;

  factory ContactKeys(
      {required ContactMode? mode,
      String? identifier,
      String? singleContactId,
      String? unifiedContactId,
      Map<String, String>? otherKeys}) {
    assert(mode != null || identifier == null,
        "You must provide a mode if you provide an identifier");
    if (mode == null) {
      return ContactKeys._(
          identifier: null,
          mode: null,
          unifiedContactId: unifiedContactId,
          singleContactId: singleContactId,
          otherKeys: otherKeys);
    }
    switch (mode) {
      case ContactMode.single:
        assert(identifier == null ||
            singleContactId == null ||
            identifier == singleContactId);
        return ContactKeys._(
          mode: mode,
          identifier: identifier ?? singleContactId,
          singleContactId: identifier ?? singleContactId,
          unifiedContactId: unifiedContactId,
          otherKeys: otherKeys,
        );
      case ContactMode.unified:
        assert(identifier == null ||
            unifiedContactId == null ||
            identifier == unifiedContactId);
        return ContactKeys._(
          mode: mode,
          identifier: identifier ?? unifiedContactId,
          singleContactId: singleContactId,
          unifiedContactId: identifier ?? unifiedContactId,
          otherKeys: otherKeys,
        );

      default:
        return (throw "This can't happen");
    }
  }

  ContactKeys.empty(this.mode)
      : identifier = null,
        unifiedContactId = null,
        singleContactId = null,
        otherKeys = <String, String>{};

  ContactKeys._({
    required this.mode,
    required this.identifier,
    required this.singleContactId,
    required this.unifiedContactId,
    Map<String, String>? otherKeys,
  }) : otherKeys = otherKeys ?? <String, String>{};

  factory ContactKeys.of(ContactMode mode, dyn) {
    if (dyn == null) {
      return ContactKeys.empty(mode);
    } else if (dyn is ContactKeys) {
      return dyn;
    } else if (dyn is Map) {
      return ContactKeys.fromMap(mode, dyn);
    } else if (dyn is String) {
      return ContactKeys.id(mode, dyn);
    } else {
      return (throw "Invalid input for ContactKeys");
    }
  }

  factory ContactKeys.fromMap(ContactMode mode, Map map) {
    final otherKeys = (map[_kotherKeys] ?? {}) as Map;
    return ContactKeys(
      mode: mode,
      identifier: map[_kidentifier]?.toString(),
      singleContactId: map[_ksingleContactId]?.toString(),
      unifiedContactId: map[_kunifiedContactId]?.toString(),
      otherKeys: {
        for (final e in otherKeys.entries)
          if (e.value != null) "${e.key}": "${e.value}",
      },
    );
  }

  Map<String, dynamic> toMap() {
    // ignore: unnecessary_cast
    return {
      'identifier': this.identifier,
      'singleContactId': this.singleContactId,
      'unifiedContactId': this.unifiedContactId,
      'otherKeys': this.otherKeys,
    } as Map<String, dynamic>;
  }

  @override
  List<Object?> get props =>
      [mode, singleContactId, unifiedContactId, otherKeys];

  /// Contact keys that is based on the logic PK for the mode
  factory ContactKeys.id(ContactMode mode, String identifier) {
    return ContactKeys(
        mode: mode,
        identifier: identifier,
        singleContactId: null,
        unifiedContactId: null,
        otherKeys: <String, String>{});
  }
}

class Contact {
  Contact(
      {this.givenName,
      this.identifier,
      this.keys,
      this.middleName,
      this.displayName,
      this.prefix,
      this.suffix,
      this.familyName,
      this.company,
      this.jobTitle,
      List<String>? linkedContactIds,
      List<Item>? emails,
      List<Item>? phones,
      List<PostalAddress>? postalAddresses,
      List<Item>? socialProfiles,
      List<Item>? urls,
      List<ContactDate>? dates,
      this.avatar,
      this.lastModified,
      this.note})
      : _emails = [...?emails],
        _phones = [...?phones],
        _socialProfiles = [...?socialProfiles],
        _urls = [...?urls],
        _dates = [...?dates],
        _linkedContactIds = [...?linkedContactIds],
        _postalAddresses = [...?postalAddresses];

  final ContactKeys? keys;

  String? identifier,
      displayName,
      givenName,
      middleName,
      prefix,
      suffix,
      familyName,
      company,
      jobTitle,
      note;

  final List<String> _linkedContactIds;
  final List<Item> _emails;
  final List<Item> _phones;
  final List<Item> _socialProfiles;
  final List<ContactDate> _dates;
  final List<Item> _urls;
  final List<PostalAddress> _postalAddresses;

  DateTime? lastModified;
  Uint8List? avatar;

  /// If the avatar is already loaded, uses it.  Otherwise, fetches the avatar from the server,
  /// but does not cache the result in memory.
  ///
  /// May be null.
  FutureOr<Uint8List?> getOrFetchAvatar() {
    if (avatar != null) return avatar;

    if (keys?.unifiedContactId == keys?.singleContactId) {
      return UnifiedContacts.getContactImage(this.identifier);
    } else {
      return SingleContacts.getContactImage(this.identifier);
    }
  }

  List<Item> get emails => _emails;

  set emails(List<Item>? value) {
    _emails.clear();
    emails.addAll([...?value]);
  }

  List<Item> get phones => _phones;

  set phones(List<Item>? value) {
    _phones.clear();
    phones.addAll([...?value]);
  }

  List<Item> get socialProfiles => _socialProfiles;

  set socialProfiles(List<Item>? value) {
    _socialProfiles.clear();
    _socialProfiles.addAll([...?value]);
  }

  List<ContactDate> get dates => _dates;

  set dates(List<ContactDate>? value) {
    _dates.clear();
    dates.addAll([...?value]);
  }

  List<String> get linkedContactIds => _linkedContactIds;

  set linkedContactIds(List<String>? value) {
    _linkedContactIds.clear();
    _linkedContactIds.addAll([...?value]);
  }

  List<Item> get urls => _urls;

  set urls(List<Item>? value) {
    _urls.clear();
    urls.addAll([...?value]);
  }

  List<PostalAddress> get postalAddresses => _postalAddresses;

  set postalAddresses(List<PostalAddress>? value) {
    _postalAddresses.clear();
    postalAddresses.addAll([...?value]);
  }

  bool get hasAvatar => avatar?.isNotEmpty == true;

  String initials() {
    return ((this.givenName?.isNotEmpty == true ? this.givenName![0] : "") +
            (this.familyName?.isNotEmpty == true ? this.familyName![0] : ""))
        .toUpperCase();
  }

  static Contact? of(final dyn, ContactMode mode) {
    if (dyn == null) {
      return null;
    } else if (dyn is Contact) {
      return dyn;
    } else {
      return Contact.fromMap(dyn, mode);
    }
  }

  factory Contact.fromMap(final dyn, ContactMode? mode) {
    mode ??= contactModeOf(dyn["mode"])!;
    return Contact(
      identifier: dyn[_kidentifier] as String?,
      displayName: dyn[_kdisplayName] as String?,
      givenName: dyn[_kgivenName] as String?,
      middleName: dyn[_kmiddleName] as String?,
      familyName: dyn[_kfamilyName] as String?,
      prefix: dyn[_kprefix] as String?,
      keys: ContactKeys.of(mode, dyn),
      lastModified: parseDateTime(dyn[_klastModified]),
      suffix: dyn[_ksuffix] as String?,
      company: dyn[_kcompany] as String?,
      jobTitle: dyn[_kjobTitle] as String?,
      linkedContactIds: <String>[
        for (final c in _iterableKey(dyn, _klinkedContactIds)) "$c",
      ],
      emails: [for (final m in _iterableKey(dyn, _kemails)) Item.fromMap(m)]
          .notNullList(),
      phones: [for (final m in _iterableKey(dyn, _kphones)) Item.fromMap(m)]
          .notNullList(),
      socialProfiles: [
        for (final m in _iterableKey(dyn, _ksocialProfiles)) Item.fromMap(m)
      ].whereType<Item>().toList(),
      urls: [for (final m in _iterableKey(dyn, _kurls)) Item.fromMap(m)]
          .notNullList(),
      dates: [
        for (final m in _iterableKey(dyn, _kdates)) ContactDate.fromMap(m)
      ].notNullList(),
      postalAddresses: [
        for (final m in _iterableKey(dyn, _kpostalAddresses))
          PostalAddress.fromMap(m)
      ].notNullList(),
      avatar: dyn[_kavatar] as Uint8List?,
      note: dyn[_knote] as String?,
    );
  }

  Map<String, dynamic> toMap() {
    final _ = _contactToMap(this);
    return _;
  }

  /// The [+] operator fills in this contact's empty fields with the fields from [other]
  Contact operator +(Contact other) => Contact(
      keys: this.keys ?? other.keys,
      identifier: this.identifier ?? other.identifier,
      displayName: this.displayName ?? other.displayName,
      givenName: this.givenName ?? other.givenName,
      middleName: this.middleName ?? other.middleName,
      prefix: this.prefix ?? other.prefix,
      lastModified: this.lastModified ?? other.lastModified,
      suffix: this.suffix ?? other.suffix,
      familyName: this.familyName ?? other.familyName,
      company: this.company ?? other.company,
      jobTitle: this.jobTitle ?? other.jobTitle,
      linkedContactIds: this.linkedContactIds + other.linkedContactIds,
      note: this.note ?? other.note,
      emails: {...this.emails, ...other.emails}.toList(),
      socialProfiles:
          {...this.socialProfiles, ...other.socialProfiles}.toList(),
      dates: {...this.dates, ...other.dates}.toList(),
      urls: {...this.urls, ...other.urls}.toList(),
      phones: {...this.phones, ...other.phones}.toList(),
      postalAddresses:
          {...this.postalAddresses, ...other.postalAddresses}.toList(),
      avatar: this.avatar ?? other.avatar);

  /// Removes duplicates from the collections.  Duplicates are defined as having the exact same value
  Contact removeDuplicates() {
    return this + Contact();
  }

  /// Returns true if all items in this contact are identical.
  @override
  bool operator ==(Object other) {
    return other is Contact &&
        this.keys == other.keys &&
        this.identifier == other.identifier &&
        this.company == other.company &&
        this.displayName == other.displayName &&
        this.givenName == other.givenName &&
        this.familyName == other.familyName &&
        this.jobTitle == other.jobTitle &&
        this.middleName == other.middleName &&
        this.note == other.note &&
        this.prefix == other.prefix &&
        this.suffix == other.suffix &&
        this.lastModified == other.lastModified &&
        DeepCollectionEquality.unordered().equals(this.phones, other.phones) &&
        DeepCollectionEquality.unordered()
            .equals(this.socialProfiles, other.socialProfiles) &&
        DeepCollectionEquality.unordered().equals(this.urls, other.urls) &&
        DeepCollectionEquality.unordered().equals(this.dates, other.dates) &&
        DeepCollectionEquality.unordered().equals(this.emails, other.emails) &&
        DeepCollectionEquality.unordered()
            .equals(this.postalAddresses, other.postalAddresses);
  }

  @override
  int get hashCode {
    return hashOf(identifier, keys, company, displayName, lastModified,
        givenName, familyName, jobTitle, middleName, note, prefix, suffix);
  }
}

class ContactDate {
  final String? label;
  final FlexiDate? date;
  final String? value;

  ContactDate.ofDate({this.label, required FlexiDate this.date})
      : value = "$date";

  ContactDate.ofValue({
    this.label,
    required String this.value,
    this.date,
  });

  ContactDate({
    this.label,
    this.value,
    this.date,
  }) : assert(value != null || date != null);

  static ContactDate? fromMap(final dyn) {
    if (dyn is Map<dynamic, dynamic>) {
      if (dyn[_kdate] == null && dyn[_kvalue] == null) {
        flutterContactLog.warning(
            "Received date with no value for either 'date' or 'value'");
        return null;
      }
      final label = dyn[_klabel] as String?;
      FlexiDate? flexi;
      try {
        flexi = (dyn[_kdate] != null || dyn[_kvalue] != null)
            ? FlexiDate.from(dyn[_kdate] ?? dyn[_kvalue])
            : null;
      } catch (e) {
        flutterContactLog.finer("Error parsing date: $dyn");
      }
      if (flexi?.isValid == true) {
        return ContactDate.ofDate(date: flexi!, label: label);
      } else if (flexi?.isValid == false && flexi?.source != null) {
        return ContactDate.ofValue(value: "$flexi", label: label);
      } else {
        return ContactDate.ofValue(value: dyn[_kvalue] as String, label: label);
      }
    }
    return null;
  }

  String? get dateOrValue => date?.toString() ?? value;

  @override
  String toString() {
    return 'ContactDate{label: $label, date: $date, value: $value}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactDate &&
          label == other.label &&
          date == other.date &&
          value == other.value;

  @override
  int get hashCode => hashOf(label, date, value);
}

// ignore: must_be_immutable
class PostalAddress extends Equatable {
  PostalAddress(
      {this.label,
      this.street,
      this.city,
      this.postcode,
      this.region,
      this.country});

  String? label, street, city, postcode, region, country;

  static PostalAddress? fromMap(final dyn) {
    if (dyn is Map) {
      return PostalAddress(
        label: dyn[_klabel] as String?,
        street: dyn[_kstreet] as String?,
        city: dyn[_kcity] as String?,
        postcode: dyn[_kpostcode] as String?,
        region: dyn[_kregion] as String?,
        country: dyn[_kcountry] as String?,
      );
    } else {
      return null;
    }
  }

  @override
  List get props => [
        this.label,
        this.street,
        this.city,
        this.country,
        this.region,
        this.postcode,
      ];
}

/// Item class used for contact fields which only have a [label] and
/// a [value], such as emails and phone numbers
// ignore: must_be_immutable
class Item extends Equatable {
  Item({this.label, this.value});

  String? label, value;

  static Item? fromMap(final dyn) {
    if (dyn is Map) {
      return Item(
        value: dyn["value"] as String?,
        label: dyn["label"] as String?,
      );
    } else {
      return null;
    }
  }

  String? get equalsValue => value;

  @override
  List get props => [equalsValue];
}

// ignore: must_be_immutable
class PhoneNumber extends Item {
  final String _unformattedNumber;

  PhoneNumber({String? label, String? number})
      : _unformattedNumber = _sanitizer(number),
        super(label: label, value: number);

  @override
  String get equalsValue {
    return _unformattedNumber;
  }

  static PhoneNumberSanitizer _sanitizer = defaultPhoneNumberSanitizer;

  static set sanitizer(PhoneNumberSanitizer sanitizer) {
    _sanitizer = sanitizer;
  }
}

extension ItemToMap on Item? {
  Map<String, String>? toMap() {
    if (this == null) {
      return null;
    } else {
      if (this?.value?.isNotEmpty != true) return null;
      return {
        "label": this!.label,
        "value": this!.value,
      }.valuesNotNull();
    }
  }
}

extension ItemListsToMap on Iterable<Item> {
  List<Map<String, String>> toJson() {
    return [
      for (var i in this) i.toMap(),
    ].notNullList();
  }
}

Iterable _iterableKey(map, String key) {
  if (map == null) return [];
  return map[key] as Iterable? ?? [];
}

Map<String, dynamic> _contactToMap(Contact contact) {
  return {
    _kidentifier: contact.identifier,
    _kdisplayName: contact.displayName,
    _kgivenName: contact.givenName,
    _kmiddleName: contact.middleName,
    _kfamilyName: contact.familyName,
    _klastModified: contact.lastModified?.toIso8601String(),
    _kunifiedContactId: contact.unifiedContactId,
    _ksingleContactId: contact.singleContactId,
    _kotherKeys: contact.otherKeys,
    _kprefix: contact.prefix,
    _ksuffix: contact.suffix,
    _kcompany: contact.company,
    _kjobTitle: contact.jobTitle,
    _kemails: contact.emails.toJson(),
    _kphones: contact.phones.toJson(),
    _kdates: [
      for (final item in contact.dates) _contactDateToMap(item),
    ].notNullList(),
    _ksocialProfiles: contact.socialProfiles.toJson(),
    _kurls: contact.urls.toJson(),
    _kpostalAddresses: [
      for (final address in contact.postalAddresses) address.toMap(),
    ].notNullList(),
    _kavatar: contact.avatar,
    _knote: contact.note
  }.valuesNotNull();
}

bool Function(T item) notNullList<T>() => (item) => item != null;

extension PostalAddressToMap on PostalAddress? {
  Map<String, String>? toMap() {
    if (this == null) return null;
    final address = this!;
    final map = {
      _klabel: address.label,
      _kstreet: address.street,
      _kcity: address.city,
      _kpostcode: address.postcode,
      _kregion: address.region,
      _kcountry: address.country
    }.valuesNotNull();

    /// There will always be a type field, so make sure there's at least one more
    return map.length <= 1 ? null : map;
  }
}

Map<String, dynamic>? _contactDateToMap(ContactDate? date) => date == null
    ? null
    : {
        _klabel: date.label,
        _kdate: date.date?.toDateMap(),
        _kvalue: date.value ?? date.date?.toString(),
      }.valuesNotNull();

typedef PhoneNumberSanitizer = String Function(String?);

String defaultPhoneNumberSanitizer(String? input) {
  String out = "";

  for (var i = 0; i < input!.length; ++i) {
    var char = input[i];
    if (_isNumeric((char))) {
      out += char;
    }
  }

  if (out.length == 10 && !out.startsWith("0") && !out.startsWith("1")) {
    return "1$out";
  } else {
    return out;
  }
}

bool _isNumeric(String? str) {
  if (str == null) {
    return false;
  }
  return double.tryParse(str) != null;
}

DateTime? parseDateTime(final dyn) {
  if (dyn is DateTime) return dyn;
  if (dyn == null) return null;
  return DateTime.tryParse(dyn.toString());
}

const _kgivenName = "givenName";
const _kidentifier = "identifier";
const _kmiddleName = "middleName";
const _kdisplayName = "displayName";
const _kprefix = "prefix";
const _ksuffix = "suffix";
const _kfamilyName = "familyName";
const _kcompany = "company";
const _kunifiedContactId = "unifiedContactId";
const _ksingleContactId = "singleContactId";
const _kotherKeys = "otherKeys";
const _kjobTitle = "jobTitle";
const _kemails = "emails";
const _klinkedContactIds = "linkedContactIds";
const _kphones = "phones";
const _kpostalAddresses = "postalAddresses";
const _ksocialProfiles = "socialProfiles";
const _kurls = "urls";
const _kdates = "dates";
const _kavatar = "avatar";
const _klabel = "label";
const _kdate = "date";
const _kvalue = "value";
const _knote = "note";
const _klastModified = "lastModified";

const _kstreet = "street";
const _kcity = "city";
const _kpostcode = "postcode";
const _kregion = "region";
const _kcountry = "country";

extension FlexiDateToMap on FlexiDate {
  Map<String, int?>? toDateMap() {
    if (this is FlexiDateData && this.isValid) {
      return (this as FlexiDateData).toMap();
    } else {
      return null;
    }
  }
}

extension ContactKeyAccessExt on Contact {
  ContactMode? get mode {
    return keys?.mode;
  }

  bool get isAggregate {
    return keys?.mode == ContactMode.unified;
  }

  String? get unifiedContactId {
    return keys?.unifiedContactId;
  }

  String? get singleContactId {
    return keys?.singleContactId;
  }

  Map<String, String> get otherKeys {
    return keys?.otherKeys ?? const {};
  }

  String? getKey(String name) {
    switch (name) {
      case _kunifiedContactId:
        return keys?.unifiedContactId;
      case _ksingleContactId:
        return keys?.singleContactId;
      case _kidentifier:
        return identifier;
      default:
        if (keys?.otherKeys == null) return null;
        return keys!.otherKeys[name];
    }
  }
}

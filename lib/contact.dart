import 'dart:async';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:equatable/equatable.dart';
import 'package:flutter/widgets.dart';
import 'package:flutter_contact/contacts.dart';
import 'package:sunny_dart/time.dart';

class Contact {
  Contact(
      {this.givenName,
      this.identifier,
      this.middleName,
      this.displayName,
      this.prefix,
      this.suffix,
      this.familyName,
      this.company,
      this.jobTitle,
      List<Item> emails,
      List<Item> phones,
      List<PostalAddress> postalAddresses,
      List<Item> socialProfiles,
      List<Item> urls,
      List<ContactDate> dates,
      this.avatar,
      this.lastModified,
      this.note})
      : _emails = [...?emails],
        _phones = [...?phones],
        _socialProfiles = [...?socialProfiles],
        _urls = [...?urls],
        _dates = [...?dates],
        _postalAddresses = [...?postalAddresses];

  String identifier,
      displayName,
      givenName,
      middleName,
      prefix,
      suffix,
      familyName,
      company,
      jobTitle,
      note;
  final List<Item> _emails;
  final List<Item> _phones;
  final List<Item> _socialProfiles;
  final List<ContactDate> _dates;
  final List<Item> _urls;
  final List<PostalAddress> _postalAddresses;

  DateTime lastModified;
  Uint8List avatar;

  /// If the avatar is already loaded, uses it.  Otherwise, fetches the avatar from the server,
  /// but does not cache the result in memory.
  ///
  /// May be null.
  FutureOr<Uint8List> getOrFetchAvatar() {
    if (avatar != null) return avatar;

    return Contacts.getContactImage(this.identifier);
  }

  List<Item> get emails => _emails;

  set emails(List<Item> value) {
    _emails.clear();
    emails.addAll([...?value]);
  }

  List<Item> get phones => _phones;

  set phones(List<Item> value) {
    _phones.clear();
    phones.addAll([...?value]);
  }

  List<Item> get socialProfiles => _socialProfiles;

  set socialProfiles(List<Item> value) {
    _socialProfiles.clear();
    _socialProfiles.addAll([...?value]);
  }

  List<ContactDate> get dates => _dates;

  set dates(List<ContactDate> value) {
    _dates.clear();
    dates.addAll([...?value]);
  }

  List<Item> get urls => _urls;

  set urls(List<Item> value) {
    _urls.clear();
    urls.addAll([...?value]);
  }

  List<PostalAddress> get postalAddresses => _postalAddresses;

  set postalAddresses(List<PostalAddress> value) {
    _postalAddresses.clear();
    postalAddresses.addAll([...?value]);
  }

  bool get hasAvatar => avatar?.isNotEmpty == true;

  String initials() {
    return ((this.givenName?.isNotEmpty == true ? this.givenName[0] : "") +
            (this.familyName?.isNotEmpty == true ? this.familyName[0] : ""))
        .toUpperCase();
  }

  factory Contact.of(final dyn) {
    if (dyn == null) {
      return null;
    } else if (dyn is Contact) {
      return dyn;
    } else {
      return Contact.fromMap(dyn);
    }
  }

  Contact.fromMap(final dyn)
      : this(
          identifier: dyn[_kidentifier] as String,
          displayName: dyn[_kdisplayName] as String,
          givenName: dyn[_kgivenName] as String,
          middleName: dyn[_kmiddleName] as String,
          familyName: dyn[_kfamilyName] as String,
          prefix: dyn[_kprefix] as String,
          lastModified: parseDateTime(dyn[_klastModified]),
          suffix: dyn[_ksuffix] as String,
          company: dyn[_kcompany] as String,
          jobTitle: dyn[_kjobTitle] as String,
          emails: [
            for (final m in _iterableKey(dyn, _kemails)) Item.fromMap(m)
          ],
          phones: [
            for (final m in _iterableKey(dyn, _kphones)) Item.fromMap(m)
          ],
          socialProfiles: [
            for (final m in _iterableKey(dyn, _ksocialProfiles)) Item.fromMap(m)
          ],
          urls: [for (final m in _iterableKey(dyn, _kurls)) Item.fromMap(m)],
          dates: [
            for (final m in _iterableKey(dyn, _kdates)) ContactDate.fromMap(m)
          ],
          postalAddresses: [
            for (final m in _iterableKey(dyn, _kpostalAddresses))
              PostalAddress.fromMap(m)
          ],
          avatar: dyn[_kavatar] as Uint8List,
          note: dyn[_knote] as String,
        );

  Map<String, dynamic> toMap() {
    return _contactToMap(this);
  }

  /// The [+] operator fills in this contact's empty fields with the fields from [other]
  Contact operator +(Contact other) => Contact(
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
      note: this.note ?? other.note,
      emails: {...?this.emails, ...?other.emails}.toList(),
      socialProfiles:
          {...?this.socialProfiles, ...?other.socialProfiles}.toList(),
      dates: {...?this.dates, ...?other.dates}.toList(),
      urls: {...?this.urls, ...?other.urls}.toList(),
      phones: {...?this.phones, ...?other.phones}.toList(),
      postalAddresses:
          {...?this.postalAddresses, ...?other.postalAddresses}.toList(),
      avatar: this.avatar ?? other.avatar);

  /// Removes duplicates from the collections.  Duplicates are defined as having the exact same value
  Contact removeDuplicates() {
    return this + Contact();
  }

  /// Returns true if all items in this contact are identical.
  @override
  bool operator ==(Object other) {
    return other is Contact &&
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
    return hashValues(identifier, company, displayName, lastModified, givenName,
        familyName, jobTitle, middleName, note, prefix, suffix);
  }
}

class ContactDate {
  final String label;
  final DateComponents date;

  ContactDate({this.label, this.date});

  factory ContactDate.fromMap(final dyn) {
    if (dyn is! Map<dynamic, dynamic> || dyn[_kdate] == null) return null;
    return ContactDate(
        label: dyn[_klabel] as String, date: DateComponents.from(dyn[_kdate]));
  }

  @override
  String toString() {
    return 'ContactDate{label: $label, date: $date}';
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is ContactDate && label == other.label && date == other.date;

  @override
  int get hashCode => hashValues(label, date);
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

  String label, street, city, postcode, region, country;

  PostalAddress.fromMap(final dyn) {
    if (dyn is Map) {
      label = dyn[_klabel] as String;
      street = dyn[_kstreet] as String;
      city = dyn[_kcity] as String;
      postcode = dyn[_kpostcode] as String;
      region = dyn[_kregion] as String;
      country = dyn[_kcountry] as String;
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

  String label, value;

  Item.fromMap(final dyn) {
    if (dyn is Map) {
      value = dyn["value"] as String;
      label = dyn["label"] as String;
    }
  }

  String get equalsValue => value;

  @override
  List get props => [equalsValue];
}

// ignore: must_be_immutable
class PhoneNumber extends Item {
  final String _unformattedNumber;
  PhoneNumber({String label, String number})
      : _unformattedNumber = _sanitizer(number),
        super(label: label, value: number);

  @override
  String get equalsValue {
    return _unformattedNumber;
  }

  static PhoneNumberSanitizer _sanitizer = defaultPhoneNumberSanitizer;
  static set sanitizer(PhoneNumberSanitizer sanitizer) {
    assert(sanitizer != null);
    _sanitizer = sanitizer;
  }
}

Map<String, dynamic> _itemToMap(Item i) => {"label": i.label, "value": i.value};

Iterable _iterableKey(map, String key) {
  if (map == null) return [];
  return map[key] as Iterable ?? [];
}

Map<String, dynamic> _contactToMap(Contact contact) {
  return {
    _kidentifier: contact.identifier,
    _kdisplayName: contact.displayName,
    _kgivenName: contact.givenName,
    _kmiddleName: contact.middleName,
    _kfamilyName: contact.familyName,
    _klastModified: contact.lastModified?.toIso8601String(),
    _kprefix: contact.prefix,
    _ksuffix: contact.suffix,
    _kcompany: contact.company,
    _kjobTitle: contact.jobTitle,
    _kemails: [
      for (final item in contact.emails.where(notNull())) _itemToMap(item)
    ],
    _kphones: [
      for (final item in contact.phones.where(notNull())) _itemToMap(item)
    ],
    _kdates: [
      for (final item in contact.dates.where(notNull())) _contactDateToMap(item)
    ],
    _ksocialProfiles: [
      for (final item in contact.socialProfiles.where(notNull()))
        _itemToMap(item)
    ],
    _kurls: [
      for (final item in contact.urls.where(notNull())) _itemToMap(item)
    ],
    _kpostalAddresses: [
      for (final address in contact.postalAddresses.where(notNull()))
        _addressToMap(address)
    ],
    _kavatar: contact.avatar,
    _knote: contact.note
  };
}

bool Function(T item) notNull<T>() => (item) => item != null;
Map _addressToMap(PostalAddress address) => {
      _klabel: address.label,
      _kstreet: address.street,
      _kcity: address.city,
      _kpostcode: address.postcode,
      _kregion: address.region,
      _kcountry: address.country
    };

Map _contactDateToMap(ContactDate date) => {
      _klabel: date.label,
      _kdate: date.date?.toMap() ?? {},
    };

typedef PhoneNumberSanitizer = String Function(String);

String defaultPhoneNumberSanitizer(String input) {
  String out = "";

  for (var i = 0; i < input.length; ++i) {
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

bool _isNumeric(String str) {
  if (str == null) {
    return false;
  }
  return double.tryParse(str) != null;
}

DateTime parseDateTime(final dyn) {
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
const _kjobTitle = "jobTitle";
const _kemails = "emails";
const _kphones = "phones";
const _kpostalAddresses = "postalAddresses";
const _ksocialProfiles = "socialProfiles";
const _kurls = "urls";
const _kdates = "dates";
const _kavatar = "avatar";
const _klabel = "label";
const _kdate = "date";
const _knote = "note";
const _klastModified = "lastModified";

const _kstreet = "street";
const _kcity = "city";
const _kpostcode = "postcode";
const _kregion = "region";
const _kcountry = "country";

extension _DateComponentsExt on DateComponents {}

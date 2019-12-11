import 'package:equatable/equatable.dart';
import 'package:flutter_contact/contact.dart';

const kid = "id";
const kname = "name";
const kdescription = "description";
const kcontacts = "contacts";

/// Group class used for contact groups or labels
class Group extends Equatable {
  Group(
      {this.identifier, this.name, this.description, Iterable<String> contacts})
      : contacts = (contacts ?? []).cast<String>().toSet();

  final String identifier, name, description;
  final Set<String> contacts;

  Group.fromMap(dyn)
      : this(
            identifier: dyn[kidentifier] as String,
            name: dyn[kname] as String,
            description: dyn[kdescription] as String,
            contacts: (dyn[kcontacts] as Iterable).cast<String>());

  Map toMap() => {
        kid: identifier,
        kname: name,
        kdescription: description,
        kcontacts: contacts.toList()
      };

  @override
  List<Object> get props => [identifier, name, description];
}

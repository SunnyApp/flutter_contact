import 'package:equatable/equatable.dart';

const _kidentifier = "identifier";
const _kid = "id";
const _kname = "name";
const _kdescription = "description";
const _kcontacts = "contacts";

/// Group class used for contact groups or labels
class Group extends Equatable {
  Group(
      {this.identifier, this.name, this.description, Iterable<String>? contacts})
      : contacts = (contacts ?? []).cast<String>().toSet();

  final String? identifier, name, description;
  final Set<String> contacts;

  Group.fromMap(dyn)
      : this(
            identifier: dyn[_kidentifier] as String?,
            name: dyn[_kname] as String?,
            description: dyn[_kdescription] as String?,
            contacts: (dyn[_kcontacts] as Iterable).cast<String>());

  Map toMap() => {
        _kid: identifier,
        _kname: name,
        _kdescription: description,
        _kcontacts: contacts.toList()
      };

  @override
  List<Object?> get props => [identifier, name, description];
}

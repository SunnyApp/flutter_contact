import 'package:equatable/equatable.dart';

/// Group class used for contact groups or labels
class Group extends Equatable {
  Group(
      {this.identifier, this.name, this.description, Iterable<String> contacts})
      : contacts = (contacts ?? []).cast<String>().toSet();

  final String identifier, name, description;
  final Set<String> contacts;

  Group.fromMap(Map m)
      : this(
            identifier: m["identifier"],
            name: m["name"],
            description: m["description"],
            contacts: m["contacts"].cast<String>());

  Map toMap() => {
        'id': identifier,
        'name': name,
        'description': description,
        'contacts': contacts.toList()
      };

  @override
  List<Object> get props => [identifier, name, description];
}

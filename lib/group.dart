import 'package:quiver/core.dart';

/// Group class used for contact groups or labels
class Group {
  Group({this.identifier, this.name, this.description, Iterable<String> contacts})
      : contacts = (contacts ?? []).cast<String>().toSet();

  final String identifier, name, description;
  final Set<String> contacts;

  Group.fromMap(Map m)
      : this(
            identifier: m["identifier"],
            name: m["name"],
            description: m["description"],
            contacts: m["contacts"].cast<String>());

  @override
  bool operator ==(Object other) {
    return other is Group && this.identifier == other.identifier;
  }

  Map toMap() => {'id': identifier, 'name': name, 'description': description, 'contacts': contacts.toList()};

  @override
  int get hashCode => hash2(identifier ?? "", identifier ?? "");
}

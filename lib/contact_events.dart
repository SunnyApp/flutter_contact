abstract class ContactEvent {}

class ContactsChangedEvent implements ContactEvent {
  @override
  String toString() {
    return 'ContactsChangedEvent{}';
  }
}

class UnknownContactEvent implements ContactEvent {
  final Map<String, dynamic> payload;

  UnknownContactEvent(this.payload);

  @override
  String toString() {
    return 'UnknownContactEvent{payload: $payload}';
  }
}

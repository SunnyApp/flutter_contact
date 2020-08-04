# flutter_contact  
[![pub package](https://img.shields.io/pub/v/flutter_contact.svg)](https://pub.dartlang.org/packages/flutter_contact)
[![Coverage Status](https://coveralls.io/repos/github/SunnyApp/flutter_contact/badge.svg?branch=master)](https://coveralls.io/github/SunnyApp/flutter_contact?branch=master)

A Flutter plugin to access and manage the device's native contacts.  
  
## Usage  
  
To use this plugin, add `flutter_contact` as a [dependency in your `pubspec.yaml` file](https://flutter.io/platform-plugins/).  
For example:  
```yaml  
dependencies:  
    flutter_contact: ^0.6.1
```
  
## Permissions  
### Android  
Add the following permissions to your AndroidManifest.xml:  
  
```xml  
<uses-permission android:name="android.permission.READ_CONTACTS" />  
<uses-permission android:name="android.permission.WRITE_CONTACTS" />  
```  
### iOS
Set the `NSContactsUsageDescription` in your `Info.plist` file  
  
```xml  
<key>NSContactsUsageDescription</key>  
<string>Your description of why you are requesting permissions.</string>  
```  

**Note**  
`flutter_contact` does not handle the process of asking and checking for permissions. To check and request user permission to access contacts, try using the following plugins: [flutter_simple_permissions](https://github.com/AppleEducate/flutter_simple_permissions)  or [permission_handler](https://pub.dartlang.org/packages/permission_handler).
  
If you do not request user permission or have it granted, the application will fail. For testing purposes, you can manually set the permissions for your test app in Settings for your app on the device that you are using. For Android, go to "Settings" - "Apps" - select your test app - "Permissions" - then turn "on" the slider for contacts.   
 
## Unified vs Single contacts
There are two main entry points into the application: `SingleContacts` and `UnifiedContacts`.  These share
the same API and most of the underlying code, however:

* `SingleContacts` will interact with the unlinked raw contacts on each platform
* `UnifiedContacts` will interact with linked/aggregated contacts on each platform. 
 
## Memory Efficiency

This plugin tries to be memory and cpu friendly.  It avoid loading your entire address book into memory, 
but rather provides some ways to iterate over contacts in a more memory friendly way:

### Stream
``` dart
import 'package:flutter_contact/contact.dart';  

// By default, this will loop through all contacts using a page size of 20.
await Contacts.streamContacts().forEach((contact) {
    print("${contact.displayName}");
});

// You can manually adjust the buffer size
Stream<Contact> contacts = await Contacts.streamContacts(bufferSize: 50);
```

### Paging List
The second option is a paging list, which also uses an underlying page buffer, 
but doesn't have any subscriptions to manage, and has some other nice features, like
a total count
``` dart
import 'package:flutter_contact/contact.dart';

final contacts = Contacts.listContacts();
final total = await contacts.length;

// This will fetch the page this contact belongs to, and return the contact
final contact = await contacts.get(total - 1);

while(await contacts.moveNext()) {
    final contact = await contacts.current;
}

```

## Example  

``` dart  
// Import package  
import 'package:flutter_contact/contact.dart';  
  
// Get all contacts on device as a stream
Stream<Contact> contacts = await Contacts.streamContacts();  

// Get all contacts without thumbnail(faster)
Iterable<Contact> contacts = await Contacts.streamContacts(withThumbnails: false);
  
// Get contacts matching a string
Stream<Contact> johns = await Contacts.streamContacts(query : "john");

// Add a contact  
// The contact must have a firstName / lastName to be successfully added  
await Contacts.addContact(newContact);  
  
// Delete a contact
// The contact must have a valid identifier
await Contacts.deleteContact(contact);  

// Update a contact
// The contact must have a valid identifier
await Contacts.updateContact(contact);

/// Lazily fetch avatar data without caching it in the contact instance.
final contact = Contacts.getContact(contactId);
final Uint8List avatarData = await contact.getOrFetchAvatar();
```  


## Credits

This plugin was originally a fork of the 
https://pub.dev/packages/flutter_contact plugin, but has effectively been mostly rewritten (in 
part because it was ported to kotlin)


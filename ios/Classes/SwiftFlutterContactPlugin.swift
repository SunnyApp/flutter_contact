import Foundation

import Flutter
import UIKit
import Contacts


@available(iOS 9.0, *)
public class SwiftFlutterContactPlugin: NSObject, FlutterPlugin, FlutterStreamHandler {
    
    var eventSink : FlutterEventSink!
    var syncToken: Data?
    
    
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        self.eventSink = events
        
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(addressBookDidChange),
            name: NSNotification.Name.CNContactStoreDidChange,
            object: nil)
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "github.com/sunnyapp/flutter_contact", binaryMessenger: registrar.messenger())
        let events = FlutterEventChannel(name: "github.com/sunnyapp/flutter_contact_events", binaryMessenger: registrar.messenger())
        let instance = SwiftFlutterContactPlugin()
        registrar.addMethodCallDelegate(instance, channel: channel)
        events.setStreamHandler(instance)
    }
    
    @objc func addressBookDidChange(notification: NSNotification){
        if let eventSink = self.eventSink {
            eventSink(["event": "contacts-changed"])
        }
    }
    
    let contactFetchKeys:[Any] = [CNContactFormatter.descriptorForRequiredKeys(for: .fullName),
                                  CNContactBirthdayKey,
                                  CNContactDatesKey,
                                  CNContactEmailAddressesKey,
                                  CNContactFamilyNameKey,
                                  CNContactGivenNameKey,
                                  CNContactJobTitleKey,
                                  CNContactMiddleNameKey,
                                  CNContactNamePrefixKey,
                                  CNContactNameSuffixKey,
                                  CNContactThumbnailImageDataKey,
                                  CNContactOrganizationNameKey,
                                  CNContactPhoneNumbersKey,
                                  CNContactPostalAddressesKey,
                                  CNContactSocialProfilesKey,
                                  CNContactUrlAddressesKey]
    
    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        
        
        DispatchQueue.global(qos: .userInteractive).async {
            do {
                switch call.method {
                case "getContacts":
                    let contacts: [CNContact] = try self.getContacts(query: call.getString("query"),
                                                                     withThumbnails: call.getBool("withThumbnails"),
                                                                     photoHighResolution: call.getBool("photoHighResolution"),
                                                                     forCount: false,
                                                                     phoneQuery: call.getBool("phoneQuery"),
                                                                     limit: call.arg("limit"),
                                                                     offset: call.arg("offset"),
                                                                     ids: call.argx("ids") ?? [String](),
                                                                     sortBy: call.getString("sortBy"))
                    result(contacts.map{$0.toDictionary()})
                    
                case "getTotalContacts":
                    let contacts: [CNContact] = try self.getContacts(query: call.getString("query"),
                                                                     withThumbnails: false,
                                                                     photoHighResolution: false,
                                                                     forCount: true,
                                                                     phoneQuery: call.getBool("phoneQuery"),
                                                                     limit: 1000,
                                                                     offset: 0,
                                                                     ids: call.argx("ids") ?? [String]())
                    result(contacts.count)
                case "getContact":
                    let contact: CNContact? = try self.getContact(identifier: call.getString("identifier")!,
                                                                  withThumbnails: call.getBool("withThumbnails"),
                                                                  photoHighResolution: call.getBool("photoHighResolution"))
                    result(contact?.toDictionary())
                case "getGroups":
                    result(try self.getGroups())
                case "addContact":
                    let contact = CNMutableContact()
                    contact.takeFromDictionary(call.args)
                    let saved = try self.addContact(contact: contact)
                    result(saved.toDictionary())
                case "deleteContact":
                    let deleted = try self.deleteContact(call.args)
                    result(deleted)
                case "updateContact":
                    let contact = try self.updateContact(call.args)
                    result(contact.toDictionary())
                case "getContactImage":
                    let imageData = try self.getContactImage(identifier: call.arg("identifier"))
                    if let imageData = imageData {
                        result(FlutterStandardTypedData(bytes: imageData))
                    }else {
                        result(nil)
                    }
                    
                default:
                    result(FlutterMethodNotImplemented)
                }
            } catch let error as PluginError {
                switch(error) {
                case .runtimeError(let code, let message):
                    result(FlutterError(
                        code: code,
                        message: message,
                        details: nil))
                }
            } catch _ as NSError {
                result(FlutterError(
                    code: "unknown",
                    message: "unknown error",
                    details: nil))
            }
        }
        
    }
    
    func getGroups() throws ->[[String:Any?]] {
        let store = CNContactStore()
        
        // Fetch groups
        let groups:[[String:Any]] = try store.groups(matching: nil)
            .map { group in
                var dict = [String:Any]()
                dict["identifier"] = group.identifier
                dict["name"] = group.name
                dict["description"] = group.description
                dict["contacts"] = try store.unifiedContacts(
                    matching: CNContact.predicateForContactsInGroup(withIdentifier: group.identifier),
                    keysToFetch: [CNContactIdentifierKey as CNKeyDescriptor])
                    .map { $0.identifier }
                
                return dict
        }
        return groups
        
    }
    
    func getContacts(query : String?, withThumbnails: Bool, photoHighResolution: Bool, forCount: Bool,
                     phoneQuery: Bool, limit: Int, offset: Int, ids: [String], sortBy: String? = nil) throws -> [CNContact] {
        
        var contacts : [CNContact] = []
        
        //Create the store, keys & fetch request
        let store = CNContactStore()
        
        var keys = forCount ? [Any]() : contactFetchKeys
        
        if (withThumbnails) {
            if(photoHighResolution) {
                keys.append(CNContactImageDataKey)
            } else {
                keys.append(CNContactThumbnailImageDataKey)
            }
        }
        
        let fetchRequest = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        // Set the predicate if there is a query
        if query != nil && !phoneQuery {
            fetchRequest.predicate = CNContact.predicateForContacts(matchingName: query!)
        }
        
        
        switch (sortBy ?? "lastName") {
        case "firstName":
            fetchRequest.sortOrder = CNContactSortOrder.givenName
        case "lastName":
            fetchRequest.sortOrder = CNContactSortOrder.familyName
        default:
            fetchRequest.sortOrder = CNContactSortOrder.userDefault
        }
        
        // Fetch contacts
        var count = 0
        try store.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop ) -> Void in
            if contacts.count >= limit {
                stop.initialize(to: true)
                return
            }
            if phoneQuery {
                if query != nil && self.has(contact: contact, phone: query!) {
                    if count >= offset {
                        contacts.append(contact)
                    }
                    count = count + 1
                }
            } else {
                if count >= offset {
                    contacts.append(contact)
                }
                count = count + 1
            }
            
        })
        return contacts
    }
    
    func getContact(identifier : String, withThumbnails: Bool, photoHighResolution: Bool) throws -> CNContact? {
        
        var result : CNContact? = nil
        
        //Create the store, keys & fetch request
        let store = CNContactStore()
        var keys = contactFetchKeys
        
        if(withThumbnails){
            keys.append(CNContactThumbnailImageDataKey)
            if(photoHighResolution){
                keys.append(CNContactImageDataKey)
            }
        }
        
        let fetchRequest = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        
        // Query by identifier
        fetchRequest.predicate = CNContact.predicateForContacts(withIdentifiers: [identifier])
        
        // Fetch contacts
        try store.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop) -> Void in
            result = contact
            stop.initialize(to: true)
        })
        
        return result
    }
    
    
    @available(iOS 9.0, *)
    private func has(contact: CNContact, phone: String) -> Bool {
        if (!contact.phoneNumbers.isEmpty) {
            let phoneNumberToCompareAgainst = phone.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
            for phoneNumber in contact.phoneNumbers {
                
                if let phoneNumberStruct = phoneNumber.value as CNPhoneNumber? {
                    let phoneNumberString = phoneNumberStruct.stringValue
                    let phoneNumberToCompare = phoneNumberString.components(separatedBy: NSCharacterSet.decimalDigits.inverted).joined(separator: "")
                    if phoneNumberToCompare == phoneNumberToCompareAgainst {
                        return true
                    }
                }
            }
        }
        return false
    }
    
    @available(iOS 9.0, *)
    func addContact(contact : CNMutableContact) throws -> CNMutableContact  {
        let store = CNContactStore()
        let saveRequest = CNSaveRequest()
        saveRequest.add(contact, toContainerWithIdentifier: nil)
        try store.execute(saveRequest)
        return contact
    }
    
    @available(iOS 9.0, *)
    func deleteContact(_ dictionary: [String:Any?]) throws -> Bool {
        guard let identifier = dictionary["identifier"] as? String else {
            throw PluginError.runtimeError(code: "invalid.input", message: "No identifier for contact")
        }
        
        let keys = [CNContactIdentifierKey as NSString]
        let store = CNContactStore()
        if let contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keys).mutableCopy() as? CNMutableContact{
            let request = CNSaveRequest()
            request.delete(contact)
            try store.execute(request)
            return true
        } else {
            return false
        }
    }
    
    func getContactImage(identifier: String) throws -> Data? {
        let imageKeys = [CNContactThumbnailImageDataKey as NSString, CNContactImageDataKey as NSString]
        let fetchRequest = CNContactFetchRequest(keysToFetch: imageKeys as [CNKeyDescriptor])
        
        // Query by identifier
        fetchRequest.predicate = CNContact.predicateForContacts(withIdentifiers: [identifier])
        
        var result: CNContact? = nil
        // Fetch contacts
        try CNContactStore().enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop) -> Void in
            result = contact
            stop.initialize(to: true)
        })
        
        guard let contact = result else {
            throw PluginError.runtimeError(code: "recordNotFound", message: "Contact not found with this id")
        }
        
        return contact.getAvatarData()
    }
    
    @available(iOS 9.0, *)
    func updateContact(_ dictionary : [String:Any?]) throws -> CNMutableContact {
        
        // Check to make sure dictionary has an identifier
        guard let identifier = dictionary["identifier"] as? String else {
            throw PluginError.runtimeError(code: "invalid.input", message: "No identifier for contact");
        }
        
        let store = CNContactStore()
        var keys = contactFetchKeys
        keys.append(CNContactImageDataKey)
        keys.append(CNContactDatesKey)
        
        // Check if the contact exists
        if let contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keys as! [CNKeyDescriptor]).mutableCopy() as? CNMutableContact {
            
            contact.takeFromDictionary(dictionary)
            
            // Attempt to update the contact
            let request = CNSaveRequest()
            request.update(contact)
            try store.execute(request)
            return contact
        } else {
            throw PluginError.runtimeError(code: "contact.notFound", message: "Couldn't find contact")
        }
    }
}

extension Date {
    
    ///Convert date to string using ISO formatting e.g., YYYY-MM-DD
    func string(_ dateFormat: String, useUTC: Bool = false) -> String {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        if useUTC {
            dateFormatter.timeZone = TimeZone(abbreviation: "UTC")
        }
        dateFormatter.dateFormat = dateFormat
        let string = dateFormatter.string(from: self)
        return string
    }
    
    var isoDateString: String {
        return string("yyyy-MM-dd")
    }
    
    ///Turns a CNDate into the start of day for the local time zone
    var convertFromCNDate: Date? {
        var year = string("yyyy", useUTC: true)
        if (Int(year) ?? 0) <= 1 {//some dates from iOS come in with no year?
            year = Date().string("yyyy")
        }
        let month = string("MM", useUTC: true)
        let day = string("dd", useUTC: true)
        return "\(year)\(month)\(day)".parseDate(format: "yyyyMMdd")
    }
}





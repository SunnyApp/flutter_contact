import Foundation

import Flutter
import UIKit
import Contacts
import ContactsUI


@available(iOS 9.0, *)
public class SwiftFlutterContactPlugin: NSObject, FlutterPlugin {
    
    var mode: ContactMode!
    
    public init(mode:ContactMode) {
        super.init()
        var mode = mode
        mode.plugin = self
        self.mode = mode
    }
    
    public static func registerMode(mode: ContactMode, registrar: FlutterPluginRegistrar) {
        
        let plugin = SwiftFlutterContactPlugin(mode: mode)
        let channel = FlutterMethodChannel(name: mode.channelName, binaryMessenger: registrar.messenger())
        
        registrar.addMethodCallDelegate(plugin, channel: channel)
        plugin.registerEvents(registrar: registrar)
        plugin.preLoadContactView()
    }
    
    public static func register(with registrar: FlutterPluginRegistrar) {
        registerMode(mode: SingleMode(), registrar: registrar)
        registerMode(mode: UnifiedMode(), registrar: registrar)
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
                    let contacts: [UnifiedContact] = try self.getContacts(query: call.getString("query"),
                                                                     withThumbnails: call.getBool("withThumbnails"),
                                                                     photoHighResolution: call.getBool("photoHighResolution"),
                                                                     forCount: false,
                                                                     withUnifyInfo: call.getBool("withUnifyInfo"),
                                                                     phoneQuery: call.getBool("phoneQuery"),
                                                                     limit: call.arg("limit"),
                                                                     offset: call.arg("offset"),
                                                                     ids: call.argx("ids") ?? [String](),
                                                                     sortBy: call.getString("sortBy"))
                    result(contacts.map{$0.toDictionary()})
                    
                case "getTotalContacts":
                    let contacts: [UnifiedContact] = try self.getContacts(query: call.getString("query"),
                                                                     withThumbnails: false,
                                                                     photoHighResolution: false,
                                                                     forCount: true,
                                                                     withUnifyInfo: false,
                                                                     phoneQuery: call.getBool("phoneQuery"),
                                                                     limit: 1000,
                                                                     offset: 0,
                                                                     ids: call.argx("ids") ?? [String]())
                    result(contacts.count)
                case "getContact":
                    let key = try self.contactKeyOf(call.args["identifier"]!)
                    let contact = try self.getContact(key: key,
                                                      withThumbnails: call.getBool("withThumbnails"),
                                                      photoHighResolution: call.getBool("photoHighResolution"),
                                                      withUnifyInfo: call.getBool("withUnifyInfo"))
                    result(contact?.toDictionary())
                case "getUnifySummary":
                    result(try self.calculateLinkedContacts())
                case "getGroups":
                    result(try self.getGroups())
                case "addContact":
                    let contact = CNMutableContact()
                    contact.takeFromDictionary(call.args)
                    let saved = try self.addContact(contact: contact)
                    result(saved.toDictionary(self.mode))
                case "deleteContact":
                    let deleted = try self.deleteContact(call.args)
                    result(deleted)
                case "updateContact":
                    let contact = try self.updateContact(call.args)
                    result(contact.toDictionary(self.mode))
                case "getContactImage":
                    let key = try self.contactKeyOf(call.args["identifier"]!)
                    let imageData = try self.getContactImage(key: key)
                    if let imageData = imageData {
                        result(FlutterStandardTypedData(bytes: imageData))
                    } else {
                        result(nil)
                    }
                case "openContactEditForm":
                    // Check to make sure dictionary has an identifier
                    let key = try self.contactKeyOf(call.args["identifier"]!)
                    let _ = try self.openContactEditForm(result: result, key: key)
                    
                case "openContactInsertForm":
                    // Check to make sure dictionary has an identifier
                    let contactData:[String:Any?]? = call.arguments as? [String:Any?]
                    var contact:CNContact? = nil
                    if let contactData = contactData {
                        let mutable = CNMutableContact()
                        mutable.takeFromDictionary(contactData)
                        contact = mutable
                    }
                    let _ = self.openContactInsertForm(result: result, contact: contact)
                    
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
            } catch let genError as NSError {
                result(FlutterError(
                    code: "unknown",
                    message: "unknown error",
                    details: "\(genError.code)"))
            }
        }
        
    }
    
    func calculateLinkedContacts(_ forId: String? = nil) throws -> [String: [String]] {
        // First get all raw contact ids, then iterate over unified records and map them
        var result = [String: [String]]()
        var rawContactIds = Set([String]())
        let fetchRequest = CNContactFetchRequest(keysToFetch: [CNKeyDescriptor]())
        fetchRequest.unifyResults = false
        if let forId = forId  {
            fetchRequest.predicate = CNContact.predicateForContacts(withIdentifiers: [forId])
        }
        let store = CNContactStore()
        try store.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop ) -> Void in
            rawContactIds.insert(contact.identifier)
        })
        
        fetchRequest.unifyResults = true
        // Now, fetch all unified contacts and link them with the others
        //fetchRequest.unifyResults = true
        try store.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop ) -> Void in
            var linked = [String]()
            if rawContactIds.contains(contact.identifier) {
                linked.append(contact.identifier)
            }
            rawContactIds.forEach {
                if contact.isUnifiedWithContact(withIdentifier: $0) {
                    linked.append($0)
                }
            }
            result[contact.identifier] = linked
        })
        return result
    }
    
    func calculateUnifiedContactId(_ singleContactId: String) throws -> String {
        // First get all raw contact ids, then iterate over unified records and map them
        let fetchRequest = CNContactFetchRequest(keysToFetch: [CNKeyDescriptor]())
        fetchRequest.unifyResults = false
        fetchRequest.predicate = CNContact.predicateForContacts(withIdentifiers: [singleContactId])
        
        let store = CNContactStore()
        let result = try store.unifiedContact(withIdentifier: singleContactId, keysToFetch: [CNKeyDescriptor]())
        return result.identifier
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
    
    func getContacts(query : String?, withThumbnails: Bool, photoHighResolution: Bool, forCount: Bool, withUnifyInfo: Bool,
                     phoneQuery: Bool, limit: Int, offset: Int, ids: [String], sortBy: String? = nil) throws -> [UnifiedContact] {
        
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
        
        fetchRequest.unifyResults = self.mode.unifyResults
        
        var linkedContactIds: [String: [String]] = [String: [String]]()
        if withUnifyInfo {
            linkedContactIds = try calculateLinkedContacts()
        }
        var backRefs = [String: String]()
        linkedContactIds.forEach { (unifiedId, linkedIds) in
            linkedIds.forEach { singleId in
                backRefs[singleId] = unifiedId
            }
        }
        
        switch (sortBy ?? "lastName") {
        case "firstName":
            fetchRequest.sortOrder = CNContactSortOrder.givenName
        case "lastName":
            fetchRequest.sortOrder = CNContactSortOrder.familyName
        case "displayName":
            fetchRequest.sortOrder = CNContactSortOrder.userDefault
            
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
        
        return contacts.map {contact in
            contact.toUnifyInfo(self.mode,
                                linkedContactIds: linkedContactIds[contact.identifier],
                                unifiedContactId: backRefs[contact.identifier])
        }
    }
    
    func getContact(key: ContactKey, withThumbnails: Bool, photoHighResolution: Bool, withUnifyInfo: Bool = false, forEditForm: Bool = false) throws -> UnifiedContact? {
        
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
        
        if (forEditForm) {
            keys.append(CNContactViewController.descriptorForRequiredKeys())
        }
        
        let fetchRequest = CNContactFetchRequest(keysToFetch: keys as! [CNKeyDescriptor])
        fetchRequest.unifyResults = self.mode.unifyResults
        
        // Query by identifier
        fetchRequest.predicate = CNContact.predicateForContacts(withIdentifiers: [key.identifier])
        
        // Fetch contacts
        try store.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop) -> Void in
            result = contact
            stop.initialize(to: true)
        })
        
        guard let found = result else {
            return nil
        }
        if(withUnifyInfo) {
            return try self.mode.calculateUnifyInfo(found)
        } else {
            return found.toUnifyInfo(self.mode)
        }
        
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
        let key = try contactKeyOf(dictionary["identifier"]!)
        let keys = [CNContactIdentifierKey as NSString]
        let store = CNContactStore()
        if let contact = try self.mode.getContact(store: store, key: key, fetch: keys).mutableCopy() as? CNMutableContact {
            let request = CNSaveRequest()
            request.delete(contact)
            try store.execute(request)
            return true
        } else {
            return false
        }
        
    }
    
    func getContactImage(key: ContactKey) throws -> Data? {
        let imageKeys = [CNContactThumbnailImageDataKey as NSString, CNContactImageDataKey as NSString]
        let fetchRequest = CNContactFetchRequest(keysToFetch: imageKeys as [CNKeyDescriptor])
        fetchRequest.unifyResults = self.mode.unifyResults
        // Query by identifier
        fetchRequest.predicate = CNContact.predicateForContacts(withIdentifiers: [key.identifier])
        
        let contact = try self.mode.getContact(store: CNContactStore(), key: key, fetch: imageKeys)
        
        return contact.getAvatarData()
    }
    
    @available(iOS 9.0, *)
    func updateContact(_ dictionary : [String:Any?]) throws -> CNMutableContact {
        
        let key = try contactKeyOf(dictionary["identifier"]!)
        
        let store = CNContactStore()
        var keys = contactFetchKeys
        keys.append(CNContactImageDataKey)
        keys.append(CNContactDatesKey)
        
        // Check if the contact exists
        if let contact = try self.mode.getContact(store: store, key: key, fetch: keys as! [CNKeyDescriptor]).mutableCopy() as? CNMutableContact {
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
    
    func contactKeyOf(_ key: Any?) throws -> ContactKey {
        guard let key = tryContactKeyOf(key) else {
            throw PluginError.runtimeError(code: "invalid.input", message: "No identifier for contact")
        }
        return key
    }
    
    func tryContactKeyOf(_ key: Any?) -> ContactKey? {
        if let key = key as? ContactKey {
            return key
        } else if let key = key as? String {
            return self.mode.key(key)
        } else if let key = key as? [String: Any?] {
            var singleContactId: String? = key["singleContactId"] as? String
            var unifiedContactId: String? = key["unifiedContactId"] as? String
            if let id = key["identifier"] as? String {
                if self.mode is UnifiedMode {
                    unifiedContactId = id
                } else {
                    singleContactId = id
                }
            }
            return ContactKey(mode: self.mode, unifiedContactId: unifiedContactId, singleContactId: singleContactId)
        } else {
            return nil
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

enum ErrorCodes: String, CustomStringConvertible {
    case formOperationCancelled = "formOperationCancelled"
    case formCouldNotBeOpened = "formCouldNotBeOpened"
    case notFound = "notFound"
    case unknownError = "unknownError"
    case invalidParameter = "invalidParameter"
    
    var description: String {
        get {
            return self.rawValue
        }
    }
}

@available(iOS 9.0, *)
public protocol ContactMode {
    var name: String {get}
    var plugin: SwiftFlutterContactPlugin! {get set}
    var channelName: String {get}
    var eventsName:String {get}
    var unifyResults:Bool {get}
    func getContact(store: CNContactStore, key: ContactKey, fetch: [CNKeyDescriptor]) throws -> CNContact
    func key(_ identifier: String)->ContactKey
    func calculateUnifyInfo(_ forContact: CNContact) throws -> UnifiedContact
}

@available(iOS 9.0, *)
class UnifiedMode: ContactMode {
    
    let name = "unified"
    var plugin: SwiftFlutterContactPlugin!
    
    func key(_ identifier: String) -> ContactKey {
        return ContactKey(mode: self, unifiedContactId: identifier, singleContactId: nil)
    }
    
    func calculateUnifyInfo(_ forContact: CNContact) throws-> UnifiedContact {
        let res = try plugin.calculateLinkedContacts(forContact.identifier)
        return forContact.toUnifyInfo(self, linkedContactIds: res[forContact.identifier] ?? [String]())
    }
    
    func getContact(store: CNContactStore, key: ContactKey, fetch: [CNKeyDescriptor]) throws-> CNContact {
        return try store.unifiedContact(withIdentifier: key.identifier, keysToFetch: fetch)
    }
    
    var channelName: String = "github.com/sunnyapp/flutter_unified_contact"
    
    var eventsName: String = "github.com/sunnyapp/flutter_unified_contact_events"
    var unifyResults: Bool = true
}

@available(iOS 9.0, *)
class SingleMode: ContactMode {
    var plugin: SwiftFlutterContactPlugin!
    
    let name = "single"
    var channelName: String = "github.com/sunnyapp/flutter_single_contact"
    
    var eventsName: String = "github.com/sunnyapp/flutter_single_contact_events"
    var unifyResults: Bool = false
    func key(_ identifier: String) -> ContactKey {
        return ContactKey(mode: self, unifiedContactId: nil, singleContactId: identifier)
    }
    
    func calculateUnifyInfo(_ forContact: CNContact) throws-> UnifiedContact {
        let res = try plugin.calculateLinkedContacts(forContact.identifier)
        return forContact.toUnifyInfo(self, linkedContactIds: res[forContact.identifier] ?? [String]())
    }
    
    func getContact(store: CNContactStore, key: ContactKey, fetch: [CNKeyDescriptor]) throws -> CNContact {
        _ = CNContact.predicateForContactsInContainer(withIdentifier: key.identifier)
        let request = CNContactFetchRequest(keysToFetch: fetch)
        request.unifyResults = false
        request.predicate = CNContact.predicateForContacts(withIdentifiers: [key.identifier])
        var found: CNContact? = nil
        try store.enumerateContacts(with: request) {
            (contact, stop) in
            found = contact
            stop.initialize(to: true)
        }
        guard let result = found else {
            throw PluginError.runtimeError(code: "invalid.id", message: "Invalid identifier for contact")
        }
        return result
    }
}

@available(iOS 9.0, *)
public struct UnifiedContact {
    let contact: CNContact
    let mode: ContactMode
    let unifiedContactId: String?
    let linkedContactIds: [String]?
    
    func toDictionary() -> [String: Any] {
        var base = self.contact.toDictionary(self.mode)
        if let uid = self.unifiedContactId {
            base["unifiedContactId"] = uid
        }
        if let lids = self.linkedContactIds {
            base["linkedContactIds"] = lids
        }
        base["mode"] = mode.name
        return base
    }
}

@available(iOS 9.0, *)
public struct ContactKey {
    let mode: ContactMode
    var identifier: String {
        get {
            if mode is UnifiedMode {
                return unifiedContactId!
            }
            else {
                return singleContactId!
            }
            
        }
    }
    let unifiedContactId: String?
    let singleContactId: String?
}

@available(iOS 9.0, *)
extension CNContact {
    func toUnifyInfo(_ mode: ContactMode, linkedContactIds: [String]? = nil, unifiedContactId: String? = nil)-> UnifiedContact {
        return UnifiedContact(contact: self, mode: mode, unifiedContactId: unifiedContactId, linkedContactIds: linkedContactIds)
    }
}

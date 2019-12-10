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
        do {
            switch call.method {
            case "getContacts":
                let contacts: [CNContact] = try getContacts(query: call.getString("query"),
                                       withThumbnails: call.getBool("withThumbnails"),
                                       photoHighResolution: call.getBool("photoHighResolution"),
                                       phoneQuery: false,
                                       limit: call.argx("limit") ?? 50,
                                       offset: call.argx("offset") ?? 0,
                                       ids: call.argx("ids") ?? [String]())
                result(contacts.map{$0.toDictionary()})
            
            case "getContact":
                let contact: CNContact? = try getContact(identifier: call.getString("identifier")!,
                                                         withThumbnails: call.getBool("withThumbnails"),
                                                         photoHighResolution: call.getBool("photoHighResolution"))
                result(contact?.toDictionary())
            case "getGroups":
                result(try getGroups())
            case "addContact":
                let contact = CNMutableContact()
                contact.takeFromDictionary(call.args)
                let saved = try addContact(contact: contact)
                result(saved.toDictionary())
            case "deleteContact":
                let deleted = try deleteContact(call.args)
                result(deleted)
            case "updateContact":
                let contact = try updateContact(call.args)
                result(contact.toDictionary())
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

    func getContacts(query : String?, withThumbnails: Bool, photoHighResolution: Bool, phoneQuery: Bool,
                     limit: Int, offset: Int, ids: [String]) throws -> [CNContact] {

        var contacts : [CNContact] = []

        //Create the store, keys & fetch request
        let store = CNContactStore()

        var keys = contactFetchKeys

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

        // Fetch contacts
        var count = 0
        try store.enumerateContacts(with: fetchRequest, usingBlock: { (contact, stop ) -> Void in
            if count >= limit {
                stop.initialize(to: true)
                return
            }
            if phoneQuery {
                if query != nil && self.has(contact: contact, phone: query!) {
                    if count >= offset {
                        contacts.append(contact)
                        count = count + 1
                    }
                }
            } else {
                if count >= offset {
                    contacts.append(contact)
                    count = count + 1
                }
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
        let store = CNContactStore()
        let keys = [CNContactIdentifierKey as NSString]

        if let contact = try store.unifiedContact(withIdentifier: identifier, keysToFetch: keys).mutableCopy() as? CNMutableContact{
            let request = CNSaveRequest()
            request.delete(contact)
            try store.execute(request)
            return true
        } else {
            return false
        }

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

@available(iOS 9.0, *)
extension CNContact {

    func toDictionary() -> [String:Any]{
        let contact = self
        var result = [String:Any]()

        //Simple fields
        result["identifier"] = contact.identifier
        result["displayName"] = CNContactFormatter.string(from: contact, style: CNContactFormatterStyle.fullName)
        result["givenName"] = contact.givenName
        result["familyName"] = contact.familyName
        result["middleName"] = contact.middleName
        result["prefix"] = contact.namePrefix
        result["suffix"] = contact.nameSuffix
        result["company"] = contact.organizationName
        result["jobTitle"] = contact.jobTitle
        //  result["note"] = contact.note
        if contact.isKeyAvailable(CNContactThumbnailImageDataKey) {
            if let avatarData = contact.thumbnailImageData {
                result["avatarThumbnail"] = FlutterStandardTypedData(bytes: avatarData)
            }
        }

        if contact.isKeyAvailable(CNContactThumbnailImageDataKey) {
            if let avatarData = contact.thumbnailImageData {
                result["avatar"] = FlutterStandardTypedData(bytes: avatarData)
            }
        }
        if contact.isKeyAvailable(CNContactImageDataKey) {
            if let avatarData = contact.imageData {
                result["avatar"] = FlutterStandardTypedData(bytes: avatarData)
            }
        }

        if contact.isKeyAvailable(CNContactPhoneNumbersKey) {
            //Phone numbers
            var phoneNumbers = [[String:String]]()
            for phone in contact.phoneNumbers{
                var phoneDictionary = [String:String]()
                phoneDictionary["value"] = phone.value.stringValue
                phoneDictionary["label"] = "other"
                if let label = phone.label{
                    phoneDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: label)
                }
                phoneNumbers.append(phoneDictionary)
            }
            result["phones"] = phoneNumbers
        }

        if contact.isKeyAvailable(CNContactEmailAddressesKey) {
            //Emails
            var emailAddresses = [[String:String]]()
            for email in contact.emailAddresses{
                var emailDictionary = [String:String]()
                emailDictionary["value"] = String(email.value)
                emailDictionary["label"] = "other"
                if let label = email.label{
                    emailDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: label)
                }
                emailAddresses.append(emailDictionary)
            }
            result["emails"] = emailAddresses
        }

        if contact.isKeyAvailable(CNContactPostalAddressesKey) {
            //Postal addresses
            var postalAddresses = [[String:String]]()
            for address in contact.postalAddresses{
                var addressDictionary = [String:String]()
                addressDictionary["label"] = ""
                if let label = address.label{
                    addressDictionary["label"] = CNLabeledValue<NSString>.localizedString(forLabel: label)
                }
                addressDictionary["street"] = address.value.street
                addressDictionary["city"] = address.value.city
                addressDictionary["postcode"] = address.value.postalCode
                addressDictionary["region"] = address.value.state
                addressDictionary["country"] = address.value.country

                postalAddresses.append(addressDictionary)
            }
            result["postalAddresses"] = postalAddresses
        }

        if contact.isKeyAvailable(CNContactSocialProfilesKey) {
            var socialProfiles = [[String:String]]()
            for profile in contact.socialProfiles {

                var profileDict = [String:String]()
                profileDict["label"] = profile.value.service
                profileDict["value"] = String(profile.value.username)
                socialProfiles.append(profileDict)
            }
            result["socialProfiles"] = socialProfiles
        }

        if contact.isKeyAvailable(CNContactUrlAddressesKey) {
            var urlAddresses = [[String:String]]()
            for url in contact.urlAddresses {
                var urlDict = [String:String]()
                urlDict["label"] = "other"
                urlDict["value"] = String(url.value)
                if let label = url.label{
                    urlDict["label"] = CNLabeledValue<NSString>.localizedString(forLabel: label)
                }
                urlAddresses.append(urlDict)
            }
            result["urls"] = urlAddresses
        }

        if contact.isKeyAvailable(CNContactDatesKey) {
            var dates = [[String:Any]]()
            for date in contact.dates {
                var dateDict = [String:Any]()
                dateDict["label"] = "other"
                dateDict["date"] = date.value.toDict()
                if let label = date.label{
                    dateDict["label"] = CNLabeledValue<NSString>.localizedString(forLabel: label)
                }
                dates.append(dateDict)
            }
            if let bDay = contact.birthday?.toDict() {
                dates.append([
                    "label": "birthday",
                    "date": bDay])
            }
            result["dates"] = dates
        }
        return result
    }

}

@available(iOS 9.0, *)
extension CNMutableContact {
    func takeFromDictionary(_ dictionary: [String:Any?]) {
        let contact = self
        /// Update the contact that was retrieved from the store
        //Simple fields
        contact.givenName = dictionary["givenName"] as? String ?? ""
        contact.familyName = dictionary["familyName"] as? String ?? ""
        contact.middleName = dictionary["middleName"] as? String ?? ""
        contact.namePrefix = dictionary["prefix"] as? String ?? ""
        contact.nameSuffix = dictionary["suffix"] as? String ?? ""
        contact.organizationName = dictionary["company"] as? String ?? ""
        contact.jobTitle = dictionary["jobTitle"] as? String ?? ""
        //contact.note = dictionary["note"] as? String ?? ""
        contact.imageData = (dictionary["avatar"] as? FlutterStandardTypedData)?.data

        //Phone numbers
        if let phoneNumbers = dictionary["phones"] as? [[String:String]] {
            var updatedPhoneNumbers = [CNLabeledValue<CNPhoneNumber>]()
            for phone in phoneNumbers where phone["value"] != nil {
                updatedPhoneNumbers.append(CNLabeledValue(label:phone["label"]?.toPhoneLabel() ?? "",
                                                          value: CNPhoneNumber(stringValue: phone["value"]!)))
            }
            contact.phoneNumbers = updatedPhoneNumbers
        }

        //Emails
        if let emails = dictionary["emails"] as? [[String:String]]{
            var updatedEmails = [CNLabeledValue<NSString>]()
            for email in emails where nil != email["value"] {
                let emailLabel = email["label"] ?? ""
                updatedEmails.append(CNLabeledValue(label: emailLabel, value: email["value"]! as NSString))
            }
            contact.emailAddresses = updatedEmails
        }

        //Social profiles
        if let socialProfiles = dictionary["socialProfiles"] as? [[String:String]]{
            var updatedItems = [CNLabeledValue<CNSocialProfile>]()
            for item in socialProfiles where nil != item["value"] && nil != item["label"] {
                updatedItems.append(CNLabeledValue(label: item["label"],
                                                   value: CNSocialProfile(urlString: nil,
                                                                          username: item["value"]!,
                                                                          userIdentifier: item["value"]!,
                                                                          service:  item["label"])))
            }
            contact.socialProfiles = updatedItems
        }

        // Websites
        if let urls = dictionary["urls"] as? [[String:String]]{
            var updatedItems = [CNLabeledValue<NSString>]()
            for item in urls where nil != item["value"] {
                updatedItems.append(CNLabeledValue(label: item["label"] ?? "",
                                                   value: item["value"]! as NSString))
            }
            contact.urlAddresses = updatedItems
        }

        // Dates
        if let dates = dictionary["dates"] as? [[String:Any?]] {
            var updatedItems = [CNLabeledValue<NSDateComponents>]()
            for item in dates where nil != item["date"] && nil != item["label"] {
                if let date = item["date"] as? [String:Int] {
                    let dateComp = convertNSDateComponents(date)
                    let label = item["label"] as! String
                    
                    if label == "birthday" {
                        contact.birthday = convertDateComponents(date)
                    } else {
                        updatedItems.append(CNLabeledValue(
                            label: item["label"] as? String ?? "",
                            value: dateComp))
                    }
                }
            }
            contact.dates = updatedItems
        }


        //Postal addresses
        if let postalAddresses = dictionary["postalAddresses"] as? [[String:String]]{
            var updatedPostalAddresses = [CNLabeledValue<CNPostalAddress>]()
            for postalAddress in postalAddresses{
                let newAddress = CNMutablePostalAddress()
                newAddress.street = postalAddress["street"] ?? ""
                newAddress.city = postalAddress["city"] ?? ""
                newAddress.postalCode = postalAddress["postcode"] ?? ""
                newAddress.country = postalAddress["country"] ?? ""
                newAddress.state = postalAddress["region"] ?? ""
                let label = postalAddress["label"] ?? ""
                updatedPostalAddresses.append(CNLabeledValue(label: label, value: newAddress))
            }
            contact.postalAddresses = updatedPostalAddresses
        }
    }
}




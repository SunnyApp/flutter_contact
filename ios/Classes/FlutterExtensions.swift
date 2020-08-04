//
//  FlutterExtensions.swift
//  flutter_contact
//
//  Created by Eric Martineau on 12/10/19.
//

import Foundation
import Contacts
import Flutter

extension FlutterMethodCall {
    
    func arg<T>(_ key: String) throws -> T {
        guard let val = args[key] as? T else {
            throw PluginError.runtimeError(code: "invalidType", message: "Invalid Type")
        }
        
        return val
    }
    
    func argx<T>(_ key: String) throws -> T? {
        return args[key] as? T
    }
    
    func getBool(_ key: String)-> Bool {
        return (args[key] as? Bool) ?? false
    }
    
    func getString(_ key: String)-> String? {
        return args[key] as? String
    }
    
    func getDict(_ key: String)-> [String:Any?] {
        return (args[key] as? [String:Any?]) ?? [String:Any?]()
    }
    
    // Quick way to access args as a dictionary
    var args: [String:Any?] {
        get {
            return self.arguments as? [String:Any?] ?? [String:Any?]()
        }
    }
}

enum PluginError: Error {
    case runtimeError(code:String, message:String)
}

extension String {
    ///Attempts to parse a date from string in yyyyMMdd format
    func parseDate(format: String) -> Date? {
        let dateFormatter = DateFormatter()
        dateFormatter.locale = Locale(identifier: "en_US_POSIX")
        dateFormatter.dateFormat = format
        return dateFormatter.date(from: self)
    }
    
    @available(iOS 9.0, *)
    func toPhoneLabel() -> String{
        let labelValue = self
        switch(labelValue){
        case "main": return CNLabelPhoneNumberMain
        case "mobile": return CNLabelPhoneNumberMobile
        case "iPhone": return CNLabelPhoneNumberiPhone
        default: return labelValue
        }
    }
}

func convertNSDateComponents(_ dict: [String:Int])-> NSDateComponents {
    var nsDate = NSDateComponents()
    nsDate.takeFrom(dictionary: dict)
    return nsDate
}


func convertDateComponents(_ dict: [String:Int])-> DateComponents {
    var nsDate = DateComponents()
    nsDate.takeFrom(dictionary: dict)
    return nsDate
}

protocol DComponents {
    var year: Int { get set }
    var month: Int { get set }
    var day: Int { get set }
}

extension DComponents {
    // Takes values from a dictionary
    mutating func takeFrom(dictionary: [String:Int]) {
        if let year = dictionary["year"] {
            self.year = year
        }
        if let month = dictionary["month"] {
            self.month = month
        }
        if let day = dictionary["day"] {
            self.day = day
        }
    }
    
    // Parses a string and populates this date
    mutating func takeFrom(string: String) {
        let parts = string.split(separator: "-")
            .flatMap { $0.split(separator: "/") }
            .map{ Int($0) }
            .compactMap{$0}
        
        if parts.count == 1 {
            // Year
            
            if parts.first! > 1000 {
                self.year = parts.first!
            } else {
                self.day = parts.first!
            }
            
        } else if parts.count == 2 {
            if parts.contains(where: {$0 > 1000}) {
                for part in parts {
                    if part > 1000 {
                        self.year = part
                    } else {
                        self.month = part
                    }
                }
            } else {
                self.month = parts[0]
                self.day = parts[1]
            }
        } else if parts.count == 3 {
            if parts[0] > 1000 {
                self.year = parts[0]
                self.month = parts[1]
                self.day = parts[2]
                
            } else {
                self.month = parts[0]
                self.day = parts[1]
                self.year = parts[2]
            }
        } else {
            return
        }
    }
    
    func toDict() -> [String:Int] {
        var dict = [String:Int]()
        if self.year != NSDateComponentUndefined {
            dict["year"] = self.year
        }
        
        if self.month != NSDateComponentUndefined {
            dict["month"] = self.month
        }
        
        if self.day != NSDateComponentUndefined {
            dict["day"] = self.day
        }
        
        return dict
    }
}

extension DateComponents: DComponents {
    var year: Int {
        get { self.value(for: .year)! }
        set(value) { self.setValue(value, for: .year) }
    }
    
    var month: Int {
        get { self.value(for: .month)! }
        set(value) { self.setValue(value, for: .month) }
    }
    
    var day: Int {
        get { self.value(for: .day)! }
        set(value) { self.setValue(value, for: .day) }
    }
}

extension NSDateComponents: DComponents {
    var year: Int {
        get { self.value(forComponent: .year) }
        set(value) { self.setValue(value, forComponent: .year) }
    }
    
    var month: Int {
        get { self.value(forComponent: .month) }
        set(value) { self.setValue(value, forComponent: .month) }
    }
    
    var day: Int {
      get { self.value(forComponent: .day) }
        set(value) { self.setValue(value, forComponent: .day) }
    }
}

@available(iOS 9.0, *)
extension CNContact {
    
    func toDictionary(_ mode: ContactMode) -> [String:Any]{
        let contact = self
        var result = [String:Any]()
        
        //Simple fields
        result["identifier"] = contact.identifier
        if mode is UnifiedMode {
            result["mode"] = "unified"
        } else {
            result["mode"] = "single"
        }
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
    
    func getAvatarData() -> Data? {
        if self.isKeyAvailable(CNContactImageDataKey) {
            if let imageData = self.imageData {
                return imageData
            } else {
                if self.isKeyAvailable(CNContactThumbnailImageDataKey) {
                    return self.thumbnailImageData
                }
            }
        }
        
        return nil
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
                if let phoneNumber = phone["value"] {
                    if !phoneNumber.isEmpty {
                        updatedPhoneNumbers.append(
                            CNLabeledValue(
                                label:phone["label"]?.toPhoneLabel() ?? "",
                                value: CNPhoneNumber(stringValue:phoneNumber)))
                    }
                }
            }
            contact.phoneNumbers = updatedPhoneNumbers
        }
        
        //Emails
        if let emails = dictionary["emails"] as? [[String:String]]{
            var updatedEmails = [CNLabeledValue<NSString>]()
            for email in emails where nil != email["value"] {
                let emailLabel = email["label"] ?? ""
                if let emailValue = email["value"] {
                    updatedEmails.append(CNLabeledValue(label: emailLabel, value: emailValue as NSString))
                }
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


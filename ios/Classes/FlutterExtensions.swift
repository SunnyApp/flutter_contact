//
//  FlutterExtensions.swift
//  flutter_contact
//
//  Created by Eric Martineau on 12/10/19.
//

import Foundation
import Contacts

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



//
//  ContactEventHandler.swift
//  flutter_contact
//
//  Created by Eric Martineau on 12/12/19.
//

import Foundation
import Flutter


var eventSink: FlutterEventSink!

@available(iOS 9.0, *)
extension SwiftFlutterContactPlugin: FlutterStreamHandler {
    public func onListen(withArguments arguments: Any?, eventSink events: @escaping FlutterEventSink) -> FlutterError? {
        eventSink = events
        NotificationCenter.default.addObserver(
            forName: NSNotification.Name.CNContactStoreDidChange,
            object: nil,
            queue: nil,
            using: { notification in
                // We don't get anything else right now from Apple.  Maybe at some point...
                if let eventSink = eventSink {
                    eventSink(["event": "contacts-changed"])
                }
        })
        
        return nil
    }
    
    public func onCancel(withArguments arguments: Any?) -> FlutterError? {
        NotificationCenter.default.removeObserver(self)
        eventSink = nil
        return nil
    }
    
    public func registerEvents(registrar: FlutterPluginRegistrar) {
        let events = FlutterEventChannel(name: self.mode.eventsName,
                                         binaryMessenger: registrar.messenger())
        
        events.setStreamHandler(self)
    }
}

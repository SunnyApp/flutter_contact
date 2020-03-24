//
//  ContactFormsHandler.swift
//  flutter_contact
//
//  Created by Eric Martineau on 3/23/20.
//

import Foundation
import Contacts
import ContactsUI
import Flutter

var flutterResult: FlutterResult? = nil

@available(iOS 9.0, *)
extension SwiftFlutterContactPlugin: CNContactViewControllerDelegate {
    
    
    func openContactInsertForm(result: @escaping FlutterResult, contact:CNContact?=nil) ->  [String:Any]? {
        flutterResult = result
        let contact = contact ?? CNMutableContact.init()
        let controller = CNContactViewController.init(forNewContact:contact)
        controller.delegate = self
        DispatchQueue.main.async {
            let navigation = UINavigationController .init(rootViewController: controller)
            let viewController : UIViewController? = UIApplication.shared.delegate?.window??.rootViewController
            viewController?.present(navigation, animated:true, completion: nil)
        }
        return nil
    }
    func openContactEditForm(result: @escaping FlutterResult, identifier:String) throws ->  [String:Any]? {
        flutterResult = result
    
        do {
            
            guard let cnContact = try self.getContact(identifier: identifier, withThumbnails: false, photoHighResolution: false, forEditForm: true) else {
                throw PluginError.runtimeError(code: ErrorCodes.notFound.description, message: "contact not found")
            }
            
            let viewController = CNContactViewController(for: cnContact)
            viewController.navigationItem.backBarButtonItem = UIBarButtonItem.init(title: "Cancel", style: UIBarButtonItem.Style.plain,
                                                                                   target: self, action: #selector(cancelContactForm))
            viewController.delegate = self
            DispatchQueue.main.async {
                let navigation = UINavigationController .init(rootViewController: viewController)
                var currentViewController = UIApplication.shared.keyWindow?.rootViewController
                while let nextView = currentViewController?.presentedViewController {
                    currentViewController = nextView
                }
                let activityIndicatorView = UIActivityIndicatorView.init(style: UIActivityIndicatorView.Style.gray)
                activityIndicatorView.frame = (UIApplication.shared.keyWindow?.frame)!
                activityIndicatorView.startAnimating()
                activityIndicatorView.backgroundColor = UIColor.white
                navigation.view.addSubview(activityIndicatorView)
                currentViewController!.present(navigation, animated: true, completion: nil)
                
                DispatchQueue.main.asyncAfter(deadline: .now()+0.5 ){
                    activityIndicatorView.removeFromSuperview()
                }
            }
            return nil
        } catch {
            NSLog(error.localizedDescription)
            throw PluginError.runtimeError( code: ErrorCodes.formCouldNotBeOpened.description,
                                            message: "Error opening form: \(error.localizedDescription)")
        }
    }
    
    public func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true, completion: nil)
        if let result = flutterResult {
            if let contact = contact {
                result(contactResult(contact: contact))
            } else {
                result(contactFailResult(code: ErrorCodes.formOperationCancelled.description))
            }
            flutterResult = nil
        }
    }
    
    func preLoadContactView() {
        DispatchQueue.main.asyncAfter(deadline: .now()+5) {
            NSLog("Preloading CNContactViewController")
            let _ = CNContactViewController.init(forNewContact: nil)
        }
    }
    
    @objc func cancelContactForm() {
        if let result = flutterResult {
            let viewController : UIViewController? = UIApplication.shared.delegate?.window??.rootViewController
            viewController?.dismiss(animated: true, completion: nil)
            result(contactFailResult(code: ErrorCodes.formOperationCancelled.description))
            flutterResult = nil
        }
    }
    
}

func contactFailResult(code: String)-> [String:Any] {
    return ["successful": false, "code": code]
    
}

@available(iOS 9.0, *)
func contactResult(contact:CNContact)-> [String:Any] {
    return ["successful": true, "contact": contact.toDictionary()]
    
}

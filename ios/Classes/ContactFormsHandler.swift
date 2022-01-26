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
extension SwiftFlutterContactPlugin: CNContactViewControllerDelegate, CNContactPickerDelegate {
    
    
    func openContactInsertForm(result: @escaping FlutterResult, contact: CNContact?=nil) ->  [String:Any]? {
        flutterResult = result
        let contact = contact ?? CNMutableContact.init()
    
        DispatchQueue.main.async {
            let vc = CNContactViewController.init(forNewContact: contact)
            vc.delegate = self
            vc.navigationItem.backBarButtonItem = UIBarButtonItem.init(title: "Cancel", style: UIBarButtonItem.Style.plain,
                                                                                   target: self, action: #selector(self.cancelContactForm))
            vc.view.layoutIfNeeded()
            let navigation = UINavigationController .init(rootViewController: vc)
            var rvc = UIApplication.shared.keyWindow?.rootViewController
            while let nextView = rvc?.presentedViewController {
                rvc = nextView
            }
            rvc?.present(navigation, animated:true, completion: nil)
        }
        return nil
    }
    func openContactEditForm(result: @escaping FlutterResult, key: ContactKey) throws ->  [String:Any]? {
        flutterResult = result
    
        do {
            guard let cnContact = try self.getContact(key: key,
                                                      withThumbnails: false,
                                                      photoHighResolution: false,
                                                      forEditForm: true) else {
                throw PluginError.runtimeError(code: ErrorCodes.notFound.description, message: "contact not found")
            }
            
            let viewController = CNContactViewController(for: cnContact.contact)
            viewController.delegate = self
            DispatchQueue.main.async {
                
                viewController.navigationItem.backBarButtonItem = UIBarButtonItem.init(title: "Cancel", style: UIBarButtonItem.Style.plain,
                                                                                       target: self, action: #selector(self.cancelContactForm))
                viewController.view.layoutIfNeeded()
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

    func openContactPicker(result: @escaping FlutterResult) {
        flutterResult = result
        DispatchQueue.main.async {
          let contactPicker = CNContactPickerViewController()
          contactPicker.delegate = self
          var rvc = UIApplication.shared.keyWindow?.rootViewController
          while let nextView = rvc?.presentedViewController {
            rvc = nextView
          }
          rvc?.present(contactPicker, animated:true, completion: nil)
        }
    }

    func insertOrUpdateContactViaPicker(result: @escaping FlutterResult, contact: CNContact?=nil) -> [String:Any]? {
        flutterResult = result
        let contact = contact ?? CNMutableContact()
        DispatchQueue.main.async {
            let cnvc = CNContactViewController(forUnknownContact:contact)
            cnvc.delegate = self
            cnvc.contactStore = CNContactStore()
//             cnvc.displayedPropertyKeys = [CNContactPhoneNumbersKey]
            cnvc.allowsActions = false
            cnvc.allowsEditing = false
            cnvc.edgesForExtendedLayout = []
            cnvc.view.layoutIfNeeded()
            let navigationController = UINavigationController .init(rootViewController: cnvc)
            if #available(iOS 13.0, *) {
                // use the feature available in iOS 13 or later
                navigationController.navigationBar.backgroundColor = .systemBackground
            } else {
                navigationController.navigationBar.backgroundColor = .white
            }
            var rvc = UIApplication.shared.keyWindow?.rootViewController
            while let nextView = rvc?.presentedViewController {
                rvc = nextView
            }
            rvc?.present(navigationController, animated: true, completion: nil)
        }
        return nil
    }

    //MARK:- CNContactPickerDelegate Method
    public func contactPicker(_ picker: CNContactPickerViewController, didSelect contact: CNContact) {
        if let result = flutterResult {
          result(contactResult(self.mode, contact: contact))
          flutterResult = nil
        }
    }

    public func contactPickerDidCancel(_ picker: CNContactPickerViewController) {
        if let result = flutterResult {
          result(contactFailResult(code: ErrorCodes.formOperationCancelled.description))
          flutterResult = nil
        }
    }
    
    public func contactViewController(_ viewController: CNContactViewController, didCompleteWith contact: CNContact?) {
        viewController.dismiss(animated: true, completion: nil)
        if let result = flutterResult {
            if let contact = contact {
                result(contactResult(self.mode, contact: contact))
            } else {
                result(contactFailResult(code: ErrorCodes.formOperationCancelled.description))
            }
            flutterResult = nil
        }
    }
    
    func preLoadContactView() {
        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
            NSLog("Preloading CNContactViewController")
            let controller = CNContactViewController.init(forNewContact: nil)
            controller.view.layoutIfNeeded()
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
    return ["success": false, "code": code]
    
}

@available(iOS 9.0, *)
func contactResult(_ mode: ContactMode, contact:CNContact)-> [String:Any] {
    return ["success": true, "contact": contact.toDictionary(mode)]
    
}
